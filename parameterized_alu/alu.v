module ALU#(parameter data_width=8,
            parameter op_width=4)(
    input wire [op_width-1:0] op,
    input wire [data_width-1:0] data_in1,
    input wire [data_width-1:0] data_in2,
    output reg [data_width-1:0] data_out
);

    always@(*)begin
        case(op)
            4'b0000: data_out = data_in1 + data_in2;                 // ADD
            4'b0001: data_out = data_in1 - data_in2;                 // SUB
            4'b0010: data_out = data_in1 & data_in2;                 // AND
            4'b0011: data_out = data_in1 | data_in2;                 // OR
            4'b0100: data_out = data_in1 ^ data_in2;                 // XOR
            4'b0101: data_out = ~data_in1;                           // NOT
            4'b0110: data_out = data_in1 + {{(data_width-1){1'b0}}, 1'b1};  // INC
            4'b0111: data_out = data_in1 - {{(data_width-1){1'b0}}, 1'b1};  // DEC
            4'b1000: data_out = data_in1 << 1;                       // SHL
            4'b1001: data_out = data_in1 >> 1;                       // SHR
            4'b1010: data_out = {data_in1[data_width-2:0], data_in1[data_width-1]};     // ROL
            4'b1011: data_out = {data_in1[0], data_in1[data_width-1:1]};                // ROR
            default: data_out = {data_width{1'b0}};  
        endcase
    end

endmodule
