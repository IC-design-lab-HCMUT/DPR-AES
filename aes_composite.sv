
//===================================================================
// MODULE 1: AES-256 TOP WRAPPER
//===================================================================
module aes_composite (
  input  logic clk_sys,
  input  logic rst_n,
  input  logic [255:0] cipher_key, // KHÁC BIỆT: Khóa 256-bit
  input  logic [127:0] plain_text,
  input  logic cipher_en,
  
  output logic [127:0] cipher_text,
  output logic cipher_ready
);
  logic [3:0]   round_num;
  logic         rkey_en;
  logic [127:0] round_key_out;

  aes256_cipher_core aes256_core (
    .clk_sys(clk_sys),
    .rst_n(rst_n),
    .cipher_key(cipher_key[255:128]), // Gửi Word 0-3 (nửa trên) cho vòng 0
    .round_key(round_key_out),
    .plain_text(plain_text),
    .cipher_en(cipher_en),
    .cipher_text(cipher_text),
    .cipher_ready(cipher_ready),
    .round_num(round_num),
    .rkey_en(rkey_en) 
  );

  aes256_key_expansion aes256_key_exp (
    .clk_sys(clk_sys),
    .rst_n(rst_n),
    .cipher_en(cipher_en),
    .rkey_en(rkey_en),
    .cipher_key(cipher_key), // Gửi trọn 256-bit vào mạch sinh khóa
    .round_num(round_num),
    .round_key_out(round_key_out)
  );
endmodule

//===================================================================
// MODULE 2: AES-256 CIPHER CORE
//===================================================================
module aes256_cipher_core(
  input  logic clk_sys,
  input  logic rst_n,
  input  logic [127:0] cipher_key, // 128-bit khóa cho vòng 0 (Word 0-3)
  input  logic [127:0] round_key,
  input  logic [127:0] plain_text,
  input  logic cipher_en,
  
  output logic [127:0] cipher_text,
  output logic cipher_ready,
  output logic [3:0]   round_num,
  output logic rkey_en 
);

  logic	[127:0]	after_mixColumns;
  logic	[127:0]	subbytes_sel;
  logic [127:0]	after_shiftRows;
  logic [127:0]	cipherText_reg;
  logic	[127:0]	mixColumns_in;
  logic [127:0]	after_subBytes;
  logic [127:0] addRoundKey_in;
  logic [127:0] after_addRoundkey;
  logic [3:0]	cipher_counter;
  logic		    cipher_complete;

  // Monitor counter (SỬA LẠI ĐẾM TỚI 14 CHO AES-256)
  always @ (posedge clk_sys, negedge rst_n) begin
  	if (~rst_n) cipher_counter	<= 4'd0;
  	else if (cipher_complete)
  		cipher_counter	<= 4'd0;
  	else if (cipher_en | rkey_en)
  		cipher_counter	<= cipher_counter + 1'b1;
  end
  
  // KHÁC BIỆT: Vòng lặp thứ 14 là kết thúc
  assign cipher_complete = (cipher_counter == 4'b1110)? 1'b1: 1'b0; 
  assign round_num[3:0]  = cipher_counter[3:0];

  // Cipher status
  always @ (posedge clk_sys, negedge rst_n) begin
  	if (~rst_n)
      cipher_ready	<= 1'b1;
  	else if (cipher_en)
  		cipher_ready	<= 1'b0;
  	else if (cipher_complete)
      cipher_ready	<= 1'b1;
  end
  assign rkey_en = ~cipher_ready;

  // SubBytes Address Routing
  assign subbytes_sel[127:120] = cipherText_reg[127:120];
  assign subbytes_sel[119:112] = cipherText_reg[95:88];
  assign subbytes_sel[111:104] = cipherText_reg[63:56];
  assign subbytes_sel[103:96]  = cipherText_reg[31:24];
  assign subbytes_sel[95:88]   = cipherText_reg[119:112];
  assign subbytes_sel[87:80]   = cipherText_reg[87:80];
  assign subbytes_sel[79:72]   = cipherText_reg[55:48];
  assign subbytes_sel[71:64]   = cipherText_reg[23:16];
  assign subbytes_sel[63:56]   = cipherText_reg[111:104];
  assign subbytes_sel[55:48]   = cipherText_reg[79:72];
  assign subbytes_sel[47:40]   = cipherText_reg[47:40];
  assign subbytes_sel[39:32]   = cipherText_reg[15:8];
  assign subbytes_sel[31:24]   = cipherText_reg[103:96];
  assign subbytes_sel[23:16]   = cipherText_reg[71:64];
  assign subbytes_sel[15:8]	   = cipherText_reg[39:32];
  assign subbytes_sel[7:0]	   = cipherText_reg[7:0];

  // SubBytes Sbox
  aes_sbox u0  (.in_byte(subbytes_sel[127:120]), .out_byte(after_subBytes[127:120]));
  aes_sbox u1  (.in_byte(subbytes_sel[119:112]), .out_byte(after_subBytes[119:112]));
  aes_sbox u2  (.in_byte(subbytes_sel[111:104]), .out_byte(after_subBytes[111:104]));
  aes_sbox u3  (.in_byte(subbytes_sel[103:96]),  .out_byte(after_subBytes[103:96]));
  aes_sbox u4  (.in_byte(subbytes_sel[95:88]),   .out_byte(after_subBytes[95:88]));
  aes_sbox u5  (.in_byte(subbytes_sel[87:80]),   .out_byte(after_subBytes[87:80]));
  aes_sbox u6  (.in_byte(subbytes_sel[79:72]),   .out_byte(after_subBytes[79:72]));
  aes_sbox u7  (.in_byte(subbytes_sel[71:64]),   .out_byte(after_subBytes[71:64]));
  aes_sbox u8  (.in_byte(subbytes_sel[63:56]),   .out_byte(after_subBytes[63:56]));
  aes_sbox u9  (.in_byte(subbytes_sel[55:48]),   .out_byte(after_subBytes[55:48]));
  aes_sbox u10 (.in_byte(subbytes_sel[47:40]),   .out_byte(after_subBytes[47:40]));
  aes_sbox u11 (.in_byte(subbytes_sel[39:32]),   .out_byte(after_subBytes[39:32]));
  aes_sbox u12 (.in_byte(subbytes_sel[31:24]),   .out_byte(after_subBytes[31:24]));
  aes_sbox u13 (.in_byte(subbytes_sel[23:16]),   .out_byte(after_subBytes[23:16]));
  aes_sbox u14 (.in_byte(subbytes_sel[15:8]),    .out_byte(after_subBytes[15:8]));
  aes_sbox u15 (.in_byte(subbytes_sel[7:0]),     .out_byte(after_subBytes[7:0]));

  // ShiftRows
  always @ (*) begin
  	after_shiftRows[127:120] = after_subBytes[127:120];
  	after_shiftRows[119:112] = after_subBytes[119:112];
  	after_shiftRows[111:104] = after_subBytes[111:104];
  	after_shiftRows[103:96]  = after_subBytes[103:96];
  	
  	after_shiftRows[71:64] = after_subBytes[95:88];
  	after_shiftRows[95:88] = after_subBytes[87:80];
  	after_shiftRows[87:80] = after_subBytes[79:72];
  	after_shiftRows[79:72] = after_subBytes[71:64];
  	
  	after_shiftRows[47:40] = after_subBytes[63:56];
  	after_shiftRows[39:32] = after_subBytes[55:48];
  	after_shiftRows[63:56] = after_subBytes[47:40];
  	after_shiftRows[55:48] = after_subBytes[39:32];
  	
  	after_shiftRows[23:16] = after_subBytes[31:24];
  	after_shiftRows[15:8]  = after_subBytes[23:16];
  	after_shiftRows[7:0]   = after_subBytes[15:8];
  	after_shiftRows[31:24] = after_subBytes[7:0];
  end
  
  // MixColumns
  assign mixColumns_in[127:96]	= {after_shiftRows[127:120], after_shiftRows[95:88], after_shiftRows[63:56], after_shiftRows[31:24]};
  assign mixColumns_in[95:64]	= {after_shiftRows[119:112], after_shiftRows[87:80], after_shiftRows[55:48], after_shiftRows[23:16]};
  assign mixColumns_in[63:32]	= {after_shiftRows[111:104], after_shiftRows[79:72], after_shiftRows[47:40], after_shiftRows[15:8]};
  assign mixColumns_in[31:0]	= {after_shiftRows[103:96],  after_shiftRows[71:64], after_shiftRows[39:32], after_shiftRows[7:0]};

  assign after_mixColumns[127:96] = mixcol(mixColumns_in[127:96]);
  assign after_mixColumns[95:64]  = mixcol(mixColumns_in[95:64]);
  assign after_mixColumns[63:32]  = mixcol(mixColumns_in[63:32]);
  assign after_mixColumns[31:0]   = mixcol(mixColumns_in[31:0]);

  // AddRoundKey 
  assign addRoundKey_in[127:0] = cipher_en? plain_text[127:0]:
                                 (cipher_complete? mixColumns_in[127:0]: after_mixColumns[127:0]);
  assign after_addRoundkey[127:0] = addRoundKey_in[127:0] ^ (cipher_en? cipher_key[127:0]: round_key[127:0]);

  // State Register
  always	@ (posedge clk_sys) begin
  	if (cipher_en | rkey_en)
      cipherText_reg <= after_addRoundkey;
  end

  assign cipher_text = cipherText_reg;

  // INTERNAL FUNCTIONS FOR CIPHER CORE
  function logic [7:0] mul2;
    input [7:0] mul2_in;
    mul2 = (mul2_in[7] == 1'b1)? ({mul2_in[6:0], 1'b0} ^ 8'b0001_1011) : {mul2_in[6:0], 1'b0};
  endfunction

  function logic [7:0] mul3;
    input [7:0] mul3_in;
    mul3 = mul2(mul3_in) ^ mul3_in;
  endfunction

  function logic [31:0] mixcol;
    input [31:0] mixcol_in;
    mixcol[31:24] = mul2(mixcol_in[31:24]) ^ mul3(mixcol_in[23:16]) ^ mixcol_in[15:8]       ^ mixcol_in[7:0];
    mixcol[23:16] = mixcol_in[31:24]       ^ mul2(mixcol_in[23:16]) ^ mul3(mixcol_in[15:8]) ^ mixcol_in[7:0];
    mixcol[15:8]  = mixcol_in[31:24]       ^ mixcol_in[23:16]       ^ mul2(mixcol_in[15:8])  ^ mul3(mixcol_in[7:0]);
    mixcol[7:0]   = mul3(mixcol_in[31:24]) ^ mixcol_in[23:16]       ^ mixcol_in[15:8]       ^ mul2(mixcol_in[7:0]);
  endfunction

endmodule

//===================================================================
// MODULE 3: AES-256 KEY EXPANSION
//===================================================================
module aes256_key_expansion (
  input  logic clk_sys,
  input  logic rst_n,
  input  logic cipher_en,
  input  logic rkey_en,
  input  logic [255:0] cipher_key, // Khóa gốc 256-bit
  input  logic [3:0]   round_num,
  
  output logic [127:0] round_key_out
);
  
  logic [255:0] key_reg; 
  
  // Dữ liệu dùng để tính toán (128 bit quá khứ xa và 128 bit quá khứ gần)
  logic [127:0] key_old;    // Word 0-3 (nếu ở vòng lẻ) hoặc Word 4-7 (nếu ở vòng chẵn)
  logic [127:0] key_recent; // Word 4-7 (nếu ở vòng lẻ) hoặc Word 8-11 (nếu ở vòng chẵn)
  logic [127:0] key_new;    // 128-bit khóa phụ mới sinh ra

  logic [31:0]  w_in;       // Word cuối cùng dùng để nhào nặn
  logic [31:0]  after_rotW;
  logic [31:0]  after_subW;
  logic [31:0]  rcon_value;
  logic [31:0]  w_transformed; // Word sau khi đã qua phép biến hóa
  
  // Cờ báo hiệu đang ở Vòng chẵn hay Vòng lẻ
  // AES-256: Vòng 1, 3, 5... là vòng lẻ. Vòng 2, 4, 6... là vòng chẵn.
  logic is_even_round;
  assign is_even_round = (round_num[0] == 1'b0); // Chia hết cho 2 là chẵn

  // Điều phối đầu vào dựa trên vòng lặp
  assign key_old    = (round_num == 4'd0) ? cipher_key[255:128] : key_reg[255:128];
  assign key_recent = (round_num == 4'd0) ? cipher_key[127:0]   : key_reg[127:0];

  // Lấy Word cuối cùng của quá khứ gần nhất (Word 3 hoặc Word 7)
  assign w_in = key_recent[31:0];

  
  // 1. RotWord: Chỉ xoay byte ở vòng lẻ (i % 8 == 0)
  // Nếu vòng chẵn (i % 8 == 4), giữ nguyên vị trí byte
  assign after_rotW = is_even_round ? w_in : {w_in[23:0], w_in[31:24]};

  // 2. SubWord: Luôn luôn cho chạy qua S-box (Cả vòng chẵn và lẻ)
  aes_sbox uu0 (.in_byte(after_rotW[31:24]), .out_byte(after_subW[31:24]));
  aes_sbox uu1 (.in_byte(after_rotW[23:16]), .out_byte(after_subW[23:16]));
  aes_sbox uu2 (.in_byte(after_rotW[15:8]),  .out_byte(after_subW[15:8]));
  aes_sbox uu3 (.in_byte(after_rotW[7:0]),   .out_byte(after_subW[7:0]));
  
  // 3. Rcon: Chỉ cộng Rcon ở vòng lẻ
  assign rcon_value = is_even_round ? 32'h0000_0000 : aes256_rcon(round_num);
  
  // W_transformed = SubWord(RotWord(W)) ^ Rcon (vòng lẻ)
  //                 SubWord(W)                 (vòng chẵn)
  assign w_transformed = after_subW ^ rcon_value;

  // ==================================================
  // PHẢN ỨNG DÂY CHUYỀN XOR (Cascade XOR)
  // ==================================================
  // Đem W_transformed XOR với quá khứ xa (key_old)
  assign key_new[127:96] = w_transformed ^ key_old[127:96];
  assign key_new[95:64]  = key_new[127:96] ^ key_old[95:64];
  assign key_new[63:32]  = key_new[95:64]  ^ key_old[63:32];
  assign key_new[31:0]   = key_new[63:32]  ^ key_old[31:0];

  // Lưu trữ khóa mới vào thanh ghi 256-bit (Đẩy khóa cũ ra khỏi hàng đợi)
  always @ (posedge clk_sys) begin
  	if (cipher_en) begin
          key_reg <= cipher_key; // Vòng 0: Nạp 256 bit khóa gốc
    end else if (rkey_en) begin
          // Dịch trái 128 bit: Vứt 128 bit cũ nhất đi, nạp 128 bit mới sinh vào
          key_reg <= {key_recent, key_new};
    end
  end

  // Đầu ra luôn lấy từ 128-bit mới sinh (trừ vòng đầu lấy Word 4-7 của khóa gốc)
  assign round_key_out = (round_num == 4'd0) ? cipher_key[127:0] : key_recent;

  // INTERNAL FUNCTION FOR RCON
  // Bảng Rcon cho AES-256 (Cứ 2 vòng mã hóa xài chung 1 Rcon)
  function logic [31:0] aes256_rcon;
      input [3:0] round_idx;
      logic [2:0] rcon_index;
      rcon_index = (round_idx + 1) / 2; 

      case (rcon_index)
          3'd1: aes256_rcon = 32'h0100_0000;
          3'd2: aes256_rcon = 32'h0200_0000;
          3'd3: aes256_rcon = 32'h0400_0000;
          3'd4: aes256_rcon = 32'h0800_0000;
          3'd5: aes256_rcon = 32'h1000_0000;
          3'd6: aes256_rcon = 32'h2000_0000;
          3'd7: aes256_rcon = 32'h4000_0000;
          default: aes256_rcon = 32'h0000_0000;
      endcase
  endfunction

endmodule
/*****************************************************

MODULE TOP: AES S-BOX (COMPOSITE FIELD - POLYNOMIAL BASIS)

Dựa trên S-Box #152 (Canright 2005)

Kiến trúc này khớp 100% với sơ đồ Cơ sở Đa thức:

GF(2^8) -> GF(2^4) dùng Polynomial Basis

GF(2^4) -> GF(2^2) dùng Polynomial Basis

GF(2^2) -> GF(2)   dùng Polynomial Basis
*****************************************************/
//POLYNOMIAL BASIS
module aes_sbox (
input  wire [7:0] in_byte,
output wire [7:0] out_byte
);

wire [7:0] g_in, g_out;
wire [3:0] t1, t2, t3, t4, t5, t6, t7;

// ===================================================================
// BƯỚC 1: ÁNH XẠ ĐẲNG CẤU (GF(2^8) -> GF(((2^2)^2)^2))
// ===================================================================
assign g_in[7] = in_byte[7] ^ in_byte[5];
assign g_in[6] = in_byte[6] ^ in_byte[5] ^ in_byte[4] ^ in_byte[3] ^ in_byte[2] ^ in_byte[1];
assign g_in[5] = in_byte[7] ^ in_byte[6] ^ in_byte[4] ^ in_byte[1];
assign g_in[4] = in_byte[7] ^ in_byte[6] ^ in_byte[4] ^ in_byte[3] ^ in_byte[2];
assign g_in[3] = in_byte[4] ^ in_byte[2];
assign g_in[2] = in_byte[7] ^ in_byte[2];
assign g_in[1] = in_byte[2] ^ in_byte[1];
assign g_in[0] = in_byte[7] ^ in_byte[6] ^ in_byte[5] ^ in_byte[4] ^ in_byte[1] ^ in_byte[0];

// ===================================================================
// BƯỚC 2: TÌM NGHỊCH ĐẢO 4-BIT (KHỚP 100% SƠ ĐỒ POLYNOMIAL)
// ===================================================================

// t1 = (Cao ^ Thấp)
assign t1 = g_in[7:4] ^ g_in[3:0];

// t2 = (Cao ^ Thấp) * Thấp
GF_2_4_MUL_Nw_PolyPoly u_mul_1 (.q(t2), .a(t1), .b(g_in[3:0]));

// t3 = Cao^2 * C
GF_2_4_SQR_SCL_N_N2_Nw_PolyPoly u_sqr_scl (.q(t3), .a(g_in[7:4]));

// t4 = Định thức D
assign t4 = t2 ^ t3;

// t5 = Nghịch đảo của Định thức D
GF_2_4_INV_Nw_PolyPoly u_inv (.q(t5), .a(t4));

// Cao mới = Inv(D) * Cao cũ
GF_2_4_MUL_Nw_PolyPoly u_mul_2 (.q(t6), .a(t5), .b(g_in[7:4]));

// Thấp mới = Inv(D) * (Cao cũ ^ Thấp cũ)
GF_2_4_MUL_Nw_PolyPoly u_mul_3 (.q(t7), .a(t5), .b(t1));

// Ghép lại thành 8-bit trong không gian hỗn hợp
assign g_out = {t6, t7};

// ===================================================================
// BƯỚC 3: ÁNH XẠ NGƯỢC + BIẾN ĐỔI AFFINE
// ===================================================================
assign out_byte[7] = g_out[7] ^ g_out[4] ^ g_out[2];
assign out_byte[6] = ~( g_out[7] ^ g_out[4] );
assign out_byte[5] = ~( g_out[7] ^ g_out[5] ^ g_out[4] ^ g_out[3] ^ g_out[2] );
assign out_byte[4] = g_out[7] ^ g_out[4] ^ g_out[3] ^ g_out[2] ^ g_out[0];
assign out_byte[3] = g_out[7] ^ g_out[4] ^ g_out[0];
assign out_byte[2] = g_out[6] ^ g_out[4] ^ g_out[3] ^ g_out[2] ^ g_out[1] ^ g_out[0];
assign out_byte[1] = ~( g_out[7] ^ g_out[6] ^ g_out[4] ^ g_out[3] ^ g_out[1] ^ g_out[0] );
assign out_byte[0] = ~( g_out[7] ^ g_out[6] ^ g_out[4] ^ g_out[0] );


endmodule

/***********************************************************************

MODULES 4-BIT (TẦNG GIỮA)
***********************************************************************/

// Bộ nhân 4-bit (Polynomial Basis)
module GF_2_4_MUL_Nw_PolyPoly (q, a, b);
input   [3:0]   a, b;
output  [3:0]   q;
wire    [1:0]   t0, t1, t2, t3;

GF_2_2_MUL_Poly  u_mul_0 (.q(t0), .a(a[1:0]), .b(b[1:0]));
GF_2_2_MUL_Poly  u_mul_1 (.q(t1), .a(a[3:2]), .b(b[3:2]));
GF_2_2_MUL_Poly  u_mul_2 (.q(t2), .a(a[3:2] ^ a[1:0]), .b(b[3:2] ^ b[1:0]));
GF_2_2_SCLw_Poly u_scl   (.q(t3), .a(t1));

assign q = {(t2 ^ t0), (t3 ^ t0)};


endmodule

// Bộ nghịch đảo 4-bit (Polynomial Basis)
module GF_2_4_INV_Nw_PolyPoly (q, a);
input   [3:0]   a;
output  [3:0]   q;
wire    [1:0]   t, t0, t1, t2, q1, q0;

assign t = a[3:2] ^ a[1:0];
GF_2_2_MUL_Poly      u_mul_0   (.q(t0), .a(t), .b(a[1:0]));
GF_2_2_SQR_SCLw_Poly u_sqr_scl (.q(t1), .a(a[3:2]));
GF_2_2_INV_Poly      u_inv     (.q(t2), .a(t0 ^ t1));
GF_2_2_MUL_Poly      u_mul_1   (.q(q1), .a(t2), .b(a[3:2]));
GF_2_2_MUL_Poly      u_mul_2   (.q(q0), .a(t2), .b(t));

assign q = {q1, q0};


endmodule

// Bộ Bình phương & Nhân hằng số C cho 4-bit (Polynomial Basis)
module GF_2_4_SQR_SCL_N_N2_Nw_PolyPoly (q, a);
input   [3:0]   a;
output  [3:0]   q;
wire    [1:0]   t00, t01, t10, t11;

GF_2_2_SQR_SCLw_Poly  u_sqr_scl_10 (.q(t10), .a(a[1:0]));
GF_2_2_SQR_SCLw2_Poly u_sqr_scl_00 (.q(t00), .a(a[1:0]));
GF_2_2_SQR_SCLw_Poly  u_sqr_scl_11 (.q(t11), .a(a[3:2]));

assign t01 = t11;
assign q = {(t10 ^ t11), (t00 ^ t01)};


endmodule

/***********************************************************************

MODULES 2-BIT (TẦNG ĐÁY) - CƠ SỞ ĐA THỨC (Polynomial Basis)
***********************************************************************/

// Bộ nhân 2-bit
module GF_2_2_MUL_Poly (q, a, b);
input   [1:0]   a, b;
output  [1:0]   q;
wire    t;

assign t = a[0] & b[0];
assign q[1] = t ^ ((a[1] ^ a[0]) & (b[1] ^ b[0]));
assign q[0] = t ^ (a[1] & b[1]);


endmodule

// Bộ nghịch đảo 2-bit
module GF_2_2_INV_Poly (q, a);
input   [1:0]   a;
output  [1:0]   q;

assign q[1] = a[1];
assign q[0] = a[1] ^ a[0];


endmodule

// Bộ nhân hằng số W cho 2-bit
module GF_2_2_SCLw_Poly (q, a);
input   [1:0]   a;
output  [1:0]   q;

assign q[1] = a[1] ^ a[0];
assign q[0] = a[1];


endmodule

// Bộ bình phương & nhân hằng số W cho 2-bit
module GF_2_2_SQR_SCLw_Poly (q, a);
input   [1:0]   a;
output  [1:0]   q;

assign q[1] = a[0];
assign q[0] = a[1];


endmodule

// Bộ bình phương & nhân hằng số W^2 cho 2-bit
module GF_2_2_SQR_SCLw2_Poly (q, a);
input   [1:0]   a;
output  [1:0]   q;

assign q[1] = a[1] ^ a[0];
assign q[0] = a[0];


endmodule