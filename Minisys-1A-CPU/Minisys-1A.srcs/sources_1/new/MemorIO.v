`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/12/17 19:35:20
// Design Name: 这个模块用来选择写/读的对象是IO设备还是存储器
// Module Name: MemorIO
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


module MemorIO(
  input [31:0] ALU_result,//执行阶段计算出的结果
  input CTL_MemRead,//来自控制模块
  input CTL_MemWrite,
  input CTL_IORead,
  input CTL_IOWrite,
  input [31:0] Mem_data,//从存储器中读出的数据
  input [15:0] IO_data,//从IO设备中读出的数据
  input [31:0] write_data,//将要写入存储器或者IO设备的数据
  
  output [31:0] read_data,//从存储器或者IO设备中读出的数据
  output reg[31:0] write_data_o,//写入的数据
  output [31:0] write_address,//写数据的地址
  //接下来是一些外设的控制信号
  output timerCTL,//2个16位定时/计数器
  output keyboardCTL,//4*4键盘控制器
  output digitalTubeCTL,//8位7段数码管
  output buzzerCTL,//蜂鸣器
  output watchdogCTL,//看门狗
  output pwmCTL,//脉冲宽度调制
  output ledCTL,//LED灯
  output switchCTL//switch拨码开关
    );
  
  assign write_address = ALU_result;//ALU的计算结果就是写的地址
  assign read_data = (CTL_MemRead)? Mem_data : {16'h0000, IO_data[15:0]};
  //下面涉及一些IO操作
  wire IO;
  assign IO = (CTL_IORead || CTL_IOWrite);
  
  assign digitalTubeCTL = ((IO) && (ALU_result[31:4] == 28'hFFFFFC0))? 1'b1:1'b0;
  assign keyboardCTL = ((IO) && (ALU_result[31:4] == 28'hFFFFFC1))? 1'b1:1'b0;
  assign timerCTL = ((IO) && (ALU_result[31:4] == 28'hFFFFFC2))? 1'b1:1'b0;
  assign pwmCTL = ((IO) && (ALU_result[31:4] == 28'hFFFFFC3))? 1'b1:1'b0;
  assign watchdogCTL = ((IO) && (ALU_result[31:4] == 28'hFFFFFC5))? 1'b1:1'b0;
  assign ledCTL = ((IO) && (ALU_result[31:4] == 28'hFFFFFC6))? 1'b1:1'b0;
  assign switchCTL = ((IO) && (ALU_result[31:4] == 28'hFFFFFC7))? 1'b1:1'b0;
  assign buzzerCTL = ((IO) && (ALU_result[31:4] == 28'hFFFFFD1))? 1'b1:1'b0;
  
  //这个进程用来写
  always @(*) begin
    if(CTL_MemWrite || CTL_IOWrite) begin
      write_data_o = write_data;
    end
    else begin
      write_data_o = 32'hZZZZZZZZ;
    end
  end
endmodule
