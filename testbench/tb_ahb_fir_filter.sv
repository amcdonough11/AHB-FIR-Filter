`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_ahb_fir_filter ();

    localparam CLK_PERIOD = 20ns;

    logic clk, n_rst;
    logic hsel, hsize, hwrite, hresp;
    logic [3:0] haddr;
    logic [1:0] htrans;
    logic [15:0] hwdata, hrdata;

    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

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

    // bus model signals
    logic enqueue_transaction_en;
    logic transaction_write;
    logic transaction_fake;
    logic [3:0] transaction_addr;
    logic [15:0] transaction_data;
    logic transaction_error;
    logic [2:0] transaction_size;

    logic model_reset;
    logic enable_transactions;
    integer current_transaction_num;
    logic current_transaction_error;

    ahb_model BFM (.clk(clk),
        // Testing setup signals
        .enqueue_transaction(enqueue_transaction_en),
        .transaction_write(transaction_write),
        .transaction_fake(transaction_fake),
        .transaction_addr(transaction_addr),
        .transaction_data(transaction_data),
        .transaction_error(transaction_error),
        .transaction_size(transaction_size),
        // Testing controls
        .model_reset(model_reset),
        .enable_transactions(enable_transactions),
        .current_transaction_num(current_transaction_num),
        .current_transaction_error(current_transaction_error),
        // AHB-Subordinate Side
        .hsel(hsel),
        .htrans(htrans),
        .haddr(haddr),
        .hsize(hsize),
        .hwrite(hwrite),
        .hwdata(hwdata),
        .hrdata(hrdata),
        .hresp(hresp)
    );

    ahb_fir_filter DUT (.clk(clk), .n_rst(n_rst), .hsel(hsel), .haddr(haddr), .hsize(hsize), .htrans(htrans), .hwrite(hwrite), .hwdata(hwdata), .hrdata(hrdata), .hresp(hresp));

    // bus model tasks
    task reset_model;
    begin
        model_reset = 1'b1;
        #(0.1);
        model_reset = 1'b0;
    end
    endtask
    
    task enqueue_transaction;
        input logic for_dut;
        input logic write_mode;
        input logic [3:0] address;
        input logic [15:0] data;
        input logic expected_error;
        input logic size;
    begin
        // Make sure enqueue flag is low (will need a 0->1 pulse later)
        enqueue_transaction_en = 1'b0;
        #(0.1ns);
    
        // Setup info about transaction
        transaction_fake  = ~for_dut;
        transaction_write = write_mode;
        transaction_addr  = address;
        transaction_data  = data;
        transaction_error = expected_error;
        transaction_size  = {2'b00,size};
    
        // Pulse the enqueue flag
        enqueue_transaction_en = 1'b1;
        #(0.1ns);
        enqueue_transaction_en = 1'b0;
    end
    endtask
    
    task execute_transactions;
        input integer num_transactions;
        integer wait_var;
    begin
        // Activate the bus model
        enable_transactions = 1'b1;
        @(posedge clk);
    
        // Process the transactions (all but last one overlap 1 out of 2 cycles
        for(wait_var = 0; wait_var < num_transactions; wait_var++) begin
            @(posedge clk);
        end
    
        // Run out the last one (currently in data phase)
        @(posedge clk);
    
        // Turn off the bus model
        @(negedge clk);
        enable_transactions = 1'b0;
    end
    endtask

    task stream_samples;
        input logic [15:0] samples[];
        input integer num_samples;
        begin
            $display("%t: IGNORE ", $time,);
            for (int i = 0; i < num_samples; i++) begin
                enqueue_transaction(1, 0, 4'h0, 0, 0, 1);
                execute_transactions(1);
                @(negedge clk);
                while(hrdata != 0) begin
                    enqueue_transaction(1, 0, 4'h0, 0, 0, 1);
                    execute_transactions(1);
                    @(negedge clk);
                end
                $display("%t: STOP IGNORE ", $time,);
                enqueue_transaction(1, 1, 4'h4, samples[i], 0, 1);
                execute_transactions(1);
        end
        end
    endtask

    task power_on_reset;
    begin
        reset_model();
        reset_dut();
        @(negedge clk);

    end
    endtask

    task result_check;
        input [3:0] address;
        input size;
        input [15:0] expected_data;
        input expected_err;
        input string check_name;
    begin
            $display("%t: Checking %s at address %0h", $time, check_name, address);
            enqueue_transaction(1, 0, address, expected_data, expected_err,size);
            execute_transactions(1);
    end
    endtask

    task set_coeff;
    input [15:0] f0;
    input [15:0] f1;
    input [15:0] f2;
    input [15:0] f3;
    begin
        enqueue_transaction(1, 1, 6, f0, 0, 1);

        enqueue_transaction(1, 1, 8, f1, 0, 1);

        enqueue_transaction(1, 1, 4'ha, f2, 0, 1);

        enqueue_transaction(1, 1, 4'hc, f3, 0, 1);

        enqueue_transaction(1, 0, 6, f0, 0, 1);

        enqueue_transaction(1, 0, 8, f1, 0, 1);

        enqueue_transaction(1, 0, 4'ha, f2, 0, 1);

        enqueue_transaction(1, 0, 4'hc, f3, 0, 1);

        enqueue_transaction(1, 1, 4'he, 1, 0, 0);
        enqueue_transaction(1, 0, 4'he, 1, 0, 0);
        execute_transactions(10);

        repeat(5) @(negedge clk);

        enqueue_transaction(1, 0, 4'he, 0, 0, 0);
        execute_transactions(1);
        repeat(5) @(negedge clk);
    end
    endtask

    task set_sample_data;
        input logic [15:0] t_hwdata;
        input integer num_samples;
    begin
        integer i;
        for(i = 0; i < num_samples; i = i + 1) begin
            enqueue_transaction(1, 1, 4, t_hwdata + i, 0, 1);
            execute_transactions(1);
            repeat(13) @(negedge clk);
        end
    end
    endtask
    string test_name;


    typedef struct {
        logic [15:0] coeffs[4];
        logic [15:0] samples[8];
    } test_vector_t;

    test_vector_t test0 = '{
        coeffs: '{16'd20, 16'd45, 16'd24, 16'd15},
        samples: '{16'd60000, 16'd34656, 16'd32245, 16'd48650, 16'd5121, 16'd61213, 16'd753, 16'd8334}
    };

    initial begin
        n_rst = 1;
        test_name = "reset";

        model_reset = 1'b0;
        enable_transactions = 1'b0;
        enqueue_transaction_en = 1'b0;
        transaction_write = 1'b0;
        transaction_fake = 1'b0;
        transaction_addr = '0;
        transaction_data = '0;
        transaction_error = 1'b0;
        transaction_size = 3'd0;

        reset_model();
        reset_dut();

        test_name = "power-on reset";
        power_on_reset();

        test_name = "set_coeff";
        set_coeff(1,2,3,4);

        test_name = "set_sample_data";
        set_sample_data(60000,100);
        enqueue_transaction(1, 1, 5, 16'h4400, 0, 0);
        execute_transactions(1);
        repeat(13) @(negedge clk);
        enqueue_transaction(1, 1, 5, 16'haa00, 0, 0);
        execute_transactions(1);
        repeat(13) @(negedge clk);
        $display("%t: DONE first check", $time,);

        @(negedge clk);

        test_name = "power-on reset";
        power_on_reset();

        test_name = "set_coeff test0";
        set_coeff(test0.coeffs[0],test0.coeffs[1],test0.coeffs[2],test0.coeffs[3]);

        test_name = "set_sample_data test0";
        stream_samples(test0.samples, 8);

        test_name = "hresp test";
        power_on_reset();
        @(negedge clk);

        enqueue_transaction(1, 0, 4'he, 0, 1,1);
        execute_transactions(1);

        @(negedge clk);

        enqueue_transaction(1, 0, 4'hf, 0, 1,0);
        execute_transactions(1);
        @(negedge clk);

        enqueue_transaction(1, 1, 4'h0, 0, 1,0);
        execute_transactions(1);
        @(negedge clk);

        test_name = "power-on reset";
        power_on_reset();

        test_name = "set_coeff test1";
        set_coeff(16'd60000, 16'd60000, 16'd60000, 16'd60000);

        set_sample_data(60000,20);

        test_name = "power-on reset";
        power_on_reset();
        enqueue_transaction(1, 1, 4'he, 1, 0, 0);
        enqueue_transaction(1, 0, 4'he, 1, 0, 0);
        execute_transactions(2);



        $finish;
    end
endmodule

/* verilator coverage_on */

