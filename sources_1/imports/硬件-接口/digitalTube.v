`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: ShuBo Xue
// 
// Create Date: 2025/01/02 16:49:06
// Design Name: 
// Module Name: digitalTube
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


module digitalTube(
   input clock,
   input reset,
   input write_enable,             // 写信号
   input [15:0] write_data_in,     // 写到数码管的数据
   input [2:0] address,            // 到keyboard模块的地址低端（此处为00/02/04）
   output reg[7:0] enable,        // 8位 位使能 信号A0-A7，低电平有效
   output reg[7:0] value          // 8位 段使能 信号CA-DP，低电平有效
   );
   
   reg [15:0] lowData;             // 低四位数码管数据
   reg [15:0] highData;            // 高四位数码管数据
   reg [15:0] specialDisplay;      // 特殊显示寄存器
   reg [7:0] choose;
   reg [3:0] datatmp;
   reg [6:0] C_out;
   reg DP;
   
   //分频，降低刷新速率，否则会出现显示不全/错误的情况
   reg        refresh;
   reg[15:0]   counter;

   initial begin
        counter = 16'd0;
        refresh = 1'b0;
        lowData = 16'd0;
        highData = 16'd0;
        specialDisplay = 16'd0;
        choose = 8'b00000001;
   end
    
   always @(posedge clock) begin
       if (counter != 16'd0)
           counter = counter - 1'd1;
       else begin
           counter = 16'h0612;
           refresh = ~refresh;
       end
       if (write_enable == 1)
       case (address)
           3'b000: lowData = write_data_in;
           3'b010: highData = write_data_in;
           3'b100: specialDisplay = write_data_in;
       endcase
   end
   
   always @(posedge refresh or posedge reset) begin
       if (reset == 1) begin
           value = 8'hff;
           enable = 8'hff;
           choose = 8'b00000001;
       end else begin
           if(choose==8'b10000000)
               choose=8'b00000001;
           else choose=choose<<1;
           case(choose) // value[0]即DP
               8'b00000001:begin datatmp=lowData[3:0];value[0]=~specialDisplay[0];end
               8'b00000010:begin datatmp=lowData[7:4];value[0]=~specialDisplay[1];end
               8'b00000100:begin datatmp=lowData[11:8];value[0]=~specialDisplay[2];end
               8'b00001000:begin datatmp=lowData[15:12];value[0]=~specialDisplay[3];end
               8'b00010000:begin datatmp=highData[3:0];value[0]=~specialDisplay[4];end
               8'b00100000:begin datatmp=highData[7:4];value[0]=~specialDisplay[5];end
               8'b01000000:begin datatmp=highData[11:8];value[0]=~specialDisplay[6];end
               8'b10000000:begin datatmp=highData[15:12];value[0]=~specialDisplay[7];end
               default:datatmp=4'b0000;
           endcase
           case (datatmp)
               4'b0000: value[7:1] = 7'b0000001;// CA、CB、CC、…、CG,低电平有效
               4'b0001: value[7:1] = 7'b1001111;
               4'b0010: value[7:1] = 7'b0010010;
               4'b0011: value[7:1] = 7'b0000110;
               4'b0100: value[7:1] = 7'b1001100;
               4'b0101: value[7:1] = 7'b0100100;
               4'b0110: value[7:1] = 7'b0100000;
               4'b0111: value[7:1] = 7'b0001111;
               4'b1000: value[7:1] = 7'b0000000;
               4'b1001: value[7:1] = 7'b0000100;
               4'b1010: value[7:1] = 7'b0001000;
               4'b1011: value[7:1] = 7'b1100000;
               4'b1100: value[7:1] = 7'b0110001;
               4'b1101: value[7:1] = 7'b1000010;
               4'b1110: value[7:1] = 7'b0110000;
               4'b1111: value[7:1] = 7'b0111000;
           endcase
           enable=~(choose&specialDisplay[15:8]); // 特殊显示寄存器的高八位表示对应八个数码管要显示，1表示要显示数据
       end
   end
endmodule
