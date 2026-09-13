# AES-128 Baseline

## 1. Mục tiêu

Tài liệu này quy định cách chọn, freeze và kiểm chứng **AES baseline** cho DPR-AES Version 1.

Baseline không chỉ là “một core AES chạy được”. Baseline phải đủ rõ để tất cả RM variants và DFX configurations được so sánh trên cùng một functional reference.

---

## 2. AES scope cho Version 1

Freeze ở mức project:

```text
Algorithm: AES
Block size: 128 bits
Key size: 128 bits
Direction: encryption baseline
```

AES chuẩn có block size 128 bit và hỗ trợ key 128/192/256 bit. Version 1 chỉ dùng **AES-128** để giảm biến số khi nghiên cứu DPR/implementation diversity.

AES-192/AES-256 có thể bổ sung sau Version 1.

---

## 3. Tiêu chí chọn baseline RTL

AES core được chọn ở P0 nên đáp ứng:

- synthesizable RTL;
- license rõ ràng;
- source/revision có thể pin chính xác;
- testbench hoặc known-answer flow dễ tái lập;
- không phụ thuộc vendor primitive nếu không cần thiết;
- interface đủ đơn giản để wrap thành common RM contract;
- không quá phức tạp về countermeasure để tránh trộn nhiều biến nghiên cứu ngay từ đầu.

### Candidate tham khảo

- `secworks/aes` — phù hợp để khảo sát một AES RTL baseline tương đối độc lập vendor.
- OpenTitan AES — tài liệu và implementation tốt để tham khảo kiến trúc/security design, nhưng có thể phức tạp hơn mức cần thiết cho baseline DPR sinh viên.

P0 phải ghi exact source/commit trước khi bắt đầu chỉnh sửa/wrap.

---

## 4. Baseline Lock Record

Sau khi P0 chọn core, tạo một lock record, ví dụ:

```text
source_repository: <owner/repo>
commit: <40-char SHA>
license: <license>
source_path: <path>
operation: AES-128 encrypt
clock_target: <MHz or period>
vivado_version: <version>
simulator: <tool/version>
fpga_part: <part>
board: <board>
```

Có thể lưu tại:

```text
deps/aes.lock
```

hoặc manifest tương đương được instructor chấp thuận.

Không dùng `latest`, branch floating hoặc URL không pin revision làm baseline cuối.

---

## 5. Known-Answer Test tối thiểu

Một test vector AES-128 chuẩn thường dùng:

```text
key       = 000102030405060708090a0b0c0d0e0f
plaintext = 00112233445566778899aabbccddeeff
ciphertext= 69c4e0d86a7b0430d8cdb78070b4c55a
```

P0 phải xác nhận baseline cho đúng ciphertext.

Không chỉ dùng một vector duy nhất cho final regression. P2 cần:

- nhiều known-answer vectors;
- randomized vectors với software/reference model;
- cùng vector set cho RM-A/RM-B.

---

## 6. Baseline Wrapper

Nếu upstream core có interface khác RM contract, dùng wrapper thay vì sửa sâu core ngay từ đầu.

Ví dụ:

```text
Common DPR-AES Interface
        │
        ▼
┌────────────────────┐
│ Baseline/RM Wrapper│
└─────────┬──────────┘
          │ upstream-specific signals
          ▼
┌────────────────────┐
│ Frozen AES Core    │
└────────────────────┘
```

Ưu điểm:

- giữ upstream revision dễ đối chiếu;
- giảm diff;
- dễ thay core/variant;
- interface của Static Region không phụ thuộc internal core.

---

## 7. Baseline Configuration Record

P0 phải ghi rõ:

- iterative/unrolled/pipelined architecture nếu core hỗ trợ nhiều option;
- key expansion strategy;
- S-box implementation;
- number of cycles/block;
- reset semantics;
- input/output handshake;
- synthesis defines/parameters;
- FPGA clock target.

Nếu một parameter không được ghi, later comparison có nguy cơ không còn matched.

---

## 8. Baseline Simulation Gate

PASS tối thiểu khi:

- [ ] compile/elaborate PASS;
- [ ] reset PASS;
- [ ] AES-128 KAT PASS;
- [ ] repeated encryption PASS;
- [ ] output-valid/done semantics rõ;
- [ ] simulation command documented;
- [ ] simulator version recorded.

Output khuyến nghị:

```text
results/simulation/p0-baseline/
```

với log ngắn gọn hoặc machine-readable result.

---

## 9. Baseline Synthesis Gate

P0 chỉ cần reference synthesis, chưa cần tối ưu cực hạn.

Ghi tối thiểu:

| Metric | Baseline |
|---|---:|
| LUT | TBD |
| FF | TBD |
| BRAM | TBD |
| DSP | TBD |
| Target clock | TBD |
| WNS/TNS hoặc timing status | TBD |
| Estimated Fmax nếu dùng | TBD |
| Latency/block | TBD |
| Throughput | TBD |

P4 sẽ chạy matched comparison chính thức.

---

## 10. Quy tắc tạo AES variants

Variant phải giữ:

```text
same AES algorithm
same AES-128 key size
same 128-bit block semantics
same external RM contract
same correctness criteria
```

Variant có thể thay đổi:

- S-box implementation;
- resource mapping;
- microarchitecture;
- pipeline structure nếu contract xử lý latency đúng;
- physical implementation strategy nếu đó là biến nghiên cứu.

Không được gọi một implementation là “variant AES” nếu nó cho output khác hoặc thay đổi cryptographic semantics.

---

## 11. Baseline vs RM comparison

Tối thiểu ba nhóm:

```text
Static Baseline
RM-A standalone
RM-B standalone
```

Sau đó mới so với:

```text
DFX Static + RP + RM-A
DFX Static + RP + RM-B
```

Như vậy có thể tách:

- cost của AES variant;
- cost của DFX infrastructure;
- cost của reconfiguration.

---

## 12. P0 Baseline Freeze Checklist

- [ ] AES source selected.
- [ ] License checked.
- [ ] Exact commit/revision pinned.
- [ ] AES-128 configuration recorded.
- [ ] KAT PASS.
- [ ] Simulation command documented.
- [ ] Baseline synthesis PASS.
- [ ] Resource/timing reference saved.
- [ ] Board/device/tool versions recorded.
- [ ] Instructor review PASS.

Sau khi checklist này PASS, mọi thay đổi baseline phải có lý do và review; không silently update upstream revision giữa project.
