`timescale 1ns / 10ps

module ahb_subordinate (
    input logic clk,
    input logic n_rst,
    output logic [15:0] sample_data,
    output logic data_ready,
    output logic new_coefficient_set,
    input logic clear_coeff,
    input logic [1:0] coefficient_num,
    output logic [15:0] fir_coefficient,
    input logic modwait,
    input logic [15:0] fir_out,
    input logic err,
    input logic hsel,
    input logic [3:0] haddr,
    input logic hsize,
    input logic [1:0] htrans,
    input logic hwrite,
    input logic [15:0] hwdata,
    output logic [15:0] hrdata,
    output logic hresp
);

typedef enum logic [1:0] {HOLD1, HOLD2, IDLE} state_t;

state_t state, next_state;

logic last_hwrite, last_hsize;
logic [3:0] last_haddr;
logic [1:0] last_htrans;

logic [15:0] results_reg, status_reg, new_sample_reg, F0_reg, F1_reg, F2_reg, F3_reg, new_coeff_set_reg;
logic [15:0] next_new_sample_reg, next_F0_reg, next_F1_reg, next_F2_reg, next_F3_reg, next_new_coeff_set_reg, next_hrdata;
always_ff @( posedge clk, negedge n_rst ) begin
    if(~n_rst)begin
        new_sample_reg <= 0;
        F0_reg <= 0;
        F1_reg <= 0;
        F2_reg <= 0;
        F3_reg <= 0;
        new_coeff_set_reg <= 0;
        hrdata <=0;
    end
    else begin
        new_sample_reg <= next_new_sample_reg;
        F0_reg <= next_F0_reg;
        F1_reg <= next_F1_reg;
        F2_reg <= next_F2_reg;
        F3_reg <= next_F3_reg;
        new_coeff_set_reg <= next_new_coeff_set_reg;
        hrdata <= next_hrdata;
    end
end


//set reg and hwdata
always_comb begin
    next_F0_reg = F0_reg;
    next_F1_reg = F1_reg;
    next_F2_reg = F2_reg;
    next_F3_reg = F3_reg;
    next_new_sample_reg = new_sample_reg;
    next_new_coeff_set_reg = new_coeff_set_reg;
    hresp = 0;
    next_hrdata = 0;
    case(hsel)
        0: begin 
            next_hrdata = 0;
        end
        1:begin 
            if(htrans == 2) begin //ADDRESS
                if(~hwrite) begin 
                    case(hsize)
                        0: begin
                            case(haddr)
                                4'h0: next_hrdata[7:0] = status_reg[7:0];
                                4'h1: next_hrdata[15:8] = status_reg[15:8];
                                4'h2: next_hrdata[7:0] = results_reg[7:0];
                                4'h3: next_hrdata[15:8] = results_reg[15:8];
                                4'h4: next_hrdata[7:0] = new_sample_reg[7:0];
                                4'h5: next_hrdata[15:8] = new_sample_reg[15:8];
                                4'h6: next_hrdata[7:0] = F0_reg[7:0];
                                4'h7: next_hrdata[15:8] = F0_reg[15:8];
                                4'h8: next_hrdata[7:0] = F1_reg[7:0];
                                4'h9: next_hrdata[15:8] = F1_reg[15:8];
                                4'hA: next_hrdata[7:0] = F2_reg[7:0];
                                4'hB: next_hrdata[15:8] = F2_reg[15:8];
                                4'hC: next_hrdata[7:0] = F3_reg[7:0];
                                4'hD: next_hrdata[15:8] = F3_reg[15:8];
                                4'hE: next_hrdata[7:0] = new_coeff_set_reg[7:0];
                                default: hresp = 1;
                            endcase
                        end
                        1: begin
                            case(haddr)
                                4'h0: next_hrdata = status_reg;
                                4'h2: next_hrdata = results_reg;
                                4'h4: next_hrdata = new_sample_reg;
                                4'h6: next_hrdata = F0_reg;
                                4'h8: next_hrdata = F1_reg;
                                4'hA: next_hrdata = F2_reg;
                                4'hC: next_hrdata = F3_reg;
                                default: hresp = 1;
                            endcase
                        end
                        default: hresp = 1;
                    endcase
                end
                else begin
                        case(haddr)
                            4'h4: hresp = 0;
                            4'h5: hresp = 0;
                            4'h6: hresp = 0;
                            4'h7: hresp = 0;
                            4'h8: hresp = 0;
                            4'h9: hresp = 0;
                            4'hA: hresp = 0;
                            4'hB: hresp = 0;
                            4'hC: hresp = 0;
                            4'hD: hresp = 0;
                            4'hE: hresp = 0;
                            default: hresp = 1;
                        endcase
                end
            end
            if(last_htrans == 2) begin
                if(last_hwrite) begin
                        case(last_hsize)
                            0: begin
                                case(last_haddr)
                                    4'h4: next_new_sample_reg[7:0] = hwdata[7:0];
                                    4'h5: next_new_sample_reg[15:8] = hwdata[15:8];
                                    4'h6: next_F0_reg[7:0] = hwdata[7:0];
                                    4'h7: next_F0_reg[15:8] = hwdata[15:8];
                                    4'h8: next_F1_reg[7:0] = hwdata[7:0];
                                    4'h9: next_F1_reg[15:8] = hwdata[15:8];
                                    4'hA: next_F2_reg[7:0] = hwdata[7:0];
                                    4'hB: next_F2_reg[15:8] = hwdata[15:8];
                                    4'hC: next_F3_reg[7:0] = hwdata[7:0];
                                    4'hD: next_F3_reg[15:8] = hwdata[15:8];
                                    4'hE: next_new_coeff_set_reg[7:0] = hwdata[7:0];
                                    default: hresp = 0;
                                endcase
                            end
                            1: begin
                                case(last_haddr)
                                    4'h4: begin
                                        next_new_sample_reg[7:0] = hwdata[7:0];
                                        next_new_sample_reg[15:8] = hwdata[15:8];
                                    end
                                    4'h6: begin
                                        next_F0_reg[7:0] = hwdata[7:0];
                                        next_F0_reg[15:8] = hwdata[15:8];
                                    end
                                    4'h8: begin
                                        next_F1_reg[7:0] = hwdata[7:0];
                                        next_F1_reg[15:8] = hwdata[15:8];
                                    end
                                    4'hA: begin
                                        next_F2_reg[7:0] = hwdata[7:0];
                                        next_F2_reg[15:8] = hwdata[15:8];
                                    end
                                    4'hC: begin
                                        next_F3_reg[7:0] = hwdata[7:0];
                                        next_F3_reg[15:8] = hwdata[15:8];
                                    end
                                    4'hE: begin
                                        next_new_coeff_set_reg[7:0] = hwdata[7:0];
                                    end
                                    default: hresp = 0;
                                endcase
                            end

                        endcase
                end
            end
        end
        default: begin 
            next_hrdata = 0;
        end
    endcase
    if(hsel && htrans == 2 && ~hwrite && last_hwrite && hsize == last_hsize && last_haddr == haddr) begin
        next_hrdata = hwdata;
    end
    if(clear_coeff) next_new_coeff_set_reg = 0; //wrong logic

end

//fir_coefficient
always_comb begin
    case(coefficient_num) 
        0: fir_coefficient = F0_reg;
        1: fir_coefficient = F1_reg;
        2: fir_coefficient = F2_reg;
        3: fir_coefficient = F3_reg;
        default: fir_coefficient = 0;
    endcase
    /*else if (hsel && hwrite && (htrans == 2'b10) && haddr == 3) begin
        next_new_coeff_set_reg = 16'b1;
    end
    */
end

//assign
assign results_reg = fir_out;
assign status_reg = {7'b0, err, 7'b0, modwait || new_coefficient_set};
assign sample_data = new_sample_reg;
assign new_coefficient_set = new_coeff_set_reg[0];

//data_ready
always_comb begin
    data_ready = 0;
    next_state = state;
    if(hsel && (htrans == 2) && hwrite && ((haddr == 4) || (haddr == 5))) begin
        data_ready = 0;
        next_state = HOLD1;
    end
    else if(state == HOLD1) begin
        data_ready = 1;
        next_state = HOLD2;
    end
    else if(state == HOLD2) begin
        data_ready = 1;
        next_state = IDLE;
    end
    else begin
        data_ready = 0;
        next_state = IDLE;
    end
end

always_ff @( posedge clk, negedge n_rst ) begin
    if(~n_rst) begin
        state <= IDLE;
    end
    else begin
        state <= next_state;
    end
    
end

//RAW HAZARD
always_ff @( posedge clk, negedge n_rst ) begin
    if(~n_rst) begin
        last_haddr <= 0;
        last_hwrite <= 0;
        last_hsize <= 0;
        last_htrans <= 0;
    end
    else begin
        last_haddr <= haddr;
        last_hwrite <= hwrite;
        last_hsize <= hsize;
        last_htrans <= htrans;
    end
end


endmodule

