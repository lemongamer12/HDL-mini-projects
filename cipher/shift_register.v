module shift_register1 #(parameter WIDTH=93)(
    input wire clk, rst, load,
    input wire data_in,
    input wire [79:0] key_data,
    output wire tap66, tap69, tap91, tap92, tap93
);
reg [WIDTH-1:0] mem;

always @(posedge clk) begin 
    if (rst)
        mem <= 0;
    else if (load)
        // Spec: s1...s80 = Key, s81...s93 = 0.
        // mem[0] is s93 (oldest), mem[92] is s1 (newest)
        mem <= {key_data, 13'b0}; 
    else
        mem <= {data_in, mem[WIDTH-1:1]};
end

assign tap93 = mem[0];
assign tap92 = mem[1];
assign tap91 = mem[2];
assign tap69 = mem[24];
assign tap66 = mem[27];
endmodule

module shift_register2 #(parameter WIDTH = 84)(
    input wire clk, rst, load,
    input wire data_in,
    input wire [79:0] iv_data,
    output wire tap162, tap171, tap175, tap176, tap177
);
reg [WIDTH-1:0] mem;

always @(posedge clk) begin
    if (rst)
        mem <= 0;
    else if (load)
        // Spec: s94...s173 = IV, s174...s177 = 0.
        // mem[0] is s177, mem[83] is s94
        mem <= {iv_data, 4'b0};
    else
        mem <= {data_in, mem[WIDTH-1:1]};
end

assign tap177 = mem[0];
assign tap176 = mem[1];
assign tap175 = mem[2];
assign tap171 = mem[6];
assign tap162 = mem[15];
endmodule

module shift_register3 #(parameter WIDTH = 111)(
    input wire clk, rst, load,
    input wire data_in,
    output wire tap243, tap264, tap286, tap287, tap288
);
reg [WIDTH-1:0] mem;

always @(posedge clk) begin
    if (rst)
        mem <= 0;
    else if (load)
        // Spec: s178...s285 = 0, s286...s288 = 1.
        // mem[0] is s288, mem[110] is s178
        mem <= {108'b0, 3'b111};
    else
        mem <= {data_in, mem[WIDTH-1:1]};
end

assign tap288 = mem[0];
assign tap287 = mem[1];
assign tap286 = mem[2];
assign tap264 = mem[24];
assign tap243 = mem[45];
endmodule
