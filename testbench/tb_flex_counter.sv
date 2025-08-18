`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_flex_counter ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst;
    logic clear, count_enable, rollover_flag;
    logic [7:0] rollover_val, count_out;

    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    flex_counter #(.SIZE(8)) f0 (.clk(clk), .n_rst(n_rst), .clear(clear), .count_enable(count_enable), .rollover_val(rollover_val), .count_out(count_out), .rollover_flag(rollover_flag)); 

    localparam NUM_TEST_CASES = 18;

    typedef struct {
        logic n_rst;
        logic clear;
        logic count_enable;
        logic [7:0] rollover_val;
        logic exp_rollover_flag;
        logic [7:0] exp_count_out;
    } testVector_t;

    testVector_t test_vec [NUM_TEST_CASES];

    task set_tv;
        input logic tv_n_rst;
        input logic tv_clear;
        input logic tv_count_enable;
        input logic [7:0] tv_rollover_val;
        input integer idx;
    begin 
        automatic logic [7:0] tv_count_out;
        automatic logic tv_rollover_flag;

        if(tv_clear) begin
            tv_count_out = 0;
            tv_rollover_flag = 0;
        end
        else if (tv_count_enable) begin 
            if (tv_count_out == tv_rollover_val) begin
                tv_count_out = 1;
            end 
            else begin
                tv_count_out = tv_count_out + 1;
            end
        end

        tv_rollover_flag = ((count_out == rollover_val) ? 1'b1: 1'b0);
        tv_count_out = (tv_n_rst) ? tv_count_out : 4'b0000;

        n_rst = tv_n_rst;
        count_enable = tv_count_enable;
        rollover_val = tv_rollover_val;
        clear = tv_clear;

        test_vec[idx].n_rst = tv_n_rst;
        test_vec[idx].count_enable = tv_count_enable;
        test_vec[idx].rollover_val = tv_rollover_val;
        test_vec[idx].clear = tv_clear;
        test_vec[idx].exp_count_out = tv_count_out;
        test_vec[idx].exp_rollover_flag = tv_rollover_flag;

        @(negedge clk);
        if(test_vec[idx].exp_count_out != count_out) begin 
            $display("Test %d Incorrect Count_out. Expected: %b, Actual: %b", idx, test_vec[idx].exp_count_out, count_out);
        end
        if(test_vec[idx].exp_rollover_flag != rollover_flag) begin 
            $display("Test %d Incorrect rollover_flag. Expected: %b, Actual: %b", idx, test_vec[idx].exp_rollover_flag, rollover_flag);
        end
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

    initial begin
        n_rst = 1;

        reset_dut;
        // n_rst, clear, count_enable, rollover_val, idx
        set_tv(0, 0, 0, 6, 0); //rst
        set_tv(1, 0, 1, 6, 1); //0->1
        set_tv(1, 0, 1, 6, 2); //1->2
        set_tv(1, 0, 1, 6, 3); //2->3
        set_tv(1, 0, 0, 6, 4); //count disable
        set_tv(1, 0, 1, 6, 5); //3->4
        set_tv(1, 0, 1, 6, 6); //4->5
        set_tv(1, 0, 1, 6, 7); //5->6 
        set_tv(1, 0, 0, 6, 7); //5->6
        set_tv(1, 0, 1, 6, 8); //6->1 rollover
        set_tv(1, 0, 1, 6, 9); //1->2
        set_tv(1, 1, 1, 6, 10); //clear while counting
        set_tv(1, 0, 1, 6, 11); //0->1
        set_tv(1, 0, 1, 6, 12); //1->2
        set_tv(1, 0, 1, 6, 13); //2->3
        set_tv(1, 0, 1, 6, 14); //2->3
        set_tv(1, 0, 1, 2, 15); //2->1 rollover edge
        set_tv(1, 0, 1, 2, 16); //
        set_tv(1, 0, 1, 2, 17);


        $finish;
    end
endmodule

/* verilator coverage_on */

