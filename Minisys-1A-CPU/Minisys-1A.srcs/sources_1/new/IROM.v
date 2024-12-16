`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/12/16 21:11:50
// Design Name: 指令ROM，用于存放指令并读取指令的存储器
// Module Name: IROM
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


module IROM(
  input ROM_clk_i,//ROM的时钟信号
  input [13:0] rom_read_addr,//来自取指模块的值，用于检索当前指令的地址
  output [31:0] Jpadr//取出的指令
    );
//接下来就是原件例化的过程
  instructionROM I_ROM(
        .clka       (ROM_clk_i),
        .wea        (1'b0),
        .addra      (rom_read_addr),
        .dina       (32'h00000000),
        .douta      (Jpadr)
   );
endmodule
