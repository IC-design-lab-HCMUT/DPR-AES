#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <strings.h>
#include <ctype.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>

#define AXI_BASE        0xA0000000UL
#define MAP_SIZE        0x10000

#define COMMAND_OFF     0x00
#define STATUS_OFF      0x04
#define RM_CONTROL_OFF  0x08

#define KEY0_OFF        0x10
#define PT0_OFF         0x30
#define CT0_OFF         0x40

#define STATUS_DONE     0x1
#define STATUS_READY    0x2

#define AES_TIMEOUT_NS  100000000ULL

#define FPGAUTIL_PATH   "/usr/sbin/fpgautil"
#define FPGA_STATE_PATH "/sys/class/fpga_manager/fpga0/state"

static volatile uint32_t *regs = NULL;

typedef struct {
    const char *name;
    const char *bitfile;
} variant_t;

static const variant_t variants[] = {
    {"LUT",       "/home/ubuntu/aes256_lut_partial.bit.bin"},
    {"BRAM",      "/home/ubuntu/aes256_bram_partial.bit.bin"},
    {"COMPOSITE", "/home/ubuntu/aes256_composite_partial.bit.bin"},
    {"NOISE",     "/home/ubuntu/aes256_dummy_noise_partial.bit.bin"}
};

#define NUM_VARIANTS ((int)(sizeof(variants) / sizeof(variants[0])))

static const char *nist_files[] = {
    "ECBGFSbox256.rsp",
    "ECBKeySbox256.rsp",
    "ECBVarKey256.rsp",
    "ECBVarTxt256.rsp"
};

#define NUM_NIST_FILES ((int)(sizeof(nist_files) / sizeof(nist_files[0])))

typedef struct {
    unsigned long total;
    unsigned long pass;
    unsigned long fail;
    unsigned long ready_timeout;
    unsigned long done_timeout;
} rm_stats_t;

static uint64_t diff_ns(struct timespec a, struct timespec b)
{
    return (uint64_t)(b.tv_sec - a.tv_sec) * 1000000000ULL +
           (uint64_t)(b.tv_nsec - a.tv_nsec);
}

static inline void mmio_write(uint32_t off, uint32_t value)
{
    regs[off / 4] = value;
    __sync_synchronize();
}

static inline uint32_t mmio_read(uint32_t off)
{
    uint32_t value = regs[off / 4];
    __sync_synchronize();
    return value;
}

static char *trim(char *s)
{
    char *end;
    while (isspace((unsigned char)*s))
        s++;
    if (*s == '\0')
        return s;
    end = s + strlen(s) - 1;
    while (end > s && isspace((unsigned char)*end))
        end--;
    end[1] = '\0';
    return s;
}

static int file_readable(const char *path)
{
    return access(path, R_OK) == 0;
}

static int hex_to_words_le(const char *hex, uint32_t *words, int nwords)
{
    int expected_len = nwords * 8;
    int len = (int)strlen(hex);

    if (len != expected_len)
        return -1;

    for (int i = 0; i < nwords; i++) {
        int start = len - (i + 1) * 8;
        char tmp[9];
        memcpy(tmp, hex + start, 8);
        tmp[8] = '\0';

        char *endptr = NULL;
        unsigned long value = strtoul(tmp, &endptr, 16);

        if (endptr == tmp || *endptr != '\0')
            return -1;

        words[i] = (uint32_t)value;
    }

    return 0;
}

static void words_to_hex_be(const uint32_t *words, int nwords,
                            char *out, size_t out_size)
{
    size_t need = (size_t)nwords * 8 + 1;

    if (out_size < need) {
        if (out_size > 0)
            out[0] = '\0';
        return;
    }

    char *p = out;

    for (int i = nwords - 1; i >= 0; i--) {
        sprintf(p, "%08X", words[i]);
        p += 8;
    }

    *p = '\0';
}

static int fpga_is_operating(void)
{
    int fd = open(FPGA_STATE_PATH, O_RDONLY);

    if (fd < 0) {
        perror("open FPGA state");
        return 0;
    }

    char buf[64] = {0};
    ssize_t n = read(fd, buf, sizeof(buf) - 1);
    close(fd);

    if (n <= 0)
        return 0;

    buf[n] = '\0';

    return strstr(buf, "operating") != NULL;
}

static int load_partial(const char *bitfile)
{
    pid_t pid = fork();

    if (pid < 0) {
        perror("fork");
        return -1;
    }

    if (pid == 0) {
        execl(FPGAUTIL_PATH,
              "fpgautil",
              "-b", bitfile,
              "-f", "Partial",
              (char *)NULL);

        _exit(127);
    }

    int status = 0;

    if (waitpid(pid, &status, 0) < 0) {
        perror("waitpid");
        return -1;
    }

    if (!WIFEXITED(status))
        return -1;

    if (WEXITSTATUS(status) != 0)
        return -1;

    return 0;
}

static int dpr_switch(int target, uint64_t *dpr_ns)
{
    struct timespec t0, t1;

    *dpr_ns = 0;

    clock_gettime(CLOCK_MONOTONIC_RAW, &t0);

    mmio_write(RM_CONTROL_OFF, 0x1);

    if (load_partial(variants[target].bitfile) != 0) {
        mmio_write(RM_CONTROL_OFF, 0x0);
        return -1;
    }

    if (!fpga_is_operating()) {
        mmio_write(RM_CONTROL_OFF, 0x0);
        return -2;
    }

    mmio_write(RM_CONTROL_OFF, 0x0);

    if (mmio_read(RM_CONTROL_OFF) != 0x0)
        return -3;

    clock_gettime(CLOCK_MONOTONIC_RAW, &t1);

    *dpr_ns = diff_ns(t0, t1);

    return 0;
}

static int wait_status(uint32_t mask, uint32_t expected,
                       uint64_t timeout_ns, uint32_t *last_status)
{
    struct timespec t0, t1;

    clock_gettime(CLOCK_MONOTONIC_RAW, &t0);

    while (1) {
        uint32_t status = mmio_read(STATUS_OFF);

        if (last_status)
            *last_status = status;

        if ((status & mask) == expected)
            return 0;

        clock_gettime(CLOCK_MONOTONIC_RAW, &t1);

        if (diff_ns(t0, t1) >= timeout_ns)
            return -1;
    }
}

static int run_aes_case(const uint32_t key[8],
                        const uint32_t pt[4],
                        const uint32_t expected_ct[4],
                        uint32_t actual_ct[4],
                        uint32_t *final_status)
{
    uint32_t status = 0;

    if (wait_status(STATUS_READY, STATUS_READY,
                    AES_TIMEOUT_NS, &status) != 0) {
        if (final_status)
            *final_status = status;
        return 2;
    }

    for (int i = 0; i < 8; i++)
        mmio_write(KEY0_OFF + 4 * i, key[i]);

    for (int i = 0; i < 4; i++)
        mmio_write(PT0_OFF + 4 * i, pt[i]);

    mmio_write(COMMAND_OFF, 0x1);

    usleep(100);

    if (wait_status(STATUS_DONE, STATUS_DONE,
                    AES_TIMEOUT_NS, &status) != 0) {
        if (final_status)
            *final_status = status;
        return 3;
    }

    for (int i = 0; i < 4; i++)
        actual_ct[i] = mmio_read(CT0_OFF + 4 * i);

    if (final_status)
        *final_status = status;

    for (int i = 0; i < 4; i++) {
        if (actual_ct[i] != expected_ct[i])
            return 1;
    }

    return 0;
}

static int run_rsp_file(const char *rm_name,
                        const char *rsp_path,
                        const char *suite_name,
                        uint64_t dpr_ns,
                        FILE *csv,
                        rm_stats_t *stats)
{
    FILE *fp = fopen(rsp_path, "r");

    if (!fp) {
        perror(rsp_path);
        return -1;
    }

    char line[1024];

    int in_encrypt = 0;
    long count = -1;

    char key_hex[65] = {0};
    char pt_hex[33] = {0};
    char ct_hex[33] = {0};

    int cases_in_file = 0;

    while (fgets(line, sizeof(line), fp)) {
        char *s = trim(line);

        if (*s == '\0' || *s == '#')
            continue;

        if (*s == '[') {
            in_encrypt = (strncasecmp(s, "[ENCRYPT]", 9) == 0);
            continue;
        }

        if (!in_encrypt)
            continue;

        if (strncasecmp(s, "COUNT", 5) == 0) {
            char *eq = strchr(s, '=');
            if (eq)
                count = strtol(trim(eq + 1), NULL, 10);
            continue;
        }

        if (strncasecmp(s, "KEY", 3) == 0) {
            char *eq = strchr(s, '=');
            if (eq)
                snprintf(key_hex, sizeof(key_hex), "%s", trim(eq + 1));
            continue;
        }

        if (strncasecmp(s, "PLAINTEXT", 9) == 0) {
            char *eq = strchr(s, '=');
            if (eq)
                snprintf(pt_hex, sizeof(pt_hex), "%s", trim(eq + 1));
            continue;
        }

        if (strncasecmp(s, "CIPHERTEXT", 10) == 0) {
            char *eq = strchr(s, '=');

            if (!eq)
                continue;

            snprintf(ct_hex, sizeof(ct_hex), "%s", trim(eq + 1));

            uint32_t key[8];
            uint32_t pt[4];
            uint32_t expected[4];
            uint32_t actual[4] = {0, 0, 0, 0};

            if (hex_to_words_le(key_hex, key, 8) != 0 ||
                hex_to_words_le(pt_hex, pt, 4) != 0 ||
                hex_to_words_le(ct_hex, expected, 4) != 0) {

                fprintf(stderr,
                        "Parse error: %s COUNT=%ld\n",
                        suite_name, count);

                fclose(fp);
                return -1;
            }

            uint32_t status = 0;

            int result = run_aes_case(
                key, pt, expected, actual, &status
            );

            const char *result_str;

            stats->total++;
            cases_in_file++;

            if (result == 0) {
                stats->pass++;
                result_str = "PASS";
            }
            else if (result == 1) {
                stats->fail++;
                result_str = "FAIL";
            }
            else if (result == 2) {
                stats->ready_timeout++;
                result_str = "READY_TIMEOUT";
            }
            else {
                stats->done_timeout++;
                result_str = "DONE_TIMEOUT";
            }

            char actual_hex[33];
            words_to_hex_be(actual, 4, actual_hex, sizeof(actual_hex));

            fprintf(csv,
                    "%s,%s,%ld,%s,%.6f,0x%08X,%s,%s,%s\n",
                    rm_name,
                    suite_name,
                    count,
                    result_str,
                    dpr_ns / 1000000.0,
                    status,
                    key_hex,
                    pt_hex,
                    actual_hex);

            if (result != 0) {
                fprintf(stderr,
                        "%s %-18s COUNT=%ld -> %s\n",
                        rm_name, suite_name, count, result_str);
                fprintf(stderr,
                        "  Expected CT = %s\n", ct_hex);
                fprintf(stderr,
                        "  Actual CT   = %s\n", actual_hex);
            }

            count = -1;
            key_hex[0] = '\0';
            pt_hex[0] = '\0';
            ct_hex[0] = '\0';
        }
    }

    fclose(fp);

    printf("  %-18s : %d cases processed\n",
           suite_name, cases_in_file);

    return 0;
}

int main(int argc, char **argv)
{
    const char *nist_dir =
        (argc >= 2) ? argv[1] : "/home/ubuntu/benchmarks";

    printf("============================================================\n");
    printf(" AES-256 DPR NIST ECB KAT VERIFICATION\n");
    printf("============================================================\n");
    printf("NIST directory: %s\n", nist_dir);
    printf("============================================================\n");

    if (access(FPGAUTIL_PATH, X_OK) != 0) {
        fprintf(stderr,
                "ERROR: %s not found or not executable\n",
                FPGAUTIL_PATH);
        return 1;
    }

    for (int i = 0; i < NUM_VARIANTS; i++) {
        if (!file_readable(variants[i].bitfile)) {
            fprintf(stderr,
                    "ERROR: missing partial bitstream: %s\n",
                    variants[i].bitfile);
            return 1;
        }
    }

    char rsp_paths[NUM_NIST_FILES][512];

    for (int i = 0; i < NUM_NIST_FILES; i++) {
        snprintf(rsp_paths[i], sizeof(rsp_paths[i]),
                 "%s/%s", nist_dir, nist_files[i]);

        if (!file_readable(rsp_paths[i])) {
            fprintf(stderr,
                    "ERROR: missing NIST file: %s\n",
                    rsp_paths[i]);
            return 1;
        }
    }

    int memfd = open("/dev/mem", O_RDWR | O_SYNC);

    if (memfd < 0) {
        perror("open /dev/mem");
        return 1;
    }

    regs = mmap(NULL,
                MAP_SIZE,
                PROT_READ | PROT_WRITE,
                MAP_SHARED,
                memfd,
                AXI_BASE);

    if (regs == MAP_FAILED) {
        perror("mmap");
        close(memfd);
        return 1;
    }

    if (!fpga_is_operating()) {
        fprintf(stderr,
                "ERROR: FPGA manager is not in operating state\n");
        munmap((void *)regs, MAP_SIZE);
        close(memfd);
        return 1;
    }

    FILE *csv = fopen("aes256_dpr_nist_results.csv", "w");

    if (!csv) {
        perror("fopen CSV");
        munmap((void *)regs, MAP_SIZE);
        close(memfd);
        return 1;
    }

    fprintf(csv,
            "rm,suite,count,result,dpr_ms,status,key,plaintext,actual_ciphertext\n");

    rm_stats_t stats[NUM_VARIANTS];
    memset(stats, 0, sizeof(stats));

    int fatal_error = 0;

    for (int rm = 0; rm < NUM_VARIANTS; rm++) {
        printf("\n============================================================\n");
        printf("RM: %s\n", variants[rm].name);
        printf("Partial: %s\n", variants[rm].bitfile);
        printf("============================================================\n");

        uint64_t dpr_ns = 0;

        int sw = dpr_switch(rm, &dpr_ns);

        if (sw != 0) {
            fprintf(stderr,
                    "ERROR: DPR load failed for %s (code %d)\n",
                    variants[rm].name, sw);
            fatal_error = 1;
            break;
        }

        printf("DPR load time: %.6f ms\n",
               dpr_ns / 1000000.0);

        for (int f = 0; f < NUM_NIST_FILES; f++) {
            if (run_rsp_file(
                    variants[rm].name,
                    rsp_paths[f],
                    nist_files[f],
                    dpr_ns,
                    csv,
                    &stats[rm]) != 0) {

                fatal_error = 1;
                break;
            }

            fflush(csv);
        }

        if (fatal_error)
            break;

        printf("\n%s summary:\n", variants[rm].name);
        printf("  TOTAL          : %lu\n", stats[rm].total);
        printf("  PASS           : %lu\n", stats[rm].pass);
        printf("  FAIL           : %lu\n", stats[rm].fail);
        printf("  READY TIMEOUT  : %lu\n", stats[rm].ready_timeout);
        printf("  DONE TIMEOUT   : %lu\n", stats[rm].done_timeout);
    }

    fflush(csv);
    fclose(csv);

    printf("\n============================================================\n");
    printf(" FINAL SUMMARY\n");
    printf("============================================================\n");

    unsigned long grand_total = 0;
    unsigned long grand_pass = 0;
    unsigned long grand_fail = 0;
    unsigned long grand_ready_timeout = 0;
    unsigned long grand_done_timeout = 0;

    for (int rm = 0; rm < NUM_VARIANTS; rm++) {
        printf("%-10s TOTAL=%-5lu PASS=%-5lu FAIL=%-5lu READY_TO=%-5lu DONE_TO=%-5lu\n",
               variants[rm].name,
               stats[rm].total,
               stats[rm].pass,
               stats[rm].fail,
               stats[rm].ready_timeout,
               stats[rm].done_timeout);

        grand_total += stats[rm].total;
        grand_pass += stats[rm].pass;
        grand_fail += stats[rm].fail;
        grand_ready_timeout += stats[rm].ready_timeout;
        grand_done_timeout += stats[rm].done_timeout;
    }

    printf("------------------------------------------------------------\n");
    printf("GRAND TOTAL      : %lu\n", grand_total);
    printf("GRAND PASS       : %lu\n", grand_pass);
    printf("GRAND FAIL       : %lu\n", grand_fail);
    printf("READY TIMEOUT    : %lu\n", grand_ready_timeout);
    printf("DONE TIMEOUT     : %lu\n", grand_done_timeout);
    printf("CSV              : aes256_dpr_nist_results.csv\n");

    if (!fatal_error &&
        grand_total > 0 &&
        grand_fail == 0 &&
        grand_ready_timeout == 0 &&
        grand_done_timeout == 0) {

        printf("RESULT           : ALL TESTS PASS\n");
    }
    else {
        printf("RESULT           : CHECK FAILURES / TIMEOUTS\n");
    }

    printf("============================================================\n");

    munmap((void *)regs, MAP_SIZE);
    close(memfd);

    return fatal_error ? 2 :
           (grand_fail || grand_ready_timeout || grand_done_timeout) ? 3 : 0;
}
