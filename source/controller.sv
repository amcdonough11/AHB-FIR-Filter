`timescale 1ns / 10ps

module controller (
    input logic clk,
    input logic n_rst,
    input logic dr,
    input logic lc,
    input logic overflow,
    output logic cnt_up,
    output logic clear,
    output logic modwait,
    output logic [2:0] op,
    output logic [3:0] src1,
    output logic [3:0] src2,
    output logic [3:0] dest,
    output logic err
);
typedef enum logic [5:0] {
    IDLE,
    EIDLE,
    LOAD_F0,
    WAIT_F0,
    LOAD_F1,
    WAIT_F1,
    LOAD_F2,
    WAIT_F2,
    LOAD_F3,
    CHECK_DR1,
    CLEAR_R0,
    S3_TO_S4,
    S2_TO_S3,
    S1_TO_S2,
    LOAD_S1,
    S1_MUL_F0,
    S2_MUL_F1,
    S2_SUB_S1,
    S3_MUL_F2,
    S3_ADD_S2,
    S4_MUL_F3,
    S4_SUB_S3
} state_t;

state_t state, next_state;
logic next_modwait;

always_ff @ (posedge clk, negedge n_rst) begin
    if(~n_rst) begin
        state <= IDLE;
        modwait <= 0;
    end
    else begin
        state <= next_state;
        modwait <= next_modwait;
    end
end

always_comb begin
    next_state = state;
    next_modwait = modwait;
    case(state)
        IDLE: begin
            if(lc) next_state = LOAD_F0;
            if(dr) next_state = CHECK_DR1;
            next_modwait = (lc | dr) ? 1 : 0;
        end
        EIDLE: begin
            if(lc) next_state = LOAD_F0;
            if(dr) next_state = CHECK_DR1;
            next_modwait = (lc | dr) ? 1 : 0;
        end
        LOAD_F0: begin
                next_state = WAIT_F0; 
                next_modwait = 0;
        end
        WAIT_F0: begin
            next_state = lc ? LOAD_F1 : WAIT_F0;
            next_modwait = (lc) ? 1 : 0;
        end
        LOAD_F1: begin 
            next_state = WAIT_F1;
            next_modwait = 0; 
        end
        WAIT_F1: begin
            next_state = lc ? LOAD_F2 : WAIT_F1;
            next_modwait = (lc) ? 1 : 0;
        end
        LOAD_F2: begin 
            next_state = WAIT_F2;
            next_modwait = 0;
        end
        WAIT_F2: begin
            next_state = lc ? LOAD_F3 : WAIT_F2;
            next_modwait = (lc) ? 1 : 0;
        end
        LOAD_F3: begin 
            next_state = IDLE;
            next_modwait = 0;
        end
        CHECK_DR1:begin
            if(~dr) next_state = EIDLE; next_modwait = 0;
            if(dr) next_state = CLEAR_R0; next_modwait = 1;
        end
        CLEAR_R0: begin 
            next_state = overflow ? EIDLE : S3_TO_S4;
            next_modwait = 1;
        end
        S3_TO_S4: begin
            next_state = overflow ? EIDLE : S2_TO_S3;
            next_modwait = 1;
        end
        S2_TO_S3: next_state = overflow ? EIDLE : S1_TO_S2;
        S1_TO_S2: next_state = overflow ? EIDLE : LOAD_S1;
        LOAD_S1: begin
            next_state = overflow ? EIDLE : S1_MUL_F0;
            next_modwait = (overflow) ? 0 : 1;
        end
        S1_MUL_F0: begin 
            next_state = overflow ? EIDLE : S2_MUL_F1;
            next_modwait = (overflow) ? 0 : 1;
        end
        S2_MUL_F1: begin
            next_state = overflow ? EIDLE : S2_SUB_S1;
            next_modwait = (overflow) ? 0 : 1;
        end
        S2_SUB_S1: begin
            next_state = overflow ? EIDLE : S3_MUL_F2;
            next_modwait = (overflow) ? 0 : 1;
        end
        S3_MUL_F2: begin
            next_state = overflow ? EIDLE : S3_ADD_S2;
            next_modwait = (overflow) ? 0 : 1;
        end
        S3_ADD_S2: begin
            next_state = overflow ? EIDLE : S4_MUL_F3;
            next_modwait = (overflow) ? 0 : 1;
        end
        S4_MUL_F3: begin
            next_state = overflow ? EIDLE : S4_SUB_S3;
            next_modwait = (overflow) ? 0 : 1;
        end
        S4_SUB_S3: begin
            next_state = overflow ? EIDLE : IDLE;
            next_modwait = (overflow) ? 0 : 1;
        end
        default : begin
            next_state = IDLE;
            next_modwait = 0;
        end
    endcase
end

always_comb begin
    case(state)
        IDLE: begin 
            cnt_up = 0;
            clear = 0;
            //modwait = 0;
            err = 0;
            op = 3'b0;
            src1 = 0;
            src2 = 0;
            dest = 0;
        end
        EIDLE: begin 
            cnt_up = 0;
            clear = 0;
            //modwait = 0;
            err = 1;
            op = 3'b0;
            src1 = 0;
            src2 = 0;
            dest = 0;
        end
        LOAD_F0: begin 
            cnt_up = 0;
            clear = 1;
            //modwait = 1;
            err = 0;
            op = 3'b011;
            src1 = 0;
            src2 = 12;
            dest = 5;
        end
        WAIT_F0: begin 
            cnt_up = 0;
            clear = 1;
            //modwait = 0;
            err = 0;
            op = 3'b0;
            src1 = 0;
            src2 = 12;
            dest = 5;
        end
        LOAD_F1: begin 
            cnt_up = 0;
            clear = 1;
            //modwait = 1;
            err = 0;
            op = 3'b011;
            src1 = 0;
            src2 = 12;
            dest = 6;
        end
        WAIT_F1: begin 
            cnt_up = 0;
            clear = 1;
            //modwait = 0;
            err = 0;
            op = 3'b0;
            src1 = 0;
            src2 = 12;
            dest = 6;
        end
        LOAD_F2: begin 
            cnt_up = 0;
            clear = 1;
            //modwait = 1;
            err = 0;
            op = 3'b011;
            src1 = 0;
            src2 = 12;
            dest = 7;
        end
        WAIT_F2: begin 
            cnt_up = 0;
            clear = 1;
            //modwait = 0;
            err = 0;
            op = 3'b0;
            src1 = 0;
            src2 = 12;
            dest = 7;
        end
        LOAD_F3: begin 
            cnt_up = 0;
            clear = 1;
            //modwait = 1;
            err = 0;
            op = 3'b011;
            src1 = 0;
            src2 = 12;
            dest = 8;
        end
        CHECK_DR1: begin 
            cnt_up = 0;
            clear = 0;
            //modwait = 1;
            err = 0;
            op = 3'b010;
            src1 = 0;
            src2 = 0;
            dest = 13;
        end
        CLEAR_R0: begin 
            cnt_up = 0;
            clear = 0;
            //modwait = 1;
            err = 0;
            op = 3'b101;
            src1 = 0;
            src2 = 0;
            dest = 0;
        end
        S3_TO_S4: begin 
            cnt_up = 1;
            clear = 0;
            //modwait = 1;
            err = 0;
            op = 3'b001;
            src1 = 3;
            src2 = 0;
            dest = 4;
        end
        S2_TO_S3: begin 
            cnt_up = 0;
            clear = 0;
            //modwait = 1;
            err = 0;
            op = 3'b001;
            src1 = 2;
            src2 = 0;
            dest = 3;
        end
        S1_TO_S2: begin 
            cnt_up = 0;
            clear = 0;
            //modwait = 1;
            err = 0;
            op = 3'b001;
            src1 = 1;
            src2 = 0;
            dest = 2;
        end
        LOAD_S1: begin 
            cnt_up = 0;
            clear = 0;
            //modwait = 1;
            err = 0;
            op = 3'b001;
            src1 = 13;
            src2 = 0;
            dest = 1;
        end
        S1_MUL_F0: begin 
            cnt_up = 0;
            clear = 0;
            //modwait = 1;
            err = 0;
            op = 3'b110;
            src1 = 1;
            src2 = 5;
            dest = 0;
        end
        S2_MUL_F1: begin 
            cnt_up = 0;
            clear = 0;
            //modwait = 1;
            err = 0;
            op = 3'b110;
            src1 = 2;
            src2 = 6;
            dest = 9;
        end
        S2_SUB_S1: begin 
            cnt_up = 0;
            clear = 0;
            //modwait = 1;
            err = 0;
            op = 3'b101;
            src1 = 0;
            src2 = 9;
            dest = 0;
        end
        S3_MUL_F2: begin 
            cnt_up = 0;
            clear = 0;
            //modwait = 1;
            err = 0;
            op = 3'b110;
            src1 = 3;
            src2 = 7;
            dest = 9;
        end
        S3_ADD_S2: begin 
            cnt_up = 0;
            clear = 0;
            //modwait = 1;
            err = 0;
            op = 3'b100;
            src1 = 0;
            src2 = 9;
            dest = 0;
        end
        S4_MUL_F3: begin 
            cnt_up = 0;
            clear = 0;
            //modwait = 1;
            err = 0;
            op = 3'b110;
            src1 = 4;
            src2 = 8;
            dest = 9;
        end
        S4_SUB_S3: begin 
            cnt_up = 0;
            clear = 0;
            //modwait = 1;
            err = 0;
            op = 3'b101;
            src1 = 0;
            src2 = 9;
            dest = 0;
        end
        default: begin 
            cnt_up = 0;
            clear = 0;
            //modwait = 0;
            err = 0;
            op = 3'b0;
            src1 = 0;
            src2 = 0;
            dest = 0;
        end
    endcase

end


endmodule

