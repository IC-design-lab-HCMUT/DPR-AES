# Toolchain & Build Environment

## 1. Mục tiêu

Tài liệu này mô tả toolchain tham chiếu cho **DPR-AES Version 1**. P0 phải cập nhật lại bằng **exact versions thực tế** sau khi FPGA board/device được chọn.

Không dùng các mô tả mơ hồ như:

```text
Vivado latest
Verilator latest
Python latest
```

Mỗi kết quả cần gắn với environment có thể tái lập.

---

## 2. Toolchain tổng quan

```text
AES RTL / Testbench
        │
        ▼
Simulator
        │
        ├── AES KAT
        ├── randomized regression
        └── cross-RM equivalence
        │
        ▼
Vivado Synthesis
        │
        ├── static baseline
        ├── RM-A standalone
        └── RM-B standalone
        │
        ▼
Vivado DFX
        │
        ├── static design
        ├── RP/RM configurations
        ├── implementation/timing
        └── full + partial bitstreams
        │
        ▼
FPGA Deployment
        │
        ├── functional validation
        ├── partial reconfiguration
        └── measurement
```

---

## 3. Required Tools

### 3.1 AMD/Xilinx Vivado

Dùng cho:

- synthesis;
- implementation;
- timing analysis;
- DFX/partial-reconfiguration flow;
- bitstream generation;
- hardware programming/bring-up khi phù hợp.

P0 phải ghi:

```text
Vivado version:
Vivado build:
FPGA part:
Board:
DFX flow mode:
```

Tài liệu DFX chính: **UG909 — Vivado Design Suite User Guide: Dynamic Function eXchange**.

### 3.2 RTL Simulator

Khuyến nghị một trong:

- Verilator;
- Questa/ModelSim nếu lab có license;
- simulator khác được instructor chấp thuận.

P0 phải chọn một simulator chuẩn cho regression chính.

Icarus Verilog có thể dùng smoke test nếu design tương thích nhưng không bắt buộc.

### 3.3 Python

Dùng cho:

- test-vector generation;
- reference AES model/checking;
- log/result parsing;
- regression orchestration;
- table/CSV generation.

Pin Python major/minor version và package dependencies nếu dùng package ngoài standard library.

### 3.4 GTKWave hoặc waveform viewer

Dùng debug simulation. Không phải evidence chính nếu có machine-readable test logs tốt hơn.

---

## 4. Environment Record

P0 tạo file environment record, ví dụ:

```text
results/environment/p0-tool-versions.txt
```

Nội dung tối thiểu:

```text
OS:
Kernel:
Vivado:
Simulator:
Python:
Git:
FPGA board:
FPGA part:
AES baseline commit:
Clock target:
```

Có thể dùng script để sinh record tự động.

---

## 5. Simulation Flow

Target command cuối cùng nên đơn giản, ví dụ:

```bash
make sim-baseline
make sim-rm-a
make sim-rm-b
make regression
```

hoặc script tương đương.

Không bắt buộc dùng `make`; yêu cầu là command phải:

- deterministic;
- document rõ;
- trả exit code khác 0 khi test FAIL;
- ghi summary dễ đọc.

### Regression output mong muốn

```text
[PASS] AES-128 KAT baseline
[PASS] AES-128 KAT RM-A
[PASS] AES-128 KAT RM-B
[PASS] randomized equivalence N=<count>
```

---

## 6. AES Reference Model

P2 cần một reference để so output RTL.

Có thể dùng:

- trusted software AES library;
- Python implementation/package đã pin version;
- known-answer vectors từ NIST.

Không lấy output của RM-A làm “golden” cho RM-B; cả hai phải so với một reference độc lập hoặc KAT chuẩn.

---

## 7. Vivado Source-of-Truth Policy

Ưu tiên version-control các source có thể tái tạo project:

```text
RTL
XDC
Tcl
IP configuration source
source manifest
DFX configuration manifest
build scripts
```

Hạn chế commit generated directories:

```text
*.cache/
*.runs/
*.gen/
*.ip_user_files/
temporary checkpoints
GUI-only state
```

Nếu cần DCP/checkpoint làm source-of-truth cho một flow cụ thể, phải document lý do và Vivado version.

---

## 8. DFX Build Strategy

P1/P3 phải chọn và freeze một flow phù hợp target/project.

Yêu cầu chung:

1. static top-level xác định rõ;
2. RP instance xác định rõ;
3. RM-A/RM-B có cùng partition interface;
4. configuration list được quản lý bằng script/manifest;
5. mỗi configuration chạy implementation/timing checks;
6. partial bitstreams có tên định danh được variant/configuration.

Ví dụ output naming:

```text
full_rm_a.bit
partial_aes_rm_a.bit
partial_aes_rm_b.bit
```

Tên thật có thể khác nhưng phải nhất quán.

---

## 9. Recommended Build Targets

Khi project trưởng thành, nên có targets tương đương:

```text
setup/check-env
sim-baseline
sim-all-rms
regression
synth-baseline
synth-rms
build-dfx
verify-dfx
bitstreams
report
clean
```

Không cần tạo tất cả ở P0. Tạo dần theo roadmap.

---

## 10. Timing & Resource Reports

Mỗi synthesis/implementation flow cần lưu các metrics chính:

- LUT;
- FF;
- BRAM;
- DSP;
- WNS/TNS hoặc timing status;
- requested clock period;
- achieved/estimated Fmax nếu methodology cho phép.

P4 phải dùng cùng extraction method cho baseline/RM-A/RM-B.

Khuyến nghị parse report sang CSV/JSON để tránh copy tay.

---

## 11. DFX Verification

P3 cần chạy các DFX consistency checks do Vivado hỗ trợ cho flow đã chọn, bao gồm verification giữa configurations khi phù hợp.

Build không được xem là PASS nếu:

- routing chưa complete;
- timing requirement bị vi phạm mà không document;
- DFX verification/checks fail;
- partial bitstream không sinh được;
- static design không nhất quán giữa configurations.

---

## 12. Runtime Software

Nếu target dùng processor/host để điều khiển reconfiguration, code runtime đặt ở:

```text
software/
```

P3 phải document:

- cách load partial bitstream;
- path/interface được dùng;
- error return;
- timeout;
- variant identity/status;
- timing measurement method.

Không hard-code absolute host paths hoặc user-specific directories.

---

## 13. Reconfiguration Timing Measurement

P3 phải định nghĩa chính xác hai mốc:

```text
t_start = thời điểm bắt đầu partial-bitstream transfer/request
t_end   = thời điểm RP hợp lệ và ready/resume
```

Sau đó:

```text
T_reconfig = t_end - t_start
```

Nếu đo chỉ thời gian transfer mà không gồm reset/recovery, phải đặt metric khác tên và ghi rõ.

Ví dụ tách:

```text
T_transfer
T_reinit
T_total_reconfig
```

---

## 14. Reproducibility Checklist

Trước khi P4-G:

- [ ] clean clone;
- [ ] environment versions recorded;
- [ ] dependency revisions pinned;
- [ ] simulation regression chạy bằng documented command;
- [ ] Vivado project/DFX build có script hoặc procedure rõ;
- [ ] reports sinh lại được;
- [ ] hardware procedure có input/output expected;
- [ ] không phụ thuộc file local không có trong repository;
- [ ] binary artifact policy rõ.

---

## 15. P0 Toolchain Freeze Template

Điền trong P0:

```text
Host OS              : TBD
Vivado                : TBD
UG909/reference release: TBD
Simulator             : TBD
Python                : TBD
FPGA board            : TBD
FPGA device/part      : TBD
Clock target          : TBD
AES baseline repo     : TBD
AES baseline commit   : TBD
Runtime config path   : TBD
```

Sau khi instructor review PASS, record này trở thành baseline cho matched evaluation của Version 1.
