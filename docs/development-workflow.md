# Development Workflow cho từng Phase

## 1. Mục tiêu

Tài liệu này quy định workflow bắt buộc cho project **DPR-AES** nhằm bảo đảm source code, DFX project, documentation và evidence luôn đồng bộ.

Flow chuẩn:

```text
main
 │
 ├── tạo phase branch
 │
 ▼
Implementation / Documentation / Evidence
 │
 ▼
Local Verification
 │
 ▼
Push branch
 │
 ▼
Pull Request → main
 │
 ▼
Instructor Review
 │
 ├── Changes requested → sửa trên cùng branch
 │
 └── PASS → Merge
              │
              ▼
        Update/Close Issue
              │
              ▼
        Start Next Phase
```

---

## 2. Nguyên tắc chung

### 2.1 Không làm việc trực tiếp trên `main`

`main` là nhánh ổn định. Sinh viên không commit implementation trực tiếp lên `main`.

### 2.2 Một Phase — một branch chính

Branch naming:

```text
phase/p0-foundation-baseline
phase/p1-architecture-design
phase/p2-aes-variants
phase/p3-dfx-runtime
phase/p4-evaluation-release
```

### 2.3 Một Phase gắn với một issue

| Phase | Issue |
|---|---|
| P0 — Foundation, Toolchain & AES Baseline | `#2` |
| P1 — DPR Architecture & Variant Design | `#3` |
| P2 — AES Variants & Functional Verification | `#4` |
| P3 — DFX Integration & Runtime Reconfiguration | `#5` |
| P4 — Evaluation, Reproducibility & Release | `#6` |

Master control: `#1`.

### 2.4 Evidence là một phần của deliverable

Không xem task hoàn thành chỉ vì RTL compile hoặc Vivado build xong. Mỗi claim phải có evidence phù hợp:

- correctness → test log / test report;
- equivalence → common vectors/regression;
- timing → timing report;
- resource → utilization report;
- DFX → configuration/build log + hardware procedure;
- reconfiguration latency → measurement method + raw result;
- side-channel/leakage → chỉ khi có trace methodology và measurement evidence.

---

## 3. Step 1 — Đồng bộ `main`

```bash
git checkout main
git pull origin main
git status
```

Yêu cầu:

```text
working tree clean
```

---

## 4. Step 2 — Tạo Phase branch

Ví dụ P0:

```bash
git switch -c phase/p0-foundation-baseline
git push -u origin phase/p0-foundation-baseline
```

Mọi thay đổi của P0 thực hiện trên branch này.

---

## 5. Step 3 — Thực hiện task theo issue

Thay đổi có thể gồm:

- RTL;
- testbench;
- scripts;
- Vivado/DFX Tcl;
- board constraints;
- host/runtime software;
- documentation;
- reports/evidence.

### Commit nhỏ và có ý nghĩa

Ví dụ:

```text
build: add AES baseline simulation flow
docs: freeze DPR-AES RM interface
rtl: add LUT-based AES reconfigurable module
test: add cross-variant equivalence regression
fpga: add DFX configuration for RM-A and RM-B
results: add P3 reconfiguration latency evidence
```

Tránh commit message như:

```text
update
fix
final
new code
```

---

## 6. Step 4 — Verification trước PR

Tối thiểu xác nhận:

- [ ] source/build không lỗi;
- [ ] test liên quan PASS;
- [ ] documentation phản ánh đúng implementation;
- [ ] evidence cần thiết đã được lưu;
- [ ] không có file temporary/generated không cần thiết;
- [ ] không có thay đổi ngoài scope issue;
- [ ] branch đã push.

Nếu Phase có DFX build:

- [ ] mọi RM configuration implement thành công;
- [ ] timing status được ghi lại;
- [ ] full/partial bitstream outputs được kiểm tra;
- [ ] tool/device/configuration được ghi rõ.

Nếu Phase có hardware test:

- [ ] procedure có thể lặp lại;
- [ ] test vectors được định danh;
- [ ] PASS/FAIL criteria rõ;
- [ ] raw log hoặc result artifact được lưu.

---

## 7. Step 5 — Tạo Pull Request

PR phải mô tả:

### Summary

Đã thay đổi gì và tại sao.

### Scope

Issue/Phase nào đang được giải quyết.

### Verification

Các lệnh/test đã chạy và kết quả.

### Evidence

Link/path tới logs, reports, screenshots hoặc result files.

### Limitations

Các phần chưa làm hoặc chưa được chứng minh.

### Checklist

```markdown
- [ ] Scope đúng issue
- [ ] Tests PASS
- [ ] Docs updated
- [ ] Evidence committed
- [ ] No unrelated changes
- [ ] Ready for instructor review
```

PR nên liên kết issue, ví dụ:

```text
Closes #2
```

Chỉ dùng `Closes` khi PR thực sự đủ điều kiện đóng issue sau merge.

---

## 8. Step 6 — Instructor Review

Instructor review theo ba mức:

### BLOCK

Có lỗi correctness, scope, reproducibility hoặc claim không có evidence.

### CHANGES REQUESTED

Kiến trúc/implementation cơ bản đúng nhưng cần chỉnh sửa trước merge.

### PASS

Gate của Phase đạt, evidence đủ và có thể merge.

Sinh viên sửa trực tiếp trên cùng Phase branch, không mở PR mới chỉ để sửa review comments.

---

## 9. Step 7 — Merge và chuyển Phase

Sau khi PR PASS và merge:

1. cập nhật issue checklist;
2. ghi comment tóm tắt evidence cuối;
3. đóng issue nếu gate đã PASS;
4. `git checkout main && git pull`;
5. chỉ tạo branch Phase tiếp theo khi instructor xác nhận START.

---

## 10. Quy tắc riêng cho DPR/DFX

### 10.1 Không commit generated project artifacts vô tội vạ

Ưu tiên source-of-truth có thể tái tạo:

- Tcl scripts;
- XDC;
- source lists;
- RTL;
- configuration manifest;
- documented Vivado version.

Không commit toàn bộ thư mục `.runs/`, `.cache/`, `.gen/` hoặc temporary files nếu không có lý do evidence rõ ràng.

### 10.2 Bitstream policy

Full/partial bitstreams có thể lớn và phụ thuộc tool/device. Chỉ commit khi instructor xác nhận repository policy cho binary artifacts. Nếu không, lưu build metadata/checksum và hướng dẫn tái tạo.

### 10.3 Matched comparison

Khi so sánh baseline/RM-A/RM-B phải giữ cố định:

```text
FPGA device/board
Vivado version
clock constraint
implementation strategy (trừ khi chính strategy là biến nghiên cứu)
test vector/workload
measurement method
```

### 10.4 Không thay đổi interface giữa các RM sau P1 nếu chưa review

Nếu RM interface phải thay đổi:

1. dừng implementation;
2. cập nhật `docs/architecture.md`;
3. ghi rõ reason trong issue/PR;
4. instructor review lại P1 contract trước khi tiếp tục.

---

## 11. Definition of Ready cho mỗi Phase

Một Phase chỉ được START khi:

- Phase trước đã merge/PASS;
- issue hiện tại có scope rõ;
- branch được tạo từ `main` mới nhất;
- dependencies và board/tool assumptions đã biết đủ để bắt đầu.

## 12. Definition of Done cho mỗi Phase

Một Phase chỉ DONE khi:

```text
Implementation/Documentation
        +
Verification
        +
Evidence
        +
Instructor Review PASS
        +
Merge to main
```

Thiếu một thành phần trên thì Phase chưa hoàn thành.
