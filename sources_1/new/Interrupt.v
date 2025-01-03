`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/03 21:25:00
// Design Name: 
// Module Name: Interrupt
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


module Interrupt(
    input   [4:0]   button,             // 五个按钮开关（S1-S5)
    input           keyboardIn,         // 键盘输入线(列线)  
    output  [5:0]   interrupt
    );
   
    assign interrupt[0] = keyboardIn;   // keyboard 优先级最高
    assign interrupt[1] = button[0];    // S1 左
    assign interrupt[2] = button[1];    // S2 右
    assign interrupt[3] = button[2];    // S3 上
    assign interrupt[4] = button[3];    // S4 中
    assign interrupt[5] = button[4];    // S5 下
endmodule
