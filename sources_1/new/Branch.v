`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/13 14:24:55
// Design Name: 分支处理模块，本来是放在控制模块里的，后来发现放在ID模块比较合适，由于直接放入要改的信号较多，因此单列出一个模块专门处理分支语句
// Module Name: branchprocess
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


module branchprocess(
  input IF_ID_op,//IF/ID段传入的Instruction的高6位
  //有条件跳转
  input Beq,
  input Bne,
  input Bgez,
  input Bgtz,
  input Blez,
  input Bltz,
  input Bgezal,
  input Bltzal,
  //J指令
  input Jrn,
  input Jalr,
  input Jmp,
  input Jal,
  //控制信号，选择信号
  input CTL_Alusrc,
  input IF_WPC,
  input [1:0] FWD_AluCsrc,//来自转发模块
  input [1:0] FWD_AluDsrc,//来自转发模块
  input MemorIORead,
  input [31:0] ID_read_data_1,
  input [31:0] ID_read_data_2,
  input [31:0] ID_sign_extend,
  input [31:0] EX_ALU_result,
  input [31:0] MEM_ALU_result,
  input [31:0] MemorIOData,
  input [31:0] Wdata,
  
  output Branch,
  output nBranch,
  output IF_flush,
  output [1:0] Wpc,
  output [31:0] rs_data
);
  //传入值
  wire [31:0] rt_data;
  assign rs_data = (FWD_AluCsrc == 2'b00) ? ID_read_data_1 : (FWD_AluCsrc == 2'b01) ? EX_ALU_result : (FWD_AluCsrc == 2'b10) ? ((MemorIORead == 1'b1) ? MemorIOData : MEM_ALU_result) : Wdata;
  assign rt_data = (CTL_Alusrc == 1'b1) ? ID_sign_extend: (FWD_AluDsrc == 2'b00) ? ID_read_data_2 : (FWD_AluDsrc == 2'b01) ? EX_ALU_result : (FWD_AluDsrc == 2'b10) ? ((MemorIORead == 1'b1) ? MemorIOData : MEM_ALU_result) : Wdata;
 //判0，正，负
 wire Zero,Positive,Negative;
 assign Zero = (rs_data == rt_data);
 assign Negative = rs_data[31];
 assign Positive = (rs_data[31] == 1'b0 && rs_data != 32'd0);
 //分支指令的情况
 assign Branch = IF_ID_op == 6'b000100 || IF_ID_op == 6'b000101 || IF_ID_op == 6'b000001 || IF_ID_op == 6'b000111 || IF_ID_op == 6'b000110 ;
 //有条件跳转失败
 assign nBranch = ((Beq && !Zero) || (Bne && Zero) || (Bgez && Negative) || (Bgtz && !Positive) || (Blez && Positive) || (Bltz && !Negative) || (Bgezal && Negative) || (Bltzal && !Negative)) && IF_WPC;
 //流水线冲刷，当分支失败时，也就是说这里预测分支总会成功
 assign IF_flush = nBranch || Jalr || Jrn || Jmp || Jal;
 //写PC的情况
 //Wpc的值
  assign Wpc = (Branch) ? 2'b01 :
               (Jmp || Jal) ? 2'b10 :
               (Jalr || Jrn) ? 2'b11 :
               2'b00;
  
endmodule
