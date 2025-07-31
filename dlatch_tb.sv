module dlatch_tb;
logic rst;
logic clk;
logic[3:0] q;
logic[3:0] data;
dlatch UUT(.rst(rst),.clk(clk),.q(q),.data(data));

initial
begin
clk=0;
forever #5 clk=~clk;
end
initial begin
rst=1;
#3
rst=0;
#5
data=4'b0101;
#5
data=4'b0110;
#5
data=4'b1011;
end

endmodule
