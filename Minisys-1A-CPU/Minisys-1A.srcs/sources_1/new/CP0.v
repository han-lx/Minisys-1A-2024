`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/13 15:33:29
// Design Name: 协处理器CP0，负责处理中断和异常，有说中断和异常是放到写回阶段的
// Module Name: coprocessor0
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


module coprocessor0(
  input reset,//复位信号
  input clock,//时钟信号
  //由之前的阶段抛出的异常信号
  input OF,//加减溢出异常
  input Div_0,//除0异常
  input Rsvd,//未定义指令异常（保留异常）
  //3条特权指令
  input Mfc0,
  input Mtc0,
  input Eret,
  //2条中断指令
  input Break,
  input Syscall,
  input [5:0] part_of_IM,//表示6个外部中断
  input recover,//从中断恢复，上一条指令是Eret
  input [31:0] PC,//传入EPC
  input [4:0] rd,
  input [31:0] rt_data,
  
  output reg Wcp0,//写协处理器使能信号
  output reg [31:0] CP0_data_out,
  output reg [31:0] CP0_pc_out
);
  //定义一些特殊的信号位
  wire [4:0] CAUSE_ExcCode;
  reg wen;
  reg [31:0] cp0[0:31];//cp0中的32个寄存器
  reg STATUS_IE;//中断屏蔽信号
  reg [1:0] STATUS_KSU;//00核心态，10用户态
  
  //外部中断的优先级最高，因此先考虑外部中断
  assign CAUSE_ExcCode = (part_of_IM[0] == 1'b1) ? 5'b00000:
                         (part_of_IM[1] == 1'b1) ? 5'b01101:
                         (part_of_IM[2] == 1'b1) ? 5'b01110:
                         (part_of_IM[3] == 1'b1) ? 5'b01111:
                         (part_of_IM[4] == 1'b1) ? 5'b10000:
                         (part_of_IM[5] == 1'b1) ? 5'b10001:
                         (Break == 1'b1) ? 5'b01001:
                         (Syscall == 1'b1) ? 5'b01000:
                         (Rsvd == 1'b1) ? 5'b01010:
                         (Div_0 == 1'b1) ? 5'b00111:
                         (OF == 1'b1) ? 5'b01100:
                         5'b11111;
  integer i;
  always @(negedge clock) begin
    if(reset) begin//初始化寄存器组
      for(i=0;i<32;i=i+1)
        cp0[i] = 32'd0;
      cp0[12][0] = 1'b1;//中断使能位IE
      cp0[12][15:10] = 6'b111111;//6种外部中断都有，初始化的值
    end
    wen = (CAUSE_ExcCode != 5'b11111) && !recover && cp0[12][0];//此时是有中断的情况
    Wcp0 = wen || Eret;//写CPO要么是中断，要么是有返回地址
    if (Mtc0 == 1'b1) begin
      cp0[rd] = rt_data;
    end
    else if (Eret == 1'b1) begin
    //当前是Eret,那么下一个状态就要从终端恢复了
      cp0[12][4:3] = STATUS_KSU;//恢复到中断前的状态，不一定是用户态，所以这里用了一个寄存器来记录中断前的KSU值
      cp0[12][0] = 1'b1;//IE置1，所有的中断和异常才能触发
      CP0_pc_out = cp0[14];//从EPC中获得返回地址
    end
    else if (wen == 1'b1) begin
    //中断发生的情况
      cp0[12][0] = 1'b0;//中断屏蔽，此时专心处理当前中断，其余异常和中断都不使能
      STATUS_KSU = cp0[12][4:3];//暂存中断处理前的态
      cp0[12][4:3] = 2'b00;//进入核心态处理中断
      cp0[13][6:2] = CAUSE_ExcCode;//传入导致中断的原因
      cp0[14] = PC;//EPC
      CP0_pc_out = 32'h0000F500;//进入中断处理程序
    end
  end
  
  always @(*) begin
    if(reset) begin
      CP0_data_out = 32'd0;
    end
    else begin
      if(Mfc0 == 1'b1) begin//最后一条特权指令的处理
        CP0_data_out = cp0[rd];
      end
    end
  end
endmodule
