`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_coefficient_loader ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst;
    logic new_coefficient_set, modwait, load_coeff, clear_coeff;
    logic [1:0] coefficient_num;

    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    coefficient_loader DUT (.clk(clk), .n_rst(n_rst), .new_coefficient_set(new_coefficient_set), .modwait(modwait), .load_coeff(load_coeff), .coefficient_num(coefficient_num), .clear_coeff(clear_coeff));

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

    string test_name;

    task full_cycle;
    begin
        test_name = "IDLE to LOAD0";
        new_coefficient_set = 1; 
        @(negedge clk);

        test_name = "LOAD0 to WAIT0";
        modwait = 1;
        @(negedge clk);

        test_name = "WAIT0 to WAIT0";
        modwait = 1;
        @(negedge clk);

        test_name = "WAIT0 to LOAD1";
        modwait = 0;
        @(negedge clk);

        test_name = "LOAD1 to WAIT1";
        modwait = 1;
        @(negedge clk);

        test_name = "WAIT1 to WAIT1";
        modwait = 1;
        @(negedge clk);

        test_name = "WAIT1 to LOAD2";
        modwait = 0;
        @(negedge clk);

        test_name = "LOAD2 to WAIT2";
        modwait = 0;
        @(negedge clk);

        test_name = "WAIT2 to LOAD3";
        modwait = 0;
        @(negedge clk);

        test_name = "LOAD3 to CLEAR";
        modwait = 0;
        @(negedge clk);

        test_name = "CLEAR to IDLE";
        @(negedge clk);

        test_name = "IDLE";
        @(negedge clk);
    end
    endtask

    initial begin
        n_rst = 1;

        reset_dut();

        full_cycle();

        $finish;
    end
endmodule

/* verilator coverage_on */

