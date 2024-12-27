`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/12/16 21:11:50
// Design Name: ָ��ROM�����ڴ��ָ���ȡָ��Ĵ洢��
// Module Name: IROM
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


module IROM(
  input ROM_clk_i,//ROM��ʱ���ź�
  input [13:0] rom_read_addr,//����ȡָģ���ֵ�����ڼ�����ǰָ��ĵ�ַ
  output [31:0] Jpadr//ȡ����ָ��
    );
//����������ԭ�������Ĺ���
  instructionROM I_ROM(
        .clka       (ROM_clk_i),
        .wea        (1'b0),
        .addra      (rom_read_addr),
        .dina       (32'h00000000),
        .douta      (Jpadr)
   );
endmodule
