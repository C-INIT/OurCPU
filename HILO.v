`include "lib/defines.vh"
module HILO(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [31:0] w_hi_i,
    input wire [31:0] w_lo_i,
    output reg [31:0] r_hi_o,
    output reg [31:0] r_lo_o
    );
    
    always @ (posedge clk) begin 
        if (rst) begin 
            r_hi_o <= 32'b0;
            r_lo_o <= 32'b0 ;
        end 
        else if (we) begin 
            r_hi_o <= w_hi_i;
            r_lo_o <= w_lo_i;
        end
    end 
    
    
endmodule
