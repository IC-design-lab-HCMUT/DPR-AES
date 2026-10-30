module aes_sbox_bram (
    input  logic       clk,
    input  logic [7:0] addr,
    output logic [7:0] q
);
    (* ramstyle = "M10K" *) logic [7:0] rom [0:255];

    initial begin
        rom[8'h00] = 8'h63;
        rom[8'h01] = 8'h7c;
        rom[8'h02] = 8'h77;
        rom[8'h03] = 8'h7b;
        rom[8'h04] = 8'hf2;
        rom[8'h05] = 8'h6b;
        rom[8'h06] = 8'h6f;
        rom[8'h07] = 8'hc5;
        rom[8'h08] = 8'h30;
        rom[8'h09] = 8'h01;
        rom[8'h0a] = 8'h67;
        rom[8'h0b] = 8'h2b;
        rom[8'h0c] = 8'hfe;
        rom[8'h0d] = 8'hd7;
        rom[8'h0e] = 8'hab;
        rom[8'h0f] = 8'h76;
        rom[8'h10] = 8'hca;
        rom[8'h11] = 8'h82;
        rom[8'h12] = 8'hc9;
        rom[8'h13] = 8'h7d;
        rom[8'h14] = 8'hfa;
        rom[8'h15] = 8'h59;
        rom[8'h16] = 8'h47;
        rom[8'h17] = 8'hf0;
        rom[8'h18] = 8'had;
        rom[8'h19] = 8'hd4;
        rom[8'h1a] = 8'ha2;
        rom[8'h1b] = 8'haf;
        rom[8'h1c] = 8'h9c;
        rom[8'h1d] = 8'ha4;
        rom[8'h1e] = 8'h72;
        rom[8'h1f] = 8'hc0;
        rom[8'h20] = 8'hb7;
        rom[8'h21] = 8'hfd;
        rom[8'h22] = 8'h93;
        rom[8'h23] = 8'h26;
        rom[8'h24] = 8'h36;
        rom[8'h25] = 8'h3f;
        rom[8'h26] = 8'hf7;
        rom[8'h27] = 8'hcc;
        rom[8'h28] = 8'h34;
        rom[8'h29] = 8'ha5;
        rom[8'h2a] = 8'he5;
        rom[8'h2b] = 8'hf1;
        rom[8'h2c] = 8'h71;
        rom[8'h2d] = 8'hd8;
        rom[8'h2e] = 8'h31;
        rom[8'h2f] = 8'h15;
        rom[8'h30] = 8'h04;
        rom[8'h31] = 8'hc7;
        rom[8'h32] = 8'h23;
        rom[8'h33] = 8'hc3;
        rom[8'h34] = 8'h18;
        rom[8'h35] = 8'h96;
        rom[8'h36] = 8'h05;
        rom[8'h37] = 8'h9a;
        rom[8'h38] = 8'h07;
        rom[8'h39] = 8'h12;
        rom[8'h3a] = 8'h80;
        rom[8'h3b] = 8'he2;
        rom[8'h3c] = 8'heb;
        rom[8'h3d] = 8'h27;
        rom[8'h3e] = 8'hb2;
        rom[8'h3f] = 8'h75;
        rom[8'h40] = 8'h09;
        rom[8'h41] = 8'h83;
        rom[8'h42] = 8'h2c;
        rom[8'h43] = 8'h1a;
        rom[8'h44] = 8'h1b;
        rom[8'h45] = 8'h6e;
        rom[8'h46] = 8'h5a;
        rom[8'h47] = 8'ha0;
        rom[8'h48] = 8'h52;
        rom[8'h49] = 8'h3b;
        rom[8'h4a] = 8'hd6;
        rom[8'h4b] = 8'hb3;
        rom[8'h4c] = 8'h29;
        rom[8'h4d] = 8'he3;
        rom[8'h4e] = 8'h2f;
        rom[8'h4f] = 8'h84;
        rom[8'h50] = 8'h53;
        rom[8'h51] = 8'hd1;
        rom[8'h52] = 8'h00;
        rom[8'h53] = 8'hed;
        rom[8'h54] = 8'h20;
        rom[8'h55] = 8'hfc;
        rom[8'h56] = 8'hb1;
        rom[8'h57] = 8'h5b;
        rom[8'h58] = 8'h6a;
        rom[8'h59] = 8'hcb;
        rom[8'h5a] = 8'hbe;
        rom[8'h5b] = 8'h39;
        rom[8'h5c] = 8'h4a;
        rom[8'h5d] = 8'h4c;
        rom[8'h5e] = 8'h58;
        rom[8'h5f] = 8'hcf;
        rom[8'h60] = 8'hd0;
        rom[8'h61] = 8'hef;
        rom[8'h62] = 8'haa;
        rom[8'h63] = 8'hfb;
        rom[8'h64] = 8'h43;
        rom[8'h65] = 8'h4d;
        rom[8'h66] = 8'h33;
        rom[8'h67] = 8'h85;
        rom[8'h68] = 8'h45;
        rom[8'h69] = 8'hf9;
        rom[8'h6a] = 8'h02;
        rom[8'h6b] = 8'h7f;
        rom[8'h6c] = 8'h50;
        rom[8'h6d] = 8'h3c;
        rom[8'h6e] = 8'h9f;
        rom[8'h6f] = 8'ha8;
        rom[8'h70] = 8'h51;
        rom[8'h71] = 8'ha3;
        rom[8'h72] = 8'h40;
        rom[8'h73] = 8'h8f;
        rom[8'h74] = 8'h92;
        rom[8'h75] = 8'h9d;
        rom[8'h76] = 8'h38;
        rom[8'h77] = 8'hf5;
        rom[8'h78] = 8'hbc;
        rom[8'h79] = 8'hb6;
        rom[8'h7a] = 8'hda;
        rom[8'h7b] = 8'h21;
        rom[8'h7c] = 8'h10;
        rom[8'h7d] = 8'hff;
        rom[8'h7e] = 8'hf3;
        rom[8'h7f] = 8'hd2;
        rom[8'h80] = 8'hcd;
        rom[8'h81] = 8'h0c;
        rom[8'h82] = 8'h13;
        rom[8'h83] = 8'hec;
        rom[8'h84] = 8'h5f;
        rom[8'h85] = 8'h97;
        rom[8'h86] = 8'h44;
        rom[8'h87] = 8'h17;
        rom[8'h88] = 8'hc4;
        rom[8'h89] = 8'ha7;
        rom[8'h8a] = 8'h7e;
        rom[8'h8b] = 8'h3d;
        rom[8'h8c] = 8'h64;
        rom[8'h8d] = 8'h5d;
        rom[8'h8e] = 8'h19;
        rom[8'h8f] = 8'h73;
        rom[8'h90] = 8'h60;
        rom[8'h91] = 8'h81;
        rom[8'h92] = 8'h4f;
        rom[8'h93] = 8'hdc;
        rom[8'h94] = 8'h22;
        rom[8'h95] = 8'h2a;
        rom[8'h96] = 8'h90;
        rom[8'h97] = 8'h88;
        rom[8'h98] = 8'h46;
        rom[8'h99] = 8'hee;
        rom[8'h9a] = 8'hb8;
        rom[8'h9b] = 8'h14;
        rom[8'h9c] = 8'hde;
        rom[8'h9d] = 8'h5e;
        rom[8'h9e] = 8'h0b;
        rom[8'h9f] = 8'hdb;
        rom[8'ha0] = 8'he0;
        rom[8'ha1] = 8'h32;
        rom[8'ha2] = 8'h3a;
        rom[8'ha3] = 8'h0a;
        rom[8'ha4] = 8'h49;
        rom[8'ha5] = 8'h06;
        rom[8'ha6] = 8'h24;
        rom[8'ha7] = 8'h5c;
        rom[8'ha8] = 8'hc2;
        rom[8'ha9] = 8'hd3;
        rom[8'haa] = 8'hac;
        rom[8'hab] = 8'h62;
        rom[8'hac] = 8'h91;
        rom[8'had] = 8'h95;
        rom[8'hae] = 8'he4;
        rom[8'haf] = 8'h79;
        rom[8'hb0] = 8'he7;
        rom[8'hb1] = 8'hc8;
        rom[8'hb2] = 8'h37;
        rom[8'hb3] = 8'h6d;
        rom[8'hb4] = 8'h8d;
        rom[8'hb5] = 8'hd5;
        rom[8'hb6] = 8'h4e;
        rom[8'hb7] = 8'ha9;
        rom[8'hb8] = 8'h6c;
        rom[8'hb9] = 8'h56;
        rom[8'hba] = 8'hf4;
        rom[8'hbb] = 8'hea;
        rom[8'hbc] = 8'h65;
        rom[8'hbd] = 8'h7a;
        rom[8'hbe] = 8'hae;
        rom[8'hbf] = 8'h08;
        rom[8'hc0] = 8'hba;
        rom[8'hc1] = 8'h78;
        rom[8'hc2] = 8'h25;
        rom[8'hc3] = 8'h2e;
        rom[8'hc4] = 8'h1c;
        rom[8'hc5] = 8'ha6;
        rom[8'hc6] = 8'hb4;
        rom[8'hc7] = 8'hc6;
        rom[8'hc8] = 8'he8;
        rom[8'hc9] = 8'hdd;
        rom[8'hca] = 8'h74;
        rom[8'hcb] = 8'h1f;
        rom[8'hcc] = 8'h4b;
        rom[8'hcd] = 8'hbd;
        rom[8'hce] = 8'h8b;
        rom[8'hcf] = 8'h8a;
        rom[8'hd0] = 8'h70;
        rom[8'hd1] = 8'h3e;
        rom[8'hd2] = 8'hb5;
        rom[8'hd3] = 8'h66;
        rom[8'hd4] = 8'h48;
        rom[8'hd5] = 8'h03;
        rom[8'hd6] = 8'hf6;
        rom[8'hd7] = 8'h0e;
        rom[8'hd8] = 8'h61;
        rom[8'hd9] = 8'h35;
        rom[8'hda] = 8'h57;
        rom[8'hdb] = 8'hb9;
        rom[8'hdc] = 8'h86;
        rom[8'hdd] = 8'hc1;
        rom[8'hde] = 8'h1d;
        rom[8'hdf] = 8'h9e;
        rom[8'he0] = 8'he1;
        rom[8'he1] = 8'hf8;
        rom[8'he2] = 8'h98;
        rom[8'he3] = 8'h11;
        rom[8'he4] = 8'h69;
        rom[8'he5] = 8'hd9;
        rom[8'he6] = 8'h8e;
        rom[8'he7] = 8'h94;
        rom[8'he8] = 8'h9b;
        rom[8'he9] = 8'h1e;
        rom[8'hea] = 8'h87;
        rom[8'heb] = 8'he9;
        rom[8'hec] = 8'hce;
        rom[8'hed] = 8'h55;
        rom[8'hee] = 8'h28;
        rom[8'hef] = 8'hdf;
        rom[8'hf0] = 8'h8c;
        rom[8'hf1] = 8'ha1;
        rom[8'hf2] = 8'h89;
        rom[8'hf3] = 8'h0d;
        rom[8'hf4] = 8'hbf;
        rom[8'hf5] = 8'he6;
        rom[8'hf6] = 8'h42;
        rom[8'hf7] = 8'h68;
        rom[8'hf8] = 8'h41;
        rom[8'hf9] = 8'h99;
        rom[8'hfa] = 8'h2d;
        rom[8'hfb] = 8'h0f;
        rom[8'hfc] = 8'hb0;
        rom[8'hfd] = 8'h54;
        rom[8'hfe] = 8'hbb;
        rom[8'hff] = 8'h16;
    end

    // Synchronous read: q becomes valid after the rising edge.
    always @(posedge clk) begin
        q <= rom[addr];
    end
endmodule

//====================================================================
// AES-256 BRAM TOP
//====================================================================
module aes256_bram (
    input  logic         clk_sys,
    input  logic         rst_n,
    input  logic [255:0] cipher_key,
    input  logic [127:0] plain_text,
    input  logic         cipher_en,

    output logic [127:0] cipher_text,
    output logic         cipher_ready
);

    localparam logic [1:0] ST_IDLE         = 2'd0;
    localparam logic [1:0] ST_SB_READ      = 2'd1;
    localparam logic [1:0] ST_ROUND_UPDATE = 2'd2;

    logic [1:0]   state_fsm;
    logic [3:0]   round_counter;
    logic [127:0] state_reg;
    logic [255:0] key_window;

    logic [127:0] state_sbox_q;
    logic [127:0] shifted_state;
    logic [127:0] mixed_state;
    logic [127:0] round_data;
    logic [127:0] round_result;

    logic [127:0] key_old;
    logic [127:0] key_recent;
    logic [127:0] key_new;
    logic [31:0]  key_last_word;
    logic [31:0]  key_sub_addr_word;
    logic [31:0]  key_sbox_q;
    logic [31:0]  key_transform;
    logic         odd_key_round;

    assign cipher_text = state_reg;

    // ---------------------------------------------------------------
    // 16 parallel synchronous S-box lookups for the AES state.
    // 128-bit state = sixteen 8-bit bytes.
    // ---------------------------------------------------------------
    genvar state_byte;
    generate
        for (state_byte = 0; state_byte < 16; state_byte = state_byte + 1) begin : GEN_STATE_SBOX
            aes_sbox_bram u_state_sbox (
                .clk  (clk_sys),
                .addr (state_reg[127-(state_byte*8) -: 8]),
                .q    (state_sbox_q[127-(state_byte*8) -: 8])
            );
        end
    endgenerate

    // ---------------------------------------------------------------
    // AES-256 key-window organization:
    //   key_old    = four older words
    //   key_recent = round key used by the current AES round
    // ---------------------------------------------------------------
    assign key_old       = key_window[255:128];
    assign key_recent    = key_window[127:0];
    assign key_last_word = key_recent[31:0];
    assign odd_key_round = round_counter[0];

    // Odd AES-256 key-generation steps use RotWord + SubWord + Rcon.
    // Even steps use only SubWord.
    assign key_sub_addr_word = odd_key_round
                             ? {key_last_word[23:0], key_last_word[31:24]}
                             : key_last_word;

    genvar key_byte;
    generate
        for (key_byte = 0; key_byte < 4; key_byte = key_byte + 1) begin : GEN_KEY_SBOX
            aes_sbox_bram u_key_sbox (
                .clk  (clk_sys),
                .addr (key_sub_addr_word[31-(key_byte*8) -: 8]),
                .q    (key_sbox_q[31-(key_byte*8) -: 8])
            );
        end
    endgenerate

    assign key_transform = key_sbox_q ^
                           (odd_key_round ? aes256_rcon(round_counter)
                                          : 32'h0000_0000);

    // Cascade XOR that generates the next four AES-256 key words.
    assign key_new[127:96] = key_old[127:96] ^ key_transform;
    assign key_new[95:64]  = key_old[95:64]  ^ key_new[127:96];
    assign key_new[63:32]  = key_old[63:32]  ^ key_new[95:64];
    assign key_new[31:0]   = key_old[31:0]   ^ key_new[63:32];

    // ---------------------------------------------------------------
    // ShiftRows. The vector uses standard AES column-major byte order:
    // byte 0 = [127:120], byte 15 = [7:0].
    // ---------------------------------------------------------------
    always @(*) begin
        shifted_state[127:120] = state_sbox_q[127:120]; //  0 <-  0
        shifted_state[119:112] = state_sbox_q[87:80];   //  1 <-  5
        shifted_state[111:104] = state_sbox_q[47:40];   //  2 <- 10
        shifted_state[103:96]  = state_sbox_q[7:0];     //  3 <- 15

        shifted_state[95:88]   = state_sbox_q[95:88];   //  4 <-  4
        shifted_state[87:80]   = state_sbox_q[55:48];   //  5 <-  9
        shifted_state[79:72]   = state_sbox_q[15:8];    //  6 <- 14
        shifted_state[71:64]   = state_sbox_q[103:96];  //  7 <-  3

        shifted_state[63:56]   = state_sbox_q[63:56];   //  8 <-  8
        shifted_state[55:48]   = state_sbox_q[23:16];   //  9 <- 13
        shifted_state[47:40]   = state_sbox_q[111:104]; // 10 <-  2
        shifted_state[39:32]   = state_sbox_q[71:64];   // 11 <-  7

        shifted_state[31:24]   = state_sbox_q[31:24];   // 12 <- 12
        shifted_state[23:16]   = state_sbox_q[119:112]; // 13 <-  1
        shifted_state[15:8]    = state_sbox_q[79:72];   // 14 <-  6
        shifted_state[7:0]     = state_sbox_q[39:32];   // 15 <- 11
    end

    // Four columns are transformed in parallel.
    assign mixed_state[127:96] = mixcol(shifted_state[127:96]);
    assign mixed_state[95:64]  = mixcol(shifted_state[95:64]);
    assign mixed_state[63:32]  = mixcol(shifted_state[63:32]);
    assign mixed_state[31:0]   = mixcol(shifted_state[31:0]);

    // Final AES round bypasses MixColumns.
    assign round_data   = (round_counter == 4'd14)
                        ? shifted_state
                        : mixed_state;
    assign round_result = round_data ^ key_recent;

    // ---------------------------------------------------------------
    // Controller
    // ---------------------------------------------------------------
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            state_fsm     <= ST_IDLE;
            round_counter <= 4'd0;
            state_reg     <= 128'd0;
            key_window    <= 256'd0;
            cipher_ready  <= 1'b1;
        end else begin
            case (state_fsm)
                ST_IDLE: begin
                    cipher_ready <= 1'b1;

                    if (cipher_en) begin
                        // Initial AddRoundKey uses W0-W3.
                        state_reg     <= plain_text ^ cipher_key[255:128];
                        key_window    <= cipher_key;
                        round_counter <= 4'd1;
                        cipher_ready  <= 1'b0;
                        state_fsm     <= ST_SB_READ;
                    end
                end

                ST_SB_READ: begin
                    // During this phase the 20 synchronous ROM outputs
                    // capture the 16 state bytes and 4 key-schedule bytes.
                    // Data is consumed in ST_ROUND_UPDATE.
                    state_fsm <= ST_ROUND_UPDATE;
                end

                ST_ROUND_UPDATE: begin
                    state_reg <= round_result;

                    if (round_counter == 4'd14) begin
                        // state_reg receives the final ciphertext on this edge.
                        cipher_ready <= 1'b1;
                        state_fsm    <= ST_IDLE;
                    end else begin
                        // Shift the key window only once per completed round.
                        // key_recent is used by the current round; key_new is
                        // prepared for the next round.
                        key_window    <= {key_recent, key_new};
                        round_counter <= round_counter + 4'd1;
                        state_fsm     <= ST_SB_READ;
                    end
                end

                default: begin
                    state_fsm    <= ST_IDLE;
                    cipher_ready <= 1'b1;
                end
            endcase
        end
    end

    // ---------------------------------------------------------------
    // AES arithmetic helpers
    // ---------------------------------------------------------------
    function automatic logic [7:0] mul2;
        input logic [7:0] value;
        begin
            mul2 = value[7] ? {value[6:0], 1'b0} ^ 8'h1b
                            : {value[6:0], 1'b0};
        end
    endfunction

    function automatic logic [7:0] mul3;
        input logic [7:0] value;
        begin
            mul3 = mul2(value) ^ value;
        end
    endfunction

    function automatic logic [31:0] mixcol;
        input logic [31:0] column;
        logic [7:0] a0, a1, a2, a3;
        begin
            a0 = column[31:24];
            a1 = column[23:16];
            a2 = column[15:8];
            a3 = column[7:0];

            mixcol[31:24] = mul2(a0) ^ mul3(a1) ^ a2       ^ a3;
            mixcol[23:16] = a0       ^ mul2(a1) ^ mul3(a2) ^ a3;
            mixcol[15:8]  = a0       ^ a1       ^ mul2(a2) ^ mul3(a3);
            mixcol[7:0]   = mul3(a0) ^ a1       ^ a2       ^ mul2(a3);
        end
    endfunction

    function automatic logic [31:0] aes256_rcon;
        input logic [3:0] round_idx;
        begin
            case ((round_idx + 4'd1) >> 1)
                4'd1: aes256_rcon = 32'h0100_0000;
                4'd2: aes256_rcon = 32'h0200_0000;
                4'd3: aes256_rcon = 32'h0400_0000;
                4'd4: aes256_rcon = 32'h0800_0000;
                4'd5: aes256_rcon = 32'h1000_0000;
                4'd6: aes256_rcon = 32'h2000_0000;
                4'd7: aes256_rcon = 32'h4000_0000;
                default: aes256_rcon = 32'h0000_0000;
            endcase
        end
    endfunction

endmodule
