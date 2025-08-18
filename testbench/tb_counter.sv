`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_counter ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst;
    logic cnt_up, clear, one_k_sample;

    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    counter DUT (.clk(clk), .n_rst(n_rst), .cnt_up(cnt_up), .clear(clear), .one_k_sample(one_k_sample));

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

    task set_tv;
        input logic tv_n_rst;
        input logic tv_cnt_up;
        input logic tv_clear;
    begin
        automatic logic one_k_sample;

        n_rst = tv_n_rst;
        cnt_up = tv_cnt_up;
        clear = tv_clear;

    end
    endtask

    initial begin
        n_rst = 1;

        reset_dut();

        //n_rst, cnt_up_ clear
        set_tv(0, 0, 0);
        @(negedge clk);
        for(int i = 0; i < 1000; i++) begin
            set_tv(1,1,0);
            @(negedge clk);
        end

        set_tv(1,0,1);
        @(negedge clk);


        $finish;
    end
endmodule

/* verilator coverage_on */

