`timescale 1ns / 10ps

module coefficient_loader (
    input logic clk,
    input logic n_rst,
    input logic new_coefficient_set,
    input logic modwait,
    output logic load_coeff,
    output logic [1:0] coefficient_num,
    output logic clear_coeff
);

typedef enum logic [3:0] {IDLE, LOAD0, LOAD1, LOAD2, LOAD3, WAIT0, WAIT1, WAIT2, WAIT3, CLEAR} state_t;

state_t state, next_state;

always_ff @( posedge clk, negedge n_rst ) begin
    if(~n_rst) begin
        state <= IDLE;
    end
    else begin
        state <= next_state;
    end
end

always_comb begin
    load_coeff = 0;
    coefficient_num = 0;
    clear_coeff = 0;
    next_state = state;
    case(state)
        IDLE: begin
            load_coeff = 0;
            if(new_coefficient_set) begin
                next_state = CLEAR;
            end
        end
        LOAD0: begin
            next_state = WAIT0;
            load_coeff = 1;
            coefficient_num = 0;
        end
        WAIT0: begin
            if(~modwait) next_state = LOAD1;
            load_coeff = 0;
            coefficient_num = 0;
        end
        LOAD1: begin
            next_state = WAIT1;
            load_coeff = 1;
            coefficient_num = 1;
        end
        WAIT1: begin
            if(~modwait) next_state = LOAD2;
            load_coeff = 0;
            coefficient_num = 1;
        end
        LOAD2: begin
            next_state = WAIT2;
            load_coeff = 1;
            coefficient_num = 2;
        end
        WAIT2: begin
            if(~modwait) next_state = LOAD3;
            load_coeff = 0;
            coefficient_num = 2;
        end
        LOAD3: begin
            next_state = WAIT3;
            load_coeff = 1;
            coefficient_num = 3;
        end
        WAIT3: begin
            if(~modwait) next_state = IDLE;
            load_coeff = 0;
            coefficient_num = 3;
        end
        CLEAR: begin
            next_state = LOAD0;
            load_coeff = 0;
            clear_coeff = 1;
        end
        default: begin
            next_state = IDLE;
        end
    endcase
end

endmodule

