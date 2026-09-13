# DPR-AES — Dynamic Partial Reconfiguration for AES on FPGA

> **Nghiên cứu và triển khai Dynamic Partial Reconfiguration (DPR/DFX) cho AES-128 trên FPGA**

Repository này là workspace triển khai, kiểm chứng và đánh giá một hệ thống **AES-128 có khả năng Dynamic Partial Reconfiguration** trên FPGA. Mục tiêu chính là xây dựng nhiều **AES hardware variants** có cùng chức năng và cùng giao diện, đặt chúng trong một **Reconfigurable Partition (RP)** và thay đổi variant trong quá trình vận hành mà không cần thay đổi toàn bộ thiết kế FPGA.

Version 1 ưu tiên ba yêu cầu:

1. **Correctness** — mọi AES variant phải cho cùng kết quả mã hóa với cùng `key/plaintext`.
2. **Reconfiguration evidence** — phải chứng minh được quá trình `RM-A → RM-B → RM-A` trên FPGA và AES vẫn đúng sau mỗi lần partial reconfiguration.
3. **Cost & diversity evidence** — mọi lợi ích từ DPR phải được đánh giá cùng overhead về tài nguyên, timing, hiệu năng, kích thước partial bitstream và thời gian tái cấu hình.

> **Lưu ý về security claim:** implementation diversity/DPR có thể được nghiên cứu như một Moving Target Defense primitive, nhưng **không tự động chứng minh side-channel resistance**. Chỉ đưa ra claim định lượng về leakage/SCA khi có measurement methodology và evidence phù hợp.

---

## Sinh viên bắt đầu từ đâu?

Nếu đây là lần đầu làm việc với repository, **không bắt đầu bằng việc tạo DFX project hoặc sửa RTL ngay**. Hãy đọc và thực hiện theo thứ tự:

```text
README.md
   ↓
docs/development-workflow.md
   ↓
docs/roadmap.md
   ↓
docs/architecture.md
   ↓
docs/references.md
   ↓
docs/toolchain.md
   ↓
docs/fpga-deployment.md
   ↓
Issue #1 — Master Control
   ↓
Issue #2 — P0: Foundation, Toolchain & AES Baseline
```

### 1. Hiểu project và cách làm việc

Đọc trước:

- **README này** — hiểu mục tiêu, phạm vi và kết quả cuối cùng.
- **[Development Workflow](docs/development-workflow.md)** — quy trình bắt buộc `main → phase branch → PR → instructor review → merge`.
- **[Roadmap](docs/roadmap.md)** — các Phase P0–P4 và điều kiện hoàn thành từng Phase.

### 2. Hiểu kiến trúc trước khi implement

Đọc:

- **[Architecture](docs/architecture.md)** — Static Region, Reconfigurable Partition, Reconfigurable Module và interface/lifecycle của AES RM.
- **[AES Baseline](docs/aes-baseline.md)** — cách freeze AES core, revision, configuration và known-answer tests.
- **[References](docs/references.md)** — tài liệu AES, DPR/DFX và implementation diversity cần đọc.
- **[Toolchain](docs/toolchain.md)** — simulation, synthesis và Vivado/DFX flow.
- **[FPGA Deployment](docs/fpga-deployment.md)** — hardware bring-up và partial-reconfiguration validation.

### 3. Theo dõi công việc qua GitHub Issues

Toàn bộ Version 1 được quản lý tại **[#1 — Master Control](https://github.com/IC-design-lab-HCMUT/DPR-AES/issues/1)**.

| Phase | Issue | Mục tiêu chính |
|---|---|---|
| P0 — Foundation, Toolchain & AES Baseline | [#2](https://github.com/IC-design-lab-HCMUT/DPR-AES/issues/2) | Freeze board/toolchain, AES-128 baseline, DFX smoke test |
| P1 — DPR Architecture & Variant Design | [#3](https://github.com/IC-design-lab-HCMUT/DPR-AES/issues/3) | Freeze Static/RP boundary, RM interface và variant plan |
| P2 — AES Variants & Functional Verification | [#4](https://github.com/IC-design-lab-HCMUT/DPR-AES/issues/4) | Implement tối thiểu 2 RM và chứng minh functional equivalence |
| P3 — DFX Integration & Runtime Reconfiguration | [#5](https://github.com/IC-design-lab-HCMUT/DPR-AES/issues/5) | Full/partial bitstreams, FPGA swap và runtime reconfiguration |
| P4 — Evaluation, Reproducibility & Release | [#6](https://github.com/IC-design-lab-HCMUT/DPR-AES/issues/6) | Matched evaluation, clean-clone reproduction và release |

### 4. Task đầu tiên

**Bắt đầu từ [Issue #2 — P0](https://github.com/IC-design-lab-HCMUT/DPR-AES/issues/2).**

Trước khi làm P0:

```bash
git checkout main
git pull origin main
git switch -c phase/p0-foundation-baseline
git push -u origin phase/p0-foundation-baseline
```

Khi P0 hoàn thành, tạo Pull Request:

```text
phase/p0-foundation-baseline → main
```

Sinh viên **không tự merge**. Instructor review, yêu cầu chỉnh sửa nếu cần, merge khi PASS, cập nhật/đóng issue và xác nhận Phase tiếp theo.

> **Nguyên tắc:** chỉ làm Phase đang được instructor xác nhận START; không tự chuyển Phase khi gate hiện tại chưa PASS.

---

## 1. Project Scope

### In Scope — Version 1

- Thuật toán: **AES-128**.
- Block size: **128 bit**.
- Một static AES baseline có known-answer-test evidence.
- Tối thiểu **2 AES hardware variants** có cùng external interface và cùng functional behavior.
- Khuyến nghị baseline variants:
  - `RM-A`: LUT/logic-based S-box;
  - `RM-B`: BRAM/distributed-memory-based S-box.
- Static Region + một Reconfigurable Partition.
- Full bitstream + partial bitstream cho từng RM.
- Hardware reconfiguration `RM-A ↔ RM-B`.
- Correctness test trước và sau partial reconfiguration.
- Runtime reconfiguration path phù hợp với board đã freeze ở P0.
- Matched evaluation: `LUT`, `FF`, `BRAM`, `DSP`, `Fmax`, latency, throughput, partial-bitstream size và reconfiguration latency.
- Structural/physical diversity analysis dựa trên implementation evidence.

### Out of Scope — Version 1

Các nội dung sau không phải blocking requirement:

- AES-192/AES-256 support.
- Thay đổi thuật toán AES hoặc đề xuất cryptographic primitive mới.
- Nhiều hơn 2–3 variants trước khi baseline DFX ổn định.
- Randomized/event-triggered policy trước khi deterministic runtime reconfiguration chạy đúng.
- Fault-injection countermeasure hoàn chỉnh.
- Secure key provisioning/Root of Trust hoàn chỉnh.
- Chứng minh side-channel resistance nếu chưa có trace acquisition + leakage methodology.
- Tuyên bố power estimate hoặc resource diversity là bằng chứng SCA resistance.

---

## 2. Kiến trúc tổng quan

Baseline tĩnh:

```text
Key + Plaintext
      │
      ▼
┌───────────────┐
│ Static AES-128│
└───────┬───────┘
        │
        ▼
   Ciphertext
```

DPR-AES:

```text
┌──────────────────────── Static Region ────────────────────────┐
│ Controller / Host Interface                                  │
│ Key + Plaintext Registers                                    │
│ Reconfiguration Manager                                      │
│ Quiesce / Reset / Status                                     │
│                         │                                    │
│                         ▼                                    │
│              ┌──── Reconfigurable Partition ────┐            │
│              │ RM-A: AES-128 Variant A          │            │
│              │          or                       │            │
│              │ RM-B: AES-128 Variant B          │            │
│              └───────────────────────────────────┘            │
│                         │                                    │
│                         ▼                                    │
│                    Ciphertext                                │
└───────────────────────────────────────────────────────────────┘
```

Runtime lifecycle tối thiểu:

```text
RUN RM-A
   ↓
QUIESCE
   ↓
PARTIAL RECONFIGURE
   ↓
RESET / RE-INITIALIZE RP
   ↓
VERIFY STATUS
   ↓
RUN RM-B
```

Chi tiết xem [docs/architecture.md](docs/architecture.md).

---

## 3. Threat Model và Security Objective

Version 1 không bắt đầu bằng claim “DPR chống side-channel”. Mục tiêu khoa học/kỹ thuật trước tiên là chứng minh:

- một attacker/observer phải đối mặt với **nhiều implementation state** thay vì một implementation cố định;
- các implementation state có cùng AES function nhưng khác microarchitecture/resource/placement evidence;
- hệ thống có thể chuyển implementation state bằng partial reconfiguration;
- chi phí của việc chuyển state được đo định lượng.

Nếu có thiết bị đo power/EM và methodology phù hợp, leakage/SCA evaluation có thể được bổ sung ở P4. Nếu không, kết luận phải giới hạn ở **correctness + DPR mechanism + implementation diversity + overhead**.

---

## 4. Tool & Hardware Flow

Flow Version 1:

```text
AES RTL / RM Variants
        │
        ▼
Simulation / Regression
        │
        ▼
Per-RM Synthesis
        │
        ▼
Vivado DFX Project
        │
        ├── Static Design
        ├── RM-A configuration
        └── RM-B configuration
        │
        ▼
Full + Partial Bitstreams
        │
        ▼
FPGA Bring-up
        │
        ├── AES correctness
        ├── RM-A ↔ RM-B swap
        └── Reconfiguration measurement
```

Tool chính:

- **Vivado** — synthesis, implementation, DFX, bitstream và hardware bring-up;
- **Verilator / simulator phù hợp** — functional regression;
- **GTKWave** — waveform khi cần;
- **Python** — test vectors, regression và result processing;
- **Vitis/PetaLinux hoặc host software** — chỉ khi target runtime path cần PS/software support.

Tool/version cụ thể được freeze tại P0, không hard-code trước khi chọn board.

---

## 5. Kết quả mong đợi

Version 1 cần có tối thiểu:

- AES-128 baseline simulation PASS.
- Exact baseline source/revision/configuration được ghi lại.
- Tối thiểu 2 AES variants có cùng interface.
- Known-answer tests và randomized functional regression PASS cho mọi RM.
- Static/RP/RM architecture được freeze trước implementation.
- Full bitstream và partial bitstream cho từng RM.
- Hardware demo `RM-A → RM-B → RM-A` PASS.
- Ciphertext đúng sau mỗi lần partial reconfiguration.
- Matched result table:

| Metric | Static baseline | RM-A | RM-B | DPR notes |
|---|---:|---:|---:|---|
| LUT | TBD | TBD | TBD | TBD |
| FF | TBD | TBD | TBD | TBD |
| BRAM | TBD | TBD | TBD | TBD |
| DSP | TBD | TBD | TBD | TBD |
| Fmax | TBD | TBD | TBD | same constraint |
| Latency/block | TBD | TBD | TBD | — |
| Throughput | TBD | TBD | TBD | — |
| Partial bitstream size | N/A | TBD | TBD | — |
| Reconfiguration latency | N/A | TBD | TBD | method documented |

---

## 6. Documentation

Đọc theo thứ tự:

1. **[Development Workflow](docs/development-workflow.md)** — branch/PR/review/evidence workflow.
2. **[Roadmap](docs/roadmap.md)** — canonical P0–P4 roadmap và gates.
3. **[Architecture](docs/architecture.md)** — Static/RP/RM boundaries và lifecycle.
4. **[AES Baseline](docs/aes-baseline.md)** — freeze AES baseline và verification contract.
5. **[References](docs/references.md)** — reading list và tài liệu cần bổ sung trong P0.
6. **[Toolchain](docs/toolchain.md)** — simulation/synthesis/DFX environment.
7. **[FPGA Deployment](docs/fpga-deployment.md)** — bring-up và partial-reconfiguration evidence.

---

## 7. Repository Structure dự kiến

```text
DPR-AES/
├── README.md
├── docs/
│   ├── development-workflow.md
│   ├── roadmap.md
│   ├── architecture.md
│   ├── aes-baseline.md
│   ├── references.md
│   ├── toolchain.md
│   └── fpga-deployment.md
├── rtl/
│   ├── static/
│   ├── common/
│   └── rm/
│       ├── aes_rm_a/
│       └── aes_rm_b/
├── tb/
├── scripts/
├── fpga/
│   ├── common/
│   └── <target-board>/
├── software/
└── results/
    ├── simulation/
    ├── synthesis/
    ├── dfx/
    └── hardware/
```

Các thư mục implementation được tạo dần theo Phase; không tạo placeholder rỗng chỉ để “đủ cây thư mục”.

---

## 8. Nguyên tắc thực hiện

- **Branch before work:** mỗi Phase bắt đầu từ `main` mới nhất và dùng branch riêng.
- **PR before merge:** mọi thay đổi phải qua review trước khi merge.
- **Baseline before variants:** phải freeze AES baseline trước khi tạo implementation diversity.
- **Architecture before DFX:** freeze Static/RP/RM contract trước khi tạo DFX project chính thức.
- **Equivalent function:** mọi RM phải giữ cùng AES functional semantics.
- **Matched comparison:** dùng cùng device, tool version, clock constraint và measurement method.
- **Evidence before claim:** correctness, DPR, cost, diversity và security claim đều cần evidence tương ứng.
- **Reproducibility:** người khác phải clone repository và tái chạy được flow chính bằng documented commands.
- **Security-claim discipline:** không đồng nhất “khác implementation” với “đã chống side-channel”.

---

## 9. Master Control

Bắt đầu tại:

- [#1 — DPR-AES Version 1 Master Control](https://github.com/IC-design-lab-HCMUT/DPR-AES/issues/1)
- [#2 — P0: Foundation, Toolchain & AES Baseline](https://github.com/IC-design-lab-HCMUT/DPR-AES/issues/2)

Version 1 chỉ được xem là hoàn thành khi có đủ:

```text
AES Correctness Evidence
        +
Variant Equivalence Evidence
        +
DFX/Reconfiguration Evidence
        +
Cost & Timing Evidence
        +
Reproducibility Evidence
        =
DPR-AES Version 1 Complete
```
