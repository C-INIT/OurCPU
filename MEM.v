`include "lib/defines.vh"
module MEM(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,

    input wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,
    input wire [31:0] data_sram_rdata,
    output wire [`MEM_TO_ID_WD-1:0]  mem_to_id_bus,
    output wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus
);

    reg [`EX_TO_MEM_WD-1:0] ex_to_mem_bus_r;

    always @ (posedge clk) begin
        if (rst) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        end
        // else if (flush) begin
        //     ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        // end
        else if (stall[3]==`Stop && stall[4]==`NoStop) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        end
        else if (stall[3]==`NoStop) begin
            ex_to_mem_bus_r <= ex_to_mem_bus;
        end
    end

    wire [31:0] mem_pc;
    wire data_ram_en;
    wire [3:0] data_ram_wen;
    wire sel_rf_res;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire [31:0] rf_wdata;
    wire [31:0] ex_result;
    wire [31:0] mem_result;
    wire w_hi_we;       
    wire [31:0] w_hi_i;        
    wire w_lo_we;       
    wire [31:0] w_lo_i;  

    assign {
        w_hi_we,        // 141
        w_hi_i,         // 140:109
        w_lo_we,        // 108
        w_lo_i,         // 107:76
        mem_pc,         // 75:44
        data_ram_en,    // 43
        data_ram_wen,   // 42:39
        sel_rf_res,     // 38
        rf_we,          // 37
        rf_waddr,       // 36:32
        ex_result       // 31:0
    } =  ex_to_mem_bus_r;

    //���lwʱ������mem_resultΪ��ֵ,data_sram_rdataΪ����Ҫ��ֵ����data_sram_rdata�ı���û�õ�
    //������Ҫ������
    assign mem_result = data_sram_rdata;

    //lw��һ��ʱ��Ҫ�޸�ID�ε�sel_rf_res����ʾ��������load������
    assign rf_wdata = sel_rf_res ? mem_result : ex_result;
    //assign rf_wdata = sel_rf_res ? mem_result : ex_result;

    assign mem_to_wb_bus = {
        w_hi_we,    // 135
        w_hi_i,     // 134:103
        w_lo_we,    // 102
        w_lo_i,     // 101:70    
        mem_pc,     // 69:38
        rf_we,      // 37
        rf_waddr,   // 36:32
        rf_wdata    // 31:0
    };
    assign mem_to_id_bus = {
        w_hi_we,    // 103
        w_hi_i,     // 102:71
        w_lo_we,    // 70
        w_lo_i,     // 69:38  
        rf_we,      // 37
        rf_waddr,   // 36:32
        rf_wdata    // 31:0
    };



endmodule