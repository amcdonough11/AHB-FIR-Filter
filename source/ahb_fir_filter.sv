`timescale 1ns / 10ps

module ahb_fir_filter (
    input logic clk,
    input logic n_rst,
    input logic hsel,
    input logic [3:0] haddr,
    input logic hsize,
    input logic [1:0] htrans,
    input logic hwrite,
    input logic [15:0] hwdata,
    output logic [15:0] hrdata,
    output logic hresp
);
    logic [15:0] sample_data, fir_coefficient, fir_out;
    logic data_ready, new_coefficient_set, clear_coeff, modwait, err, load_coeff;
    logic [1:0] coefficient_num;

    ahb_subordinate sub (.clk(clk), .n_rst(n_rst), .sample_data(sample_data), .data_ready(data_ready), .new_coefficient_set(new_coefficient_set), .clear_coeff(clear_coeff), .coefficient_num(coefficient_num), 
    .fir_coefficient(fir_coefficient), .modwait(modwait), .fir_out(fir_out), .err(err), .hsel(hsel), .haddr(haddr), .hsize(hsize), .htrans(htrans), .hwrite(hwrite), .hwdata(hwdata), .hrdata(hrdata), .hresp(hresp));

    fir_filter fir (.clk(clk), .n_rst(n_rst), .sample_data(sample_data), .fir_coefficient(fir_coefficient), .load_coeff(load_coeff), .data_ready(data_ready), .one_k_samples(), .modwait(modwait), .fir_out(fir_out), .err(err));

    coefficient_loader coeff (.clk(clk), .n_rst(n_rst), .new_coefficient_set(new_coefficient_set), .modwait(modwait), .load_coeff(load_coeff), .coefficient_num(coefficient_num), .clear_coeff(clear_coeff));

endmodule

