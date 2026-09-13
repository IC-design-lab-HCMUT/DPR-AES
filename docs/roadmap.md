# Master Roadmap

## 1. Mục tiêu

Tài liệu này là **roadmap canonical** cho Version 1 của project **DPR-AES**.

Project được quản lý bằng 5 Phase chính, map trực tiếp với GitHub Issues:

| Phase | Issue | Nội dung chính |
|---|---|---|
| P0 — Foundation, Toolchain & AES Baseline | #2 | Freeze target/toolchain, AES-128 baseline, DFX smoke test |
| P1 — DPR Architecture & Variant Design | #3 | Freeze Static/RP/RM contract và variant plan |
| P2 — AES Variants & Functional Verification | #4 | Implement tối thiểu 2 RM và chứng minh equivalence |
| P3 — DFX Integration & Runtime Reconfiguration | #5 | Full/partial bitstreams, hardware swap và runtime path |
| P4 — Evaluation, Reproducibility & Release | #6 | Matched evaluation, limitations, clean-clone và release |

Master control: **#1**.

Điểm dừng bắt buộc của Version 1:

> **AES-128 baseline + ≥2 functionally equivalent AES RMs + working DFX/partial reconfiguration on FPGA + measured reconfiguration/cost evidence + reproducible workflow**

---

## 2. Roadmap Overview

```text
P0 — Foundation, Toolchain & AES Baseline
          │
          ▼
P1 — DPR Architecture & Variant Design
          │
          ▼
P2 — AES Variants & Functional Verification
          │
          ▼
P3 — DFX Integration & Runtime Reconfiguration
          │
          ▼
P4 — Evaluation, Reproducibility & Release
```

Chỉ bắt đầu Phase tiếp theo sau khi Phase hiện tại được instructor review PASS và merge vào `main`.

---

# 3. P0 — Foundation, Toolchain & AES Baseline

**Issue:** #2

## Objective

Thiết lập environment có thể tái lập, chọn/freeze target FPGA và chứng minh AES-128 baseline hoạt động đúng trước khi tạo implementation diversity.

## Main Tasks

- [ ] Chọn FPGA board/device cho Version 1.
- [ ] Freeze Vivado version và toolchain phụ trợ.
- [ ] Chọn AES baseline RTL; ghi source/license/exact revision.
- [ ] Build/simulate AES-128 baseline.
- [ ] Chạy known-answer tests.
- [ ] Synthesis baseline và ghi resource/timing reference.
- [ ] Chạy một DFX smoke test/example cho platform.
- [ ] Đọc tài liệu AES, DPR/DFX và implementation diversity.
- [ ] Freeze threat model và security-claim boundary.
- [ ] Ghi clock target và baseline configuration.

## Main Outputs

```text
Frozen FPGA/toolchain
+
AES-128 baseline reproducible
+
Known-answer-test evidence
+
DFX smoke-test evidence
+
Threat/evaluation scope
```

## Gate P0-G

PASS khi:

- clean clone dựng được AES baseline bằng documented commands;
- known-answer tests PASS;
- board/device, Vivado version, baseline RTL revision và clock target đã freeze;
- DFX tool flow tối thiểu chạy được;
- student giải thích được Static Region / RP / RM và mục tiêu implementation diversity.

---

# 4. P1 — DPR Architecture & Variant Design

**Issue:** #3

## Objective

Freeze hệ thống DPR-AES trước khi bắt đầu implementation chính thức của các Reconfigurable Modules.

## Main Tasks

- [ ] Phân tích baseline AES data/control flow.
- [ ] Xác định Static Region và Reconfigurable Partition.
- [ ] Freeze RM interface.
- [ ] Freeze handshake, reset và error behavior.
- [ ] Freeze quiesce/reconfigure/recovery sequence.
- [ ] Chọn tối thiểu 2 variants và nguồn diversity của mỗi variant.
- [ ] Xác định RP resource budget/floorplan principle.
- [ ] Xác định runtime reconfiguration path của target platform.
- [ ] Freeze measurement methodology.
- [ ] Instructor review architecture.

## Recommended baseline variants

```text
RM-A — AES-128 LUT/logic S-box
RM-B — AES-128 BRAM/distributed-memory S-box
```

Các variant khác chỉ thêm sau khi baseline 2-RM ổn định:

- composite-field S-box;
- khác mức pipeline;
- placement/routing variants;
- controlled dummy/noise logic.

## Main Outputs

```text
Static/RP/RM architecture
+
Frozen RM contract
+
Variant matrix
+
Runtime reconfiguration plan
+
Evaluation methodology
```

## Gate P1-G

PASS khi:

- static/RP boundary rõ;
- mọi RM có cùng interface và functional contract;
- quiesce/reset/recovery sequence rõ;
- RP budget đủ cho các RM;
- runtime path xác định được;
- instructor review PASS.

> Không đổi RM interface sau P1-G nếu chưa review lại architecture.

---

# 5. P2 — AES Variants & Functional Verification

**Issue:** #4

## Objective

Triển khai các AES RMs và chứng minh functional equivalence **trước khi DFX integration**.

## Main Tasks

- [ ] Implement/fetch RM-A.
- [ ] Implement/fetch RM-B.
- [ ] Dùng common interface/wrapper.
- [ ] Xây common testbench.
- [ ] Known-answer tests cho mọi RM.
- [ ] Randomized cross-variant regression.
- [ ] Reset/start/busy/done tests.
- [ ] Standalone synthesis cho từng RM.
- [ ] Ghi resource/timing/latency/throughput.
- [ ] Xác nhận mọi RM fit RP budget.
- [ ] Tạo repeatable regression command.

## Main Outputs

```text
≥2 AES-128 RMs
+
Common regression
+
Equivalence evidence
+
Per-RM synthesis evidence
```

## Gate P2-G

PASS khi:

- cùng key/plaintext cho cùng ciphertext trên mọi RM;
- KAT + randomized regression PASS;
- interface không drift;
- mọi RM fit RP budget;
- clean checkout chạy lại được regression.

> P2 chứng minh correctness + implementation diversity, chưa chứng minh side-channel resistance.

---

# 6. P3 — DFX Integration & Runtime Reconfiguration

**Issue:** #5

## Objective

Tích hợp static design và các RMs vào Vivado DFX, tạo partial bitstreams và chứng minh hardware reconfiguration hoạt động đúng.

## 6.1 DFX Build

- [ ] Tạo static design + RP.
- [ ] Tạo DFX configuration cho RM-A.
- [ ] Tạo DFX configuration cho RM-B.
- [ ] Freeze/verify pblock.
- [ ] Check implementation + timing cho từng configuration.
- [ ] Generate full + partial bitstreams.

## 6.2 Hardware Bring-up

- [ ] Boot full design với RM-A.
- [ ] AES test PASS.
- [ ] Quiesce.
- [ ] Partial reconfigure sang RM-B.
- [ ] Reset/re-initialize RP.
- [ ] AES test PASS.
- [ ] Reconfigure trở lại RM-A.
- [ ] AES test PASS.

## 6.3 Runtime Control

- [ ] Tích hợp PCAP/ICAP hoặc mechanism tương đương phù hợp target.
- [ ] Tạo manual/deterministic trigger trước.
- [ ] Ghi variant/status/error handling.
- [ ] Chỉ thêm periodic/randomized policy sau khi deterministic flow ổn định.

## 6.4 Measurement

- [ ] Partial-bitstream size.
- [ ] Reconfiguration latency.
- [ ] Timing status từng configuration.
- [ ] Recovery behavior.

## Gate P3-G

PASS khi:

```text
RM-A boot PASS
  +
RM-A → RM-B partial reconfiguration PASS
  +
AES correctness after swap PASS
  +
RM-B → RM-A partial reconfiguration PASS
  +
AES correctness after swap PASS
  +
measured reconfiguration evidence
```

---

# 7. P4 — Evaluation, Reproducibility & Release

**Issue:** #6

## Objective

Đánh giá matched baseline/DPR variants, giới hạn claim đúng evidence và hoàn thiện Version 1 thành project có thể tái lập.

## Main Tasks

- [ ] Matched resource comparison.
- [ ] Matched timing/performance comparison.
- [ ] Reconfiguration cost analysis.
- [ ] Static DPR infrastructure cost.
- [ ] Structural/physical diversity analysis.
- [ ] Optional leakage/SCA measurement nếu có thiết bị + methodology.
- [ ] Hoàn thiện docs theo implementation thực tế.
- [ ] Chuẩn hóa scripts/build procedure.
- [ ] Clean-clone reproduction.
- [ ] Final demonstration.
- [ ] Final review + release candidate.

## Minimum Results Table

| Metric | Static baseline | RM-A | RM-B | Notes |
|---|---:|---:|---:|---|
| LUT | TBD | TBD | TBD | same device/tool |
| FF | TBD | TBD | TBD | same device/tool |
| BRAM | TBD | TBD | TBD | same device/tool |
| DSP | TBD | TBD | TBD | same device/tool |
| Fmax | TBD | TBD | TBD | same clock method |
| Latency/block | TBD | TBD | TBD | same test workload |
| Throughput | TBD | TBD | TBD | same definition |
| Partial bitstream size | N/A | TBD | TBD | bytes |
| Reconfiguration latency | N/A | TBD | TBD | method documented |

## Security/Diversity Claim Policy

### Có thể claim khi có evidence

- variants có implementation/resource differences;
- variants có placement/routing differences nếu report chứng minh;
- DPR làm thay đổi active hardware implementation;
- reconfiguration có chi phí X theo measurement.

### Không được suy diễn nếu chưa đo

- “DPR chống CPA/DPA”;
- “power leakage giảm X%”;
- “cần nhiều trace hơn”;
- “chống fault injection”.

Các claim này cần experiment riêng.

## Gate P4-G

PASS khi:

- correctness/equivalence/DFX evidence đầy đủ;
- matched evaluation hoàn chỉnh;
- limitations rõ;
- clean clone có thể tái chạy flow chính;
- README/docs đồng bộ với source;
- instructor final review PASS.

---

# 8. Future Extensions sau Version 1

Sau khi Version 1 ổn định mới xem xét:

- AES-192/AES-256;
- nhiều hơn 2–3 RM variants;
- randomized reconfiguration interval;
- event-triggered reconfiguration;
- physical placement/routing mutation automation;
- trace-based leakage assessment;
- TVLA/CPA/CEMA evaluation;
- fault-injection experiment;
- secure bitstream/authentication and Root-of-Trust integration;
- adaptive MTD policy.

Các extension phải được tạo issue/roadmap riêng, không làm trôi scope của P0–P4.
