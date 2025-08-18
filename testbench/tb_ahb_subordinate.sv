`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_ahb_subordinate ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst;
    logic err, modwait, clear_coeff;
    logic [15:0] fir_out;
    logic [1:0] coefficient_num;

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

    logic hsel;
    logic [1:0] htrans;
    logic [3:0] haddr;
    logic [2:0] hsize;
    logic hwrite;
    logic [15:0] hwdata;
    logic [15:0] hrdata, fir_coefficient;
    logic hresp;

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

    ahb_subordinate DUT (.clk(clk), .n_rst(n_rst), .sample_data(sample_data), .data_ready(data_ready), .new_coefficient_set(new_coefficient_set), .clear_coeff(clear_coeff), .coefficient_num(coefficient_num), .fir_coefficient(fir_coefficient), .modwait(modwait), .fir_out(fir_out), .err(err), .hsel(hsel), .haddr(haddr), .hsize(hsize), .htrans(htrans), .hwrite(hwrite), .hwdata(hwdata), .hrdata(hrdata), .hresp(hresp));

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

    task transaction;
        input logic write;
        input logic [3:0] addr;
        input logic [15:0] data;
        input logic er;
        input logic size;
    begin
        enqueue_transaction(1, write, addr, data, er, size);
        execute_transactions(1);
    end
    endtask

    task read_result;
        fir_out = 16'h0a02;
        transaction(0, 2, 0, 0, 1);
        if(16'ha2 != hrdata) $display("2 byte read result error at time %0t", $time);
        @(negedge clk);

        transaction(0, 2, 0, 0, 0);
        if(16'h02 != hrdata) $display("addr 2, 1 byte read result error at time %0t", $time);
        @(negedge clk);

        transaction(0, 3, 0, 0, 0);
        if(16'h0a00 != hrdata) $display("addr 3, 1 byte read result error at time %0t", $time);
        @(negedge clk);
    begin
        
    end
    endtask

    task write_and_read_new_sample;
    begin

        transaction(1, 4, 16'h4532, 0, 1);
        @(negedge clk);
        @(negedge clk);

        transaction(0, 4, 0, 0, 1);
        if(16'h4532 != hrdata) $display("1: 2 byte write and read new sample error at time %0t", $time);
        @(negedge clk);

        transaction(0, 4, 0, 0, 0);
        if(16'h32 != hrdata) $display("1: addr 4, 1 byte write and read new sample error at time %0t", $time);
        @(negedge clk);

        transaction(0, 5, 0, 0, 0);
        if(16'h4500 != hrdata) $display("1: addr 5, 1 byte write and read new sample error at time %0t", $time);
        @(negedge clk);

        transaction(1, 4, 16'haa, 0, 0);
        @(negedge clk);

        transaction(1, 5, 16'hbb00, 0, 0);
        @(negedge clk);

        transaction(0, 4, 0, 0, 1);
        if(16'hbbaa != hrdata) $display("2: 2 byte write and read new sample error at time %0t", $time);
        @(negedge clk);

        transaction(0, 4, 0, 0, 0);
        if(16'haa != hrdata) $display("2: addr 4, 1 byte write and read new sample error at time %0t", $time);
        @(negedge clk);

        transaction(0, 5, 0, 0, 0);
        if(16'hbb00 != hrdata) $display("2: addr 5, 1 byte write and read new sample error at time %0t", $time);
        @(negedge clk);
    end
    endtask

    task read_status;
    begin
        err = 0;
        modwait = 0;

        transaction(0, 0, 0, 0, 1);
        if(16'h00 != hrdata) $display("2 byte read new status error at time %0t", $time);
        @(negedge clk);
        transaction(0, 0, 0, 0, 0);
        if(16'h00 != hrdata) $display("addr 0, 1 byte read new status error at time %0t", $time);
        @(negedge clk);
        transaction(0, 1, 0, 0, 0);
        if(16'h00 != hrdata) $display("addr 1, 1 byte read new status error at time %0t", $time);
        @(negedge clk);

        err = 0;
        modwait = 1;

        transaction(0, 0, 0, 0, 1);
        if(16'h01 != hrdata) $display("2 byte read new status error at time %0t", $time);
        @(negedge clk);
        transaction(0, 0, 0, 0, 0);
        if(16'h01 != hrdata) $display("addr 0, 1 byte read new status error at time %0t", $time);
        @(negedge clk);
        transaction(0, 1, 0, 0, 0);
        if(16'h00 != hrdata) $display("addr 1, 1 byte read new status error at time %0t", $time);
        @(negedge clk);

        err = 1;
        modwait = 0;

        transaction(0, 0, 0, 0, 1);
        if(16'h0100 != hrdata) $display("2 byte read new status error at time %0t", $time);
        @(negedge clk);
        transaction(0, 0, 0, 0, 0);
        if(16'h00 != hrdata) $display("addr 0, 1 byte read new status error at time %0t", $time);
        @(negedge clk);
        transaction(0, 1, 0, 0, 0);
        if(16'h0100 != hrdata) $display("addr 1, 1 byte read new status error at time %0t", $time);
        @(negedge clk);

    end
    endtask

    task write_result;
    begin
        transaction(1, 2, 0, 0, 1);
        if(1 != hresp) $display("error write to result 2 byte %0t", $time);
        @(negedge clk);

        transaction(1, 2, 0, 0, 0);
        if(1 != hresp) $display("error write to result 1 byte addr 2 %0t", $time);
        @(negedge clk);

        transaction(1, 3, 0, 0, 0);
        if(1 != hresp) $display("error write to result 1 byte addr 3 %0t", $time);
        @(negedge clk);
    end
    endtask

    task write_status;
    begin
        transaction(1, 0, 0, 0, 1);
        if(1 != hresp) $display("error write to status 2 byte %0t", $time);
        @(negedge clk);

        transaction(1, 0, 0, 0, 0);
        if(1 != hresp) $display("error write to status 1 byte addr 0 %0t", $time);
        @(negedge clk);

        transaction(1, 1, 0, 0, 0);
        if(1 != hresp) $display("error write to status 1 byte addr 1 %0t", $time);
        @(negedge clk);
    end
    endtask

    task write_and_read_coeff; //add use coeffient_num
    begin
        transaction(1, 6, 1, 0, 1);
        @(negedge clk);
        transaction(1, 8, 2, 0, 1);
        @(negedge clk);
        transaction(1, 4'ha, 3, 0, 1);
        @(negedge clk);
        transaction(1, 4'hc, 4, 0, 1);
        @(negedge clk);
        @(negedge clk);

        transaction(0, 6, 1, 0, 1);
        if(16'h01 != hrdata) $display("f0 error at time %0t", $time);
        @(negedge clk);
        transaction(0, 8, 2, 0, 1);
        if(16'h02 != hrdata) $display("f1 error at time %0t", $time);
        @(negedge clk);
        transaction(0, 4'ha, 3, 0, 1);
        if(16'h03 != hrdata) $display("f0 error at time %0t", $time);
        @(negedge clk);
        transaction(0, 4'hc, 4, 0, 1);
        if(16'h04 != hrdata) $display("f0 error at time %0t", $time);
        @(negedge clk);

        transaction(1, 6, 1, 0, 0);
        @(negedge clk);
        transaction(1, 7, 1, 0, 0);
        @(negedge clk);
        transaction(1, 8, 2, 0, 0);
        @(negedge clk);
        transaction(1, 9, 2, 0, 0);
        @(negedge clk);
        transaction(1, 4'ha, 3, 0, 0);
        @(negedge clk);
        transaction(1, 4'hb, 3, 0, 0);
        @(negedge clk);
        transaction(1, 4'hc, 4, 0, 0);
        @(negedge clk);
        transaction(1, 4'hd, 4, 0, 0);
        @(negedge clk);
        @(negedge clk);


        transaction(0, 6, 1, 0, 1);
        if(16'h101 != hrdata) $display("f0 error at time %0t", $time);
        @(negedge clk);
        transaction(0, 8, 2, 0, 1);
        if(16'h202 != hrdata) $display("f1 error at time %0t", $time);
        @(negedge clk);
        transaction(0, 4'ha, 3, 0, 1);
        if(16'h303 != hrdata) $display("f2 error at time %0t", $time);
        @(negedge clk);
        transaction(0, 4'hc, 4, 0, 1);
        if(16'h404 != hrdata) $display("f3 error at time %0t", $time);
        @(negedge clk);

        transaction(0, 6, 1, 0, 0);
        if(16'h01 != hrdata) $display("f0 error at time %0t", $time);
        @(negedge clk);
        transaction(0, 7, 1, 0, 0);
        if(16'h01 != hrdata) $display("f0 error at time %0t", $time);
        @(negedge clk);

        transaction(0, 8, 2, 0, 0);
        if(16'h02 != hrdata) $display("f1 error at time %0t", $time);
        @(negedge clk);
        transaction(0, 9, 2, 0, 0);
        if(16'h02 != hrdata) $display("f1 error at time %0t", $time);
        @(negedge clk);

        transaction(0, 4'ha, 3, 0, 0);
        if(16'h03 != hrdata) $display("f2 error at time %0t", $time);
        @(negedge clk);
        transaction(0, 4'hb, 3, 0, 0);
        if(16'h03 != hrdata) $display("f2 error at time %0t", $time);
        @(negedge clk);

        transaction( 0, 4'hc, 4, 0, 0);
        if(16'h04 != hrdata) $display("f3 error at time %0t", $time);
        @(negedge clk);
        transaction( 0, 4'hd, 4, 0, 0);
        if(16'h04 != hrdata) $display("f3 error at time %0t", $time);
        @(negedge clk);
    end
    endtask

    task write_and_read_new_coeff_set;
    begin

        transaction( 1, 4'he, 9, 0, 1);
        if(1 != hresp) $display("new_coeff_set error at time %0t", $time);
        @(negedge clk);
        @(negedge clk);

        transaction( 1, 4'he, 9, 0, 0);
        @(negedge clk);
        @(negedge clk);

        transaction( 0, 4'he, 9, 0, 0);
        if(16'h09 != hrdata) $display("new_coeff_set error at time %0t", $time);
        @(negedge clk);

        transaction( 0, 4'he, 9, 0, 1);
        if(1 != hresp) $display("new_coeff_set error at time %0t", $time);
        @(negedge clk);
    end
    endtask

    task fir_coeff;
    begin   
        coefficient_num = 0;
        @(negedge clk);
        coefficient_num = 1;
        @(negedge clk);
        coefficient_num = 2;
        @(negedge clk);
        coefficient_num = 3;
        @(negedge clk);
    end
    endtask

    task new_co_set;
    begin
        
    end
    endtask

    string test_name;

    initial begin
        n_rst = 1;

        model_reset = 1'b0;
        enable_transactions = 1'b0;
        enqueue_transaction_en = 1'b0;
        transaction_write = 1'b0;
        transaction_fake = 1'b0;
        transaction_addr = '0;
        transaction_data = '0;
        transaction_error = 1'b0;
        transaction_size = 3'd0;

        err = 0;
        modwait = 0;
        clear_coeff = 0;
        fir_out = 0;
        coefficient_num = 0;

        reset_model();
        reset_dut();

        test_name = "read_result";
        read_result();

        test_name = "write_and_read_new_sample";
        write_and_read_new_sample();

        test_name = "read_status";
        read_status();

        test_name = "write_result";
        write_result();

        test_name = "write_status";
        write_status();

        test_name = "write_and_read_coeff";
        write_and_read_coeff();

        test_name = "write_and_read_new_coeff_set";
        write_and_read_new_coeff_set();

        test_name = "fir_coeff";
        fir_coeff();

        test_name = "RAW";
        enqueue_transaction(1, 1, 6, 1, 0, 1);
        enqueue_transaction(1, 0, 6, 1, 0, 1);
        execute_transactions(2);

        enqueue_transaction(1, 1, 4'he, 1, 0, 1);
        clear_coeff = 1;
        enqueue_transaction(1, 0, 4'he, 1, 0, 1);
        execute_transactions(2);
        
        $finish;
    end
endmodule

/* verilator coverage_on */

