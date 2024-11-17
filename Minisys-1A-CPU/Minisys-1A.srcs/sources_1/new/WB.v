`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/13 00:53:49
// Design Name: 写回模块，将值传入寄存器组
// Module Name: write32
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


module write32(
  input [31:0] MemorIOData,//从存储器或者IO设备读出的数据
  input [31:0] ALU_result,//ALU运算器的运算结果
  input [31:0] CP0_data,//CP0要写入寄存器的数据
  input MemIOtoReg,//写信号
  input Mfc0,//CP0写寄存器
  
  output [31:0] Wdata//最终写的数据
);

  assign Wdata = (Mfc0===1'b1) ? CP0_data : MemIOtoReg ? MemorIOData : ALU_result;
endmodule
