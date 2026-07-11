`timescale 1ns / 1ps

module ALU_tb;

    // Parameters
    localparam DATA_WIDTH = 8;
    localparam OP_WIDTH = 4;

    // Testbench Signals
    reg [OP_WIDTH-1:0] op;
    reg [DATA_WIDTH-1:0] data_in1;
    reg [DATA_WIDTH-1:0] data_in2;
    wire [DATA_WIDTH-1:0] data_out;

    // Instantiate the Device Under Test (DUT)
    ALU #(
        .data_width(DATA_WIDTH),
        .op_width(OP_WIDTH)
    ) dut (
        .op(op),
        .data_in1(data_in1),
        .data_in2(data_in2),
        .data_out(data_out)
    );

    // Monitor to print changes automatically
    initial begin
        $monitor("Time=%0t | OP=%b (%s) | IN1=%h | IN2=%h | OUT=%h", 
                 $time, op, get_op_name(op), data_in1, data_in2, data_out);
    end

    function [23:0] get_op_name;
        input [3:0] opcode;
        begin
            case(opcode)
                4'b0000: get_op_name = "ADD ";
                4'b0001: get_op_name = "SUB ";
                4'b0010: get_op_name = "AND ";
                4'b0011: get_op_name = "OR  ";
                4'b0100: get_op_name = "XOR ";
                4'b0101: get_op_name = "NOT ";
                4'b0110: get_op_name = "INC ";
                4'b0111: get_op_name = "DEC ";
                4'b1000: get_op_name = "SHL ";
                4'b1001: get_op_name = "SHR ";
                4'b1010: get_op_name = "ROL ";
                4'b1011: get_op_name = "ROR ";
                default: get_op_name = "DEF ";
            endcase
        end
    endfunction

    // Main Test Stimulus
    initial begin
        // Initialize inputs
        data_in1 = 8'hA5; // 10100101
        data_in2 = 8'h5A; // 01011010
        
        // Test Arithmetic
        op = 4'b0000; #10; // ADD
        op = 4'b0001; #10; // SUB
        op = 4'b0110; #10; // INC
        op = 4'b0111; #10; // DEC
        
        // Test Logic
        op = 4'b0010; #10; // AND
        op = 4'b0011; #10; // OR
        op = 4'b0100; #10; // XOR
        op = 4'b0101; #10; // NOT
        
        // Test Shifts & Rotates
        op = 4'b1000; #10; // SHL
        op = 4'b1001; #10; // SHR
        op = 4'b1010; #10; // ROL
        op = 4'b1011; #10; // ROR
        
        // Test Default
        op = 4'b1111; #10; // Default (Should output 0)

        // End simulation
        $finish;
    end

endmodule
