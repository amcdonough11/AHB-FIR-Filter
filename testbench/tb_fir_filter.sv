`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_fir_filter ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst;
    logic load_coeff, data_ready, one_k_samples, modwait, err;
    logic [15:0] sample_data, fir_coefficient, fir_out;

    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    fir_filter DUT (.clk(clk), .n_rst(n_rst), .sample_data(sample_data), .fir_coefficient(fir_coefficient), .load_coeff(load_coeff), .data_ready(data_ready), .one_k_samples(one_k_samples), .modwait(modwait), .fir_out(fir_out), .err(err));

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
        input logic [15:0] tv_sample_data;
        input logic [15:0] tv_fir_coefficient;
        input logic tv_load_coeff;
        input logic tv_data_ready;
    begin

        n_rst = tv_n_rst;
        load_coeff = tv_load_coeff;
        data_ready = tv_data_ready;
        sample_data = tv_sample_data;
        fir_coefficient = tv_fir_coefficient;
    end
    endtask

    task test_full;
        input logic [15:0] load;
    begin
        //data_ready
        set_tv(1,load,0,0,1);
        repeat(2) @(negedge clk); 
        set_tv(1,load,0,0,0); 
        repeat(18) @(negedge clk);
    end
    endtask
    string test_name;

    initial begin
        n_rst = 1;

        reset_dut();

        //n_rst, sample_data, fir_coeff, load_coeff, data_ready
        set_tv(0,0,0,0,0);

        test_name = "Loading Coeff";

        //load_coeff
        set_tv(1,0,16'h8000,1,0); //1
        @(negedge clk);
        set_tv(1,0,16'h8000,0,0); //1
        repeat(4) @(negedge clk);
        set_tv(1,0,16'hffff,1,0); //2
        @(negedge clk);
        set_tv(1,0,16'hffff,0,0); //2
        repeat(4) @(negedge clk);
        set_tv(1,0,16'hffff,1,0); //2
        @(negedge clk);
        set_tv(1,0,16'hffff,0,0); //2
        repeat(4) @(negedge clk);
        set_tv(1,0,16'h4000,1,0); //.5
        @(negedge clk);
        set_tv(1,0,16'h4000,0,0); //.5
        repeat(4) @(negedge clk);

        test_name = "Full 1000";
        repeat(1000) begin
            test_full(10);
        end
        @(negedge clk);
        @(negedge clk);

        test_name = "Test Error";

        repeat(20) begin
            test_full(16'd65535);
        end

        

        $finish;
    end
endmodule

/* verilator coverage_on */

