`timescale 1ns / 1ps

// CROC external AES + KV260 DFX RP: stage 2, synthesis/debug checkpoint.
// Requires CROC_FPGA_AUTOBOOT, AES-256 firmware in XPM SRAM .mem files.
// The CROC UART TX is retained as a MARK_DEBUG net, but is NOT routed to Linux.
// No ILA is inserted yet; run synthesis then add an ILA entirely in STATIC.
// NOT a production-ready or validated DFX bitstream.
module top_dfx_aes256;
  localparam bit USE_CROC_AES = 1'b1;

  logic clk, rst_n, app_rst_n;

  // FPGA RTC reference for CROC CLINT.
  // PL0 is ~100 MHz; generate a ~32.765 kHz square wave in the PL0 domain.
  // This is a DATA-level reference sampled by CLINT, not a second clock tree.
  localparam int unsigned RtcHalfPeriodCycles = 1174;
  logic [$clog2(RtcHalfPeriodCycles)-1:0] rtc_div_ctr;
  logic rtc_ref;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rtc_div_ctr <= '0;
      rtc_ref     <= 1'b0;
    end else if (rtc_div_ctr == RtcHalfPeriodCycles-1) begin
      rtc_div_ctr <= '0;
      rtc_ref     <= ~rtc_ref;
    end else begin
      rtc_div_ctr <= rtc_div_ctr + 1'b1;
    end
  end
  (* mark_debug = "true" *) logic rm_hold;
  logic [0:0] pl_resetn_bus, rm_hold_bus;

  // Original PS AXI-Lite AES interface and RP controls.
  logic [255:0] axi_key;
  logic [127:0] axi_plain, axi_cipher;
  logic axi_start, axi_ready;

  // New static CROC AES interface.
  logic [255:0] croc_key;
  logic [127:0] croc_plain;
  (* mark_debug = "true" *) logic croc_start;
  (* mark_debug = "true" *) logic croc_status;
  (* mark_debug = "true" *) logic croc_uart_tx;

  // Existing reconfigurable module's signals (unchanged ports/instance).
  logic [255:0] rm_key;
  logic [127:0] rm_plain, rm_cipher;
  logic rm_start;
  (* mark_debug = "true" *) logic rm_ready;

  kv260_ps_wrapper u_kv260_ps (
    .pl_clk0_o   (clk),
    .pl_resetn_o (pl_resetn_bus),
    .aes_key_o   (axi_key),
    .aes_plain_o (axi_plain),
    .aes_start_o (axi_start),
    .aes_cipher_i(axi_cipher),
    .aes_ready_i (axi_ready),
    .rm_hold_o   (rm_hold_bus)
  );

  assign rst_n   = pl_resetn_bus[0];
  assign rm_hold = rm_hold_bus[0];

  // Static-to-RP isolation, preserving the original DFX boundary.
  assign app_rst_n = rst_n & ~rm_hold;
  assign rm_key   = rm_hold ? '0 : (USE_CROC_AES ? croc_key   : axi_key);
  assign rm_plain = rm_hold ? '0 : (USE_CROC_AES ? croc_plain : axi_plain);
  assign rm_start = rm_hold ? 1'b0 : (USE_CROC_AES ? croc_start : axi_start);

  // Passive STATIC observer of completed CROC -> AES transactions.
  // The RP's ready may already be high while idle. Do NOT feed it
  // directly to the AXI capture input, or the AXI DONE flag could
  // become set without any actual CROC encryption.
  typedef enum logic [1:0] {
    ObsIdle, ObsWaitNotReady, ObsWaitReady
  } observer_state_t;

  observer_state_t observer_state;
  logic [127:0] observed_croc_cipher;
  (* mark_debug = "true" *) logic observed_croc_pulse;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      observer_state       <= ObsIdle;
      observed_croc_cipher <= '0;
      observed_croc_pulse  <= 1'b0;
    end else begin
      // A one-cycle pulse is enough for the existing AXI slave to latch
      // observed_croc_cipher on the next S_AXI_ACLK rising edge.
      observed_croc_pulse <= 1'b0;

      if (rm_hold || !USE_CROC_AES) begin
        observer_state <= ObsIdle;
      end else begin
        unique case (observer_state)
          ObsIdle: begin
            if (croc_start) observer_state <= ObsWaitNotReady;
          end
          ObsWaitNotReady: begin
            if (!rm_ready) observer_state <= ObsWaitReady;
          end
          ObsWaitReady: begin
            if (rm_ready) begin
              observed_croc_cipher <= rm_cipher;
              observed_croc_pulse  <= 1'b1;
              observer_state       <= ObsIdle;
            end
          end
          default: observer_state <= ObsIdle;
        endcase
      end
    end
  end

  // Reuse existing AXI registers 0x04 (DONE) and 0x40..0x4C
  // (last ciphertext) for observation. The AXI START command remains
  // disconnected from AES while USE_CROC_AES=1.
  assign axi_cipher = rm_hold ? '0 :
                      (USE_CROC_AES ? observed_croc_cipher : rm_cipher);
  assign axi_ready  = rm_hold ? 1'b0 :
                      (USE_CROC_AES ? observed_croc_pulse : rm_ready);

  croc_soc #(
    .GpioCount    (16),
    .UseExternalAes(1'b1)
  ) u_croc_soc (
    .clk_i           (clk),
    .rst_ni          (rst_n),
    .ref_clk_i       (rtc_ref), // ~32.765 kHz reference sampled by CLINT
    .testmode_i      (1'b0),
    .status_o        (croc_status),

    // FPGA Auto Boot: firmware pre-initialized into XPM SRAM.
    // JTAG is disabled for this stage; software cannot be updated at runtime.
    .jtag_tck_i      (1'b0),
    .jtag_tdi_i      (1'b0),
    .jtag_tdo_o      (),
    .jtag_tms_i      (1'b1),
    .jtag_trst_ni    (1'b1),
    .uart_rx_i       (1'b1),
    .uart_tx_o       (croc_uart_tx), // Traced via STATIC ILA after synthesis.
    .gpio_i          (16'b0),
    .gpio_o          (),
    .gpio_out_en_o   (),

    .aes_rm_hold_i   (rm_hold),
    .aes_key_o       (croc_key),
    .aes_plain_o     (croc_plain),
    .aes_start_o     (croc_start),
    .aes_cipher_i    (rm_hold ? 128'b0 : rm_cipher),
    .aes_ready_i     (rm_hold ? 1'b0 : rm_ready)
  );

  // Keep exact RP instance path and module interface for existing DFX settings.
  aes256_rm_lut u_aes_rm (
    .clk_sys     (clk),
    .rst_n       (app_rst_n),
    .cipher_key  (rm_key),
    .plain_text  (rm_plain),
    .cipher_en   (rm_start),
    .cipher_text (rm_cipher),
    .cipher_ready(rm_ready)
  );
endmodule
