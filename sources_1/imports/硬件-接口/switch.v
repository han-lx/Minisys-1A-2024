`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: ShuBo Xue
// 
// Create Date: 2025/01/02 17:04:50
// Design Name: 
// Module Name: switch
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


module switch (
    input			switrst,		// 复位信号
    input			switclk,		// 时钟信号
    input			switchcs,		// 从memorio来的，由低至高位形成的switch片选信号
    input	[1:0]	switchaddr,		// 到switch模块的地址低端
    input			switchread,		// 读信号
    output reg[15:0]switchrdata,	// 送到CPU的拨码开关值注意数据总线只有16根
    input	[23:0]	switch_i		// 从板上读的24位开关数据
);
    always@(posedge switclk or posedge switrst) begin
        if(switrst)
            switchrdata=24'h000000;
        else if(switchcs&&switchread) begin
            if(switchaddr==2'b00)  
                switchrdata[15:0]=switch_i[15:0];
            else if(switchaddr==2'b10) // 0xFFFFC62,24位数据的高8位数据对应红色的RLD
                switchrdata[15:0]={8'd0,switch_i[23:16]};
        end   
    end
endmodule
