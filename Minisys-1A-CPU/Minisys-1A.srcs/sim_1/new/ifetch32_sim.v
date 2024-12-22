`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/22 15:44:24
// Design Name: 
// Module Name: ifetch32_sim
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


module ifetch32_sim(

    );
    //input
    reg reset;
    reg clock;
    reg [1:0] Wpc;
    reg EX_stall;
    reg WPC;
    reg [31:0] Jpc;
    reg [31:0] read_data_1;
    reg [31:0] ID_Npc;
    reg [31:0] Jpadr;
    reg [31:0] Interrupt_pc;
    reg recover;
    reg cp0_wen;
    
    //output
    wire [31:0] PC;
    wire [31:0] opcplus4;
    wire [31:0] Instruction;
    wire [13:0] rom_read_addr;
    wire IF_recover;
endmodule
