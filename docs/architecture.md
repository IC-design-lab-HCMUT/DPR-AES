# DPR-AES Architecture

## 1. Mục tiêu

Tài liệu này mô tả kiến trúc tham chiếu cho **DPR-AES Version 1**. P1 sẽ cập nhật và freeze các chi tiết phụ thuộc FPGA board/toolchain đã chọn ở P0.

Mục tiêu kiến trúc:

- giữ **Static Region** ổn định khi thay AES implementation;
- đặt AES compute core trong một **Reconfigurable Partition (RP)**;
- mọi **Reconfigurable Module (RM)** có cùng interface và cùng AES-128 functional semantics;
- reconfiguration có lifecycle rõ: `quiesce → isolate → reconfigure → reset/re-init → verify → resume`;
- dễ đo resource/timing/performance/reconfiguration overhead;
- không gắn security claim lớn hơn evidence thực tế.

---

## 2. Thuật ngữ

- **Static Region**: phần FPGA không thay đổi khi partial reconfiguration.
- **Reconfigurable Partition (RP)**: vùng vật lý/logical dành cho module có thể thay đổi.
- **Reconfigurable Module (RM)**: một implementation cụ thể được nạp vào RP.
- **Configuration**: static design + một RM cụ thể.
- **Partial bitstream**: bitstream dùng để thay nội dung RP mà không cấu hình lại toàn FPGA.
- **DFX**: Dynamic Function eXchange, terminology hiện dùng trong Vivado cho partial reconfiguration flow.

---

## 3. Baseline Architecture

Static baseline dùng để đo reference:

```text
Host / Test Controller
        │
        ▼
Input Registers
(key, plaintext)
        │
        ▼
┌──────────────────┐
│ Static AES-128   │
└────────┬─────────┘
         │
         ▼
Output Registers
(ciphertext/status)
```

Baseline phải dùng cùng:

- target FPGA;
- Vivado version;
- clock constraint;
- AES algorithm;
- test vectors;
- measurement definitions

với DPR configurations, trừ các khác biệt bắt buộc do DFX infrastructure.

---

## 4. DPR-AES Top-Level Architecture

```text
┌──────────────────────────────── Static Region ───────────────────────────────┐
│                                                                              │
│  Host / PS / UART / Control                                                  │
│            │                                                                 │
│            ▼                                                                 │
│  ┌──────────────────────┐                                                    │
│  │ Control + Status     │                                                    │
│  │ - start              │                                                    │
│  │ - busy/done          │                                                    │
│  │ - variant/status     │                                                    │
│  └──────────┬───────────┘                                                    │
│             │                                                                │
│  ┌──────────▼───────────┐                                                    │
│  │ Key / Plaintext Regs │                                                    │
│  └──────────┬───────────┘                                                    │
│             │                                                                │
│             │ stable RM interface                                            │
│             ▼                                                                │
│    ┌──────────────── Reconfigurable Partition ────────────────┐              │
│    │                                                          │              │
│    │  RM-A: AES-128 implementation A                          │              │
│    │                     OR                                   │              │
│    │  RM-B: AES-128 implementation B                          │              │
│    │                                                          │              │
│    └───────────────────────┬──────────────────────────────────┘              │
│                            │                                                 │
│                            ▼                                                 │
│                  Ciphertext / Status Regs                                    │
│                                                                              │
│  Reconfiguration Manager                                                     │
│  - request                                                                   │
│  - quiesce/isolate                                                           │
│  - partial-bitstream transfer                                                │
│  - reset/re-init                                                             │
│  - verify/resume                                                             │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

Static Region không được phụ thuộc vào internal implementation của RM-A/RM-B.

---

## 5. RM Functional Contract

### 5.1 AES scope

Version 1 freeze:

```text
Algorithm: AES-128
Block size: 128 bits
Key size: 128 bits
Operation: encryption baseline
```

AES-192/AES-256 là future extension, không phải blocking requirement.

### 5.2 Reference interface

Signal list dưới đây là **reference contract**. P1 có thể tinh chỉnh tên/polarity nhưng phải giữ semantics và freeze trước P2.

```verilog
module aes_rm (
    input  wire         clk,
    input  wire         rst_n,

    input  wire         start,
    input  wire [127:0] key,
    input  wire [127:0] plaintext,

    output wire         busy,
    output wire         done,
    output wire [127:0] ciphertext,

    output wire [31:0]  variant_id
);
```

### 5.3 Contract

- `start` chỉ được chấp nhận khi RM ready/not busy.
- `key` và `plaintext` phải ổn định theo protocol đã freeze.
- `busy` cho biết transaction đang xử lý.
- `done` đánh dấu `ciphertext` hợp lệ.
- `variant_id` có thể là constant per RM để hardware/software xác nhận active RM; nếu P1 chọn mechanism khác, phải document rõ.
- reset phải đưa RM về known idle state.
- mọi RM phải cho cùng ciphertext với cùng key/plaintext.

---

## 6. Recommended Version-1 Variants

### RM-A — LUT/logic-based S-box

Mục tiêu:

- baseline dễ hiểu;
- dùng logic/LUT implementation cho S-box;
- tạo reference về resource/timing.

### RM-B — BRAM/distributed-memory-based S-box

Mục tiêu:

- giữ nguyên AES functional semantics;
- thay đổi resource mapping/microarchitecture;
- tạo implementation diversity dễ quan sát bằng synthesis/implementation reports.

### Optional variants sau baseline

- composite-field S-box;
- khác mức pipeline;
- placement/routing variants;
- controlled dummy/noise logic.

Không thêm variant nếu RM-A/RM-B chưa PASS P2/P3.

---

## 7. Static Region Responsibilities

Static Region tối thiểu chịu trách nhiệm:

1. giữ input/output register;
2. phát lệnh start và đọc status;
3. giữ interface ổn định qua mọi RM;
4. ngăn transaction mới khi chuẩn bị reconfiguration;
5. isolate/decouple RP nếu platform/DFX architecture yêu cầu;
6. kích hoạt partial-bitstream transfer;
7. reset/re-initialize RM sau reconfiguration;
8. xác minh active variant/status;
9. resume normal processing.

Nếu board dùng Zynq/ZynqMP, runtime manager có thể nằm ở PS/software. Nếu dùng pure FPGA, controller có thể dùng ICAP hoặc host-assisted path phù hợp board. P0/P1 phải freeze lựa chọn cụ thể.

---

## 8. Reconfiguration Lifecycle

Reference sequence:

```text
NORMAL RUN
   │
   ▼
RECONFIG REQUEST
   │
   ▼
STOP ACCEPTING NEW AES JOBS
   │
   ▼
WAIT CURRENT JOB COMPLETE
   │
   ▼
QUIESCE / ISOLATE RP
   │
   ▼
TRANSFER PARTIAL BITSTREAM
   │
   ▼
RESET / RE-INITIALIZE RP
   │
   ▼
READ VARIANT/STATUS
   │
   ├── invalid → ERROR / RECOVERY
   │
   └── valid
        │
        ▼
RESUME
```

### Không được reconfigure giữa transaction mà không có protocol

P1 phải định nghĩa rõ behavior nếu request đến khi AES đang `busy`.

Version 1 khuyến nghị:

```text
request while busy
→ wait for current transaction done
→ then quiesce
```

để giảm ambiguity.

---

## 9. State Ownership qua Reconfiguration

### Static state

Nên nằm ngoài RP:

- control/status registers;
- reconfiguration policy state;
- partial-bitstream metadata;
- host communication;
- measurement timers/counters;
- input/output buffers nếu cần giữ qua swap.

### Reconfigurable state

Bên trong RP được xem là **không được bảo toàn** qua reconfiguration, trừ khi architecture sau này chứng minh mechanism khác.

Do đó sau partial reconfiguration:

```text
RM internal state = unknown until reset/re-initialized
```

và phải có reset/re-init trước transaction mới.

---

## 10. Key Handling Boundary

Version 1 tập trung vào DPR mechanism, không tuyên bố secure key provisioning hoàn chỉnh.

Nguyên tắc:

- key input contract phải rõ;
- không lưu key vào log/result artifact;
- nếu key register nằm static, document lifetime/reset behavior;
- nếu key truyền vào RM mỗi transaction, document protocol;
- không claim key secrecy trước physical/debug attacker nếu chưa có Root of Trust/provisioning model.

---

## 11. RP Resource Budget

RP phải đủ lớn cho **RM lớn nhất**.

P1/P2 cần lập bảng:

| Resource | RP budget | RM-A | RM-B | Margin |
|---|---:|---:|---:|---:|
| LUT | TBD | TBD | TBD | TBD |
| FF | TBD | TBD | TBD | TBD |
| BRAM | TBD | TBD | TBD | TBD |
| DSP | TBD | TBD | TBD | TBD |

Không chọn pblock chỉ vừa RM-A nếu RM-B cần resource type/column khác.

---

## 12. Timing Contract

Matched comparison cần freeze:

- target clock period;
- clock source;
- timing constraints;
- I/O delay assumptions nếu có;
- implementation strategy nếu không phải biến nghiên cứu.

Mọi DFX configuration phải đạt timing requirement đã định nghĩa hoặc ghi rõ failure/derating.

---

## 13. Verification Targets

### Functional

- AES known-answer tests;
- randomized vectors;
- cross-RM equivalence;
- reset behavior;
- repeated transactions.

### DFX

- RM-A full-boot PASS;
- RM-A → RM-B PASS;
- RM-B → RM-A PASS;
- correctness sau mỗi swap;
- repeated swap loop;
- error handling tối thiểu.

### Measurement

- utilization;
- timing/Fmax;
- latency/block;
- throughput;
- partial-bitstream size;
- reconfiguration latency;
- static DPR infrastructure cost.

---

## 14. Threat/Evaluation Model

Version 1 nghiên cứu DPR như một mechanism để thay đổi active implementation.

Có thể đánh giá trực tiếp:

- số lượng implementation states;
- resource mapping differences;
- placement/routing differences nếu reports cho phép;
- reconfiguration frequency/cost;
- percentage time unavailable do reconfiguration.

Không tự động suy ra:

- DPA/CPA resistance;
- TVLA pass;
- reduced power leakage;
- fault resistance.

Các claim này cần experiment riêng ở P4/future work.

---

## 15. Architecture Freeze Checklist — P1

Trước khi bắt đầu P2:

- [ ] FPGA board/device đã freeze.
- [ ] Vivado version đã freeze.
- [ ] Static/RP boundary đã freeze.
- [ ] RM interface đã freeze.
- [ ] RM-A/RM-B definitions đã freeze.
- [ ] RP resource budget đã freeze.
- [ ] clock/timing target đã freeze.
- [ ] quiesce/reset/recovery lifecycle đã freeze.
- [ ] runtime reconfiguration path đã freeze.
- [ ] measurement methodology đã freeze.
- [ ] instructor review PASS.

Nếu một mục trên thay đổi trong P2/P3, phải ghi change reason và review lại phần contract liên quan.
