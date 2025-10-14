module ram1(
  input  logic [7:0] data,
  input  logic [5:0] addr,
  input  logic       we,
  input  logic       clk,
  output logic [7:0] q
);
  // 64 x 8-bit single-port RAM with synchronous write and synchronous read
  logic [7:0] ram [63:0];
  logic [5:0] addr_reg; // must match address width

  always_ff @(posedge clk) begin
    // Write on WE
    if (we) begin
      ram[addr] <= data;
    end
    // Register address every cycle for synchronous read
    addr_reg <= addr;
    // Synchronous read: one-cycle latency
    q <= ram[addr_reg];
  end
endmodule
