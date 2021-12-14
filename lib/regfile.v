`include "defines.vh"
module regfile(
    input wire clk,
    input wire [4:0] raddr1,
    output wire [31:0] rdata1,
    input wire [4:0] raddr2,
    output wire [31:0] rdata2,
    
    //LL 数据相关
    input wire pre_ex_w_hi_we,           
    input wire pre_ex_w_lo_we,           
    input wire [31:0] pre_ex_w_hi_i,                
    input wire [31:0] pre_ex_w_lo_i,
    input wire pre_mem_w_hi_we,           
    input wire pre_mem_w_lo_we,           
    input wire [31:0] pre_mem_w_hi_i,                
    input wire [31:0] pre_mem_w_lo_i,
    input wire pre_wb_w_hi_we,           
    input wire pre_wb_w_lo_we,           
    input wire [31:0] pre_wb_w_hi_i,                
    input wire [31:0] pre_wb_w_lo_i,    
     //LL
    input wire w_hi_we,
    input wire w_lo_we,
    input wire r_hi_we,
    input wire r_lo_we,
    input wire [31:0] w_hi_i,
    input wire [31:0] w_lo_i,
    output wire [31:0] hi_out_file,
    output wire [31:0] lo_out_file,
    
    //数据相关ex mem wb
    input wire ex_to_id_we,         
    input wire [31:0] ex_to_id_waddr,     
    input wire [31:0] ex_result,     
    input wire mem_to_id_we,         
    input wire [31:0] mem_to_id_waddr,       
    input wire [31:0] mem_result,             
    input wire wb_to_id_we,
    input wire [31:0] wb_to_id_waddr,
    input wire [31:0] wb_to_id_result,
    input wire we,
    input wire [4:0] waddr,
    input wire [31:0] wdata
);
    reg [31:0] reg_array [31:0];
    reg [31:0] reg_array_hi ;
    reg [31:0] reg_array_lo ;
    // write
    always @ (posedge clk) begin
        if (we && waddr!=5'b0) begin
            reg_array[waddr] <= wdata;
        end
    end
    //write hilo
    always @ (posedge clk) begin
        if (w_hi_we) begin
            reg_array_hi <= w_hi_i;
        end
        if(w_lo_we) begin
            reg_array_lo <= w_lo_i;
        end
    end


    // read out1
    assign rdata1 = (raddr1 == 5'b0) ? 32'b0 :
                    ((raddr1== ex_to_id_waddr) & ex_to_id_we) ? ex_result :
                    ((raddr1== mem_to_id_waddr) & mem_to_id_we) ? mem_result : 
                    ((raddr1== wb_to_id_waddr) & wb_to_id_we) ? wb_to_id_result : reg_array[raddr1];
    // read out2
    assign rdata2 = (raddr2 == 5'b0) ? 32'b0 :
                    ((raddr2== ex_to_id_waddr) & ex_to_id_we) ? ex_result :
                    ((raddr2== mem_to_id_waddr) & mem_to_id_we) ? mem_result : 
                    ((raddr2== wb_to_id_waddr) & wb_to_id_we) ? wb_to_id_result : reg_array[raddr2]; 
    // read hi
    assign hi_out_file = (pre_ex_w_hi_we) ? pre_ex_w_hi_i:
                    (pre_mem_w_hi_we) ? pre_mem_w_hi_i:
                    (pre_wb_w_hi_we) ? pre_wb_w_hi_i :
                    (r_hi_we) ? w_hi_i : 32'b0;
    //read lo
    assign lo_out_file = (pre_ex_w_lo_we) ? pre_ex_w_lo_i:
                    (pre_mem_w_lo_we) ? pre_mem_w_lo_i:
                    (pre_wb_w_lo_we) ? pre_wb_w_lo_i :
                    (r_lo_we) ? w_lo_i :32'b0;
               
          
endmodule