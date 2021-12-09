`include "defines.vh"
module regfile(
    input wire clk,
    input wire [4:0] raddr1,
    output wire [31:0] rdata1,
    input wire [4:0] raddr2,
    output wire [31:0] rdata2,
    input wire [37:0] ex_to_id_bus,
    input wire[37:0] mem_to_id_bus,
    input wire[37:0] wb_to_id_bus,
    input wire we,
    input wire [4:0] waddr,
    input wire [31:0] wdata
);
    reg [31:0] reg_array [31:0];
    // write
    always @ (posedge clk) begin
        if (we && waddr!=5'b0) begin
            reg_array[waddr] <= wdata;
        end
    end

    wire ex_to_id_we;
    wire [4:0] ex_to_id_waddr;
    wire [31:0] ex_result;
    
    wire mem_to_id_we;
    wire [4:0] mem_to_id_waddr;
    wire [31:0] mem_result;
    
    wire wb_to_id_we;
    wire [4:0] wb_to_id_waddr;
    wire [31:0] wb_to_id_result;
    
 
    
    assign {
        ex_to_id_we,          // 37
        ex_to_id_waddr,       // 36:32
        ex_result       // 31:0
    } =  ex_to_id_bus;
    
    assign {
        wb_to_id_we,          // 37
        wb_to_id_waddr,       // 36:32
        wb_to_id_result       // 31:0
    } =  wb_to_id_bus;    
    
    
    assign {
        mem_to_id_we,          // 37
        mem_to_id_waddr,       // 36:32
        mem_result       // 31:0
    } =  mem_to_id_bus;   



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
endmodule