
`timescale 1ns / 1ps

module trivium_cipher_tb;

    // Inputs
    reg clk;
    reg rst;
    reg start;
    reg [79:0] initialization_vector;
    reg [79:0] secret_key;

    // Outputs
    wire ready;
    wire output_bit;

    // Instantiate the Unit Under Test (UUT)
    trivium_cipher uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .initialization_vector(initialization_vector),
        .secret_key(secret_key),
        .ready(ready),
        .output_bit(output_bit)
    );

    // Clock generation (50MHz)
    always #10 clk = ~clk;

    // Helper function to reverse bits of an 80-bit vector
    // This maps standard hex notation to Trivium's bit-ordering convention
    function [79:0] bit_reverse80(input [79:0] in);
        integer i;
        begin
            for (i = 0; i < 80; i = i + 1) begin
                bit_reverse80[i] = in[79 - i];
            end
        end
    endfunction

    // Variables for monitoring output
    reg [63:0] keystream;
    integer bit_count;

    initial begin
        // Initialize Inputs
        clk = 0;
        rst = 1;
        start = 0;
        initialization_vector = 0;
        secret_key = 0;
        keystream = 0;
        bit_count = 0;

        // Wait 100 ns for global reset to finish
        #100;
        rst = 0;
        #20;

        // --- TEST VECTOR ---
        // Key: 00 00 00 00 00 00 00 00 00 00
        // IV:  00 00 00 00 00 00 00 00 00 00
        // Expected first 64 bits of keystream (Hex): F191E2D4E12E1E69
        
        secret_key            = bit_reverse80(80'h00000000000000000000);
        initialization_vector = bit_reverse80(80'h00000000000000000000);

        $display("[TB] Starting Trivium Cipher Verification...");
        $display("[TB] Key: %h", 80'h00000000000000000000);
        $display("[TB] IV:  %h", 80'h00000000000000000000);

        // Pulse start signal to initiate LOAD state
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // Wait until initialization & warmup complete and RUN state begins
        @(posedge ready);
        $display("[TB] Warmup complete! Capturing keystream bits...");

        // Collect the first 64 bits of the keystream
        // Standard Trivium stream outputs the first bit generated as the MSB of the first byte
        while (bit_count < 64) begin
            @(posedge clk);
            keystream = {keystream[62:0], output_bit};
            bit_count = bit_count + 1;
        end

        // Display results
        $display("--------------------------------------------------");
        $display("[RESULT] Generated Keystream (64-bit): %h", keystream);
        $display("[EXPECT] Expected Keystream  (64-bit): f191e2d4e12e1e69");
        $display("--------------------------------------------------");

        if (keystream == 64'hF191E2D4E12E1E69) begin
            $display("[SUCCESS] Test Passed! Hardware matches the Trivium Specification.");
        end else begin
            $display("[FAILURE] Test Failed! Mismatch detected.");
        end

        #40;
        $finish;
    end
      
endmodule
