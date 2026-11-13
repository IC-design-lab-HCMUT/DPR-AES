#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <inttypes.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <time.h>
#include <errno.h>
#include <limits.h>

/* ============================================================
 * TEST-2: MATCHED AES-256 WORKLOAD
 *   10,000 AES jobs
 *   250 jobs/batch
 *   LUT -> BRAM -> COMPOSITE -> NOISE
 *   10 complete cycles = 40 batches = 39 switches
 *
 * Same source is used for DPR and Replica.
 * Only switch_variant() differs by runtime mode.
 * ============================================================ */

#define AXI_BASE        0xA0000000UL
#define MAP_SIZE        0x10000

#define COMMAND_OFF     0x00
#define STATUS_OFF      0x04
#define RM_CONTROL_OFF  0x08
#define KEY0_OFF        0x10
#define KEY1_OFF        0x14
#define KEY2_OFF        0x18
#define KEY3_OFF        0x1C
#define KEY4_OFF        0x20
#define KEY5_OFF        0x24
#define KEY6_OFF        0x28
#define KEY7_OFF        0x2C
#define PT0_OFF         0x30
#define PT1_OFF         0x34
#define PT2_OFF         0x38
#define PT3_OFF         0x3C
#define CT0_OFF         0x40
#define CT1_OFF         0x44
#define CT2_OFF         0x48
#define CT3_OFF         0x4C

#define STATUS_DONE     0x1u
#define STATUS_READY    0x2u
#define AES_TIMEOUT_NS  100000000ULL
#define READY_TIMEOUT_NS 100000000ULL

#define TOTAL_JOBS      10000
#define BATCH_SIZE      250
#define NUM_BATCHES     (TOTAL_JOBS / BATCH_SIZE)
#define NUM_SWITCHES    (NUM_BATCHES - 1)
#define NUM_VARIANTS    4
#define DEFAULT_SEED    3152026u

#define FPGA_FLAGS_PATH    "/sys/class/fpga_manager/fpga0/flags"
#define FPGA_FIRMWARE_PATH "/sys/class/fpga_manager/fpga0/firmware"
#define FPGA_STATE_PATH    "/sys/class/fpga_manager/fpga0/state"
#define FW_DIR             "/lib/firmware"

typedef enum { MODE_DPR = 0, MODE_REPLICA = 1 } mode_tst;

typedef struct {
    const char *name;
    const char *src_bitfile;
    const char *fw_name;
} variant_t;

static const variant_t variants[NUM_VARIANTS] = {
    {"LUT",       "/home/ubuntu/aes256_lut_partial.bit.bin",         "aes256_lut_partial.bit.bin"},
    {"BRAM",      "/home/ubuntu/aes256_bram_partial.bit.bin",        "aes256_bram_partial.bit.bin"},
    {"COMPOSITE", "/home/ubuntu/aes256_composite_partial.bit.bin",   "aes256_composite_partial.bit.bin"},
    {"NOISE",     "/home/ubuntu/aes256_dummy_noise_partial.bit.bin", "aes256_dummy_noise_partial.bit.bin"}
};

static const uint8_t AES_KEY_BYTES[32] = {
    0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,
    0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F,
    0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,
    0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F
};

static volatile uint32_t *regs = NULL;

typedef struct {
    uint32_t job_id;
    uint32_t batch_id;
    uint32_t variant;
    uint8_t pt[16];
    uint8_t expected[16];
    uint8_t actual[16];
    uint64_t aes_ns;
    uint32_t status;
    int pass;
} job_rec_t;

typedef struct {
    uint32_t switch_id;
    uint32_t batch_id;
    uint32_t from_rm;
    uint32_t to_rm;
    uint64_t programming_ns; /* DPR firmware write only; 0 for Replica */
    uint64_t switch_ns;      /* end-to-end switch boundary */
    uint32_t rm_readback;
    int pass;
} switch_rec_t;

/* ----------------------------- TIME -------------------------- */
static uint64_t diff_ns(struct timespec a, struct timespec b)
{
    int64_t sec = (int64_t)b.tv_sec - (int64_t)a.tv_sec;
    int64_t nsec = (int64_t)b.tv_nsec - (int64_t)a.tv_nsec;
    if (nsec < 0) { sec--; nsec += 1000000000LL; }
    if (sec < 0) return 0;
    return (uint64_t)sec * 1000000000ULL + (uint64_t)nsec;
}

/* ----------------------------- MMIO -------------------------- */
static inline void mmio_write(uint32_t off, uint32_t value)
{
    regs[off/4] = value;
    __sync_synchronize();
}

static inline uint32_t mmio_read(uint32_t off)
{
    uint32_t v = regs[off/4];
    __sync_synchronize();
    return v;
}

/* ------------------------ SOFTWARE AES-256 ------------------- */
static const uint8_t sbox[256] = {
0x63,0x7c,0x77,0x7b,0xf2,0x6b,0x6f,0xc5,0x30,0x01,0x67,0x2b,0xfe,0xd7,0xab,0x76,
0xca,0x82,0xc9,0x7d,0xfa,0x59,0x47,0xf0,0xad,0xd4,0xa2,0xaf,0x9c,0xa4,0x72,0xc0,
0xb7,0xfd,0x93,0x26,0x36,0x3f,0xf7,0xcc,0x34,0xa5,0xe5,0xf1,0x71,0xd8,0x31,0x15,
0x04,0xc7,0x23,0xc3,0x18,0x96,0x05,0x9a,0x07,0x12,0x80,0xe2,0xeb,0x27,0xb2,0x75,
0x09,0x83,0x2c,0x1a,0x1b,0x6e,0x5a,0xa0,0x52,0x3b,0xd6,0xb3,0x29,0xe3,0x2f,0x84,
0x53,0xd1,0x00,0xed,0x20,0xfc,0xb1,0x5b,0x6a,0xcb,0xbe,0x39,0x4a,0x4c,0x58,0xcf,
0xd0,0xef,0xaa,0xfb,0x43,0x4d,0x33,0x85,0x45,0xf9,0x02,0x7f,0x50,0x3c,0x9f,0xa8,
0x51,0xa3,0x40,0x8f,0x92,0x9d,0x38,0xf5,0xbc,0xb6,0xda,0x21,0x10,0xff,0xf3,0xd2,
0xcd,0x0c,0x13,0xec,0x5f,0x97,0x44,0x17,0xc4,0xa7,0x7e,0x3d,0x64,0x5d,0x19,0x73,
0x60,0x81,0x4f,0xdc,0x22,0x2a,0x90,0x88,0x46,0xee,0xb8,0x14,0xde,0x5e,0x0b,0xdb,
0xe0,0x32,0x3a,0x0a,0x49,0x06,0x24,0x5c,0xc2,0xd3,0xac,0x62,0x91,0x95,0xe4,0x79,
0xe7,0xc8,0x37,0x6d,0x8d,0xd5,0x4e,0xa9,0x6c,0x56,0xf4,0xea,0x65,0x7a,0xae,0x08,
0xba,0x78,0x25,0x2e,0x1c,0xa6,0xb4,0xc6,0xe8,0xdd,0x74,0x1f,0x4b,0xbd,0x8b,0x8a,
0x70,0x3e,0xb5,0x66,0x48,0x03,0xf6,0x0e,0x61,0x35,0x57,0xb9,0x86,0xc1,0x1d,0x9e,
0xe1,0xf8,0x98,0x11,0x69,0xd9,0x8e,0x94,0x9b,0x1e,0x87,0xe9,0xce,0x55,0x28,0xdf,
0x8c,0xa1,0x89,0x0d,0xbf,0xe6,0x42,0x68,0x41,0x99,0x2d,0x0f,0xb0,0x54,0xbb,0x16};

static uint8_t xtime(uint8_t x) { return (uint8_t)((x<<1) ^ ((x>>7)*0x1b)); }
static void add_rk(uint8_t s[16], const uint8_t *rk) { for(int i=0;i<16;i++) s[i]^=rk[i]; }
static void sub_bytes(uint8_t s[16]) { for(int i=0;i<16;i++) s[i]=sbox[s[i]]; }
static void shift_rows(uint8_t s[16]) {
    uint8_t t[16]; memcpy(t,s,16);
    for(int r=0;r<4;r++) for(int c=0;c<4;c++) s[r+4*c]=t[r+4*((c+r)&3)];
}
static void mix_columns(uint8_t s[16]) {
    for(int c=0;c<4;c++) {
        uint8_t *a=&s[4*c];
        uint8_t t=(uint8_t)(a[0]^a[1]^a[2]^a[3]);
        uint8_t u=a[0];
        a[0]^=t^xtime((uint8_t)(a[0]^a[1]));
        a[1]^=t^xtime((uint8_t)(a[1]^a[2]));
        a[2]^=t^xtime((uint8_t)(a[2]^a[3]));
        a[3]^=t^xtime((uint8_t)(a[3]^u));
    }
}
static void aes256_expand(const uint8_t key[32], uint8_t rk[240]) {
    memcpy(rk,key,32); int bytes=32; uint8_t rcon=1,t[4];
    while(bytes<240) {
        for(int i=0;i<4;i++) t[i]=rk[bytes-4+i];
        if(bytes%32==0) {
            uint8_t q=t[0];
            t[0]=(uint8_t)(sbox[t[1]]^rcon); t[1]=sbox[t[2]]; t[2]=sbox[t[3]]; t[3]=sbox[q];
            rcon=xtime(rcon);
        } else if(bytes%32==16) {
            for(int i=0;i<4;i++) t[i]=sbox[t[i]];
        }
        for(int i=0;i<4 && bytes<240;i++) { rk[bytes]=(uint8_t)(rk[bytes-32]^t[i]); bytes++; }
    }
}
static void aes256_encrypt_sw(const uint8_t in[16], const uint8_t key[32], uint8_t out[16]) {
    uint8_t s[16],rk[240]; memcpy(s,in,16); aes256_expand(key,rk); add_rk(s,rk);
    for(int r=1;r<14;r++) { sub_bytes(s); shift_rows(s); mix_columns(s); add_rk(s,rk+16*r); }
    sub_bytes(s); shift_rows(s); add_rk(s,rk+224); memcpy(out,s,16);
}

static int sw_selftest(void)
{
    static const uint8_t pt[16]={0x00,0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88,0x99,0xaa,0xbb,0xcc,0xdd,0xee,0xff};
    static const uint8_t exp[16]={0x8e,0xa2,0xb7,0xca,0x51,0x67,0x45,0xbf,0xea,0xfc,0x49,0x90,0x4b,0x49,0x60,0x89};
    uint8_t ct[16]; aes256_encrypt_sw(pt,AES_KEY_BYTES,ct);
    if(memcmp(ct,exp,16)==0) { puts("AES-256 software self-test: PASS"); return 0; }
    puts("AES-256 software self-test: FAIL"); return 1;
}

/* -------------------------- DATASET -------------------------- */
static uint32_t xs32(uint32_t *s)
{
    uint32_t x=*s; x^=x<<13; x^=x>>17; x^=x<<5; *s=x; return x;
}
static uint64_t fnv1a64_update(uint64_t h, const uint8_t *p, size_t n)
{
    for(size_t i=0;i<n;i++){h^=p[i]; h*=1099511628211ULL;} return h;
}
static void put_be32(uint8_t *p, uint32_t v)
{
    p[0]=(uint8_t)(v>>24); p[1]=(uint8_t)(v>>16); p[2]=(uint8_t)(v>>8); p[3]=(uint8_t)v;
}
static uint64_t generate_dataset(job_rec_t *jobs, uint32_t seed)
{
    uint32_t st=seed ? seed : 1u;
    uint64_t hash=1469598103934665603ULL;
    for(uint32_t i=0;i<TOTAL_JOBS;i++) {
        jobs[i].job_id=i+1;
        jobs[i].batch_id=i/BATCH_SIZE;
        jobs[i].variant=jobs[i].batch_id%NUM_VARIANTS;
        for(int w=0;w<4;w++) put_be32(&jobs[i].pt[4*w],xs32(&st));
        aes256_encrypt_sw(jobs[i].pt,AES_KEY_BYTES,jobs[i].expected);
        memset(jobs[i].actual,0,16); jobs[i].aes_ns=0; jobs[i].status=0; jobs[i].pass=0;
        hash=fnv1a64_update(hash,jobs[i].pt,16);
    }
    return hash;
}

/* ----------------------- FPGA / SYSFS ------------------------ */
static int write_sysfs(const char *path, const char *text)
{
    int fd=open(path,O_WRONLY); if(fd<0){perror(path);return -1;}
    size_t len=strlen(text); ssize_t n=write(fd,text,len); int e=errno; close(fd);
    if(n!=(ssize_t)len){errno=e;perror("write sysfs");return -1;} return 0;
}
static int fpga_operating(void)
{
    char b[64]={0}; int fd=open(FPGA_STATE_PATH,O_RDONLY); if(fd<0)return 0;
    ssize_t n=read(fd,b,sizeof(b)-1); close(fd); if(n<=0)return 0; b[n]='\0';
    return strstr(b,"operating")!=NULL;
}
static int copy_file(const char *src, const char *dst)
{
    int in=open(src,O_RDONLY); if(in<0)return -1;
    int out=open(dst,O_WRONLY|O_CREAT|O_TRUNC,0644); if(out<0){close(in);return -1;}
    char buf[65536]; ssize_t n; int rc=0;
    while((n=read(in,buf,sizeof(buf)))>0){char *p=buf;ssize_t left=n;while(left>0){ssize_t w=write(out,p,(size_t)left);if(w<0){rc=-1;goto done;}p+=w;left-=w;}}
    if(n<0)rc=-1;
done: close(in); close(out); return rc;
}
static int prepare_dpr_firmware(void)
{
    for(int i=0;i<NUM_VARIANTS;i++) {
        char dst[PATH_MAX]; snprintf(dst,sizeof(dst),"%s/%s",FW_DIR,variants[i].fw_name);
        if(access(variants[i].src_bitfile,R_OK)==0) {
            if(copy_file(variants[i].src_bitfile,dst)!=0){fprintf(stderr,"Cannot copy %s -> %s\n",variants[i].src_bitfile,dst);return -1;}
        } else if(access(dst,R_OK)!=0) {
            fprintf(stderr,"Missing both %s and %s\n",variants[i].src_bitfile,dst); return -1;
        }
    }
    return 0;
}

/* ------------------------ AXI HELPERS ------------------------ */
static uint32_t be32(const uint8_t *p)
{
    return ((uint32_t)p[0]<<24)|((uint32_t)p[1]<<16)|((uint32_t)p[2]<<8)|p[3];
}
static void word_to_be(uint32_t v,uint8_t *p)
{
    p[0]=(uint8_t)(v>>24);p[1]=(uint8_t)(v>>16);p[2]=(uint8_t)(v>>8);p[3]=(uint8_t)v;
}
static void write_key_hw(void)
{
    mmio_write(KEY0_OFF,0x1C1D1E1F); mmio_write(KEY1_OFF,0x18191A1B);
    mmio_write(KEY2_OFF,0x14151617); mmio_write(KEY3_OFF,0x10111213);
    mmio_write(KEY4_OFF,0x0C0D0E0F); mmio_write(KEY5_OFF,0x08090A0B);
    mmio_write(KEY6_OFF,0x04050607); mmio_write(KEY7_OFF,0x00010203);
}
static void write_pt_hw(const uint8_t pt[16])
{
    mmio_write(PT0_OFF,be32(pt+12)); mmio_write(PT1_OFF,be32(pt+8));
    mmio_write(PT2_OFF,be32(pt+4));  mmio_write(PT3_OFF,be32(pt+0));
}
static void read_ct_hw(uint8_t ct[16])
{
    uint32_t w0=mmio_read(CT0_OFF),w1=mmio_read(CT1_OFF),w2=mmio_read(CT2_OFF),w3=mmio_read(CT3_OFF);
    word_to_be(w3,ct+0); word_to_be(w2,ct+4); word_to_be(w1,ct+8); word_to_be(w0,ct+12);
}
static int wait_ready(uint64_t timeout_ns)
{
    struct timespec a,b; clock_gettime(CLOCK_MONOTONIC_RAW,&a);
    for(;;){if(mmio_read(STATUS_OFF)&STATUS_READY)return 0;clock_gettime(CLOCK_MONOTONIC_RAW,&b);if(diff_ns(a,b)>=timeout_ns)return -1;}
}

/* Per-job timer: PT MMIO + START + polling + CT read. Key is fixed and loaded once. */
static int run_hw_job(job_rec_t *j)
{
    if(wait_ready(READY_TIMEOUT_NS)!=0) return -2;
    struct timespec t0,t1,tnow; clock_gettime(CLOCK_MONOTONIC_RAW,&t0);
    write_pt_hw(j->pt); mmio_write(COMMAND_OFF,1u);
    for(;;) {
        uint32_t st=mmio_read(STATUS_OFF); j->status=st;
        if(st&STATUS_DONE) {
            uint8_t ct[16]; read_ct_hw(ct);
            if(memcmp(ct,j->expected,16)==0) {
                memcpy(j->actual,ct,16); clock_gettime(CLOCK_MONOTONIC_RAW,&t1);
                j->aes_ns=diff_ns(t0,t1); j->pass=1; return 0;
            }
        }
        clock_gettime(CLOCK_MONOTONIC_RAW,&tnow);
        if(diff_ns(t0,tnow)>=AES_TIMEOUT_NS) {
            read_ct_hw(j->actual); j->aes_ns=diff_ns(t0,tnow); j->pass=0; return -3;
        }
    }
}

/* -------------------------- SWITCHING ------------------------ */
static int switch_dpr_direct(uint32_t from, uint32_t to, switch_rec_t *r)
{
    (void)from; struct timespec t0,tp0,tp1,t1;
    r->programming_ns=0; r->switch_ns=0; r->rm_readback=0xFFFFFFFF; r->pass=0;

    /* Fair end-to-end boundary: HOLD -> flags -> firmware -> state -> RELEASE -> READY/readback. */
    clock_gettime(CLOCK_MONOTONIC_RAW,&t0);
    mmio_write(RM_CONTROL_OFF,1u);
    if(write_sysfs(FPGA_FLAGS_PATH,"1")!=0) goto fail_release;

    clock_gettime(CLOCK_MONOTONIC_RAW,&tp0);
    if(write_sysfs(FPGA_FIRMWARE_PATH,variants[to].fw_name)!=0) goto fail_release;
    clock_gettime(CLOCK_MONOTONIC_RAW,&tp1);
    r->programming_ns=diff_ns(tp0,tp1);

    if(!fpga_operating()) goto fail_release;
    mmio_write(RM_CONTROL_OFF,0u);
    r->rm_readback=mmio_read(RM_CONTROL_OFF);
    if(r->rm_readback!=0u) return -4;
    if(wait_ready(READY_TIMEOUT_NS)!=0) return -5;
    clock_gettime(CLOCK_MONOTONIC_RAW,&t1);
    r->switch_ns=diff_ns(t0,t1); r->pass=1; return 0;

fail_release:
    mmio_write(RM_CONTROL_OFF,0u); return -1;
}

static int switch_replica(uint32_t from, uint32_t to, switch_rec_t *r)
{
    struct timespec t0,t1;
    r->programming_ns=0; r->switch_ns=0; r->rm_readback=0xFFFFFFFF; r->pass=0;
    uint32_t hold_from=(from<<1)|1u, hold_to=(to<<1)|1u, release_to=(to<<1);
    clock_gettime(CLOCK_MONOTONIC_RAW,&t0);
    mmio_write(RM_CONTROL_OFF,hold_from);
    mmio_write(RM_CONTROL_OFF,hold_to);
    mmio_write(RM_CONTROL_OFF,release_to);
    r->rm_readback=mmio_read(RM_CONTROL_OFF);
    if(r->rm_readback!=release_to) return -4;
    if(wait_ready(READY_TIMEOUT_NS)!=0) return -5;
    clock_gettime(CLOCK_MONOTONIC_RAW,&t1);
    r->switch_ns=diff_ns(t0,t1); r->pass=1; return 0;
}

static int switch_variant(mode_tst mode,uint32_t from,uint32_t to,switch_rec_t *r)
{
    return mode==MODE_DPR ? switch_dpr_direct(from,to,r) : switch_replica(from,to,r);
}

/* --------------------------- OUTPUT -------------------------- */
static void hex16(FILE *f,const uint8_t b[16]){for(int i=0;i<16;i++)fprintf(f,"%02x",b[i]);}
static int save_jobs(const char *path,const job_rec_t *jobs,uint32_t completed)
{
    FILE *f=fopen(path,"w"); if(!f)return -1;
    fprintf(f,"job_id,batch_id,variant,plaintext,cipher_hw,cipher_expected,aes_latency_us,status,result\n");
    for(uint32_t i=0;i<completed;i++) {
        fprintf(f,"%u,%u,%s,",jobs[i].job_id,jobs[i].batch_id,variants[jobs[i].variant].name);
        hex16(f,jobs[i].pt);fputc(',',f);hex16(f,jobs[i].actual);fputc(',',f);hex16(f,jobs[i].expected);
        fprintf(f,",%.3f,0x%08X,%s\n",jobs[i].aes_ns/1000.0,jobs[i].status,jobs[i].pass?"PASS":"FAIL");
    }
    fclose(f); return 0;
}
static int save_switches(const char *path,const switch_rec_t *sw,uint32_t completed)
{
    FILE *f=fopen(path,"w"); if(!f)return -1;
    fprintf(f,"switch_id,batch_id,from_rm,to_rm,programming_latency_us,switch_latency_us,rm_readback,result\n");
    for(uint32_t i=0;i<completed;i++)
        fprintf(f,"%u,%u,%s,%s,%.3f,%.3f,0x%08X,%s\n",sw[i].switch_id,sw[i].batch_id,
                variants[sw[i].from_rm].name,variants[sw[i].to_rm].name,
                sw[i].programming_ns/1000.0,sw[i].switch_ns/1000.0,sw[i].rm_readback,sw[i].pass?"PASS":"FAIL");
    fclose(f); return 0;
}

static int initial_hw_verify(void)
{
    job_rec_t j={0};
    static const uint8_t pt[16]={0x00,0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88,0x99,0xaa,0xbb,0xcc,0xdd,0xee,0xff};
    memcpy(j.pt,pt,16); aes256_encrypt_sw(j.pt,AES_KEY_BYTES,j.expected);
    return run_hw_job(&j);
}

int main(int argc,char **argv)
{
    if(argc>=2 && strcmp(argv[1],"--selftest")==0) return sw_selftest();
    if(argc<2 || (strcmp(argv[1],"dpr")!=0 && strcmp(argv[1],"replica")!=0)) {
        fprintf(stderr,"Usage: %s dpr|replica [seed]\n       %s --selftest\n",argv[0],argv[0]); return 1;
    }
    mode_tst mode = strcmp(argv[1],"dpr")==0 ? MODE_DPR : MODE_REPLICA;
    uint32_t seed = (argc>=3)?(uint32_t)strtoul(argv[2],NULL,10):DEFAULT_SEED;
    if(sw_selftest()!=0)return 1;

    job_rec_t *jobs=calloc(TOTAL_JOBS,sizeof(*jobs));
    switch_rec_t *sw=calloc(NUM_SWITCHES,sizeof(*sw));
    if(!jobs||!sw){perror("calloc");return 1;}
    uint64_t dataset_hash=generate_dataset(jobs,seed);

    if(mode==MODE_DPR && prepare_dpr_firmware()!=0) {
        fprintf(stderr,"DPR firmware preparation failed. Run as root/sudo and check bitstream paths.\n"); return 1;
    }

    int memfd=open("/dev/mem",O_RDWR|O_SYNC); if(memfd<0){perror("/dev/mem");return 1;}
    regs=mmap(NULL,MAP_SIZE,PROT_READ|PROT_WRITE,MAP_SHARED,memfd,AXI_BASE);
    if(regs==MAP_FAILED){perror("mmap");return 1;}

    printf("============================================================\n");
    printf(" AES-256 TEST 2 - MATCHED 10K WORKLOAD (%s)\n",mode==MODE_DPR?"DPR":"REPLICA");
    printf("============================================================\n");
    printf("Jobs          : %d\nBatches       : %d\nJobs/batch    : %d\nSwitches      : %d\n",TOTAL_JOBS,NUM_BATCHES,BATCH_SIZE,NUM_SWITCHES);
    printf("Schedule      : 250 LUT -> 250 BRAM -> 250 COMPOSITE -> 250 NOISE, x10\n");
    printf("Seed          : %u\nDataset hash  : 0x%016" PRIx64 "\n",seed,dataset_hash);
    printf("No sleep/delay between jobs or batches. CSV is written AFTER timing.\n");

    /* Initial state is excluded from workload timing. */
    if(mode==MODE_DPR) {
        switch_rec_t init={0};
        if(switch_dpr_direct(0,0,&init)!=0){fprintf(stderr,"Initial DPR to LUT failed\n");return 2;}
    } else {
        mmio_write(RM_CONTROL_OFF,0u);
        if(mmio_read(RM_CONTROL_OFF)!=0u){fprintf(stderr,"Initial Replica LUT selection failed\n");return 2;}
        if(wait_ready(READY_TIMEOUT_NS)!=0){fprintf(stderr,"Initial Replica READY timeout\n");return 2;}
    }
    write_key_hw();
    if(initial_hw_verify()!=0){fprintf(stderr,"Initial AES hardware verification failed\n");return 2;}
    printf("Initial LUT AES verification: PASS\nRunning matched workload...\n");

    uint32_t completed_jobs=0,completed_sw=0,fail_jobs=0,fail_sw=0;
    uint64_t total_aes_ns=0,total_sw_ns=0,total_prog_ns=0;
    uint64_t var_aes_ns[NUM_VARIANTS]={0}; uint32_t var_count[NUM_VARIANTS]={0};
    struct timespec wall0,wall1; clock_gettime(CLOCK_MONOTONIC_RAW,&wall0);

    uint32_t current=0;
    for(uint32_t batch=0;batch<NUM_BATCHES;batch++) {
        uint32_t target=batch%NUM_VARIANTS;
        if(batch>0) {
            switch_rec_t *r=&sw[completed_sw];
            r->switch_id=completed_sw+1; r->batch_id=batch; r->from_rm=current; r->to_rm=target;
            int rc=switch_variant(mode,current,target,r);
            completed_sw++; total_sw_ns+=r->switch_ns; total_prog_ns+=r->programming_ns;
            if(rc!=0){fail_sw++;fprintf(stderr,"Switch failed at batch %u: %s -> %s rc=%d\n",batch,variants[current].name,variants[target].name,rc);break;}
            current=target;
        }
        uint32_t start=batch*BATCH_SIZE;
        for(uint32_t k=0;k<BATCH_SIZE;k++) {
            job_rec_t *j=&jobs[start+k];
            int rc=run_hw_job(j); completed_jobs++; total_aes_ns+=j->aes_ns;
            var_aes_ns[j->variant]+=j->aes_ns; var_count[j->variant]++;
            if(rc!=0||!j->pass)fail_jobs++;
        }
        if(fail_sw)break;
    }
    clock_gettime(CLOCK_MONOTONIC_RAW,&wall1);
    uint64_t wall_ns=diff_ns(wall0,wall1);

    const char *jobs_csv=mode==MODE_DPR?"dpr_jobs.csv":"replica_jobs.csv";
    const char *sw_csv=mode==MODE_DPR?"dpr_switches.csv":"replica_switches.csv";
    if(save_jobs(jobs_csv,jobs,completed_jobs)!=0)perror("save jobs CSV");
    if(save_switches(sw_csv,sw,completed_sw)!=0)perror("save switches CSV");

    printf("\n====================== TEST 2 RESULT =========================\n");
    printf("Completed jobs       : %u / %d\n",completed_jobs,TOTAL_JOBS);
    printf("AES PASS             : %u\n",completed_jobs-fail_jobs);
    printf("AES FAIL             : %u\n",fail_jobs);
    printf("Completed switches   : %u / %d\n",completed_sw,NUM_SWITCHES);
    printf("Switch FAIL          : %u\n",fail_sw);
    printf("Dataset hash         : 0x%016" PRIx64 "\n",dataset_hash);
    printf("Total AES time       : %.6f ms\n",total_aes_ns/1e6);
    printf("Total switch time    : %.6f ms\n",total_sw_ns/1e6);
    if(mode==MODE_DPR) printf("Total DPR programming: %.6f ms\n",total_prog_ns/1e6);
    printf("Workload wall time   : %.6f ms\n",wall_ns/1e6);
    if(wall_ns>0) {
        printf("Throughput           : %.3f jobs/s\n",completed_jobs/(wall_ns/1e9));
        printf("Switch overhead      : %.4f %%\n",100.0*(double)total_sw_ns/(double)wall_ns);
    }
    if(completed_jobs>0) printf("AES avg overall      : %.3f us\n",total_aes_ns/(double)completed_jobs/1000.0);
    for(int v=0;v<NUM_VARIANTS;v++) if(var_count[v])
        printf("AES avg %-9s   : %.3f us (%u jobs)\n",variants[v].name,var_aes_ns[v]/(double)var_count[v]/1000.0,var_count[v]);
    if(completed_sw>0) printf("Switch avg           : %.3f us\n",total_sw_ns/(double)completed_sw/1000.0);
    if(mode==MODE_DPR && completed_sw>0) printf("Programming avg      : %.3f us\n",total_prog_ns/(double)completed_sw/1000.0);
    printf("Jobs CSV             : %s\nSwitches CSV         : %s\n",jobs_csv,sw_csv);
    printf("OVERALL RESULT       : %s\n",(completed_jobs==TOTAL_JOBS&&completed_sw==NUM_SWITCHES&&fail_jobs==0&&fail_sw==0)?"PASS":"FAIL");
    printf("============================================================\n");

    munmap((void*)regs,MAP_SIZE); close(memfd); free(jobs); free(sw);
    return (completed_jobs==TOTAL_JOBS&&completed_sw==NUM_SWITCHES&&fail_jobs==0&&fail_sw==0)?0:2;
}
