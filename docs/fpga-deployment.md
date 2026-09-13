# FPGA Deployment & DFX Validation

## 1. Mục tiêu

Tài liệu này mô tả hardware-validation flow cho DPR-AES Version 1.

P0 phải chọn và freeze target board/device. Vì repository hiện chưa freeze board, các phần phụ thuộc platform được ghi dưới dạng **decision point** thay vì giả định trước một board cụ thể.

Version 1 chỉ PASS khi partial reconfiguration được chứng minh trên phần cứng, không chỉ ở simulation hoặc Vivado project view.

---

## 2. Target Selection — P0

Board được chọn cần đáp ứng:

- device hỗ trợ Vivado DFX flow phù hợp;
- đủ LUT/FF/BRAM/DSP cho Static Region + RP;
- có configuration path phù hợp cho hardware validation;
- lab có thể lập trình/debug ổn định;
- tool/license/version khả dụng;
- tài liệu reference đủ rõ.

Candidate có thể gồm các Xilinx/AMD 7-series, Zynq hoặc UltraScale+ boards đang có trong lab. Quyết định cuối phải ghi exact board + FPGA part.

### Selection record

```text
Board:
FPGA part:
Vivado version:
Configuration path:
Host/runtime environment:
Clock source:
Programming cable/interface:
```

---

## 3. Hardware Validation Levels

### Level 0 — Full-bitstream bring-up

Mục tiêu:

- board boot/program thành công;
- clock/reset ổn định;
- Static Region hoạt động;
- AES RM ban đầu chạy KAT PASS.

### Level 1 — Tool-assisted partial reconfiguration

Mục tiêu:

- nạp partial bitstream của RM khác;
- không full-program lại FPGA;
- static behavior vẫn ổn;
- AES KAT PASS sau swap.

Level 1 là bring-up evidence nhưng chưa đủ cho final runtime-control objective nếu toàn bộ thao tác vẫn phụ thuộc manual GUI/JTAG.

### Level 2 — Runtime reconfiguration path

Mục tiêu:

- runtime software/controller yêu cầu đổi RM;
- partial bitstream được transfer qua platform path đã freeze;
- lifecycle được tự động hóa đủ để repeatable;
- đo được reconfiguration latency.

P3-G yêu cầu Level 2 hoặc một cơ chế runtime tương đương được instructor chấp thuận.

---

## 4. Platform-Specific Reconfiguration Path

P0/P1 phải chọn path phù hợp target.

Ví dụ các họ platform có thể dùng:

- processor-side configuration path trên Zynq/ZynqMP;
- ICAP-based PL controller trên FPGA/SoC phù hợp;
- host-assisted path nếu architecture project yêu cầu.

Không dùng một tên interface chỉ vì quen thuộc; phải xác nhận path đó thực sự tồn tại và được support trên target đã chọn.

---

## 5. Required Bitstreams/Configurations

Tối thiểu:

```text
Configuration A = Static Design + RM-A
Configuration B = same Static Design + RM-B
```

Artifacts logic:

```text
Full bitstream for initial boot
Partial bitstream for RM-A
Partial bitstream for RM-B
```

Tên file và binary-storage policy do P3 freeze.

Mỗi artifact cần metadata:

```text
variant/configuration
Git commit
Vivado version
FPGA part
build timestamp (optional)
checksum
```

---

## 6. Initial Hardware Bring-up

### Step 1 — Program full bitstream

Boot với Configuration A/RM-A.

### Step 2 — Verify static health

Kiểm tra:

- clock present;
- reset released;
- controller/host communication;
- RP status expected;
- no obvious error flags.

### Step 3 — Run AES KAT

Input:

```text
key       = 000102030405060708090a0b0c0d0e0f
plaintext = 00112233445566778899aabbccddeeff
```

Expected:

```text
ciphertext = 69c4e0d86a7b0430d8cdb78070b4c55a
```

Record:

- active variant;
- observed ciphertext;
- PASS/FAIL;
- transaction latency if measured.

---

## 7. Required Partial-Reconfiguration Sequence

Reference procedure:

```text
1. Run KAT on RM-A
2. Request reconfiguration
3. Stop accepting new AES transactions
4. Wait current transaction complete
5. Quiesce/isolate RP
6. Load partial bitstream RM-B
7. Reset/re-initialize RP
8. Verify active variant/status
9. Run same KAT on RM-B
10. Repeat RM-B → RM-A
```

Required final demonstration:

```text
RM-A PASS
  ↓
partial reconfigure
  ↓
RM-B PASS
  ↓
partial reconfigure
  ↓
RM-A PASS
```

---

## 8. Repeated-Swap Test

Không chỉ test một lần.

P3 nên chạy loop:

```text
for i in 1..N:
    RM-A KAT
    switch to RM-B
    RM-B KAT
    switch to RM-A
```

`N` được freeze theo thời gian lab, nhưng phải đủ để phát hiện lỗi lifecycle/recovery lặp lại.

Record:

- swap count;
- failures;
- timeout;
- wrong variant/status;
- wrong ciphertext.

---

## 9. Failure Cases cần kiểm tra

Tối thiểu xem xét:

### F1 — Reconfiguration request khi AES busy

Expected Version-1 behavior khuyến nghị:

```text
wait current job done → then reconfigure
```

### F2 — Invalid/missing partial bitstream

System phải fail rõ, không silently report success.

### F3 — RM không reset/re-init đúng

Hardware test phải phát hiện qua status/KAT.

### F4 — Timeout

Runtime path cần timeout thay vì chờ vô hạn.

### F5 — Wrong variant identity

Nếu dùng `variant_id`/status, kiểm tra expected value sau swap.

---

## 10. Reconfiguration Latency Measurement

Phải định nghĩa metric trước khi đo.

Khuyến nghị tách:

```text
T_transfer = partial-bitstream transfer time
T_reinit   = reset/status recovery time
T_total    = request-to-ready total time
```

P4 comparison nên ưu tiên `T_total` vì phản ánh thời gian system không thể nhận AES job mới.

Nếu chỉ đo `T_transfer`, phải ghi rõ.

### Measurement source có thể dùng

Tùy platform:

- software high-resolution timer;
- hardware counter trong Static Region;
- logic analyzer/ILA marker;
- external GPIO timing marker.

P1/P3 phải freeze một method chính.

---

## 11. Availability / Reconfiguration Overhead

Với policy đổi RM sau mỗi `N` blocks:

```text
T_useful = thời gian xử lý N blocks
T_reconfig = tổng thời gian reconfiguration
```

Có thể báo cáo:

```text
reconfiguration_overhead_ratio
    = T_reconfig / (T_useful + T_reconfig)
```

Phải ghi workload và `N`, không báo một percentage không có context.

---

## 12. Hardware Evidence Layout

Khuyến nghị:

```text
results/hardware/p3/
├── environment.txt
├── configuration-manifest.txt
├── rm-a-kat.log
├── rm-b-kat.log
├── repeated-swap.log
├── reconfiguration-latency.csv
└── README.md
```

Không bắt buộc đúng tên file này; yêu cầu là evidence có cấu trúc và truy nguyên được Git revision/configuration.

---

## 13. Vivado/DFX Evidence

Khuyến nghị lưu summary/parsed results từ:

- utilization report;
- timing summary;
- DFX configuration status;
- verification/check output;
- bitstream sizes;
- static/RP floorplan screenshots chỉ khi chúng bổ sung cho machine-readable reports.

Không dùng screenshot GUI làm evidence duy nhất cho build correctness.

---

## 14. Optional ILA Debug

ILA có thể dùng để quan sát:

- start/busy/done;
- reconfiguration request/state;
- reset/re-init;
- variant_id/status;
- transaction markers.

Nhưng ILA thay đổi resource/floorplan. Nếu dùng trong evaluation:

- hoặc giữ ILA giống nhau ở mọi matched configuration;
- hoặc chỉ dùng debug build và không dùng resource result đó cho final comparison.

---

## 15. Side-Channel Measurement — Optional P4 Extension

Nếu lab có power/EM equipment:

- tạo build/evaluation protocol riêng;
- giữ capture setup nhất quán;
- document trigger/alignment;
- tách debug instrumentation khỏi measurement build khi cần;
- không thay đổi key/plaintext policy giữa variants nếu không có lý do.

Nếu không có measurement setup phù hợp, Version 1 không bị block; report phải ghi rõ SCA là future work.

---

## 16. P3 Hardware Gate Checklist

- [ ] Full design programs successfully.
- [ ] RM-A KAT PASS.
- [ ] Partial bitstream RM-B loads successfully.
- [ ] Static Region remains operational.
- [ ] RM-B reset/re-init PASS.
- [ ] RM-B KAT PASS.
- [ ] Partial bitstream RM-A reload PASS.
- [ ] RM-A KAT PASS again.
- [ ] Repeated-swap test PASS.
- [ ] Reconfiguration latency measured.
- [ ] Partial-bitstream sizes recorded.
- [ ] Failure/timeout behavior documented.
- [ ] Evidence linked from Issue #5 / PR.

P3 chỉ PASS khi hardware evidence tái lập được bằng documented procedure.
