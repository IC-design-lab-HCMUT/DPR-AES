`timescale 1 ns / 1 ps

module aes256_axi_controller_slave_lite_v1_0_S00_AXI #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 7
)
(
    // =========================================================
    // AES-256 interface
    // =========================================================
    output wire [255:0] aes_key_o,
    output wire [127:0] aes_plain_o,
    output reg          aes_start_o,

    // Replica / DPR control
    output wire         rm_hold_o,
    output wire [1:0]   rm_select_o,

    input  wire [127:0] aes_cipher_i,
    input  wire         aes_ready_i,

    // =========================================================
    // AXI4-Lite Slave Interface
    // =========================================================
    input  wire                              S_AXI_ACLK,
    input  wire                              S_AXI_ARESETN,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     S_AXI_AWADDR,
    input  wire [2:0]                        S_AXI_AWPROT,
    input  wire                              S_AXI_AWVALID,
    output wire                              S_AXI_AWREADY,

    input  wire [C_S_AXI_DATA_WIDTH-1:0]     S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire                              S_AXI_WVALID,
    output wire                              S_AXI_WREADY,

    output wire [1:0]                        S_AXI_BRESP,
    output wire                              S_AXI_BVALID,
    input  wire                              S_AXI_BREADY,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     S_AXI_ARADDR,
    input  wire [2:0]                        S_AXI_ARPROT,
    input  wire                              S_AXI_ARVALID,
    output wire                              S_AXI_ARREADY,

    output wire [C_S_AXI_DATA_WIDTH-1:0]     S_AXI_RDATA,
    output wire [1:0]                        S_AXI_RRESP,
    output wire                              S_AXI_RVALID,
    input  wire                              S_AXI_RREADY
);

    // =========================================================
    // AXI internal signals
    // =========================================================

    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg                          axi_awready;
    reg                          axi_wready;
    reg [1:0]                    axi_bresp;
    reg                          axi_bvalid;

    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    reg                          axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    reg [1:0]                    axi_rresp;
    reg                          axi_rvalid;

    reg                          aw_en;

    // 32-bit AXI => byte offset = 2 bits
    localparam integer ADDR_LSB = 2;

    wire [4:0] wr_index;
    wire [4:0] rd_index;

    wire slv_reg_wren;
    wire slv_reg_rden;

    assign wr_index = axi_awaddr[6:2];
    assign rd_index = axi_araddr[6:2];


    // =========================================================
    // REGISTER MAP
    // =========================================================
    //
    // 0x00 : COMMAND
    //        bit[0] = START
    //
    // 0x04 : STATUS
    //        bit[0] = DONE latched
    //        bit[1] = AES_READY raw
    //
    // 0x08 : RM_CONTROL
    //        bit[0]   = RM_HOLD
    //        bit[2:1] = RM_SELECT
    //
    //        RM_SELECT:
    //
    //        00 = LUT
    //        01 = BRAM
    //        10 = COMPOSITE
    //        11 = NOISE
    //
    // 0x0C : RESERVED
    //
    // 0x10 - 0x2C : KEY
    // 0x30 - 0x3C : PLAINTEXT
    // 0x40 - 0x4C : CIPHERTEXT
    //
    // =========================================================


    // =========================================================
    // Internal registers
    // =========================================================

    reg [31:0] reg_rm_control;

    // AES key
    reg [31:0] reg_key0;
    reg [31:0] reg_key1;
    reg [31:0] reg_key2;
    reg [31:0] reg_key3;
    reg [31:0] reg_key4;
    reg [31:0] reg_key5;
    reg [31:0] reg_key6;
    reg [31:0] reg_key7;

    // Plaintext
    reg [31:0] reg_pt0;
    reg [31:0] reg_pt1;
    reg [31:0] reg_pt2;
    reg [31:0] reg_pt3;

    // AES result
    reg         done_latched;
    reg [127:0] cipher_latched;


    // =========================================================
    // AES output mapping
    // =========================================================

    assign aes_key_o = {
        reg_key7,
        reg_key6,
        reg_key5,
        reg_key4,
        reg_key3,
        reg_key2,
        reg_key1,
        reg_key0
    };


    assign aes_plain_o = {
        reg_pt3,
        reg_pt2,
        reg_pt1,
        reg_pt0
    };


    // =========================================================
    // RM CONTROL
    // =========================================================

    assign rm_hold_o   = reg_rm_control[0];

    // NEW:
    // 00 = LUT
    // 01 = BRAM
    // 10 = COMPOSITE
    // 11 = NOISE
    assign rm_select_o = reg_rm_control[2:1];


    // =========================================================
    // AXI output assignments
    // =========================================================

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;

    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;

    assign S_AXI_ARREADY = axi_arready;

    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;


    // =========================================================
    // AXI WRITE ADDRESS CHANNEL
    // =========================================================

    always @(posedge S_AXI_ACLK)
    begin

        if (!S_AXI_ARESETN)
        begin

            axi_awready <= 1'b0;
            axi_awaddr  <= {C_S_AXI_ADDR_WIDTH{1'b0}};
            aw_en       <= 1'b1;

        end

        else
        begin

            if (!axi_awready &&
                S_AXI_AWVALID &&
                S_AXI_WVALID &&
                aw_en)
            begin

                axi_awready <= 1'b1;
                axi_awaddr  <= S_AXI_AWADDR;
                aw_en       <= 1'b0;

            end

            else if (S_AXI_BREADY &&
                     axi_bvalid)
            begin

                aw_en       <= 1'b1;
                axi_awready <= 1'b0;

            end

            else
            begin

                axi_awready <= 1'b0;

            end
        end
    end


    // =========================================================
    // AXI WRITE DATA CHANNEL
    // =========================================================

    always @(posedge S_AXI_ACLK)
    begin

        if (!S_AXI_ARESETN)
        begin

            axi_wready <= 1'b0;

        end

        else
        begin

            if (!axi_wready &&
                S_AXI_WVALID &&
                S_AXI_AWVALID &&
                aw_en)
            begin

                axi_wready <= 1'b1;

            end

            else
            begin

                axi_wready <= 1'b0;

            end
        end
    end


    // =========================================================
    // Write transaction accepted
    // =========================================================

    assign slv_reg_wren =
        axi_wready   &&
        S_AXI_WVALID &&
        axi_awready  &&
        S_AXI_AWVALID;


    // =========================================================
    // AXI WRITE RESPONSE CHANNEL
    // =========================================================

    always @(posedge S_AXI_ACLK)
    begin

        if (!S_AXI_ARESETN)
        begin

            axi_bvalid <= 1'b0;
            axi_bresp  <= 2'b00;

        end

        else
        begin

            if (axi_awready &&
                S_AXI_AWVALID &&
                axi_wready &&
                S_AXI_WVALID &&
                !axi_bvalid)
            begin

                axi_bvalid <= 1'b1;

                // OKAY
                axi_bresp <= 2'b00;

            end

            else if (S_AXI_BREADY &&
                     axi_bvalid)
            begin

                axi_bvalid <= 1'b0;

            end
        end
    end


    // =========================================================
    // Apply AXI byte strobes
    // =========================================================

    function [31:0] apply_wstrb;

        input [31:0] old_data;
        input [31:0] new_data;
        input [3:0]  strb;

        integer i;

        begin

            apply_wstrb = old_data;

            for (i = 0;
                 i < 4;
                 i = i + 1)
            begin

                if (strb[i])
                begin

                    apply_wstrb[(i*8) +: 8] =
                        new_data[(i*8) +: 8];

                end
            end
        end

    endfunction


    // =========================================================
    // AES registers + START/DONE logic
    // =========================================================

    always @(posedge S_AXI_ACLK)
    begin

        if (!S_AXI_ARESETN)
        begin

            reg_rm_control <= 32'b0;

            reg_key0 <= 32'b0;
            reg_key1 <= 32'b0;
            reg_key2 <= 32'b0;
            reg_key3 <= 32'b0;
            reg_key4 <= 32'b0;
            reg_key5 <= 32'b0;
            reg_key6 <= 32'b0;
            reg_key7 <= 32'b0;

            reg_pt0 <= 32'b0;
            reg_pt1 <= 32'b0;
            reg_pt2 <= 32'b0;
            reg_pt3 <= 32'b0;

            aes_start_o <= 1'b0;

            done_latched    <= 1'b0;
            cipher_latched  <= 128'b0;

        end

        else
        begin

            // =================================================
            // START pulse default
            // =================================================

            aes_start_o <= 1'b0;


            // =================================================
            // AES completed
            // =================================================

            if (aes_ready_i)
            begin

                cipher_latched <= aes_cipher_i;
                done_latched   <= 1'b1;

            end


            // =================================================
            // AXI register write
            // =================================================

            if (slv_reg_wren)
            begin

                case (wr_index)

                    // =========================================
                    // 0x00 : COMMAND
                    // bit0 = START
                    // =========================================

                    5'h00:
                    begin

                        if (S_AXI_WSTRB[0] &&
                            S_AXI_WDATA[0])
                        begin

                            aes_start_o <= 1'b1;

                            // Clear previous DONE
                            done_latched <= 1'b0;

                        end
                    end


                    // =========================================
                    // 0x04 : STATUS
                    // Read only
                    // =========================================

                    5'h01:
                    begin
                        // Do nothing
                    end


                    // =========================================
                    // 0x08 : RM_CONTROL
                    //
                    // bit0   = RM_HOLD
                    // bit2:1 = RM_SELECT
                    // =========================================

                    5'h02:
                    begin

                        reg_rm_control <=
                            apply_wstrb(
                                reg_rm_control,
                                S_AXI_WDATA,
                                S_AXI_WSTRB
                            );

                    end


                    // =========================================
                    // 0x0C : RESERVED
                    // =========================================

                    5'h03:
                    begin
                        // Do nothing
                    end


                    // =========================================
                    // KEY
                    // =========================================

                    // 0x10
                    5'h04:
                    begin

                        reg_key0 <=
                            apply_wstrb(
                                reg_key0,
                                S_AXI_WDATA,
                                S_AXI_WSTRB
                            );

                    end


                    // 0x14
                    5'h05:
                    begin

                        reg_key1 <=
                            apply_wstrb(
                                reg_key1,
                                S_AXI_WDATA,
                                S_AXI_WSTRB
                            );

                    end


                    // 0x18
                    5'h06:
                    begin

                        reg_key2 <=
                            apply_wstrb(
                                reg_key2,
                                S_AXI_WDATA,
                                S_AXI_WSTRB
                            );

                    end


                    // 0x1C
                    5'h07:
                    begin

                        reg_key3 <=
                            apply_wstrb(
                                reg_key3,
                                S_AXI_WDATA,
                                S_AXI_WSTRB
                            );

                    end


                    // 0x20
                    5'h08:
                    begin

                        reg_key4 <=
                            apply_wstrb(
                                reg_key4,
                                S_AXI_WDATA,
                                S_AXI_WSTRB
                            );

                    end


                    // 0x24
                    5'h09:
                    begin

                        reg_key5 <=
                            apply_wstrb(
                                reg_key5,
                                S_AXI_WDATA,
                                S_AXI_WSTRB
                            );

                    end


                    // 0x28
                    5'h0A:
                    begin

                        reg_key6 <=
                            apply_wstrb(
                                reg_key6,
                                S_AXI_WDATA,
                                S_AXI_WSTRB
                            );

                    end


                    // 0x2C
                    5'h0B:
                    begin

                        reg_key7 <=
                            apply_wstrb(
                                reg_key7,
                                S_AXI_WDATA,
                                S_AXI_WSTRB
                            );

                    end


                    // =========================================
                    // PLAINTEXT
                    // =========================================

                    // 0x30
                    5'h0C:
                    begin

                        reg_pt0 <=
                            apply_wstrb(
                                reg_pt0,
                                S_AXI_WDATA,
                                S_AXI_WSTRB
                            );

                    end


                    // 0x34
                    5'h0D:
                    begin

                        reg_pt1 <=
                            apply_wstrb(
                                reg_pt1,
                                S_AXI_WDATA,
                                S_AXI_WSTRB
                            );

                    end


                    // 0x38
                    5'h0E:
                    begin

                        reg_pt2 <=
                            apply_wstrb(
                                reg_pt2,
                                S_AXI_WDATA,
                                S_AXI_WSTRB
                            );

                    end


                    // 0x3C
                    5'h0F:
                    begin

                        reg_pt3 <=
                            apply_wstrb(
                                reg_pt3,
                                S_AXI_WDATA,
                                S_AXI_WSTRB
                            );

                    end


                    // =========================================
                    // 0x40 - 0x4C : CIPHERTEXT
                    // Read only
                    // =========================================

                    5'h10:
                    begin
                    end

                    5'h11:
                    begin
                    end

                    5'h12:
                    begin
                    end

                    5'h13:
                    begin
                    end


                    default:
                    begin
                        // Reserved
                    end

                endcase
            end
        end
    end


    // =========================================================
    // AXI READ ADDRESS CHANNEL
    // =========================================================

    always @(posedge S_AXI_ACLK)
    begin

        if (!S_AXI_ARESETN)
        begin

            axi_arready <= 1'b0;
            axi_araddr  <=
                {C_S_AXI_ADDR_WIDTH{1'b0}};

        end

        else
        begin

            if (!axi_arready &&
                S_AXI_ARVALID)
            begin

                axi_arready <= 1'b1;
                axi_araddr  <= S_AXI_ARADDR;

            end

            else
            begin

                axi_arready <= 1'b0;

            end
        end
    end


    // =========================================================
    // Read enable
    // =========================================================

    assign slv_reg_rden =
        axi_arready   &&
        S_AXI_ARVALID &&
        !axi_rvalid;


    // =========================================================
    // AXI READ DATA CHANNEL
    // =========================================================

    always @(posedge S_AXI_ACLK)
    begin

        if (!S_AXI_ARESETN)
        begin

            axi_rvalid <= 1'b0;
            axi_rresp  <= 2'b00;

        end

        else
        begin

            if (slv_reg_rden)
            begin

                axi_rvalid <= 1'b1;

                // OKAY
                axi_rresp <= 2'b00;

            end

            else if (axi_rvalid &&
                     S_AXI_RREADY)
            begin

                axi_rvalid <= 1'b0;

            end
        end
    end


    // =========================================================
    // REGISTER READ MUX
    // =========================================================

    always @(*)
    begin

        axi_rdata = 32'b0;

        case (rd_index)

            // =============================================
            // 0x00 COMMAND
            // =============================================

            5'h00:
                axi_rdata = 32'b0;


            // =============================================
            // 0x04 STATUS
            //
            // bit0 = DONE
            // bit1 = AES_READY
            // =============================================

            5'h01:
                axi_rdata = {
                    30'b0,
                    aes_ready_i,
                    done_latched
                };


            // =============================================
            // 0x08 RM_CONTROL
            //
            // bit0   = HOLD
            // bit2:1 = SELECT
            // =============================================

            5'h02:
                axi_rdata = reg_rm_control;


            // =============================================
            // 0x0C RESERVED
            // =============================================

            5'h03:
                axi_rdata = 32'b0;


            // =============================================
            // KEY
            // =============================================

            5'h04:
                axi_rdata = reg_key0;

            5'h05:
                axi_rdata = reg_key1;

            5'h06:
                axi_rdata = reg_key2;

            5'h07:
                axi_rdata = reg_key3;

            5'h08:
                axi_rdata = reg_key4;

            5'h09:
                axi_rdata = reg_key5;

            5'h0A:
                axi_rdata = reg_key6;

            5'h0B:
                axi_rdata = reg_key7;


            // =============================================
            // PLAINTEXT
            // =============================================

            5'h0C:
                axi_rdata = reg_pt0;

            5'h0D:
                axi_rdata = reg_pt1;

            5'h0E:
                axi_rdata = reg_pt2;

            5'h0F:
                axi_rdata = reg_pt3;


            // =============================================
            // CIPHERTEXT
            // =============================================

            // 0x40
            5'h10:
                axi_rdata =
                    cipher_latched[31:0];

            // 0x44
            5'h11:
                axi_rdata =
                    cipher_latched[63:32];

            // 0x48
            5'h12:
                axi_rdata =
                    cipher_latched[95:64];

            // 0x4C
            5'h13:
                axi_rdata =
                    cipher_latched[127:96];


            default:
                axi_rdata = 32'b0;

        endcase
    end


endmodule