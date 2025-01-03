`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: ShuBo Xue
// 
// Create Date: 2025/01/02 17:01:07
// Design Name: 
// Module Name: PWM
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


module PWM(
    input clock,
    input reset,
    input write_enable,//写信号
    input [15:0] write_data_in,
    input [2:0] address,//到PWM模块的地址低端（此处为30/32/34）
    output reg PWM_output
    );
    reg [15:0] maximum;     // 最大值寄存器（0XFFFFFC30）
    reg [15:0] threshold;   // 对比寄存器（0XFFFFFC32）
    reg [15:0] control;     // 控制寄存器（0XFFFFFC34）
    reg [15:0] counter;     // 计数器
    always @(posedge clock)
        begin
           if (reset == 1) begin
               maximum = 16'hFFFF;//计数器的最大值（默认为 0XFFFF）
               threshold = 16'h7FFF;//对比值（默认为 0X7FFF）
               counter = 16'h0000;
               control = 16'h0000;
               PWM_output = 1'bx;
           end else if (write_enable) begin
               case (address)
                   3'd0: maximum = write_data_in;
                   3'd2: threshold = write_data_in;
                   3'd4: control = write_data_in;
               endcase
           end else if (control[0] == 1) begin         //允许计数,第0位要置1，表示允许PWM出输出波形，其他位清0
               if (counter >= maximum) begin
                   counter = 16'h0000;
                   PWM_output = 1'b1;
               end else begin
                   counter = counter + 1'b1;
                   if (counter > threshold)
                       PWM_output = 1'b0;
                   else
                       PWM_output = 1'b1;
               end
           end else if(control[0]==0) 
                PWM_output = 1'bx;
       end
endmodule
