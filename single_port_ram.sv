module ram1(input logic[7:0] data,
           input logic[5:0] addr,
           input logic we,
           input logic clk,
           output logic [7:0] q);//data can be written only when we is true/1 and clk is high
  logic [7:0] ram[63:0];//64 locations to store the data
  logic addr_reg;
  always_ff@(posedge clk)
    begin
      if(we)
        ram[addr]<=data;
      else
        addr_reg<=addr;
    end
  assign q=ram[addr];
endmodule
