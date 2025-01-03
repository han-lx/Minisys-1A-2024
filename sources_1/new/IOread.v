`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2025/01/03 20:42:35
// Design Name: 负责将外设数据送入memorio模块可供选择
// Module Name: IOread
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


module IOread(
  input reset,//复位信号
  input ioread,//要读写IO了
  input switchCTL,//拨码开关控制信号
  input [15:0] ioread_data_switch,//来自拨码开关的数据
  input keyboardCTL,//键盘控制信号
  input [15:0] ioread_data_keyboard,//键盘传入的数据
  input timerCTL,//计时器控制信号
  input [15:0] ioread_data_timer,//计时器传入的数据
  
  output reg[15:0] ioread_data//最终传入memorio的数据
  );
    
  always @* begin
    if(reset == 1'b1)begin
      ioread_data = 16'd0;
    end
    else if(ioread == 1'b1)begin
      if(switchCTL == 1'b1)
        ioread_data = ioread_data_switch;
      if(keyboardCTL == 1'b1)
        ioread_data = ioread_data_keyboard;
      if(timerCTL == 1'b1)
        ioread_data = ioread_data_timer;
      else
        ioread_data = ioread_data;
    end
  end
endmodule
