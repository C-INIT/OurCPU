`include "defines.vh"
//////////////////////////////////////////////////////////////////////////////////
// Author:CLQ
// 
// Create Date: 2021/12/26 13:51:28
// Design Name: 
// Module Name: mul
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mul(
	input wire rst,							//复位
	input wire clk,							//时钟
	input wire signed_mul_i,				//是否为有符号乘法运算，1位有符号
	input wire[31:0] opdata1_i,				//乘数1
	input wire[31:0] opdata2_i,				//乘数2
	input wire start_i,						//是否开始乘法运算
	input wire annul_i,						//是否取消乘法运算，1位取消
	output reg[63:0] result_o,				//乘法运算结果
	output reg ready_o						//乘法运算是否结束	
);
	reg [5:0] cnt;							//记录乘法进行了几轮
	reg [63:0] product;						//移位累加的结果
	reg [1:0] state;						//乘法器处于的状态	
	reg[63:0] multiplicand;					//被乘数，初始值为temp_op1，有移位操作
	reg[31:0] temp_op1;
	reg[31:0] temp_op2;
	
	always @ (posedge clk) begin
		if (rst) begin
			state <= `MulFree;
			result_o <= {`ZeroWord,`ZeroWord};
			ready_o <= `MulResultNotReady;
		end else begin
			case(state)
				`MulFree: begin			//乘法器空闲
					if (start_i == `MulStart && annul_i == 1'b0) begin
						if(opdata1_i == `ZeroWord || opdata2_i == `ZeroWord) begin			//如果任一乘数为0
							state <= `MulByZero;
						end else begin
							state <= `MulOn;					//乘数不为0
							cnt <= 6'b000000;
							if(signed_mul_i == 1'b1 && opdata1_i[31] == 1'b1) begin			//乘数1为负数
								temp_op1 = ~opdata1_i + 1;
							end else begin
								temp_op1 = opdata1_i;
							end
							if (signed_mul_i == 1'b1 && opdata2_i[31] == 1'b1 ) begin		//乘数2为负数
								temp_op2 = ~opdata2_i + 1;
							end else begin
								temp_op2 = opdata2_i;
							end
							product <= {`ZeroWord, `ZeroWord};
							multiplicand <= {32'b0,temp_op1};
						end
					end else begin
						ready_o <= `MulResultNotReady;
						result_o <= {`ZeroWord, `ZeroWord};
					end
				end
				
				`MulByZero: begin			//除数为0
					product <= {`ZeroWord, `ZeroWord};
					state <= `MulEnd;
				end
				
				`MulOn: begin				//乘数不为0
					if(annul_i == 1'b0) begin			//进行乘法运算
						if(cnt != 6'b100000) begin
							if (temp_op2[0] == 1'b1) begin
								product <= product + multiplicand; //如果这个位是1，则加上第一个乘数
							end
							multiplicand = {multiplicand[62:0],1'b0};
							temp_op2 = {1'b0,temp_op2[31:1]};
							cnt <= cnt +1;		//乘法运算次数
						end else begin
							if ((signed_mul_i == 1'b1) && ((opdata1_i[31] ^ opdata2_i[31]) == 1'b1)) begin
								product <= (~product + 1);
							end
							state <= `MulEnd;
							cnt <= 6'b000000;
						end
					end else begin	
						state <= `MulFree;
					end
				end
				
				`MulEnd: begin			//乘法结束
					result_o <= product;
					ready_o <= `MulResultReady;
					if (start_i == `MulStop) begin
						state <= `MulFree;
						ready_o <= `MulResultNotReady;
						result_o <= {`ZeroWord, `ZeroWord};
					end
				end
			endcase
		end
	end


endmodule