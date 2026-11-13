#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <strings.h>
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

#define VERIFY_TIMEOUT_NS 100000000ULL

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

typedef struct {
    const char *name;
    uint32_t pt[4];
    uint32_t ct[4];
} aes_vector_t;

/* AES-256 key:
 * 000102030405060708090A0B0C0D0E0F
 * 101112131415161718191A1B1C1D1E1F
 */
static const uint32_t aes_key[8] = {
    0x1C1D1E1F, 0x18191A1B, 0x14151617, 0x10111213,
    0x0C0D0E0F, 0x08090A0B, 0x04050607, 0x00010203
};

static const aes_vector_t verify_vectors[] = {
    {
        "FIPS_STANDARD",
        {0xCCDDEEFF, 0x8899AABB, 0x44556677, 0x00112233},
        {0x4B496089, 0xEAFC4990, 0x516745BF, 0x8EA2B7CA}
    },
    {
        "ZERO_PLAINTEXT",
        {0x00000000, 0x00000000, 0x00000000, 0x00000000},
        {0xDD2E7780, 0xA9F39A6A, 0x2A499FD0, 0xF29000B6}
    }
};

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

static uint64_t diff_ns(struct timespec a, struct timespec b)
{
    return (uint64_t)(b.tv_sec - a.tv_sec) * 1000000000ULL +
           (uint64_t)(b.tv_nsec - a.tv_nsec);
}

static int wait_status(uint32_t mask, uint32_t expected, uint64_t timeout_ns)
{
    struct timespec t0, t1;
    clock_gettime(CLOCK_MONOTONIC_RAW, &t0);

    while (1) {
        uint32_t s = mmio_read(STATUS_OFF);
        if ((s & mask) == expected)
            return 0;

        clock_gettime(CLOCK_MONOTONIC_RAW, &t1);
        if (diff_ns(t0, t1) >= timeout_ns)
            return -1;
    }
}

static void write_key(void)
{
    for (int i = 0; i < 8; i++)
        mmio_write(KEY0_OFF + 4*i, aes_key[i]);
}

static int verify_one_vector(const aes_vector_t *v)
{
    uint32_t ct[4];

    if (wait_status(STATUS_READY, STATUS_READY, VERIFY_TIMEOUT_NS) != 0) {
        printf("  %s: READY TIMEOUT\n", v->name);
        return -1;
    }

    write_key();

    for (int i = 0; i < 4; i++)
        mmio_write(PT0_OFF + 4*i, v->pt[i]);

    mmio_write(COMMAND_OFF, 0x1);
    usleep(100);

    if (wait_status(STATUS_DONE, STATUS_DONE, VERIFY_TIMEOUT_NS) != 0) {
        printf("  %s: DONE TIMEOUT\n", v->name);
        return -1;
    }

    for (int i = 0; i < 4; i++)
        ct[i] = mmio_read(CT0_OFF + 4*i);

    int pass = 1;
    for (int i = 0; i < 4; i++) {
        if (ct[i] != v->ct[i]) {
            pass = 0;
            break;
        }
    }

    printf("  %s: CT=%08X%08X%08X%08X  %s\n",
           v->name, ct[3], ct[2], ct[1], ct[0],
           pass ? "PASS" : "FAIL");

    return pass ? 0 : -1;
}

static int verify_aes(void)
{
    int failures = 0;
    size_t n = sizeof(verify_vectors) / sizeof(verify_vectors[0]);

    for (size_t i = 0; i < n; i++) {
        if (verify_one_vector(&verify_vectors[i]) != 0)
            failures++;
    }

    return failures == 0 ? 0 : -1;
}

static int fpga_is_operating(void)
{
    char buf[64] = {0};

    int fd = open(FPGA_STATE_PATH, O_RDONLY);
    if (fd < 0) {
        perror("open FPGA state");
        return 0;
    }

    ssize_t n = read(fd, buf, sizeof(buf)-1);
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

    if (!WIFEXITED(status) || WEXITSTATUS(status) != 0)
        return -1;

    return 0;
}

static int find_variant(const char *name)
{
    size_t n = sizeof(variants) / sizeof(variants[0]);

    for (size_t i = 0; i < n; i++) {
        if (strcasecmp(name, variants[i].name) == 0)
            return (int)i;
    }

    return -1;
}

static void usage(const char *prog)
{
    fprintf(stderr,
        "Usage: sudo %s <lut|bram|composite|noise> [--verify]\n",
        prog);
}

int main(int argc, char **argv)
{
    if (argc < 2 || argc > 3) {
        usage(argv[0]);
        return 1;
    }

    int target = find_variant(argv[1]);
    if (target < 0) {
        usage(argv[0]);
        return 1;
    }

    int do_verify = (argc == 3 && strcmp(argv[2], "--verify") == 0);

    if (access(FPGAUTIL_PATH, X_OK) != 0) {
        perror(FPGAUTIL_PATH);
        return 1;
    }

    if (access(variants[target].bitfile, R_OK) != 0) {
        perror(variants[target].bitfile);
        return 1;
    }

    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("open /dev/mem");
        return 1;
    }

    regs = mmap(NULL, MAP_SIZE, PROT_READ | PROT_WRITE,
                MAP_SHARED, fd, AXI_BASE);
    if (regs == MAP_FAILED) {
        perror("mmap");
        close(fd);
        return 1;
    }

    struct timespec t0, t1;
    clock_gettime(CLOCK_MONOTONIC_RAW, &t0);

    /* DPR interface hold */
    mmio_write(RM_CONTROL_OFF, 0x1);

    int load_rc = load_partial(variants[target].bitfile);

    if (load_rc != 0) {
        mmio_write(RM_CONTROL_OFF, 0x0);
        fprintf(stderr, "ERROR: partial reconfiguration failed\n");
        munmap((void *)regs, MAP_SIZE);
        close(fd);
        return 2;
    }

    if (!fpga_is_operating()) {
        mmio_write(RM_CONTROL_OFF, 0x0);
        fprintf(stderr, "ERROR: FPGA manager is not operating\n");
        munmap((void *)regs, MAP_SIZE);
        close(fd);
        return 3;
    }

    /* Release newly loaded RM */
    mmio_write(RM_CONTROL_OFF, 0x0);
    uint32_t rb = mmio_read(RM_CONTROL_OFF);

    clock_gettime(CLOCK_MONOTONIC_RAW, &t1);
    uint64_t ns = diff_ns(t0, t1);

    printf("DPR target     : %s\n", variants[target].name);
    printf("Partial file   : %s\n", variants[target].bitfile);
    printf("RM readback    : 0x%08X\n", rb);
    printf("DPR time       : %llu ns (%.3f us, %.6f ms)\n",
           (unsigned long long)ns,
           ns / 1000.0,
           ns / 1000000.0);

    int rc = 0;

    if (rb != 0x0) {
        fprintf(stderr, "ERROR: RM_CONTROL release readback mismatch\n");
        rc = 4;
    } else if (do_verify) {
        printf("AES-256 verification:\n");
        if (verify_aes() != 0)
            rc = 5;
    }

    munmap((void *)regs, MAP_SIZE);
    close(fd);

    return rc;
}
