module ram1(
           input  logic [7:0] data,
           input  logic [5:0] addr,
           input  logic       we,
           input  logic       clk,
           output logic [7:0] q
);
  // 64 locations to store the data
  logic [7:0] ram [63:0];
  // Register the address to make read synchronous and match address width
  logic [5:0] addr_reg;

  always_ff @(posedge clk) begin
    if (we) begin
      ram[addr] <= data; // write on clock edge when write-enable is asserted
    end
    // Always capture the address so reads are synchronous
    addr_reg <= addr;
  end

  // Synchronous read using the registered address
  assign q = ram[addr_reg];
endmodule
