`timescale 1ns / 10ps

module flex_counter #(
    parameter SIZE = 4
) (
    input logic clk,
    input logic n_rst,
    input logic clear,
    input logic count_enable,
    input logic [SIZE-1:0] rollover_val,
    output logic rollover_flag,
    output logic [SIZE-1:0] count_out
);
logic [SIZE-1:0] next_count;
logic next_rollover_flag;

always_comb begin 
    if(clear) begin
        next_count = 0;
    end
    else if (count_enable) begin
        if (count_out >= rollover_val) begin
            next_count = 1;
        end
        else begin
            next_count = count_out + 1;
        end
    end
    else begin
        next_count = count_out;
    end
    next_rollover_flag = (rollover_val == next_count) ? 1'b1 : 1'b0;
end

always_ff @ (posedge clk, negedge n_rst) begin
    if(~n_rst) begin
        count_out <= 0;
        rollover_flag <= 0;
    end
    else begin
        count_out <= next_count;
        rollover_flag <= next_rollover_flag;
    end
end


endmodule

