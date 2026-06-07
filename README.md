## Tên đề tài

**Nghiên cứu cơ chế Dynamic Partial Reconfiguration cho thiết kế mã hóa đối xứng AES trên FPGA**

## Mục tiêu

Đề tài hướng đến việc nghiên cứu và hiện thực cơ chế **Dynamic Partial Reconfiguration (DPR)** cho thiết kế mã hóa đối xứng **AES** trên FPGA. Mục tiêu chính là tạo ra nhiều biến thể phần cứng khác nhau của AES và cho phép hệ thống chuyển đổi giữa các biến thể này trong quá trình vận hành, nhằm làm thay đổi đặc tính thực thi và đặc tính rò rỉ vật lý của thiết kế.

Mục tiêu cụ thể gồm:

* Tìm hiểu thuật toán AES và các kiến trúc phần cứng AES phổ biến.
* Tìm hiểu cơ chế Dynamic Partial Reconfiguration trên FPGA.
* Xây dựng thiết kế AES baseline.
* Tạo nhiều biến thể AES có cùng chức năng nhưng khác nhau về cấu trúc phần cứng.
* Tích hợp các biến thể AES vào vùng tái cấu hình động trên FPGA.
* Xây dựng cơ chế điều khiển chuyển đổi giữa các biến thể AES.
* Đánh giá thiết kế DPR-AES so với baseline theo các tiêu chí: tài nguyên, hiệu năng, độ trễ tái cấu hình, throughput, công suất và mức độ đa dạng hóa.
* Phân tích khả năng ứng dụng DPR như một cơ chế Moving Target Defense cho thiết kế mật mã phần cứng.

## Vai trò

AES là thuật toán mã hóa đối xứng được sử dụng rộng rãi trong các hệ thống nhúng, IoT, FPGA-SoC và các thiết bị biên. Về mặt thuật toán, AES được xem là an toàn trong mô hình black-box. Tuy nhiên, khi AES được hiện thực trên phần cứng, quá trình tính toán có thể làm phát sinh các kênh rò rỉ vật lý như công suất tiêu thụ, bức xạ điện từ, thời gian thực thi hoặc đáp ứng lỗi.

Trong các thiết kế FPGA truyền thống, một lõi AES thường có cấu trúc cố định trong suốt thời gian hoạt động. Điều này tạo điều kiện cho đối thủ thu thập nhiều mẫu đo trên cùng một cấu hình phần cứng để xây dựng mô hình rò rỉ. Cơ chế **Dynamic Partial Reconfiguration** cho phép thay đổi một phần mạch FPGA trong khi phần còn lại của hệ thống vẫn hoạt động. Nhờ đó, thiết kế AES có thể được triển khai dưới nhiều biến thể vật lý khác nhau và được thay đổi theo thời gian, theo số lần mã hóa hoặc theo chính sách bảo mật.

Trong bối cảnh **Moving Target Defense**, DPR-AES có thể được xem là cơ chế làm dịch chuyển **physical leakage surface** của thiết kế mật mã. Thay vì để attacker quan sát một cấu hình AES cố định, hệ thống liên tục hoặc định kỳ thay đổi cấu trúc thực thi, vị trí logic, định tuyến, S-box, pipeline hoặc các nguồn nhiễu đi kèm. Điều này làm giảm khả năng tái sử dụng trace, tăng số lượng mẫu cần thu thập và làm tăng chi phí phân tích của attacker.

Mô hình tổng quát:

```text
Static Region
  - CPU / Controller
  - AXI Bus
  - Memory
  - DPR Manager
  - Interface logic

Partial Reconfigurable Region
  - AES Variant 1
  - AES Variant 2
  - AES Variant 3
  - AES Variant N
```

Trong quá trình vận hành:

```text
Plaintext + Key
      |
      v
AES Variant hiện tại
      |
      v
Ciphertext

Sau một số chu kỳ / một số block / một sự kiện bảo mật:
      |
      v
DPR Controller nạp partial bitstream mới
      |
      v
AES Variant khác được kích hoạt
```

## Nội dung nghiên cứu

### 1. Nghiên cứu thuật toán AES và kiến trúc phần cứng AES

Sinh viên cần tìm hiểu:

* Cấu trúc thuật toán AES.
* Các bước chính: SubBytes, ShiftRows, MixColumns, AddRoundKey.
* Key expansion.
* AES-128 là phạm vi khuyến nghị cho giai đoạn đầu.
* Các kiến trúc phần cứng AES:

  * iterative AES,
  * pipelined AES,
  * unrolled AES,
  * table-based S-box,
  * composite-field S-box,
  * BRAM-based S-box.

### 2. Xây dựng thiết kế AES baseline (Dùng Opensource có sẵn)

### 3. Thiết kế các biến thể AES

Mục tiêu của DPR-AES là tạo nhiều biến thể có cùng chức năng mã hóa nhưng khác nhau về cấu trúc phần cứng.

#### Biến thể 1: AES S-box LUT-based

S-box được hiện thực bằng lookup table trong logic FPGA.

Đặc điểm:

* Dễ hiện thực.
* Tốc độ cao.
* Dễ dùng làm baseline.

#### Biến thể 2: AES S-box BRAM-based

S-box được lưu trong BRAM hoặc distributed RAM.

Đặc điểm:

* Thay đổi tài nguyên sử dụng.
* Thay đổi vị trí rò rỉ so với LUT-based S-box.
* Phù hợp với FPGA.

#### Biến thể 3: AES S-box composite-field

S-box được hiện thực bằng mạch logic theo trường hữu hạn.

Đặc điểm:

* Cấu trúc logic khác LUT-based.
* Có thể tạo đặc tính switching khác.
* Phù hợp để tạo implementation diversity.

#### Biến thể 4: AES có dummy/noise logic

Bổ sung logic giả hoặc nguồn nhiễu hoạt động song song với AES.

Đặc điểm:

* Làm nhiễu trace công suất.
* Có thể bật/tắt hoặc thay đổi theo cấu hình.
* Cần kiểm soát overhead tài nguyên và công suất.

#### Biến thể 5: AES pipeline khác nhau

Tạo các phiên bản AES có mức pipeline khác nhau.

Ví dụ:

* AES iterative 10 rounds.
* AES có pipeline từng round.
* AES có pipeline ở một số khối S-box/MixColumns.

Đặc điểm:

* Thay đổi timing behavior.
* Thay đổi throughput/latency.
* Có thể làm thay đổi pattern rò rỉ theo thời gian.

Khuyến nghị cho sinh viên:

* Mức cơ bản: tạo 2 biến thể AES, ví dụ LUT-Sbox và BRAM-Sbox.
* Mức khá: tạo 3–4 biến thể AES, thêm composite-field hoặc dummy logic.
* Mức nâng cao: tạo nhiều biến thể cùng chức năng nhưng khác placement/routing bằng flow DPR.

### 4. Thiết kế kiến trúc DPR-AES

Kiến trúc đề xuất gồm hai phần:

#### Static Region

Phần tĩnh không thay đổi trong quá trình vận hành.

Bao gồm:

* Controller.
* Bus interface.
* Input/output register.
* Key/plaintext/ciphertext buffer.
* DPR manager.
* Interface wrapper giữa static region và partial region.
* Optional: CPU mềm hoặc ARM PS nếu dùng Zynq/Kria.

#### Partial Reconfigurable Region

Phần có thể tái cấu hình động.

Bao gồm:

* AES Variant 1.
* AES Variant 2.
* AES Variant 3.
* AES Variant N.

Các biến thể phải có cùng giao diện để có thể thay thế lẫn nhau.

Giao diện vùng DPR nên được chuẩn hóa:

```verilog
module aes_pr_region (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [127:0] plaintext,
    input  wire [127:0] key,
    output wire [127:0] ciphertext,
    output wire         done
);
```

Yêu cầu quan trọng:

* Mọi AES variant phải tương thích cùng một interface.
* Static region không cần biết bên trong đang là biến thể nào.
* Sau khi nạp partial bitstream mới, hệ thống cần reset hoặc re-initialize AES region trước khi chạy.
* Cần có cơ chế kiểm tra variant đã nạp thành công.

### 5. Chính sách tái cấu hình

Sinh viên có thể nghiên cứu các chính sách chuyển đổi biến thể:

#### Chính sách 1: Periodic reconfiguration

Thay đổi AES variant sau một khoảng thời gian cố định.

Ví dụ:

```text
Mỗi 1000 block AES -> đổi variant
```

Ưu điểm:

* Dễ hiện thực.
* Dễ kiểm thử.

Nhược điểm:

* Nếu chu kỳ cố định, attacker có thể học quy luật.

#### Chính sách 2: Randomized reconfiguration

Thay đổi AES variant theo số ngẫu nhiên.

Ví dụ:

```text
Sau N block, với N được sinh ngẫu nhiên trong [Nmin, Nmax]
```

Ưu điểm:

* Khó dự đoán hơn.
* Phù hợp hơn với MTD.

Nhược điểm:

* Cần nguồn ngẫu nhiên đủ tốt.
* Khó debug hơn.

#### Chính sách 3: Event-triggered reconfiguration

Thay đổi AES variant khi có sự kiện bảo mật.

Ví dụ:

* Số lượng truy cập vượt ngưỡng.
* Phát hiện lỗi bất thường.
* Phát hiện thay đổi công suất/clock/voltage.
* Nhận lệnh từ security monitor.

## Các bước thực hiện

### Bước 1: Khảo sát tài liệu

Sinh viên cần đọc và tóm tắt:

* Thuật toán AES.
* Các kiến trúc AES phần cứng.
* Dynamic Partial Reconfiguration trên FPGA.
* Các công trình dùng implementation diversity và partial reconfiguration để bảo vệ mạch mật mã.

### Bước 2: Chọn nền tảng FPGA và công cụ

Khuyến nghị dùng Xilinx vì Vivado hỗ trợ flow Dynamic Function eXchange khá rõ.

Các lựa chọn phù hợp:

* Artix-7.
* Kintex-7.
* Zynq-7000.
* Zynq UltraScale+.
* Kria KV260.
* PYNQ-Z2 nếu chỉ làm demo nhỏ.

Nếu dùng Intel/Altera, có thể khảo sát flow Partial Reconfiguration trong Quartus, nhưng độ thuận tiện phụ thuộc board và license.

Sản phẩm:

* Chọn board hoặc target FPGA.
* Cài đặt tool.
* Chạy được ví dụ DPR/DFX mẫu.
* Báo cáo lựa chọn nền tảng.

### Bước 3: Hiện thực AES baseline

Thực hiện:

* Lấy một AES RTL open-source hoặc tự hiện thực AES-128.
* Viết testbench.
* Chạy test vector chuẩn.
* Tổng hợp baseline trên FPGA.
* Ghi nhận tài nguyên, timing, throughput và latency.

Sản phẩm:

* AES baseline chạy đúng.
* Testbench.
* Báo cáo tài nguyên baseline.

### Bước 4: Tạo các biến thể AES

Thực hiện:

* Tạo ít nhất hai biến thể AES có cùng giao diện.
* Đảm bảo tất cả biến thể cho cùng ciphertext với cùng plaintext/key.
* Kiểm tra từng biến thể bằng cùng bộ test vector.
* Tổng hợp từng biến thể riêng để so sánh tài nguyên.

Ví dụ:

```text
AES_V1: LUT-based S-box
AES_V2: BRAM-based S-box
AES_V3: Composite-field S-box
AES_V4: LUT-based S-box + dummy noise logic
```

Sản phẩm:

* RTL của các biến thể.
* Testbench chung.
* Bảng so sánh tài nguyên và timing từng biến thể.

### Bước 5: Thiết kế static wrapper và PR interface

Thực hiện:

* Thiết kế wrapper cố định.
* Định nghĩa interface giữa static region và partial region.
* Đảm bảo interface ổn định cho mọi biến thể.
* Thêm register đầu vào/đầu ra để tránh lỗi khi tái cấu hình.
* Thêm tín hiệu reset cho PR region.

Sản phẩm:

* Static wrapper.
* PR interface.
* Sơ đồ kiến trúc hệ thống.

### Bước 6: Thiết lập flow DPR/DFX

### Bước 7: Điều khiển tái cấu hình

### Bước 8: Kiểm thử chức năng DPR-AES

Kịch bản kiểm thử:

1. Nạp full bitstream.
2. Chạy AES Variant 1 với test vector.
3. Ghi nhận ciphertext.
4. Nạp partial bitstream Variant 2.
5. Reset PR region.
6. Chạy lại cùng test vector.
7. Kiểm tra ciphertext giống Variant 1.
8. Lặp lại với các variant khác.

### Bước 9: Đánh giá overhead

Các tiêu chí cần đo:

#### Tài nguyên

* LUT.
* FF.
* BRAM.
* DSP.
* Diện tích vùng PR.
* Tài nguyên static region.
* Tài nguyên controller DPR.

#### Timing

* Fmax từng variant.
* Critical path.
* Timing closure của từng reconfigurable module.

#### Hiệu năng

* Latency một lần mã hóa.
* Throughput.
* Số chu kỳ mỗi block AES.
* Thời gian tái cấu hình.
* Kích thước partial bitstream.
* Tỷ lệ thời gian hữu ích so với thời gian tái cấu hình.

#### Công suất

* Dynamic power.
* Static power.
* Power estimate từ Vivado/Quartus.
* Optional: đo công suất thực tế nếu có thiết bị.


## Tools / Open-source

### FPGA Design

* Vivado Xilinx.
* Vivado Dynamic Function eXchange / Partial Reconfiguration flow.
* Intel Quartus Partial Reconfiguration, nếu dùng FPGA Intel/Altera.
* Vitis hoặc PetaLinux nếu dùng Zynq/ZynqMP.
* Xilinx ICAP/PCAP interface.
* AXI GPIO / AXI DMA / AXI Lite nếu tích hợp với ARM PS.

### RTL và mô phỏng

* Verilog/SystemVerilog hoặc VHDL.
* Verilator.
* QuestaSim/ModelSim.
* Icarus Verilog cho thiết kế đơn giản.
* GTKWave.
* Python test script.

### AES open-source cores

* secworks/aes.
* OpenTitan AES core.
* tiny_aes hoặc AES Verilog/VHDL cores dùng cho tham khảo.
* AES S-box LUT/composite-field implementations.

## Kết quả mong đợi
* AES baseline chạy đúng trên mô phỏng.
* Ít nhất hai biến thể AES có cùng chức năng nhưng khác kiến trúc phần cứng.
* Thiết kế DPR-AES có static region và partial reconfigurable region.
* Sinh được full bitstream và partial bitstreams.
* Thực hiện được quá trình thay đổi AES variant bằng partial reconfiguration.
* Kiểm tra được ciphertext đúng sau mỗi lần tái cấu hình.
* Có bảng so sánh tài nguyên, timing, latency, throughput và reconfiguration time.
* Có đánh giá định tính hoặc định lượng về mức độ đa dạng hóa phần cứng.
* Có phân tích về lợi ích và giới hạn của DPR trong bảo vệ AES trước side-channel/fault-oriented threat model.

## Phạm vi đề tài đề xuất

* AES-128/256/512 
* Hai/Ba biến thể AES.
* Partial reconfiguration offline bằng Vivado Hardware Manager.
* Đánh giá chức năng, tài nguyên và timing.


## Các tiêu chí đánh giá

| Nhóm tiêu chí    | Nội dung đo                                                      |
| ---------------- | ---------------------------------------------------------------- |
| Chức năng        | AES test vector, correctness sau DPR                             |
| Tài nguyên       | LUT, FF, BRAM, DSP, diện tích PR region                          |
| Timing           | Fmax, critical path, timing closure                              |
| Hiệu năng        | Latency, throughput, cycles/block                                |
| DPR overhead     | Partial bitstream size, reconfiguration time                     |
| Công suất        | Dynamic power, static power, switching activity                  |

## Tài liệu tham khảo 

Tôi khuyến nghị triển khai đề tài này theo lộ trình **AES baseline → nhiều biến thể AES → DPR offline → DPR runtime → đánh giá leakage**. Với sinh viên tiền nghiên cứu, mức hợp lý nhất là tạo **2–3 biến thể AES** và chứng minh partial reconfiguration chạy đúng; phần đo side-channel có thể để thành hướng mở rộng.
