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
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= S0; 
        else
            current_state <= next_state;
    end
    always_comb begin
        case (current_state)
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
    always_comb begin
        case (current_state)
            S0: out = 0;
            S1: out = 0;
            S2: out = (in == 1) ? 1 : 0;
            default: out = 0;
        endcase
    end

endmodule
