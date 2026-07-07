//mealy FSM
module sequence_101_fsm (
    input  logic clk,           
    input  logic reset,         
    input  logic in,            
    output logic out            
);

    typedef enum logic [1:0] {
        S0 = 2'b00,  // Initial state
        S1 = 2'b01,  // Detected '1'
        S2 = 2'b10   // Detected '10'
    } state_t;

    state_t current_state, next_state;
    logic out_next; // registered Mealy output to avoid glitches
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= S0; 
        else
            current_state <= next_state;
    end
    always_comb begin
        // Default to hold state unless a branch overrides it
        next_state = current_state;
        unique case (current_state)
            S0: begin
                if (in == 1)
                    next_state = S1;
                else
                    next_state = S0;
            end
            S1: begin
                if (in == 0)
                    next_state = S2;
                else
                    next_state = S1;
            end
            S2: begin
                if (in == 1)
                    next_state = S1;
                else
                    next_state = S0;
            end
            default: next_state = S0;
        endcase
    end
    // Compute Mealy output combinationally, then register it
    always_comb begin
        out_next = 1'b0;
        unique case (current_state)
            S0: out_next = 1'b0;
            S1: out_next = 1'b0;
            S2: out_next = (in == 1);
            default: out_next = 1'b0;
        endcase
    end

    // Register output to remove combinational glitches
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            out <= 1'b0;
        else
            out <= out_next;
    end

endmodule
