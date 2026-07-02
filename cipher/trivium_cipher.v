
module trivium_cipher(
    input wire clk,
    input wire rst,
    input wire start,

    input wire [79:0] initialization_vector,
    input wire [79:0] secret_key,

    output reg ready,
    output wire output_bit
);

// Taps and Internal Signals
wire tap66, tap69, tap91, tap92, tap93;
wire tap162, tap171, tap175, tap176, tap177;
wire tap243, tap264, tap286, tap287, tap288;

wire t1, t2, t3;
wire feedback1, feedback2, feedback3;

// State Machine Setup
reg [1:0] state, next_state;
localparam IDLE   = 2'b00,
           LOAD   = 2'b01,
           WARMUP = 2'b10,
           RUN    = 2'b11;

reg [10:0] counter;
wire load_signal = (state == LOAD);

// Instantiations with Parallel Load Mapping
shift_register1 SR1(
    .clk(clk), .rst(rst), .load(load_signal),
    .data_in(feedback3), .key_data(secret_key),
    .tap66(tap66), .tap69(tap69), .tap91(tap91), .tap92(tap92), .tap93(tap93)
);

shift_register2 SR2(
    .clk(clk), .rst(rst), .load(load_signal),
    .data_in(feedback1), .iv_data(initialization_vector),
    .tap162(tap162), .tap171(tap171), .tap175(tap175), .tap176(tap176), .tap177(tap177)
);

shift_register3 SR3(
    .clk(clk), .rst(rst), .load(load_signal),
    .data_in(feedback2),
    .tap243(tap243), .tap264(tap264), .tap286(tap286), .tap287(tap287), .tap288(tap288)
);

// Core Trivium Logic Combinational Equations
assign t1 = tap66  ^ tap93;
assign t2 = tap162 ^ tap177;
assign t3 = tap243 ^ tap288;

assign feedback1 = t1 ^ (tap91 & tap92)   ^ tap171;
assign feedback2 = t2 ^ (tap175 & tap176) ^ tap264;
assign feedback3 = t3 ^ (tap286 & tap287) ^ tap69;

// Keystream Activation
assign output_bit = (state == RUN) ? (t1 ^ t2 ^ t3) : 1'b0;

// State Transition Engine
always @(posedge clk) begin
    if(rst) state <= IDLE;
    else    state <= next_state;
end

// Warmup Control (4 full cycles = 1152 steps)
always @(posedge clk) begin
    if(rst) begin
        counter <= 0;
    end else begin
        if (state == WARMUP) begin
            if(counter == 1151)
                counter <= 0;
            else
                counter <= counter + 1;
        end else begin
            counter <= 0;
        end
    end
end

// Next State Logic
always @(*) begin
    next_state = state;
    case(state)
        IDLE:   if(start) next_state = LOAD;
        LOAD:   next_state = WARMUP; // Instantly moves to warmup next cycle
        WARMUP: if(counter == 1151) next_state = RUN;
        RUN:    next_state = RUN;
    endcase
end

// Output State Indicator
always @(*) begin
    ready = (state == RUN);
end

endmodule
