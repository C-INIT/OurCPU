`include "defines.vh"
module regfile(
    input wire clk,
    input wire [4:0] raddr1,
    output wire [31:0] rdata1,
    input wire [4:0] raddr2,
    output wire [31:0] rdata2,
    input wire w_hi_we,           
    input wire w_lo_we,           
    input wire [31:0] w_hi_i,                
    input wire [31:0] w_lo_i,
    input wire hi_read,
    input wire lo_read,
    output wire [31:0] hi_out_file,
    output wire [31:0] lo_out_file,
    input wire [103:0] ex_to_regfile_bus,
    input wire[103:0] mem_to_id_bus,
    input wire[103:0] wb_to_id_bus,
    input wire we,
    input wire [4:0] waddr,
    input wire [31:0] wdata
);
    reg [31:0] reg_array [31:0];
    reg [31:0] reg_array_hi;
    reg [31:0] reg_array_lo;
    // write
    always @ (posedge clk) begin
        if (we && waddr!=5'b0) begin
            reg_array[waddr] <= wdata;
        end
    end
    always @ (posedge clk) begin
        if (w_hi_we) begin
            reg_array_hi <= w_hi_i;
        end
    end
    always @ (posedge clk) begin
        if (w_lo_we) begin
            reg_array_lo <= w_lo_i;
        end
    end
    wire ex_to_id_we;
    wire [4:0] ex_to_id_waddr;
    wire [31:0] ex_result;
    wire ex_w_hi_we;           
    wire ex_w_lo_we;           
    wire [31:0] ex_w_hi_i;                
    wire [31:0] ex_w_lo_i;
    
    wire mem_to_id_we;
    wire [4:0] mem_to_id_waddr;
    wire [31:0] mem_result;
    wire mem_w_hi_we;           
    wire mem_w_lo_we;           
    wire [31:0] mem_w_hi_i;                
    wire [31:0] mem_w_lo_i;
    
    wire wb_to_id_we;
    wire [4:0] wb_to_id_waddr;
    wire [31:0] wb_to_id_result;
    wire wb_w_hi_we;           
    wire wb_w_lo_we;           
    wire [31:0] wb_w_hi_i;                
    wire [31:0] wb_w_lo_i; 
  




    
    assign {
        ex_w_hi_we,        // 103
        ex_w_hi_i,         // 102:71
        ex_w_lo_we,        // 70
        ex_w_lo_i,         // 69:38  
        ex_to_id_we,          // 37
        ex_to_id_waddr,       // 36:32
        ex_result       // 31:0
    } =  ex_to_regfile_bus;

    assign {
        mem_w_hi_we,    // 103
        mem_w_hi_i,     // 102:71
        mem_w_lo_we,    // 70
        mem_w_lo_i,     // 69:38
        mem_to_id_we,          // 37
        mem_to_id_waddr,       // 36:32
        mem_result       // 31:0
    } =  mem_to_id_bus;   
    
    assign {
        wb_w_hi_we,    
        wb_w_hi_i,     
        wb_w_lo_we,    
        wb_w_lo_i,
        wb_to_id_we,          // 37
        wb_to_id_waddr,       // 36:32
        wb_to_id_result       // 31:0
    } =  wb_to_id_bus;    



    // read out 1
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
    assign hi_out_file = (ex_w_hi_we) ? ex_w_hi_i:
                    (mem_w_hi_we) ? mem_w_hi_i:
                    (wb_w_hi_we) ? wb_w_hi_i :
                    reg_array_hi;
    //read lo
    assign lo_out_file = (ex_w_lo_we) ? ex_w_lo_i:
                    (mem_w_lo_we) ? mem_w_lo_i:
                    (wb_w_lo_we) ? wb_w_lo_i :
                    reg_array_lo;                  
endmodule