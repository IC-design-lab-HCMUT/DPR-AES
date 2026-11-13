`timescale 1ns/1ps

module aes256_rm_dummy_noise (
    input  logic         clk_sys,
    input  logic         rst_n,
    input  logic [255:0] cipher_key,
    input  logic [127:0] plain_text,
    input  logic         cipher_en,

    output logic [127:0] cipher_text,
    output logic         cipher_ready
);

    dummy_noise u_core (
        .clk_sys      (clk_sys),
        .rst_n        (rst_n),
        .cipher_key   (cipher_key),
        .plain_text   (plain_text),
        .cipher_en    (cipher_en),
        .cipher_text  (cipher_text),
        .cipher_ready (cipher_ready)
    );

endmodule