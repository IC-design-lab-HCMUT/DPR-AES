`timescale 1ns/1ps

module tb_aes256_four_variants;

    // =========================================================
    // Clock: 100 MHz
    // =========================================================
    localparam integer CLK_PERIOD_NS = 10;

    logic clk;
    logic rst_n;
    logic cipher_en;

    logic [255:0] cipher_key;
    logic [127:0] plain_text;

    logic [127:0] lut_cipher;
    logic [127:0] bram_cipher;
    logic [127:0] composite_cipher;
    logic [127:0] noise_cipher;

    logic lut_ready;
    logic bram_ready;
    logic composite_ready;
    logic noise_ready;

    logic [127:0] expected_cipher;

    integer error_count;


    // =========================================================
    // Clock generation
    // =========================================================
    initial begin
        clk = 1'b0;

        forever begin
            #(CLK_PERIOD_NS/2);
            clk = ~clk;
        end
    end


    // =========================================================
    // Variant 1: LUT
    // =========================================================
    aes256_lut u_lut (
        .clk_sys      (clk),
        .rst_n        (rst_n),
        .cipher_key   (cipher_key),
        .plain_text   (plain_text),
        .cipher_en    (cipher_en),
        .cipher_text  (lut_cipher),
        .cipher_ready (lut_ready)
    );


    // =========================================================
    // Variant 2: BRAM
    // =========================================================
    aes256_bram u_bram (
        .clk_sys      (clk),
        .rst_n        (rst_n),
        .cipher_key   (cipher_key),
        .plain_text   (plain_text),
        .cipher_en    (cipher_en),
        .cipher_text  (bram_cipher),
        .cipher_ready (bram_ready)
    );


    // =========================================================
    // Variant 3: Composite Field
    // =========================================================
    aes256_composite u_composite (
        .clk_sys      (clk),
        .rst_n        (rst_n),
        .cipher_key   (cipher_key),
        .plain_text   (plain_text),
        .cipher_en    (cipher_en),
        .cipher_text  (composite_cipher),
        .cipher_ready (composite_ready)
    );


    // =========================================================
    // Variant 4: Dummy Noise / CPNG
    // =========================================================
    dummy_noise u_noise (
        .clk_sys      (clk),
        .rst_n        (rst_n),
        .cipher_key   (cipher_key),
        .plain_text   (plain_text),
        .cipher_en    (cipher_en),
        .cipher_text  (noise_cipher),
        .cipher_ready (noise_ready)
    );


    // =========================================================
    // Main test
    // =========================================================
    initial begin

        rst_n           = 1'b0;
        cipher_en       = 1'b0;
        error_count     = 0;

        cipher_key =
            256'h000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F;

        plain_text =
            128'h00112233445566778899AABBCCDDEEFF;

        expected_cipher =
            128'h8EA2B7CA516745BFEAFC49904B496089;


        $display("");
        $display("====================================================");
        $display(" AES-256 4-VARIANT RTL FUNCTIONAL VERIFICATION");
        $display("====================================================");
        $display("KEY      = %064h", cipher_key);
        $display("PLAINTEXT= %032h", plain_text);
        $display("EXPECTED = %032h", expected_cipher);
        $display("====================================================");


        // -----------------------------------------------------
        // Reset
        // -----------------------------------------------------
        repeat (5) @(posedge clk);

        rst_n = 1'b1;

        repeat (5) @(posedge clk);


        // -----------------------------------------------------
        // Start one AES encryption
        // -----------------------------------------------------
        @(posedge clk);
        cipher_en = 1'b1;

        @(posedge clk);
        cipher_en = 1'b0;


        // -----------------------------------------------------
        // Wait until all implementations have completed
        //
        // Different architectures are allowed to have
        // different RTL latency.
        // -----------------------------------------------------
        fork
            wait (lut_ready       === 1'b1);
            wait (bram_ready      === 1'b1);
            wait (composite_ready === 1'b1);
            wait (noise_ready     === 1'b1);
        join


        // Allow outputs to settle
        @(posedge clk);


        $display("");
        $display("---------------- RTL RESULTS ----------------");

        $display(
            "LUT        : %032h",
            lut_cipher
        );

        $display(
            "BRAM       : %032h",
            bram_cipher
        );

        $display(
            "COMPOSITE  : %032h",
            composite_cipher
        );

        $display(
            "NOISE      : %032h",
            noise_cipher
        );

        $display(
            "EXPECTED   : %032h",
            expected_cipher
        );

        $display("------------------------------------------------");


        // =====================================================
        // Individual checks
        // =====================================================

        if (lut_cipher === expected_cipher) begin
            $display("[PASS] LUT variant");
        end
        else begin
            $display("[FAIL] LUT variant");
            error_count = error_count + 1;
        end


        if (bram_cipher === expected_cipher) begin
            $display("[PASS] BRAM variant");
        end
        else begin
            $display("[FAIL] BRAM variant");
            error_count = error_count + 1;
        end


        if (composite_cipher === expected_cipher) begin
            $display("[PASS] COMPOSITE variant");
        end
        else begin
            $display("[FAIL] COMPOSITE variant");
            error_count = error_count + 1;
        end


        if (noise_cipher === expected_cipher) begin
            $display("[PASS] NOISE variant");
        end
        else begin
            $display("[FAIL] NOISE variant");
            error_count = error_count + 1;
        end


        // =====================================================
        // Cross-variant equivalence
        // =====================================================

        if (
            (lut_cipher       === bram_cipher)      &&
            (lut_cipher       === composite_cipher) &&
            (lut_cipher       === noise_cipher)
        ) begin

            $display(
                "[PASS] Cross-variant functional equivalence"
            );

        end
        else begin

            $display(
                "[FAIL] Cross-variant outputs are different"
            );

            error_count = error_count + 1;

        end


        // =====================================================
        // Summary
        // =====================================================

        $display("");
        $display("====================================================");
        $display(" RTL VERIFICATION SUMMARY");
        $display("====================================================");

        if (error_count == 0) begin

            $display("Total variants : 4");
            $display("Passed         : 4");
            $display("Failed         : 0");
            $display("OVERALL RESULT : PASS");

        end
        else begin

            $display("Total variants : 4");
            $display(
                "Failed         : %0d",
                error_count
            );
            $display("OVERALL RESULT : FAIL");

        end

        $display("====================================================");
        $display("");

        repeat (10) @(posedge clk);

        $finish;
    end


    // =========================================================
    // Timeout protection
    // =========================================================
    initial begin

        #1_000_000;

        $display("");
        $display("[FAIL] SIMULATION TIMEOUT");
        $display("");

        $finish;
    end

endmodule