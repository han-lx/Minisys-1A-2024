`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/12/22 15:22:53
// Design Name: cpuʱ�ӷ����ļ�
// Module Name: cpuclk_sim
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


module cpuclk_sim(

    );
     //  INPUT
     reg pclk = 0;
     //output
     wire clock1;
     wire clock2;
       
     cpuclk UCLK(
         .clk_in1(pclk),    //100MHz
         .clk_out1(clock1),   //cpu_clk,22
         .clk_out2(clock2)   //upg_clk,10
     );
       
     always #5 pclk = ~pclk;  //5nsһ����ת��һ������10ns����100MHz
endmodule
