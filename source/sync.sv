`timescale 1ns / 10ps

module sync #(
    parameter RST_VAL = 1'b0
) (
    input logic clk,
    input logic n_rst,
    input logic async_in,
    output logic sync_out
);
logic ff_out;

always_ff @ ( posedge clk, negedge n_rst )
begin
    if(!n_rst) begin
        ff_out <= RST_VAL;
        sync_out <= RST_VAL;
    end
    else begin
        ff_out <= async_in;
        sync_out <= ff_out;
    end
end

endmodule

