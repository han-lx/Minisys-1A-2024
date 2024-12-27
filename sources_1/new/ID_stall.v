`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/13 15:18:38
// Design Name: 产生译码阶段阻塞信号，并同时影响PC寄存器的写
// Module Name: stall
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


module stall(
  input EX_MemRead,
  input [4:0] ID_rt,
  input [4:0] ID_rs,
  input [4:0] EX_rt,
  input EX_Mfc0,
  
  output ID_stall,
  output WPC
);
  
  //由于译码阶段发现数据要跨2个时钟周期，无法转发，因此这边直接采用阻塞法 
  assign ID_stall = (EX_MemRead == 1'b1 || EX_Mfc0 == 1'b1) && (ID_rs == EX_rt || ID_rt == EX_rt);
  assign WPC = ~ID_stall;//不阻塞时才能写PC，否则整个流水线都要被阻塞
endmodule
