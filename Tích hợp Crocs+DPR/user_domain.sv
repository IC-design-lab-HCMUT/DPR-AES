// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>
//
// Local extension: optional external AES-256 interface for KV260 DFX.
// UseExternalAes=0: original internal AES LUT path (Verilator baseline).
// UseExternalAes=1: OBI regs in static region; AES core outside CROC.

module user_domain import user_pkg::*; import croc_pkg::*; #(
  parameter int unsigned GpioCount = 16,
  parameter int unsigned NumExternalIrqs = 4,
  parameter bit UseExternalAes = 1'b0
) (
  input  logic clk_i,
  input  logic ref_clk_i,
  input  logic rst_ni,
  input  logic testmode_i,

  input  sbr_obi_req_t user_sbr_obi_req_i,
  output sbr_obi_rsp_t user_sbr_obi_rsp_o,

  output mgr_obi_req_t user_mgr_obi_req_o,
  input  mgr_obi_rsp_t user_mgr_obi_rsp_i,

  input  logic [GpioCount-1:0] gpio_in_sync_i,
  output logic [NumExternalIrqs-1:0] interrupts_o,

  // AES connection to the static-to-RP boundary (active only when UseExternalAes=1).
  input  logic         aes_rm_hold_i,
  output logic [255:0] aes_key_o,
  output logic [127:0] aes_plain_o,
  output logic         aes_start_o,
  input  logic [127:0] aes_cipher_i,
  input  logic         aes_ready_i
);

  assign interrupts_o = '0;

  // No user OBI manager in this design.
  assign user_mgr_obi_req_o = '0;

  // Collection of requests and responses from the user subordinate demultiplexer.
  sbr_obi_req_t [NumDemuxSbr-1:0] all_user_sbr_obi_req;
  sbr_obi_rsp_t [NumDemuxSbr-1:0] all_user_sbr_obi_rsp;

  sbr_obi_req_t user_error_obi_req;
  sbr_obi_rsp_t user_error_obi_rsp;
  sbr_obi_req_t user_design_obi_req;
  sbr_obi_rsp_t user_design_obi_rsp;

  assign user_error_obi_req               = all_user_sbr_obi_req[UserError];
  assign all_user_sbr_obi_rsp[UserError]  = user_error_obi_rsp;
  assign user_design_obi_req              = all_user_sbr_obi_req[UserDesign];
  assign all_user_sbr_obi_rsp[UserDesign] = user_design_obi_rsp;

  logic [cf_math_pkg::idx_width(NumDemuxSbr)-1:0] user_idx;

  addr_decode #(
    .NoIndices ( NumDemuxSbr                    ),
    .NoRules   ( $size(UserAddrMap)             ),
    .addr_t    ( logic[SbrObiCfg.DataWidth-1:0] ),
    .rule_t    ( addr_map_rule_t                ),
    .Napot     ( 1'b0                           )
  ) i_addr_decode_periphs (
    .addr_i           ( user_sbr_obi_req_i.a.addr ),
    .addr_map_i       ( UserAddrMap               ),
    .idx_o            ( user_idx                  ),
    .dec_valid_o      (),
    .dec_error_o      (),
    .en_default_idx_i ( 1'b1      ),
    .default_idx_i    ( UserError )
  );

  obi_demux #(
    .ObiCfg      ( SbrObiCfg     ),
    .obi_req_t   ( sbr_obi_req_t ),
    .obi_rsp_t   ( sbr_obi_rsp_t ),
    .NumMgrPorts ( NumDemuxSbr   ),
    .NumMaxTrans ( 2             )
  ) i_obi_demux (
    .clk_i,
    .rst_ni,

    .sbr_port_select_i ( user_idx             ),
    .sbr_port_req_i    ( user_sbr_obi_req_i   ),
    .sbr_port_rsp_o    ( user_sbr_obi_rsp_o   ),

    .mgr_ports_req_o   ( all_user_sbr_obi_req ),
    .mgr_ports_rsp_i   ( all_user_sbr_obi_rsp )
  );

  // Select either the original internal AES path or the external DFX path.
  // The inactive generate branch is removed during elaboration/synthesis.
  if (UseExternalAes) begin : gen_aes_external
    aes256_obi_external #(
      .BaseAddr (32'h2000_1000)
    ) i_aes256_obi_external (
      .clk_i          (clk_i),
      .rst_ni         (rst_ni),
      .obi_req_i      (user_design_obi_req),
      .obi_rsp_o      (user_design_obi_rsp),
      .rm_hold_i      (aes_rm_hold_i),
      .cipher_key_o   (aes_key_o),
      .plain_text_o   (aes_plain_o),
      .cipher_en_o    (aes_start_o),
      .cipher_text_i  (aes_cipher_i),
      .cipher_ready_i (aes_ready_i)
    );
  end else begin : gen_aes_internal
    aes256_obi #(
      .BaseAddr (32'h2000_1000)
    ) i_aes256_obi (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .obi_req_i (user_design_obi_req),
      .obi_rsp_o (user_design_obi_rsp)
    );

    assign aes_key_o   = '0;
    assign aes_plain_o = '0;
    assign aes_start_o = 1'b0;
  end

  obi_err_sbr #(
    .ObiCfg      ( SbrObiCfg     ),
    .obi_req_t   ( sbr_obi_req_t ),
    .obi_rsp_t   ( sbr_obi_rsp_t ),
    .NumMaxTrans ( 1             ),
    .RspData     ( 32'hBADCAB1E  )
  ) i_user_err (
    .clk_i,
    .rst_ni,
    .testmode_i ( testmode_i         ),
    .obi_req_i  ( user_error_obi_req ),
    .obi_rsp_o  ( user_error_obi_rsp )
  );

endmodule

