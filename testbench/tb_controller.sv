`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_controller ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst;

    logic dr;
    logic lc;
    logic overflow;
    logic cnt_up;
    logic clear;
    logic modwait;
    logic [2:0] op;
    logic [3:0] src1;
    logic [3:0] src2;
    logic [3:0] dest;
    logic err;

    typedef enum logic [5:0] {
        IDLE = 6'd0,
        EIDLE = 6'd1,
        LOAD_F0 = 6'd2,
        WAIT_F0 = 6'd3,
        LOAD_F1 = 6'd4,
        WAIT_F1 = 6'd5,
        LOAD_F2 = 6'd6,
        WAIT_F2 = 6'd7,
        LOAD_F3 = 6'd8,
        CHECK_DR1 = 6'd9,
        CLEAR_R0 = 6'd10,
        S3_TO_S4 = 6'd11,
        S2_TO_S3 = 6'd12,
        S1_TO_S2 = 6'd13,
        LOAD_S1 = 6'd14,
        S1_MUL_F0 = 6'd15,
        S2_MUL_F1 = 6'd16,
        S2_SUB_S1 = 6'd17,
        S3_MUL_F2 = 6'd18,
        S3_ADD_S2 = 6'd19,
        S4_MUL_F3 = 6'd20,
        S4_SUB_S3 = 6'd21
    } state_t;

    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    controller DUT (
        .clk(clk),
        .n_rst(n_rst),
        .dr(dr),
        .lc(lc),
        .overflow(overflow),
        .cnt_up(cnt_up),
        .clear(clear),
        .modwait(modwait),
        .op(op),
        .src1(src1),
        .src2(src2),
        .dest(dest),
        .err(err)
    );

    task set_tv;
        input logic tv_n_rst;
        input logic tv_dr;
        input logic tv_lc;
        input logic tv_overflow;
    begin
        automatic logic tv_cnt_up;
        automatic logic tv_clear;
        automatic logic tv_modwait;
        automatic logic [2:0] tv_op;
        automatic logic [3:0] tv_src1;
        automatic logic [3:0] tv_src2;
        automatic logic [3:0] tv_dest;
        automatic logic tv_err;

        n_rst = tv_n_rst;
        dr = tv_dr;
        lc = tv_lc;
        overflow = tv_overflow;

    end
    endtask

    task reset_dut;
    begin
        n_rst = 0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(negedge clk);
        @(negedge clk);
    end
    endtask

    task check_state;
        input state_t expected_state;
        input string message;
    begin
        if (DUT.state !== expected_state) begin
            $display("ERROR at time %0t: %s - Expected state: %s, Got: %s", 
                     $time, message, expected_state.name(), DUT.state.name());
        end else begin
            $display("PASS at time %0t: %s - State: %s", 
                     $time, message, expected_state.name());
        end
    end
    endtask

    initial begin
        n_rst = 1;

        reset_dut();

        //n_rst, dr, lc, overflow
        set_tv(0, 0, 0, 0);
        @(negedge clk);

        set_tv(1, 0, 1, 0);
        @(negedge clk);
        check_state(LOAD_F0, "F0");

        @(negedge clk);
        check_state(WAIT_F0, "F0 Wait");

        @(negedge clk);
        check_state(LOAD_F1, "F1 LOAD");

        set_tv(1, 0, 1, 0);
        @(negedge clk);
        check_state(WAIT_F1, "F1 WAIT");

        @(negedge clk);
        check_state(LOAD_F2, "F2 LOAD");

        set_tv(1, 0, 1, 0);
        @(negedge clk);
        check_state(WAIT_F2, "F2 WAIT");

        @(negedge clk);
        check_state(LOAD_F3, "F3 LOAD");

        set_tv(1, 0, 0, 0);
        @(negedge clk);
        check_state(IDLE, "IDLE AFTER COEFF");

        set_tv(1, 1, 0, 0);
        @(negedge clk);
        check_state(CHECK_DR1, "IDLE TO CHECK_DR1");

        set_tv(1, 1, 0, 0);
        @(negedge clk);
        check_state(CLEAR_R0, "CLEAR_R0");

        set_tv(1, 1, 0, 0);
        @(negedge clk);
        check_state(S3_TO_S4, "S3 SHIFT");

        set_tv(1, 1, 0, 0);
        @(negedge clk);
        check_state(S2_TO_S3, "S2 SHIFT");

        set_tv(1, 1, 0, 0);
        @(negedge clk);
        check_state(S1_TO_S2, "S1 SHIFT");

        set_tv(1, 1, 0, 0);
        @(negedge clk);
        check_state(LOAD_S1, "LOAD S1");

        set_tv(1, 1, 0, 0);
        @(negedge clk);
        check_state(S1_MUL_F0, "S1_MUL_F0");

        set_tv(1, 1, 0, 0);
        @(negedge clk);
        check_state(S2_MUL_F1, "S2_MUL_F1");

        set_tv(1, 1, 0, 0);
        @(negedge clk);
        check_state(S2_SUB_S1, "SUB S1");

        set_tv(1, 1, 0, 0);
        @(negedge clk);
        check_state(S3_MUL_F2, "S3_MUL_F2");

        set_tv(1, 1, 0, 0);
        @(negedge clk);
        check_state(S3_ADD_S2, "ADD S2");

        set_tv(1, 1, 0, 0);
        @(negedge clk);
        check_state(S4_MUL_F3, "S4_MUL_F3");

        set_tv(1, 1, 0, 0);
        @(negedge clk);
        check_state(S4_SUB_S3, "SUB S4");

        set_tv(1, 0, 0, 0);
        @(negedge clk);
        check_state(IDLE, "BACK TO IDLE");

        set_tv(1, 1, 0, 0);
        @(negedge clk);
        check_state(CHECK_DR1, "CHECK_DR1");

        set_tv(1, 0, 0, 0);
        @(negedge clk);
        check_state(EIDLE, "EIDLE");


        $finish;
    end
endmodule

/* verilator coverage_on */

