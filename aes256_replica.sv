`timescale 1ns/1ps

module aes256_replica (
    input  logic         clk_sys,
    input  logic         rst_n,

    input  logic [255:0] cipher_key,
    input  logic [127:0] plain_text,
    input  logic         cipher_en,

    input  logic [1:0]   rm_select,

    output logic [127:0] cipher_text,
    output logic         cipher_ready
);

    logic [127:0] lut_cipher;
    logic [127:0] bram_cipher;
    logic [127:0] composite_cipher;
    logic [127:0] noise_cipher;

    logic lut_ready;
    logic bram_ready;
    logic composite_ready;
    logic noise_ready;

    logic lut_en;
    logic bram_en;
    logic composite_en;
    logic noise_en;


    /* Only selected replica receives START */

    assign lut_en =
        cipher_en && (rm_select == 2'b00);

    assign bram_en =
        cipher_en && (rm_select == 2'b01);

    assign composite_en =
        cipher_en && (rm_select == 2'b10);

    assign noise_en =
        cipher_en && (rm_select == 2'b11);


    /* ========================================================
       LUT
       ======================================================== */

   aes256_lut u_lut (
    .clk_sys      (clk_sys),
    .rst_n        (rst_n),
    .cipher_key   (cipher_key),
    .plain_text   (plain_text),
    .cipher_en    (lut_en),
    .cipher_text  (lut_cipher),
    .cipher_ready (lut_ready)
);


    /* ========================================================
       BRAM
       ======================================================== */

   aes256_bram u_bram (
    .clk_sys      (clk_sys),
    .rst_n        (rst_n),
    .cipher_key   (cipher_key),
    .plain_text   (plain_text),
    .cipher_en    (bram_en),
    .cipher_text  (bram_cipher),
    .cipher_ready (bram_ready)
);

    /* ========================================================
       COMPOSITE
       ======================================================== */

   aes256_composite u_composite (
    .clk_sys      (clk_sys),
    .rst_n        (rst_n),
    .cipher_key   (cipher_key),
    .plain_text   (plain_text),
    .cipher_en    (composite_en),
    .cipher_text  (composite_cipher),
    .cipher_ready (composite_ready)
);


    /* ========================================================
       NOISE
       ======================================================== */

    dummy_noise u_noise (
    .clk_sys      (clk_sys),
    .rst_n        (rst_n),
    .cipher_key   (cipher_key),
    .plain_text   (plain_text),
    .cipher_en    (noise_en),
    .cipher_text  (noise_cipher),
    .cipher_ready (noise_ready)
);

    /* ========================================================
       Output selector
       ======================================================== */

    always_comb begin

        cipher_text  = 128'b0;
        cipher_ready = 1'b0;

        case (rm_select)

            2'b00: begin
                cipher_text  = lut_cipher;
                cipher_ready = lut_ready;
            end

            2'b01: begin
                cipher_text  = bram_cipher;
                cipher_ready = bram_ready;
            end

            2'b10: begin
                cipher_text  = composite_cipher;
                cipher_ready = composite_ready;
            end

            2'b11: begin
                cipher_text  = noise_cipher;
                cipher_ready = noise_ready;
            end
        default: begin
                cipher_text  = 128'b0;
                cipher_ready = 1'b0;
            end
        endcase
    end

endmodule