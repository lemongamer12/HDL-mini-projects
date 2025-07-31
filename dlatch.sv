module dlatch (
    input logic clk,           
    input logic rst,
    input logic [3:0] data,
    output logic [3:0] q
);
    always_latch begin
        if (rst)
            q = 4'b0000;
        else if (clk)
            q = data;
    end
endmodule
