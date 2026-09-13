# References & Reading Guide

## 1. Mục tiêu

Tài liệu này là danh sách đọc ban đầu cho **DPR-AES Version 1**. P0 phải bổ sung reading notes và pin các source/revision thực sự được dùng trong implementation.

Không cần đọc mọi tài liệu trước khi bắt đầu. Ưu tiên theo thứ tự:

```text
AES standard
    ↓
AES hardware baseline
    ↓
Vivado DFX fundamentals
    ↓
DFX architecture / floorplanning / verification
    ↓
Implementation diversity / MTD / leakage literature
```

---

## 2. AES Standard — bắt buộc

### R1 — NIST FIPS 197: Advanced Encryption Standard (AES)

Official:

- https://csrc.nist.gov/pubs/fips/197/final

Mục cần hiểu:

- AES state representation;
- 128-bit block;
- key sizes 128/192/256 bit;
- SubBytes;
- ShiftRows;
- MixColumns;
- AddRoundKey;
- key expansion;
- round structure của AES-128.

Version 1 dùng AES-128.

### R2 — NIST AES validation/test material

Dùng để xây known-answer/regression vectors. P0/P2 cần ghi rõ nguồn test vector thực tế được dùng.

---

## 3. AES Hardware RTL — baseline/candidate

### R3 — secworks/aes

Repository:

- https://github.com/secworks/aes

Mục đích:

- candidate cho AES RTL baseline;
- tham khảo interface, round implementation và verification flow.

Nếu chọn làm baseline, phải pin exact commit trong `deps/aes.lock` hoặc manifest tương đương.

### R4 — OpenTitan AES HWIP

Documentation:

- https://opentitan.org/book/hw/ip/aes/

Mục đích:

- tham khảo cách một AES hardware IP production-oriented tổ chức datapath/control;
- tham khảo security-oriented AES architecture;
- không mặc định dùng toàn bộ OpenTitan AES làm baseline vì dependency/complexity lớn hơn project sinh viên.

---

## 4. AMD/Xilinx Dynamic Function eXchange — bắt buộc

### R5 — Vivado Design Suite User Guide: Dynamic Function eXchange (UG909)

Official documentation portal:

- https://docs.amd.com/r/en-US/ug909-vivado-partial-reconfiguration/

Đọc tối thiểu các phần:

- Introduction to Dynamic Function eXchange;
- DFX concepts and terminology;
- Reconfigurable Partition / Reconfigurable Module;
- DFX project/non-project flow phù hợp target;
- floorplanning and pblocks;
- implementation configurations;
- `pr_verify` / DFX design checks;
- full/partial bitstream generation;
- reconfiguration lifecycle;
- known issues/limitations tương ứng Vivado version được dùng.

> Tài liệu online có thể hiển thị release mới hơn môi trường lab. P0 phải ghi đúng **Vivado/UG909 version tương ứng tool thực tế**, không chỉ ghi “latest”.

### R6 — Target-board configuration documentation

Sau khi P0 chọn board, bổ sung tài liệu cho runtime configuration path, ví dụ:

- Zynq/ZynqMP configuration/PCAP documentation;
- ICAP documentation cho PL-controlled reconfiguration;
- board reference manual;
- boot/configuration documentation.

Không freeze PCAP/ICAP trước khi target board được chọn.

---

## 5. DFX Support IP — đọc khi architecture cần

Trong Vivado có các DFX-related IP hỗ trợ isolation/control. P1 chỉ dùng khi cần và phải document dependency rõ.

Các chủ đề nên khảo sát:

- DFX Decoupler / isolation;
- DFX Controller hoặc controller tương đương;
- Shutdown Manager khi target/architecture cần;
- AXI interface behavior trong reconfiguration.

Không thêm IP chỉ vì “có sẵn”; mỗi IP phải có lý do kiến trúc rõ.

---

## 6. Implementation Diversity

P0/P1 cần tìm tài liệu theo các nhóm sau:

### D1 — S-box implementation diversity

Từ khóa:

```text
AES FPGA LUT S-box
AES BRAM S-box FPGA
AES composite field S-box FPGA
AES hardware S-box implementation comparison
```

Mục tiêu đọc:

- hiểu resource/timing trade-off;
- chọn RM-A/RM-B có khác biệt implementation đủ rõ;
- không thay đổi AES semantics.

### D2 — Placement/routing diversity

Từ khóa:

```text
FPGA placement diversity AES
FPGA routing diversity cryptographic implementation
partial reconfiguration implementation diversity
```

Mục tiêu:

- hiểu “logical diversity” và “physical diversity” khác nhau;
- xác định metric/report nào có thể chứng minh physical implementation khác nhau.

### D3 — Moving Target Defense bằng reconfiguration

Từ khóa:

```text
FPGA moving target defense partial reconfiguration
dynamic partial reconfiguration security FPGA
reconfigurable hardware moving target defense
```

Mục tiêu:

- hiểu reconfiguration như một mechanism làm thay đổi attack surface;
- phân biệt mechanism claim với measured security improvement.

---

## 7. Side-Channel / Leakage — chỉ cho evaluation mở rộng

Nếu P4 có thiết bị đo power/EM và thời gian cho phép, đọc thêm:

### S1 — TVLA methodology

Từ khóa:

```text
Test Vector Leakage Assessment TVLA fixed versus random
side-channel leakage assessment hardware AES
```

### S2 — CPA/DPA trên AES

Từ khóa:

```text
correlation power analysis AES FPGA
DPA AES hardware implementation
```

### S3 — Measurement reproducibility

Cần ghi rõ:

- acquisition equipment;
- sampling rate;
- trigger;
- number of traces;
- fixed/random plaintext policy;
- preprocessing/alignment;
- leakage model;
- success metric.

Nếu thiếu các yếu tố này, không đưa claim định lượng về SCA resistance.

---

## 8. Reading Notes Template

Mỗi tài liệu quan trọng nên có note ngắn:

```markdown
# <Reference ID / Title>

## Problem
Tài liệu giải quyết vấn đề gì?

## Architecture / Method
Cách tiếp cận chính là gì?

## Relevant to DPR-AES
Điểm nào dùng được cho project?

## Evidence / Metrics
Tài liệu đo gì?

## Limitation
Điểm nào không nên suy diễn?

## Decision
USE / REFERENCE / NOT-USED + lý do
```

Khuyến nghị lưu ở:

```text
docs/reading-notes/
```

khi P0 bắt đầu.

---

## 9. Minimum Reading Gate cho P0

Trước P0-G, sinh viên phải ít nhất:

- [ ] đọc FIPS 197 phần AES-128 cần thiết;
- [ ] hiểu một AES RTL baseline candidate;
- [ ] đọc UG909 phần concepts + basic DFX flow;
- [ ] hiểu RP/RM/configuration/partial bitstream;
- [ ] đọc ít nhất một nhóm tài liệu về implementation diversity/MTD;
- [ ] viết notes đủ để giải thích lựa chọn RM-A/RM-B và threat/evaluation scope.

P0 không yêu cầu systematic literature review. Mục tiêu là đủ background để thiết kế đúng và không đưa security claim vượt evidence.
