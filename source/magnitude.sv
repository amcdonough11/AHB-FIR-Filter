`timescale 1ns / 10ps

module magnitude (
    input logic [16:0] in,
    output logic [15:0] out
);

always_comb begin

    if (in[16] == 1) begin
        out = ~in[15:0] + 1 ;
    end
    else begin
        out = in[15:0];
    end

end


endmodule

