module aes_sbox_lut_rom (
  input  wire [7:0] addr,
  output wire [7:0] dout
);

  // Match the Vivado ROM_STYLE inference template: force this ROM into LUT fabric.
  (* rom_style = "distributed" *) reg [7:0] sbox_rom [0:255];

  initial begin
    sbox_rom[8'h00] = 8'h63;
    sbox_rom[8'h01] = 8'h7C;
    sbox_rom[8'h02] = 8'h77;
    sbox_rom[8'h03] = 8'h7B;
    sbox_rom[8'h04] = 8'hF2;
    sbox_rom[8'h05] = 8'h6B;
    sbox_rom[8'h06] = 8'h6F;
    sbox_rom[8'h07] = 8'hC5;
    sbox_rom[8'h08] = 8'h30;
    sbox_rom[8'h09] = 8'h01;
    sbox_rom[8'h0A] = 8'h67;
    sbox_rom[8'h0B] = 8'h2B;
    sbox_rom[8'h0C] = 8'hFE;
    sbox_rom[8'h0D] = 8'hD7;
    sbox_rom[8'h0E] = 8'hAB;
    sbox_rom[8'h0F] = 8'h76;
    sbox_rom[8'h10] = 8'hCA;
    sbox_rom[8'h11] = 8'h82;
    sbox_rom[8'h12] = 8'hC9;
    sbox_rom[8'h13] = 8'h7D;
    sbox_rom[8'h14] = 8'hFA;
    sbox_rom[8'h15] = 8'h59;
    sbox_rom[8'h16] = 8'h47;
    sbox_rom[8'h17] = 8'hF0;
    sbox_rom[8'h18] = 8'hAD;
    sbox_rom[8'h19] = 8'hD4;
    sbox_rom[8'h1A] = 8'hA2;
    sbox_rom[8'h1B] = 8'hAF;
    sbox_rom[8'h1C] = 8'h9C;
    sbox_rom[8'h1D] = 8'hA4;
    sbox_rom[8'h1E] = 8'h72;
    sbox_rom[8'h1F] = 8'hC0;
    sbox_rom[8'h20] = 8'hB7;
    sbox_rom[8'h21] = 8'hFD;
    sbox_rom[8'h22] = 8'h93;
    sbox_rom[8'h23] = 8'h26;
    sbox_rom[8'h24] = 8'h36;
    sbox_rom[8'h25] = 8'h3F;
    sbox_rom[8'h26] = 8'hF7;
    sbox_rom[8'h27] = 8'hCC;
    sbox_rom[8'h28] = 8'h34;
    sbox_rom[8'h29] = 8'hA5;
    sbox_rom[8'h2A] = 8'hE5;
    sbox_rom[8'h2B] = 8'hF1;
    sbox_rom[8'h2C] = 8'h71;
    sbox_rom[8'h2D] = 8'hD8;
    sbox_rom[8'h2E] = 8'h31;
    sbox_rom[8'h2F] = 8'h15;
    sbox_rom[8'h30] = 8'h04;
    sbox_rom[8'h31] = 8'hC7;
    sbox_rom[8'h32] = 8'h23;
    sbox_rom[8'h33] = 8'hC3;
    sbox_rom[8'h34] = 8'h18;
    sbox_rom[8'h35] = 8'h96;
    sbox_rom[8'h36] = 8'h05;
    sbox_rom[8'h37] = 8'h9A;
    sbox_rom[8'h38] = 8'h07;
    sbox_rom[8'h39] = 8'h12;
    sbox_rom[8'h3A] = 8'h80;
    sbox_rom[8'h3B] = 8'hE2;
    sbox_rom[8'h3C] = 8'hEB;
    sbox_rom[8'h3D] = 8'h27;
    sbox_rom[8'h3E] = 8'hB2;
    sbox_rom[8'h3F] = 8'h75;
    sbox_rom[8'h40] = 8'h09;
    sbox_rom[8'h41] = 8'h83;
    sbox_rom[8'h42] = 8'h2C;
    sbox_rom[8'h43] = 8'h1A;
    sbox_rom[8'h44] = 8'h1B;
    sbox_rom[8'h45] = 8'h6E;
    sbox_rom[8'h46] = 8'h5A;
    sbox_rom[8'h47] = 8'hA0;
    sbox_rom[8'h48] = 8'h52;
    sbox_rom[8'h49] = 8'h3B;
    sbox_rom[8'h4A] = 8'hD6;
    sbox_rom[8'h4B] = 8'hB3;
    sbox_rom[8'h4C] = 8'h29;
    sbox_rom[8'h4D] = 8'hE3;
    sbox_rom[8'h4E] = 8'h2F;
    sbox_rom[8'h4F] = 8'h84;
    sbox_rom[8'h50] = 8'h53;
    sbox_rom[8'h51] = 8'hD1;
    sbox_rom[8'h52] = 8'h00;
    sbox_rom[8'h53] = 8'hED;
    sbox_rom[8'h54] = 8'h20;
    sbox_rom[8'h55] = 8'hFC;
    sbox_rom[8'h56] = 8'hB1;
    sbox_rom[8'h57] = 8'h5B;
    sbox_rom[8'h58] = 8'h6A;
    sbox_rom[8'h59] = 8'hCB;
    sbox_rom[8'h5A] = 8'hBE;
    sbox_rom[8'h5B] = 8'h39;
    sbox_rom[8'h5C] = 8'h4A;
    sbox_rom[8'h5D] = 8'h4C;
    sbox_rom[8'h5E] = 8'h58;
    sbox_rom[8'h5F] = 8'hCF;
    sbox_rom[8'h60] = 8'hD0;
    sbox_rom[8'h61] = 8'hEF;
    sbox_rom[8'h62] = 8'hAA;
    sbox_rom[8'h63] = 8'hFB;
    sbox_rom[8'h64] = 8'h43;
    sbox_rom[8'h65] = 8'h4D;
    sbox_rom[8'h66] = 8'h33;
    sbox_rom[8'h67] = 8'h85;
    sbox_rom[8'h68] = 8'h45;
    sbox_rom[8'h69] = 8'hF9;
    sbox_rom[8'h6A] = 8'h02;
    sbox_rom[8'h6B] = 8'h7F;
    sbox_rom[8'h6C] = 8'h50;
    sbox_rom[8'h6D] = 8'h3C;
    sbox_rom[8'h6E] = 8'h9F;
    sbox_rom[8'h6F] = 8'hA8;
    sbox_rom[8'h70] = 8'h51;
    sbox_rom[8'h71] = 8'hA3;
    sbox_rom[8'h72] = 8'h40;
    sbox_rom[8'h73] = 8'h8F;
    sbox_rom[8'h74] = 8'h92;
    sbox_rom[8'h75] = 8'h9D;
    sbox_rom[8'h76] = 8'h38;
    sbox_rom[8'h77] = 8'hF5;
    sbox_rom[8'h78] = 8'hBC;
    sbox_rom[8'h79] = 8'hB6;
    sbox_rom[8'h7A] = 8'hDA;
    sbox_rom[8'h7B] = 8'h21;
    sbox_rom[8'h7C] = 8'h10;
    sbox_rom[8'h7D] = 8'hFF;
    sbox_rom[8'h7E] = 8'hF3;
    sbox_rom[8'h7F] = 8'hD2;
    sbox_rom[8'h80] = 8'hCD;
    sbox_rom[8'h81] = 8'h0C;
    sbox_rom[8'h82] = 8'h13;
    sbox_rom[8'h83] = 8'hEC;
    sbox_rom[8'h84] = 8'h5F;
    sbox_rom[8'h85] = 8'h97;
    sbox_rom[8'h86] = 8'h44;
    sbox_rom[8'h87] = 8'h17;
    sbox_rom[8'h88] = 8'hC4;
    sbox_rom[8'h89] = 8'hA7;
    sbox_rom[8'h8A] = 8'h7E;
    sbox_rom[8'h8B] = 8'h3D;
    sbox_rom[8'h8C] = 8'h64;
    sbox_rom[8'h8D] = 8'h5D;
    sbox_rom[8'h8E] = 8'h19;
    sbox_rom[8'h8F] = 8'h73;
    sbox_rom[8'h90] = 8'h60;
    sbox_rom[8'h91] = 8'h81;
    sbox_rom[8'h92] = 8'h4F;
    sbox_rom[8'h93] = 8'hDC;
    sbox_rom[8'h94] = 8'h22;
    sbox_rom[8'h95] = 8'h2A;
    sbox_rom[8'h96] = 8'h90;
    sbox_rom[8'h97] = 8'h88;
    sbox_rom[8'h98] = 8'h46;
    sbox_rom[8'h99] = 8'hEE;
    sbox_rom[8'h9A] = 8'hB8;
    sbox_rom[8'h9B] = 8'h14;
    sbox_rom[8'h9C] = 8'hDE;
    sbox_rom[8'h9D] = 8'h5E;
    sbox_rom[8'h9E] = 8'h0B;
    sbox_rom[8'h9F] = 8'hDB;
    sbox_rom[8'hA0] = 8'hE0;
    sbox_rom[8'hA1] = 8'h32;
    sbox_rom[8'hA2] = 8'h3A;
    sbox_rom[8'hA3] = 8'h0A;
    sbox_rom[8'hA4] = 8'h49;
    sbox_rom[8'hA5] = 8'h06;
    sbox_rom[8'hA6] = 8'h24;
    sbox_rom[8'hA7] = 8'h5C;
    sbox_rom[8'hA8] = 8'hC2;
    sbox_rom[8'hA9] = 8'hD3;
    sbox_rom[8'hAA] = 8'hAC;
    sbox_rom[8'hAB] = 8'h62;
    sbox_rom[8'hAC] = 8'h91;
    sbox_rom[8'hAD] = 8'h95;
    sbox_rom[8'hAE] = 8'hE4;
    sbox_rom[8'hAF] = 8'h79;
    sbox_rom[8'hB0] = 8'hE7;
    sbox_rom[8'hB1] = 8'hC8;
    sbox_rom[8'hB2] = 8'h37;
    sbox_rom[8'hB3] = 8'h6D;
    sbox_rom[8'hB4] = 8'h8D;
    sbox_rom[8'hB5] = 8'hD5;
    sbox_rom[8'hB6] = 8'h4E;
    sbox_rom[8'hB7] = 8'hA9;
    sbox_rom[8'hB8] = 8'h6C;
    sbox_rom[8'hB9] = 8'h56;
    sbox_rom[8'hBA] = 8'hF4;
    sbox_rom[8'hBB] = 8'hEA;
    sbox_rom[8'hBC] = 8'h65;
    sbox_rom[8'hBD] = 8'h7A;
    sbox_rom[8'hBE] = 8'hAE;
    sbox_rom[8'hBF] = 8'h08;
    sbox_rom[8'hC0] = 8'hBA;
    sbox_rom[8'hC1] = 8'h78;
    sbox_rom[8'hC2] = 8'h25;
    sbox_rom[8'hC3] = 8'h2E;
    sbox_rom[8'hC4] = 8'h1C;
    sbox_rom[8'hC5] = 8'hA6;
    sbox_rom[8'hC6] = 8'hB4;
    sbox_rom[8'hC7] = 8'hC6;
    sbox_rom[8'hC8] = 8'hE8;
    sbox_rom[8'hC9] = 8'hDD;
    sbox_rom[8'hCA] = 8'h74;
    sbox_rom[8'hCB] = 8'h1F;
    sbox_rom[8'hCC] = 8'h4B;
    sbox_rom[8'hCD] = 8'hBD;
    sbox_rom[8'hCE] = 8'h8B;
    sbox_rom[8'hCF] = 8'h8A;
    sbox_rom[8'hD0] = 8'h70;
    sbox_rom[8'hD1] = 8'h3E;
    sbox_rom[8'hD2] = 8'hB5;
    sbox_rom[8'hD3] = 8'h66;
    sbox_rom[8'hD4] = 8'h48;
    sbox_rom[8'hD5] = 8'h03;
    sbox_rom[8'hD6] = 8'hF6;
    sbox_rom[8'hD7] = 8'h0E;
    sbox_rom[8'hD8] = 8'h61;
    sbox_rom[8'hD9] = 8'h35;
    sbox_rom[8'hDA] = 8'h57;
    sbox_rom[8'hDB] = 8'hB9;
    sbox_rom[8'hDC] = 8'h86;
    sbox_rom[8'hDD] = 8'hC1;
    sbox_rom[8'hDE] = 8'h1D;
    sbox_rom[8'hDF] = 8'h9E;
    sbox_rom[8'hE0] = 8'hE1;
    sbox_rom[8'hE1] = 8'hF8;
    sbox_rom[8'hE2] = 8'h98;
    sbox_rom[8'hE3] = 8'h11;
    sbox_rom[8'hE4] = 8'h69;
    sbox_rom[8'hE5] = 8'hD9;
    sbox_rom[8'hE6] = 8'h8E;
    sbox_rom[8'hE7] = 8'h94;
    sbox_rom[8'hE8] = 8'h9B;
    sbox_rom[8'hE9] = 8'h1E;
    sbox_rom[8'hEA] = 8'h87;
    sbox_rom[8'hEB] = 8'hE9;
    sbox_rom[8'hEC] = 8'hCE;
    sbox_rom[8'hED] = 8'h55;
    sbox_rom[8'hEE] = 8'h28;
    sbox_rom[8'hEF] = 8'hDF;
    sbox_rom[8'hF0] = 8'h8C;
    sbox_rom[8'hF1] = 8'hA1;
    sbox_rom[8'hF2] = 8'h89;
    sbox_rom[8'hF3] = 8'h0D;
    sbox_rom[8'hF4] = 8'hBF;
    sbox_rom[8'hF5] = 8'hE6;
    sbox_rom[8'hF6] = 8'h42;
    sbox_rom[8'hF7] = 8'h68;
    sbox_rom[8'hF8] = 8'h41;
    sbox_rom[8'hF9] = 8'h99;
    sbox_rom[8'hFA] = 8'h2D;
    sbox_rom[8'hFB] = 8'h0F;
    sbox_rom[8'hFC] = 8'hB0;
    sbox_rom[8'hFD] = 8'h54;
    sbox_rom[8'hFE] = 8'hBB;
    sbox_rom[8'hFF] = 8'h16;
  end

  assign dout = sbox_rom[addr];

endmodule

//===================================================================
// MODULE 1: AES-256 TOP WRAPPER
//===================================================================
module aes256_lut (
  input  logic clk_sys,
  input  logic rst_n,
  input  logic [255:0] cipher_key,
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

  // SubBytes S-box: 16 parallel distributed-LUT ROM instances
  genvar sbox_i;
  generate
    for (sbox_i = 0; sbox_i < 16; sbox_i = sbox_i + 1) begin : gen_state_sbox
      aes_sbox_lut_rom u_sbox (
        .addr (subbytes_sel[127-(sbox_i*8) -: 8]),
        .dout (after_subBytes[127-(sbox_i*8) -: 8])
      );
    end
  endgenerate

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
  
  // KHÁC BIỆT LỚN NHẤT: Cần thanh ghi 256-bit để nhớ 8 Word quá khứ
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

  // ==================================================
  // TRẠM BIẾN HÓA WORD (Chỉ hoạt động ở Word thứ 4 và 8)
  // ==================================================
  
  // 1. RotWord: Chỉ xoay byte ở vòng lẻ (i % 8 == 0)
  // Nếu vòng chẵn (i % 8 == 4), giữ nguyên vị trí byte
  assign after_rotW = is_even_round ? w_in : {w_in[23:0], w_in[31:24]};

  // 2. SubWord: 4 parallel distributed-LUT ROM instances
  genvar key_sbox_i;
  generate
    for (key_sbox_i = 0; key_sbox_i < 4; key_sbox_i = key_sbox_i + 1) begin : gen_key_sbox
      aes_sbox_lut_rom u_sbox (
        .addr (after_rotW[31-(key_sbox_i*8) -: 8]),
        .dout (after_subW[31-(key_sbox_i*8) -: 8])
      );
    end
  endgenerate

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
  assign round_key_out = key_recent;
endmodule

//===================================================================
// INTERNAL FUNCTIONS FOR AES MATH & RCON
//===================================================================

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
  mixcol[15:8]  = mixcol_in[31:24]       ^ mixcol_in[23:16]       ^ mul2(mixcol_in[15:8]) ^ mul3(mixcol_in[7:0]);
  mixcol[7:0]   = mul3(mixcol_in[31:24]) ^ mixcol_in[23:16]       ^ mixcol_in[15:8]       ^ mul2(mixcol_in[7:0]);
endfunction

// KHÁC BIỆT: Bảng Rcon cho AES-256 (Cứ 2 vòng mã hóa xài chung 1 Rcon)
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