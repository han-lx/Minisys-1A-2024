`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: ShuBo Xue
// 
// Create Date: 2025/01/02 17:03:02
// Design Name: 
// Module Name: LED
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


module LED (
    input			ledrst,		// 复位信号
    input			led_clk,	// 时钟信号
    input			ledwrite,	// 写信号
    input			ledcs,		// 从memorio来的，由低至高位形成的LED片选信号   !!!!!!!!!!!!!!!!!
    input	[1:0]	ledaddr,	// 到LED模块的地址低端  !!!!!!!!!!!!!!!!!!!!
    input	[15:0]	ledwdata,	// 写到LED模块的数据，注意数据线只有16根
    output reg[23:0]ledout		// 向板子上输出的24位LED信号
);
    
    always@(posedge led_clk or posedge ledrst) begin
        if(ledrst)
            ledout=24'h000000;
        else if(ledcs&&ledwrite) begin
            if(ledaddr==2'b00)  // 0xFFFFC60,24位数据的低8位数据对应绿色的GLD,次低8位数据对应黄色的YLD
                ledout[15:0]=ledwdata;
            else if(ledaddr==2'b10) // 0xFFFFC62,24位数据的高8位数据对应红色的RLD
                ledout[23:16]=ledwdata[7:0];
        end
    end
endmodule
