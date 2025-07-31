module sequence_101_fsm_tb;
    logic clk;
    logic reset;
    logic in;
    logic out;
    sequence_101_fsm uut (
        .clk(clk),
        .reset(reset),
        .in(in),
        .out(out)
    );
   initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1;
        in = 0;
        #10 reset = 0;
        #10 in = 1; 
        #10 in = 0; 
        #10 in = 1; 
        #10 in = 0; 
        #10 in = 1; 
        #10 in = 1;
        #10 in = 0; 
        #10 in = 1;
        #10 in = 0;
        #10 in = 1;
        #50 $stop;
    end
    initial begin
        $monitor("Time=%0t | Reset=%0b | In=%0b | Out=%0b", $time, reset, in, out);
    end
endmodule
