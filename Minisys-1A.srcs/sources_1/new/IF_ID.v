`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/10 17:58:08
// Design Name: IF/ID段间寄存器的设置,段间寄存器有NPC,IR,recover（相较于数据通路图新加的）
// Module Name: IFtoID
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


module IFtoID(
  input clock,//时钟信号
  input reset,//复位信号
  input flush,//清空信号
  input Wir,//写IR寄存器控制信号
  input stall,//为1时阻塞
  input recover,//从中断返回
  
  //段间寄存器的设置
  //NPC寄存器
  input [31:0] IF_opcplus4,//IF阶段得到的当前指令的PC+4值
  output reg [31:0] IF_ID_Npc,//IF/ID段间寄存器NPC
  //IR寄存器
  input [31:0] IF_instruction,//IF阶段取指得到的指令内容
  output reg [31:0] IF_ID_IR,//IF/ID段间寄存器IR
  //recover寄存器
  output reg IF_ID_recover//记录恢复，往下传递，从而恢复当前CPU状态
 );
 
 //时钟下降沿或者reset上升沿（就是reset复位信号有效）时写段间寄存器
  always @(negedge clock or posedge reset) begin
    IF_ID_recover = recover;
    if (reset) begin //复位信号把所有寄存器都复位
       IF_ID_Npc = 32'd0;
       IF_ID_IR = 32'd0;
    end
    else if (flush) begin //冲刷信号同样置0
        IF_ID_Npc = 32'd0;
        IF_ID_IR = 32'd0;
    end
    else if (Wir && stall!=1'b1) begin //写IR寄存器且目前流水线不阻塞
        IF_ID_Npc = IF_opcplus4;//这里注意IF阶段得到的PC+4已经进行了右移2位的操作，这里要恢复过来
        IF_ID_IR = IF_instruction;
    end
  end
endmodule
