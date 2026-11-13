`timescale 1ns/1ps

// CROC OBI register controller with an EXTERNAL AES-256 core interface.
// This module belongs to STATIC logic. The AES core itself belongs to the RP.
// Keep the existing aes256_obi.sv unchanged until the new path is integrated.
module aes256_obi_external
  import croc_pkg::*;
#(
  parameter logic [31:0] BaseAddr = 32'h2000_1000
) (
  input  logic         clk_i,
  input  logic         rst_ni,
  input  sbr_obi_req_t obi_req_i,
  output sbr_obi_rsp_t obi_rsp_o,

  // Hold from the KV260 static DFX control (synchronous to clk_i).
  // 1: the RP must not receive a new START; DONE is discarded.
  input  logic         rm_hold_i,

  // Static controller -> external AES reconfigurable partition.
  output logic [255:0] cipher_key_o,
  output logic [127:0] plain_text_o,
  output logic         cipher_en_o,

  // External AES reconfigurable partition -> static controller.
  input  logic [127:0] cipher_text_i,
  input  logic         cipher_ready_i
);

  localparam logic [11:0] COMMAND    = 12'h000;
  localparam logic [11:0] STATUS     = 12'h004;
  localparam logic [11:0] RM_CONTROL = 12'h008;

  localparam logic [11:0] KEY0 = 12'h010;
  localparam logic [11:0] KEY1 = 12'h014;
  localparam logic [11:0] KEY2 = 12'h018;
  localparam logic [11:0] KEY3 = 12'h01C;
  localparam logic [11:0] KEY4 = 12'h020;
  localparam logic [11:0] KEY5 = 12'h024;
  localparam logic [11:0] KEY6 = 12'h028;
  localparam logic [11:0] KEY7 = 12'h02C;

  localparam logic [11:0] PT0 = 12'h030;
  localparam logic [11:0] PT1 = 12'h034;
  localparam logic [11:0] PT2 = 12'h038;
  localparam logic [11:0] PT3 = 12'h03C;

  localparam logic [11:0] CT0 = 12'h040;
  localparam logic [11:0] CT1 = 12'h044;
  localparam logic [11:0] CT2 = 12'h048;
  localparam logic [11:0] CT3 = 12'h04C;

  typedef enum logic [1:0] {
    StIdle,
    StGrant,
    StResponse
  } state_t;

  state_t state_q;
  sbr_obi_a_chan_t req_q;
  logic [31:0] rdata_q;
  logic        err_q;

  logic [255:0] cipher_key_q;
  logic [127:0] plain_text_q;
  logic [127:0] cipher_text_q;

  logic busy_q;
  logic done_q;
  logic seen_busy_q;

  assign cipher_key_o = cipher_key_q;
  assign plain_text_o = plain_text_q;

  function automatic logic [31:0] merge_be(
    input logic [31:0] old_data,
    input logic [31:0] new_data,
    input logic [3:0]  be
  );
    logic [31:0] result;
    result = old_data;
    for (int i = 0; i < 4; i++) begin
      if (be[i]) result[i*8 +: 8] = new_data[i*8 +: 8];
    end
    return result;
  endfunction

  function automatic logic [31:0] reg_read(input logic [11:0] offset);
    case (offset)
      // READY=0 during RP hold even if the controller isn't busy.
      STATUS: reg_read = {30'b0, (~busy_q & ~rm_hold_i), done_q};
      // Status bit 0 mirrors the hold controlled by KV260 PS/Linux.
      // This is a read-only indication, not a partial-reconfig command.
      RM_CONTROL: reg_read = {31'b0, rm_hold_i};
      KEY0: reg_read = cipher_key_q[31:0];
      KEY1: reg_read = cipher_key_q[63:32];
      KEY2: reg_read = cipher_key_q[95:64];
      KEY3: reg_read = cipher_key_q[127:96];
      KEY4: reg_read = cipher_key_q[159:128];
      KEY5: reg_read = cipher_key_q[191:160];
      KEY6: reg_read = cipher_key_q[223:192];
      KEY7: reg_read = cipher_key_q[255:224];
      PT0:  reg_read = plain_text_q[31:0];
      PT1:  reg_read = plain_text_q[63:32];
      PT2:  reg_read = plain_text_q[95:64];
      PT3:  reg_read = plain_text_q[127:96];
      CT0:  reg_read = cipher_text_q[31:0];
      CT1:  reg_read = cipher_text_q[63:32];
      CT2:  reg_read = cipher_text_q[95:64];
      CT3:  reg_read = cipher_text_q[127:96];
      default: reg_read = 32'h0;
    endcase
  endfunction

  always_comb begin
    obi_rsp_o = '0;
    if (state_q == StGrant) begin
      obi_rsp_o.gnt = 1'b1;
    end
    if (state_q == StResponse) begin
      obi_rsp_o.rvalid       = 1'b1;
      obi_rsp_o.r.rdata      = rdata_q;
      obi_rsp_o.r.rid        = req_q.aid;
      obi_rsp_o.r.err        = err_q;
      obi_rsp_o.r.r_optional = '0;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q       <= StIdle;
      req_q         <= '0;
      rdata_q       <= '0;
      err_q         <= 1'b0;
      cipher_key_q  <= '0;
      plain_text_q  <= '0;
      cipher_text_q <= '0;
      cipher_en_o   <= 1'b0;
      busy_q        <= 1'b0;
      done_q        <= 1'b0;
      seen_busy_q   <= 1'b0;
    end else begin
      cipher_en_o <= 1'b0;

      // Do not sample an RM undergoing partial reconfiguration.
      if (rm_hold_i) begin
        busy_q      <= 1'b0;
        done_q      <= 1'b0;
        seen_busy_q <= 1'b0;
      end else if (busy_q) begin
        // Existing ready -> busy -> ready handshake (preserved).
        if (!cipher_ready_i) begin
          seen_busy_q <= 1'b1;
        end else if (seen_busy_q) begin
          cipher_text_q <= cipher_text_i;
          busy_q        <= 1'b0;
          done_q        <= 1'b1;
          seen_busy_q   <= 1'b0;
        end
      end

      case (state_q)
        StIdle: begin
          if (obi_req_i.req) begin
            req_q   <= obi_req_i.a;
            state_q <= StGrant;
          end
        end

        StGrant: begin
          err_q   <= (req_q.addr[31:12] != BaseAddr[31:12]);
          rdata_q <= 32'h0;

          if (req_q.addr[31:12] == BaseAddr[31:12]) begin
            if (req_q.we) begin
              case (req_q.addr[11:0])
                COMMAND: begin
                  if (req_q.be[0] && req_q.wdata[0] && !busy_q && !rm_hold_i) begin
                    cipher_en_o <= 1'b1;
                    busy_q      <= 1'b1;
                    done_q      <= 1'b0;
                    seen_busy_q <= 1'b0;
                  end
                end
                KEY0: cipher_key_q[31:0]    <= merge_be(cipher_key_q[31:0],    req_q.wdata, req_q.be);
                KEY1: cipher_key_q[63:32]   <= merge_be(cipher_key_q[63:32],   req_q.wdata, req_q.be);
                KEY2: cipher_key_q[95:64]   <= merge_be(cipher_key_q[95:64],   req_q.wdata, req_q.be);
                KEY3: cipher_key_q[127:96]  <= merge_be(cipher_key_q[127:96],  req_q.wdata, req_q.be);
                KEY4: cipher_key_q[159:128] <= merge_be(cipher_key_q[159:128], req_q.wdata, req_q.be);
                KEY5: cipher_key_q[191:160] <= merge_be(cipher_key_q[191:160], req_q.wdata, req_q.be);
                KEY6: cipher_key_q[223:192] <= merge_be(cipher_key_q[223:192], req_q.wdata, req_q.be);
                KEY7: cipher_key_q[255:224] <= merge_be(cipher_key_q[255:224], req_q.wdata, req_q.be);
                PT0:  plain_text_q[31:0]    <= merge_be(plain_text_q[31:0],    req_q.wdata, req_q.be);
                PT1:  plain_text_q[63:32]   <= merge_be(plain_text_q[63:32],   req_q.wdata, req_q.be);
                PT2:  plain_text_q[95:64]   <= merge_be(plain_text_q[95:64],   req_q.wdata, req_q.be);
                PT3:  plain_text_q[127:96]  <= merge_be(plain_text_q[127:96],  req_q.wdata, req_q.be);
                default: ;
              endcase
            end else begin
              rdata_q <= reg_read(req_q.addr[11:0]);
            end
          end

          state_q <= StResponse;
        end

        StResponse: begin
          state_q <= StIdle;
        end

        default: state_q <= StIdle;
      endcase
    end
  end
endmodule
