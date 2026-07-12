`timescale 1ns/1ps

module tb_async_fifo;

    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH  = 4;      // depth = 16
    localparam DEPTH       = (1<<ADDR_WIDTH);

    reg                      wr_clk = 0;
    reg                      rd_clk = 0;
    reg                      rst_n  = 0;
    reg                      wr_en  = 0;
    reg                      rd_en  = 0;
    reg  [DATA_WIDTH-1:0]    wr_data = 0;
    wire                     full;
    wire                     empty;
    wire [DATA_WIDTH-1:0]    rd_data;

    integer errors   = 0;
    integer wr_count = 0;
    integer rd_count = 0;
    integer total_writes = 0;
    integer total_reads  = 0;

    // Mismatched, non-integer-ratio clocks to stress CDC paths
    always #3  wr_clk = ~wr_clk;   
    always #7  rd_clk = ~rd_clk;

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .wr_data(wr_data),
        .full(full),
        .empty(empty),
        .rd_data(rd_data)
    );

    // Reference model: simple queue mirroring expected FIFO contents
    reg [DATA_WIDTH-1:0] model_q [0:1023];
    integer model_head = 0;
    integer model_tail = 0;

    task push_model(input [DATA_WIDTH-1:0] d);
        begin
            model_q[model_tail] = d;
            model_tail = model_tail + 1;
        end
    endtask

    // Track when a read actually completed (1 cycle latency after rd_en&&!empty)
    reg rd_valid_d;
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n)
            rd_valid_d <= 1'b0;
        else
            rd_valid_d <= (rd_en && !empty);
    end

    always @(posedge rd_clk) begin
        if (rd_valid_d) begin
            if (rd_data !== model_q[model_head]) begin
                $display("[%0t] MISMATCH: got %0h expected %0h (idx %0d)",
                          $time, rd_data, model_q[model_head], model_head);
                errors = errors + 1;
            end
            model_head = model_head + 1;
            rd_count = rd_count + 1;
        end
    end

    // ---------------- Stimulus ----------------
    reg [DATA_WIDTH-1:0] wdat;

    initial begin
        wr_data = 0;
        wr_en   = 0;
        rd_en   = 0;
        rst_n   = 0;

        repeat (5) @(posedge wr_clk);
        rst_n = 1;
        repeat (5) @(posedge wr_clk);

        // ---- Phase 1: fill past full, verify 'full' asserts and blocks writes ----
        $display("Phase 1: fill to full");
        wdat = 8'h01;
        while (!full) begin
            @(posedge wr_clk);
            #1;
            if (!full) begin
                wr_en   = 1;
                wr_data = wdat;
                push_model(wdat);
                wdat = wdat + 1;
            end else begin
                wr_en = 0;
            end
        end
        @(posedge wr_clk);
        wr_en = 0;

        if (!full) begin
            $display("ERROR: expected full asserted");
            errors = errors + 1;
        end else begin
            $display("[%0t] full correctly asserted, wrote %0d entries", $time, model_tail);
        end

        // try writing while full -- should be dropped by DUT (wen && !full gates memory write)
        repeat (3) begin
            @(posedge wr_clk);
            wr_en   = 1;
            wr_data = 8'hFF;
        end
        @(posedge wr_clk);
        wr_en = 0;

        // ---- Phase 2: drain to empty, verify data order & 'empty' assertion ----
        $display("Phase 2: drain to empty");
        rd_en = 1;
        while (!empty) begin
            @(posedge rd_clk);
            #1;
        end
        // allow final latched read to be checked
        @(posedge rd_clk);
        @(posedge rd_clk);
        rd_en = 0;

        if (!empty) begin
            $display("ERROR: expected empty asserted");
            errors = errors + 1;
        end else begin
            $display("[%0t] empty correctly asserted, read %0d entries", $time, rd_count);
        end

        if (model_head !== model_tail) begin
            $display("ERROR: model head/tail mismatch after drain (head=%0d tail=%0d)",
                       model_head, model_tail);
            errors = errors + 1;
        end

        // ---- Phase 3: wraparound stress - concurrent random-ish read/write ----
        $display("Phase 3: concurrent read/write, pointer wraparound stress");
        fork
            begin : wr_proc
                integer i;
                for (i = 0; i < 200; i = i + 1) begin
                    @(posedge wr_clk);
                    #1;
                    if (!full && ($random % 3 != 0)) begin
                        wr_en   = 1;
                        wr_data = wdat;
                        push_model(wdat);
                        wdat = wdat + 1;
                    end else begin
                        wr_en = 0;
                    end
                end
                @(posedge wr_clk);
                wr_en = 0;
            end
            begin : rd_proc
                integer j;
                for (j = 0; j < 260; j = j + 1) begin
                    @(posedge rd_clk);
                    #1;
                    if (!empty && ($random % 4 != 0))
                        rd_en = 1;
                    else
                        rd_en = 0;
                end
                @(posedge rd_clk);
                rd_en = 0;
            end
        join

        // Drain whatever remains
        rd_en = 1;
        while (!empty) begin
            @(posedge rd_clk);
            #1;
        end
        repeat (2) @(posedge rd_clk);
        rd_en = 0;

        if (model_head !== model_tail) begin
            $display("ERROR: model head/tail mismatch after stress drain (head=%0d tail=%0d)",
                       model_head, model_tail);
            errors = errors + 1;
        end

        total_writes = model_tail;
        total_reads  = rd_count;

        // ---- Phase 4: async reset mid-operation sanity check ----
        $display("Phase 4: reset while active");
        wr_en = 1; wr_data = 8'hAA;
        repeat (3) @(posedge wr_clk);
        rst_n = 0;
        repeat (3) @(posedge wr_clk);
        wr_en = 0;
        rst_n = 1;
        repeat (5) @(posedge wr_clk);
        model_head = 0; model_tail = 0; // model resets too

        if (!empty) begin
            $display("ERROR: expected empty after reset");
            errors = errors + 1;
        end
        if (full) begin
            $display("ERROR: expected !full after reset");
            errors = errors + 1;
        end

        $display("----------------------------------------");
        if (errors == 0)
            $display("TEST PASSED: %0d writes, %0d reads, 0 errors", total_writes, total_reads);
        else
            $display("TEST FAILED: %0d errors", errors);
        $display("----------------------------------------");

        $finish;
    end

    // Safety timeout
    initial begin
        #200000;
        $display("ERROR: TIMEOUT");
        $finish;
    end
    initial begin
        $dumpfile("async_fifo.vcd");
        $dumpvars(0, tb_async_fifo);
    end

endmodule
