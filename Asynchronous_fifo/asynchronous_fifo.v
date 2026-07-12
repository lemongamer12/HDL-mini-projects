module dff#(parameter N=4)(
    input wire clk, rst,
    input wire [N-1:0] data,
    output reg [N-1:0] q
);
    always @(posedge clk) begin 
        if (rst)
            q <= {N{1'b0}};
        else
            q <= data;
    end
endmodule

module synchronizer#(parameter N=4)(
    input wire clk, rst,
    input wire [N-1:0] data_in,
    output wire [N-1:0] out2
);
    wire [N-1:0] q;
    
    dff #(.N(N)) dff1 (
        .clk(clk),
        .rst(rst),
        .data(data_in),
        .q(q)
    );
    
    dff #(.N(N)) dff2 (
        .clk(clk),
        .rst(rst),
        .data(q),
        .q(out2)
    );
endmodule

module b2g_converter#(parameter N=4)(
    input wire [N-1:0] data,
    output wire [N-1:0] data_out
);
    assign data_out = data ^ (data >> 1);
endmodule

module wptr_handler#(parameter N=4)(
    input wire wclk, wrst, wen,
    input wire [N-1:0] rgptr,
    output wire [N-1:0] wgptr,
    output reg [N-1:0] wbptr,
    output wire full,
    output wire [N-2:0] waddr
);
    b2g_converter #(.N(N)) u_b2g_w (
        .data(wbptr),
        .data_out(wgptr)
    );

    assign waddr = wbptr[N-2:0];

    always @(posedge wclk) begin
        if (wrst)
            wbptr <= 0;
        else if (wen && !full)
            wbptr <= wbptr + 1;
    end

    wire [N-1:0] wbptr_next = wbptr + 1;
    wire [N-1:0] wgptr_next;
    
    b2g_converter #(.N(N)) u_b2g_w_next (
        .data(wbptr_next),
        .data_out(wgptr_next)
    );

    assign full = (wgptr_next == {~rgptr[N-1:N-2], rgptr[N-3:0]});
endmodule

module rptr_handler#(parameter N=4)(
    input wire rclk, rrst, ren,
    input wire [N-1:0] wgptr,
    output wire [N-1:0] rgptr,
    output reg [N-1:0] rbptr,
    output wire empty,
    output wire [N-2:0] raddr
);
    b2g_converter #(.N(N)) u_b2g_r (
        .data(rbptr),
        .data_out(rgptr)
    );

    assign raddr = rbptr[N-2:0];

    always @(posedge rclk) begin
        if (rrst)
            rbptr <= 0;
        else if (ren && !empty)
            rbptr <= rbptr + 1;
    end

    assign empty = (wgptr == rgptr);
endmodule

module dual_port_memory #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input wire wclk,
    input wire wen,
    input wire [ADDR_WIDTH-1:0] waddr,
    input wire [DATA_WIDTH-1:0] wdata,
    
    input wire rclk,
    input wire ren,
    input wire [ADDR_WIDTH-1:0] raddr,
    output reg [DATA_WIDTH-1:0] rdata
);
    reg [DATA_WIDTH-1:0] mem [0:(2**ADDR_WIDTH)-1];

    always @(posedge wclk) begin
        if (wen)
            mem[waddr] <= wdata;
    end

    always @(posedge rclk) begin
        if (ren)
            rdata <= mem[raddr];
    end

endmodule

module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input wire wr_clk,
    input wire rd_clk,
    input wire rst_n,
    input wire wr_en,
    input wire rd_en,
    input wire [DATA_WIDTH-1:0] wr_data,
    output wire full,
    output wire empty,
    output wire [DATA_WIDTH-1:0] rd_data
);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;

    wire [PTR_WIDTH-1:0] wgptr, rgptr;
    wire [PTR_WIDTH-1:0] wbptr, rbptr;
    wire [PTR_WIDTH-1:0] wgptr_sync, rgptr_sync;
    wire [ADDR_WIDTH-1:0] waddr, raddr;

    wire wrst = ~rst_n;
    wire rrst = ~rst_n;

    wptr_handler #(.N(PTR_WIDTH)) u_wptr (
        .wclk(wr_clk),
        .wrst(wrst),
        .wen(wr_en),
        .rgptr(rgptr_sync),
        .wgptr(wgptr),
        .wbptr(wbptr),
        .full(full),
        .waddr(waddr)
    );

    rptr_handler #(.N(PTR_WIDTH)) u_rptr (
        .rclk(rd_clk),
        .rrst(rrst),
        .ren(rd_en),
        .wgptr(wgptr_sync),
        .rgptr(rgptr),
        .rbptr(rbptr),
        .empty(empty),
        .raddr(raddr)
    );

    synchronizer #(.N(PTR_WIDTH)) u_sync_w2r (
        .clk(rd_clk),
        .rst(rrst),
        .data_in(wgptr),
        .out2(wgptr_sync)
    );

    synchronizer #(.N(PTR_WIDTH)) u_sync_r2w (
        .clk(wr_clk),
        .rst(wrst),
        .data_in(rgptr),
        .out2(rgptr_sync)
    );

    dual_port_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_mem (
        .wclk(wr_clk),
        .wen(wr_en && !full),
        .waddr(waddr),
        .wdata(wr_data),
        .rclk(rd_clk),
        .ren(rd_en && !empty),
        .raddr(raddr),
        .rdata(rd_data)
    );

endmodule
