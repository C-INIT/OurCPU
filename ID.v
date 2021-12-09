`include "lib/defines.vh"
module ID(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,
    
    output wire stallreq_for_id,

    input wire [`IF_TO_ID_WD-1:0] if_to_id_bus,
    
    input wire [37:0] ex_to_id_bus,
    
    input wire [37:0] mem_to_id_bus,

    input wire [31:0] inst_sram_rdata,

    input wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus,

    input wire [37:0] wb_to_id_bus,  

    //上一条指令的读写相关操作
    input wire pre_inst_data_sram_en,
    input wire [3:0] pre_inst_data_sram_wen,

    output wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,

    output wire [`BR_WD-1:0] br_bus 
);

    reg [`IF_TO_ID_WD-1:0] if_to_id_bus_r;
    wire [31:0] inst;
    wire [31:0] id_pc;
    wire ce;

    wire wb_rf_we;
    wire [4:0] wb_rf_waddr;
    wire [31:0] wb_rf_wdata;

    //为了保证PC和inst同步，使用inst_reg在出现load读写冲突时储存指令
    //assign inst = inst_sram_rdata;
    //inst暂存器
    reg [31:0] inst_reg;
    reg inst_reg_en;
    always @ (posedge clk) begin
        inst_reg_en <= 1'b0;
        if (rst) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;        
        end
        // else if (flush) begin
        //     ic_to_id_bus <= `IC_TO_ID_WD'b0;
        // end
        else if (stall[1]==`Stop && stall[2]==`NoStop) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;
        end
        else if (stall[1]==`NoStop) begin
            if_to_id_bus_r <= if_to_id_bus;
        end
    end
    
    //为了保证PC和inst同步，使用inst_reg在出现load读写冲突时储存指令
    //assign inst = inst_sram_rdata;
    //inst暂存器 这个定义放上面了
    // reg [31:0] inst_reg;
    // reg inst_reg_en;
    assign inst = inst_reg_en == 1'b0 ? inst_sram_rdata : inst_reg;
    assign {
        ce,
        id_pc
    } = if_to_id_bus_r;
    assign {
        wb_rf_we,
        wb_rf_waddr,
        wb_rf_wdata
    } = wb_to_rf_bus;

    wire [5:0] opcode;
    wire [4:0] rs,rt,rd,sa;
    wire [5:0] func;
    wire [15:0] imm;
    wire [25:0] instr_index;
    wire [19:0] code;
    wire [4:0] base;
    wire [15:0] offset;
    wire [2:0] sel;

    wire [63:0] op_d, func_d;
    wire [31:0] rs_d, rt_d, rd_d, sa_d;

    wire [2:0] sel_alu_src1;
    wire [3:0] sel_alu_src2;
    wire [11:0] alu_op;

    wire data_ram_en;
    wire [3:0] data_ram_wen;
    
    wire rf_we;
    wire [4:0] rf_waddr;
    wire sel_rf_res;
    wire [2:0] sel_rf_dst;

    wire [31:0] rdata1, rdata2;

    regfile u_regfile(
    	.clk    (clk    ),
    	.ex_to_id_bus(ex_to_id_bus),
    	.mem_to_id_bus(mem_to_id_bus),
        .raddr1 (rs ),
        .rdata1 (rdata1 ),
        .raddr2 (rt ),
        .rdata2 (rdata2 ),
        .we     (wb_rf_we     ),
        .waddr  (wb_rf_waddr  ),
        .wdata  (wb_rf_wdata  ),
        .wb_to_id_bus(wb_to_id_bus)
    );

    assign opcode = inst[31:26];
    assign rs = inst[25:21];
    assign rt = inst[20:16];
    assign rd = inst[15:11];
    assign sa = inst[10:6];
    assign func = inst[5:0];
    assign imm = inst[15:0];
    assign instr_index = inst[25:0];
    assign code = inst[25:6];
    assign base = inst[25:21];
    assign offset = inst[15:0];
    assign sel = inst[2:0];

    wire inst_ori, inst_lui, inst_addiu, inst_addu, inst_beq, inst_jr,inst_jal, inst_subu, inst_sll, inst_and, inst_or, inst_lw, inst_sw, inst_xor;
    wire inst_sltu,inst_bne,inst_slt,inst_slti,inst_sltiu,inst_j,inst_srlv,inst_srl,inst_bgtz,inst_add;
    wire op_add, op_sub, op_slt, op_sltu;
    wire op_and, op_nor, op_or, op_xor;
    wire op_sll, op_srl, op_sra, op_lui;

    decoder_6_64 u0_decoder_6_64(
    	.in  (opcode  ),
        .out (op_d )
    );

    decoder_6_64 u1_decoder_6_64(
    	.in  (func  ),
        .out (func_d )
    );
    
    decoder_5_32 u0_decoder_5_32(
    	.in  (rs  ),
        .out (rs_d )
    );

    decoder_5_32 u1_decoder_5_32(
    	.in  (rt  ),
        .out (rt_d )
    );
    
    decoder_5_32 u2_decoder_5_32(
    	.in  (sa  ),
        .out (sa_d )
    );

    
    assign inst_ori     = op_d[6'b00_1101];
    assign inst_lui     = op_d[6'b00_1111] & (rs == 5'b0_0000);
    //assign inst_lui     = op_d[6'b00_1111];
    assign inst_addiu   = op_d[6'b00_1001];
    assign inst_beq     = op_d[6'b00_0100];
    assign inst_subu    = op_d[6'b00_0000] & func_d[6'b10_0011] & (sa == 5'b0_0000);
    assign inst_jr      = op_d[6'b00_0000] & (inst[20:11] == 10'b0_000000000) & (sa == 5'b0_0000) & (func == 6'b00_1000);
    assign inst_jal     = op_d[6'b00_0011];
    assign inst_addu    = op_d[6'b00_0000] & (sa == 5'b0_0000) & (func == 6'b10_0001);
    assign inst_sll = op_d[6'b00_0000] & (rs == 5'b0_0000) & (func == 6'b00_0000);
    assign inst_or = op_d[6'b00_0000] & (sa == 5'b0_0000) & (func == 6'b10_0101);
    assign inst_lw = op_d[6'b10_0011];
    assign inst_sw = op_d[6'b10_1011];
    assign inst_xor = op_d[6'b00_0000] & (sa == 5'b0_0000) & (func == 6'b10_0110);
    assign inst_and = op_d[6'b00_0000] & (sa == 5'b0_0000) & (func == 6'b10_0100);
    assign inst_sltu = op_d[6'b00_0000] & (sa == 5'b0_0000) & (func == 6'b10_1011);
    assign inst_bne = op_d[6'b00_0101];
    assign inst_slt = op_d[6'b00_0000] & (sa == 5'b0_0000) & (func == 6'b10_1010);
    assign inst_slti = op_d[6'b00_1010];
    assign inst_sltiu = op_d[6'b00_1011];
    assign inst_j = op_d[6'b00_0010];
    assign inst_srlv = op_d[6'b00_0000] & (sa == 5'b0_0000) & (func == 6'b00_0110);
    assign inst_srl = op_d[6'b00_0000] & (rs == 5'b0_0000) & (func == 6'b00_0010);
    assign inst_bgtz = op_d[6'b00_0111] & (rt == 5'b00000);
    assign inst_add = op_d[6'b00_0000] & (sa == 5'b0_0000) & (func == 6'b10_0000);
    assign inst_addi = op_d[6'b00_1000];
    assign inst_sub = op_d[6'b00_0000] & (sa == 5'b0_0000) & (func == 6'b10_0010);

    // rs to reg1 指令不一定显示是rs，可能是base寄存器，但对应rs寄存器
    assign sel_alu_src1[0] = inst_ori | inst_addiu | inst_subu | inst_addu | inst_or | inst_lw | inst_sw | inst_xor
        | inst_and | inst_sltu | inst_slt | inst_slti | inst_sltiu | inst_srlv | inst_beq | inst_bne | inst_bgtz
        | inst_add | inst_jr | inst_addi | inst_sub;

    // pc to reg1
    assign sel_alu_src1[1] = inst_jal | inst_j;

    // sa_zero_extend to reg1
    assign sel_alu_src1[2] = inst_sll | inst_srl;

    
    // rt to reg2 不是看到rt就加在这里，有时rt是要存的，而不是读取的，不能加在这里
    assign sel_alu_src2[0] = inst_subu |inst_addu | inst_sll | inst_or | inst_xor | inst_and | inst_sltu
        | inst_slt | inst_srlv | inst_srl | inst_beq | inst_bne | inst_add | inst_sub;
    
    // imm_sign_extend to reg2
    assign sel_alu_src2[1] = inst_lui | inst_addiu | inst_lw | inst_sw | inst_slti | inst_sltiu | inst_addi;

    // 32'b8 to reg2
    assign sel_alu_src2[2] = inst_jal | inst_j;

    // imm_zero_extend to reg2
    assign sel_alu_src2[3] = inst_ori;



    assign op_add = inst_addiu | inst_addu | inst_lw | inst_sw | inst_add | inst_jal | inst_addi;
    assign op_sub = inst_subu | inst_sub;
    assign op_slt = inst_slt | inst_slti;
    assign op_sltu = inst_sltu | inst_sltiu;
    assign op_and = inst_and;
    assign op_nor = 1'b0;
    assign op_or = inst_ori | inst_or;
    assign op_xor = inst_xor;
    assign op_sll = inst_sll;
    assign op_srl = inst_srlv | inst_srl;
    assign op_sra = 1'b0;
    assign op_lui = inst_lui;
    

    assign alu_op = {op_add, op_sub, op_slt, op_sltu,
                     op_and, op_nor, op_or, op_xor,
                     op_sll, op_srl, op_sra, op_lui};


    //和访存有关
    // load and store enable
    assign data_ram_en = inst_lw | inst_sw;

    // write enable 写存储器则传入1111，不是则是0000，调换顺序会报错
    assign data_ram_wen = inst_sw ? 4'b1111:4'b0000;

    //判断是否加气泡
    //要读取的reg1是否与上一条指令存在load相关
    wire stallreq_for_reg1_dataRelate;
    //要读取的reg2是否与上一条指令存在load相关
    wire stallreq_for_reg2_dataRelate;

    // //判断是否加气泡
    // //要读取的reg1是否与上一条指令存在load相关
    // reg stallreq_for_reg1_dataRelate;
    // //要读取的reg2是否与上一条指令存在load相关
    // reg stallreq_for_reg2_dataRelate;

    //上一条指令是否为load
    wire pre_inst_is_load;
    assign pre_inst_is_load = pre_inst_data_sram_en & (pre_inst_data_sram_wen == 4'b0000);

    wire pre_ex_to_id_we;
    wire [4:0] pre_ex_to_id_waddr;
    wire [31:0] pre_ex_result;

    assign {
        pre_ex_to_id_we,          // 37
        pre_ex_to_id_waddr,       // 36:32
        pre_ex_result       // 31:0
    } =  ex_to_id_bus; //主要用前两条判断是否上一条指令在进行load或store操作

    assign stallreq_for_reg1_loadRelate = (rs == pre_ex_to_id_waddr) & sel_alu_src1[0];
    assign stallreq_for_reg2_loadRelate = (rt == pre_ex_to_id_waddr) & sel_alu_src2[0];
    assign stallreq_for_id = (stallreq_for_reg1_loadRelate | stallreq_for_reg2_loadRelate) & pre_inst_is_load;
    // always @ (posedge clk) begin
    //     if((rs == pre_ex_to_id_waddr) & sel_alu_src1[0] == 1'b1)
    //         stallreq_for_reg1_loadRelate <= `Stop;
    //     else
    //         stallreq_for_reg1_loadRelate <= `NoStop;
    //     if((rt == pre_ex_to_id_waddr) & sel_alu_src2[0] == 1'b1)
    //         stallreq_for_reg2_loadRelate <= `Stop;
    //     else
    //         stallreq_for_reg2_loadRelate <= `NoStop;
	// end

    //保证inst和PC同步，inst_reg_en为1，则表示inst_reg里面的需要用
    always @ (stallreq_for_id) begin
        inst_reg <= inst;
        inst_reg_en <= 1'b1;
    end

    // regfile store enable
    assign rf_we = inst_ori | inst_lui | inst_addiu | inst_subu | inst_jal |inst_addu | inst_sll | inst_or | inst_lw
        | inst_xor | inst_and | inst_sltu | inst_slt | inst_slti | inst_sltiu | inst_srlv | inst_srl | inst_add
        | inst_addi | inst_sub;


    // store in [rd]
    assign sel_rf_dst[0] = inst_subu | inst_addu | inst_sll | inst_or | inst_xor | inst_and | inst_sltu
        | inst_slt | inst_srlv | inst_srl | inst_add | inst_sub;
    // store in [rt] 
    assign sel_rf_dst[1] = inst_ori | inst_lui | inst_addiu | inst_lw | inst_slti | inst_sltiu | inst_addi;
    // store in [31]
    assign sel_rf_dst[2] = inst_jal;

    // sel for regfile address
    assign rf_waddr = {5{sel_rf_dst[0]}} & rd 
                    | {5{sel_rf_dst[1]}} & rt
                    | {5{sel_rf_dst[2]}} & 32'd31;

    // 0 from alu_res ; 1 from ld_res
    //assign sel_rf_res = 1'b0; 
    assign sel_rf_res = inst_lw; 

    assign id_to_ex_bus = {
        id_pc,          // 158:127
        inst,           // 126:95
        alu_op,         // 94:83
        sel_alu_src1,   // 82:80
        sel_alu_src2,   // 79:76
        data_ram_en,    // 75
        data_ram_wen,   // 74:71
        rf_we,          // 70
        rf_waddr,       // 69:65
        sel_rf_res,     // 64
        rdata1,         // 63:32
        rdata2          // 31:0
    };


    wire br_e;
    wire jr_e;
    wire [31:0] br_addr;
    wire rs_eq_rt;
    wire rs_ge_z;
    wire rs_gt_z;
    wire rs_le_z;
    wire rs_lt_z;
    wire [31:0] pc_plus_4;
    
    //beq
    assign pc_plus_4 = id_pc + 32'h4;

    assign rs_eq_rt = (rdata1 == rdata2);
    assign rs_gt_z = (rdata1 > 32'b0);

    assign br_e = (inst_beq & rs_eq_rt) | inst_jr | inst_jal | (inst_bne & ~rs_eq_rt) | inst_j | (inst_bgtz & rs_gt_z);
    assign br_addr = (inst_beq | inst_bne | inst_bgtz) ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}):
                    inst_jr ? rdata1 :
                    (inst_jal | inst_j) ? ({id_pc[31:28],inst[25:0],2'b0}) :32'b0;
    


    assign br_bus = {
        br_e,
        br_addr
    };
    


endmodule