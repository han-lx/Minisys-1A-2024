`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/13 15:18:38
// Design Name: ��������׶������źţ���ͬʱӰ��PC�Ĵ�����д
// Module Name: stall
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


module stall(
  input EX_MemRead,
  input [4:0] ID_rt,
  input [4:0] ID_rs,
  input [4:0] EX_rt,
  input EX_Mfc0,
  
  output ID_stall,
  output WPC
);
  
  //��������׶η�������Ҫ��2��ʱ�����ڣ��޷�ת����������ֱ�Ӳ��������� 
  assign ID_stall = (EX_MemRead == 1'b1 || EX_Mfc0 == 1'b1) && (ID_rs == EX_rt || ID_rt == EX_rt);
  assign WPC = ~ID_stall;//������ʱ����дPC������������ˮ�߶�Ҫ������
endmodule
