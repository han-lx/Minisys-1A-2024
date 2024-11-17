`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/13 00:53:49
// Design Name: д��ģ�飬��ֵ����Ĵ�����
// Module Name: write32
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


module write32(
  input [31:0] MemorIOData,//�Ӵ洢������IO�豸����������
  input [31:0] ALU_result,//ALU��������������
  input [31:0] CP0_data,//CP0Ҫд��Ĵ���������
  input MemIOtoReg,//д�ź�
  input Mfc0,//CP0д�Ĵ���
  
  output [31:0] Wdata//����д������
);

  assign Wdata = (Mfc0===1'b1) ? CP0_data : MemIOtoReg ? MemorIOData : ALU_result;
endmodule
