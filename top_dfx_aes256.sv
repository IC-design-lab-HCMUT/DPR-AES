`timescale 1ns / 1ps

module top_dfx_aes256;

    // =========================================================
    // Clock / reset / RM control from KV260 Block Design
    // =========================================================

    logic clk;
    logic rst_n;
    logic rm_hold;

    logic [0:0] pl_resetn_bus;
    logic [0:0] rm_hold_bus;


    // =========================================================
    // AXI controller side
    // =========================================================

    logic [255:0] axi_key;
    logic [127:0] axi_plain;
    logic         axi_start;

    logic [127:0] axi_cipher;
    logic         axi_ready;


    // =========================================================
    // Reconfigurable Module side
    // =========================================================

    logic [255:0] rm_key;
    logic [127:0] rm_plain;
    logic         rm_start;

    logic [127:0] rm_cipher;
    logic         rm_ready;

    logic         app_rst_n;


    // =========================================================
    // KV260 PS + AXI subsystem
    // =========================================================

    kv260_ps_wrapper u_kv260_ps (
        .pl_clk0_o     (clk),
        .pl_resetn_o   (pl_resetn_bus),

        .aes_key_o     (axi_key),
        .aes_plain_o   (axi_plain),
        .aes_start_o   (axi_start),

        .aes_cipher_i  (axi_cipher),
        .aes_ready_i   (axi_ready),

        .rm_hold_o     (rm_hold_bus)
    );


    assign rst_n   = pl_resetn_bus[0];
    assign rm_hold = rm_hold_bus[0];


    // =========================================================
    // RM reset / hold
    //
    // rm_hold = 1:
    //   - reset RM
    //   - isolate inputs to RM
    //   - isolate outputs from RM
    //
    // Static AXI logic remains active.
    // =========================================================

    assign app_rst_n = rst_n & ~rm_hold;


    // =========================================================
    // STATIC -> RP isolation
    // =========================================================

    assign rm_key =
        rm_hold ? 256'b0 : axi_key;

    assign rm_plain =
        rm_hold ? 128'b0 : axi_plain;

    assign rm_start =
        rm_hold ? 1'b0 : axi_start;


    // =========================================================
    // RP -> STATIC isolation
    // =========================================================

    assign axi_cipher =
        rm_hold ? 128'b0 : rm_cipher;

    assign axi_ready =
        rm_hold ? 1'b0 : rm_ready;


    // =========================================================
    // RECONFIGURABLE PARTITION
    //
    // IMPORTANT:
    // Keep instance name u_aes_rm unchanged.
    // This instance is associated with the DFX Partition
    // Definition / Pblock.
    // =========================================================

    aes256_rm_lut u_aes_rm (
        .clk_sys      (clk),
        .rst_n        (app_rst_n),

        .cipher_key   (rm_key),
        .plain_text   (rm_plain),
        .cipher_en    (rm_start),

        .cipher_text  (rm_cipher),
        .cipher_ready (rm_ready)
    );


endmodule