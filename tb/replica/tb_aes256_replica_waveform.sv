`timescale 1ns/1ps

module tb_aes256_replica_waveform;

    localparam integer CLK_PERIOD_NS = 10;   // 100 MHz

    logic clk;
    logic rst_n;
    logic cipher_en;

    logic [1:0]   rm_select;
    logic [255:0] cipher_key;
    logic [127:0] plain_text;

    logic [127:0] cipher_text;
    logic         cipher_ready;

    logic [127:0] expected_cipher;

    integer error_count;


    // =========================================================
    // DUT: Replica architecture
    // =========================================================
    aes256_replica dut (
        .clk_sys      (clk),
        .rst_n        (rst_n),

        .cipher_key   (cipher_key),
        .plain_text   (plain_text),
        .cipher_en    (cipher_en),

        .rm_select    (rm_select),

        .cipher_text  (cipher_text),
        .cipher_ready (cipher_ready)
    );


    // =========================================================
    // 100 MHz clock
    // =========================================================
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS/2) clk = ~clk;
    end


    // =========================================================
    // Run one selected implementation
    //
    // 00 = LUT
    // 01 = BRAM
    // 10 = COMPOSITE
    // 11 = NOISE
    // =========================================================
    task automatic run_variant(
        input logic [1:0] select_value,
        input integer     variant_id
    );

        begin

            // Select implementation
            @(negedge clk);
            rm_select = select_value;

            // Give selector time to settle
            repeat (2) @(posedge clk);


            // Start pulse: exactly one clock cycle
            @(negedge clk);
            cipher_en = 1'b1;

            @(negedge clk);
            cipher_en = 1'b0;


            // Wait for selected implementation
            wait (cipher_ready === 1'b1);

            @(posedge clk);


            case (variant_id)

                0:
                    $display(
                        "[LUT]       CT = %032h",
                        cipher_text
                    );

                1:
                    $display(
                        "[BRAM]      CT = %032h",
                        cipher_text
                    );

                2:
                    $display(
                        "[COMPOSITE] CT = %032h",
                        cipher_text
                    );

                3:
                    $display(
                        "[NOISE]     CT = %032h",
                        cipher_text
                    );

            endcase


            if (cipher_text === expected_cipher) begin

                case (variant_id)
                    0: $display("[PASS] LUT");
                    1: $display("[PASS] BRAM");
                    2: $display("[PASS] COMPOSITE");
                    3: $display("[PASS] NOISE");
                endcase

            end
            else begin

                case (variant_id)
                    0: $display("[FAIL] LUT");
                    1: $display("[FAIL] BRAM");
                    2: $display("[FAIL] COMPOSITE");
                    3: $display("[FAIL] NOISE");
                endcase

                error_count = error_count + 1;

            end


            // Small visible gap between transactions
            repeat (5) @(posedge clk);

        end

    endtask


    // =========================================================
    // Main test
    // =========================================================
    initial begin

        rst_n       = 1'b0;
        cipher_en   = 1'b0;
        rm_select   = 2'b00;
        error_count = 0;

        cipher_key =
            256'h000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F;

        plain_text =
            128'h00112233445566778899AABBCCDDEEFF;

        expected_cipher =
            128'h8EA2B7CA516745BFEAFC49904B496089;


        $display("");
        $display("==================================================");
        $display(" AES-256 REPLICA RTL VERIFICATION");
        $display("==================================================");
        $display("KEY       = %064h", cipher_key);
        $display("PLAINTEXT = %032h", plain_text);
        $display("EXPECTED  = %032h", expected_cipher);
        $display("==================================================");


        // -----------------------------------------------------
        // Reset
        // -----------------------------------------------------
        repeat (5) @(posedge clk);

        @(negedge clk);
        rst_n = 1'b1;

        repeat (5) @(posedge clk);


        // -----------------------------------------------------
        // Test all four Replica selections
        // -----------------------------------------------------

        // 00 = LUT
        run_variant(2'b00, 0);

        // 01 = BRAM
        run_variant(2'b01, 1);

        // 10 = COMPOSITE
        run_variant(2'b10, 2);

        // 11 = NOISE
        run_variant(2'b11, 3);


        // -----------------------------------------------------
        // Summary
        // -----------------------------------------------------
        $display("");
        $display("==================================================");
        $display(" REPLICA VERIFICATION SUMMARY");
        $display("==================================================");

        if (error_count == 0) begin
            $display("Selected cores : 4");
            $display("Passed         : 4");
            $display("Failed         : 0");
            $display("OVERALL RESULT : PASS");
        end
        else begin
            $display("Failed         : %0d", error_count);
            $display("OVERALL RESULT : FAIL");
        end

        $display("==================================================");

        repeat (10) @(posedge clk);
        $finish;

    end


    // =========================================================
    // Timeout
    // =========================================================
    initial begin

        #1_000_000;

        $display("[FAIL] REPLICA SIMULATION TIMEOUT");
        $finish;

    end

endmodule