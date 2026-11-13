`timescale 1ns/1ps

module tb_aes256_bram_waveform;

    localparam integer CLK_PERIOD_NS = 10;   // 100 MHz

    logic clk;
    logic rst_n;
    logic cipher_en;

    logic [255:0] cipher_key;
    logic [127:0] plain_text;

    logic [127:0] cipher_text;
    logic         cipher_ready;

    logic [127:0] expected_cipher;

    integer cycle_count;


    // =========================================================
    // DUT: AES-256 BRAM variant
    // =========================================================
    aes256_bram dut (
        .clk_sys      (clk),
        .rst_n        (rst_n),
        .cipher_key   (cipher_key),
        .plain_text   (plain_text),
        .cipher_en    (cipher_en),
        .cipher_text  (cipher_text),
        .cipher_ready (cipher_ready)
    );


    // =========================================================
    // Clock: 100 MHz
    // =========================================================
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS/2) clk = ~clk;
    end


    // =========================================================
    // Main test
    // =========================================================
    initial begin

        rst_n       = 1'b0;
        cipher_en   = 1'b0;
        cycle_count = 0;

        cipher_key =
            256'h000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F;

        plain_text =
            128'h00112233445566778899AABBCCDDEEFF;

        expected_cipher =
            128'h8EA2B7CA516745BFEAFC49904B496089;


        $display("==================================================");
        $display(" AES-256 BRAM RTL VERIFICATION");
        $display("==================================================");
        $display("KEY       = %064h", cipher_key);
        $display("PLAINTEXT = %032h", plain_text);
        $display("EXPECTED  = %032h", expected_cipher);


        // -----------------------------------------------------
        // Reset
        // -----------------------------------------------------
        repeat (5) @(posedge clk);

        @(negedge clk);
        rst_n = 1'b1;

        repeat (3) @(posedge clk);


        // -----------------------------------------------------
        // Start pulse: one clock cycle
        // -----------------------------------------------------
        @(negedge clk);
        cipher_en = 1'b1;

        @(negedge clk);
        cipher_en = 1'b0;


        // -----------------------------------------------------
        // Wait for BRAM implementation to finish
        // -----------------------------------------------------
        while (cipher_ready !== 1'b1) begin

            @(posedge clk);
            cycle_count = cycle_count + 1;

            if (cycle_count > 1000) begin
                $display("[FAIL] Timeout waiting for cipher_ready");
                $finish;
            end

        end


        @(posedge clk);


        // -----------------------------------------------------
        // Result
        // -----------------------------------------------------
        $display("--------------------------------------------------");
        $display("ACTUAL    = %032h", cipher_text);
        $display("LATENCY   = %0d clock cycles", cycle_count);

        if (cipher_text === expected_cipher) begin
            $display("[PASS] AES-256 BRAM ciphertext correct");
            $display("OVERALL RESULT : PASS");
        end
        else begin
            $display("[FAIL] AES-256 BRAM ciphertext mismatch");
            $display("OVERALL RESULT : FAIL");
        end

        $display("==================================================");

        repeat (5) @(posedge clk);
        $finish;
    end


    // =========================================================
    // Absolute timeout
    // =========================================================
    initial begin

        #200_000;

        $display("[FAIL] Simulation timeout");
        $finish;

    end

endmodule