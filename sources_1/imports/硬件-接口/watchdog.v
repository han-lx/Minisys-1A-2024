`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: ShuBo Xue
// 
// Create Date: 2025/01/02 16:56:49
// Design Name: 
// Module Name: watchdog
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

module watchdog(
    input clock,
    input reset,
    input write_enable,                 // 写信号
    output reg WDT_output               // 通知CPU复位
    );
    reg[15:0]   counter;                //计数器
    reg[2:0]    mini_cnt;               //小计数器，使得复位信号持续4个时钟
    always @(posedge clock) begin
        if (reset == 1) begin
            counter = 16'hFFFF;
            mini_cnt = 3'b000;
            WDT_output = 1'b0;
        end else begin
            if (counter == 16'd0) begin //已经计数到0
                counter = 16'hFFFF;
                mini_cnt = 3'b100;      //向 CPU 发 4 个时钟周期的 RESET 信号
                WDT_output = 1'b1;
            end else
                counter = counter - 1'b1;
            if (mini_cnt == 3'b000)
                WDT_output = 1'b0;
            else
                mini_cnt = mini_cnt - 1'b1;
            if (write_enable) begin
                counter = 16'hFFFF;
                mini_cnt = 3'b000;
                WDT_output = 1'b0;
            end
        end
    end
endmodule
