`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/13 13:02:32
// Design Name: ת������ģ�顣�������ǳ���������������������ˮ�ߣ������Ҫ����������
//              ������أ�RAW��أ�������أ�PC�Ĵ�����RAW��أ��������Ӧ����ִ��ģ��ļ���srcѡ���źţ�������ѡ��ǰ�����ļĴ���ֵ����ǰ�漸��ָ��Ľ��
// Module Name: forward
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


module forward(
  //���ڷ�ָ֧�����õ������Ĵ�����ֵrs��rt
  input [4:0] ID_rs,
  input [4:0] ID_rt,
  input ID_Mflo,
  input ID_Mfhi,
  //���ڷǷ�ָ֧��õ���������������Դ��EX�׶�
  input [4:0] EX_rs,
  input [4:0] EX_rt,
  input EX_Mflo,
  input EX_Mfhi,
  //
  input ID_EX_RegWrite,
  input [4:0] ID_EX_Waddr,
  input ID_EX_Mtlo,
  input ID_EX_Mthi,
  //
  input EX_MEM_RegWrite,
  input [4:0] EX_MEM_Waddr,
  input EX_MEM_Mtlo,
  input EX_MEM_Mthi,
  input MEM_WB_RegWrite,
  input [4:0] MEM_WB_Waddr,
  input MEM_WB_Mtlo,
  input MEM_WB_Mthi,
  //Mfc0,Mtc0�漰����rd�Ĵ���
  //input [4:0] EX_rd,
  
  output [1:0] AluAsrc,//ѡ���һ������
  output [1:0] AluBsrc,//ѡ��ڶ�������
  output [1:0] AluCsrc,
  output [1:0] AluDsrc,
  output [1:0] AluMsrc//ѡ��д��MEM������
);
  //case1:��ǰָ����Ĵ�����ֵ��������һ��ָ��д�Ĵ������ҵ�ǰָ����ļĴ�������/������ָ����ļĴ���ֵ��ͬ
  //����д���RAW���
  //���ڵ�һ��������˵��AluAsrc 00-�޳�ͻ��01-������ָ���ͻ��10-��������ָ���ͻ
  assign AluAsrc[0] = (EX_MEM_RegWrite && EX_rs == EX_MEM_Waddr)||//��ָͨ��֮��
                      (EX_Mflo && EX_MEM_Mtlo) || (EX_Mfhi && EX_MEM_Mthi);//����ָ���HI/LO������ָ��дHI/IO
  assign AluAsrc[1] = (MEM_WB_RegWrite && EX_rs == MEM_WB_Waddr && !(EX_MEM_RegWrite && EX_rs == EX_MEM_Waddr))||//������ָ���ͻ����������ָ���ͻ����ͬʱ��ͻ����ֻ��Ҫ����������ָ���ͻ���ɣ���Ϊ����ȡ�������µļĴ������ֵ
                      (EX_Mflo && MEM_WB_Mtlo && !EX_MEM_Mtlo) || (EX_Mfhi && MEM_WB_Mthi && !EX_MEM_Mthi);//ͬ��HI/LO�Ĵ���֮��ĳ�ͻ
  //���ڵڶ���������˵��������һ���������ƣ��Ƚϼ򵥵��ǣ����ڹ���HI/LO��дָ���rs��أ�����ֻ��Ҫ���������ۼ��ɣ�����������Ϊ��
  assign AluBsrc[0] = (EX_MEM_RegWrite && EX_rt == EX_MEM_Waddr);
  assign AluBsrc[1] = (MEM_WB_RegWrite && EX_rt == MEM_WB_Waddr && !(EX_MEM_RegWrite && EX_rt == EX_MEM_Waddr));
  //ֻ��Mfc0�漰���˶�rd�Ĵ�����ֵ���������Ҳ�漰����rd�Ĵ�����RAWð�գ�00-�޳�ͻ��ֱ��ѡ��ǰָ����rt��ֵ��01-������ָ���ͻ��10-��������ָ���ͻ
  //assign AluMsrc[0] = (EX_MEM_RegWrite && EX_rd == EX_MEM_Waddr);
  //assign AluMsrc[1] = (MEM_WB_RegWrite && EX_rd == MEM_WB_Waddr && !(EX_MEM_RegWrite && EX_rd == EX_MEM_Waddr));
  
  //case2:������أ�����ָ֧��ִ��ʱ������PCֵ����ת�ᵼ��֮ǰԤȡ��PCֵ��Ч����ˮ��Ҫ�������
  //��ָ֧��Beq,Bne�漰rs��rt�Ĵ����ļ��㣬��Ҫ����ִ��ģ�飬������֧���Ҳ���ý���ִ��ģ�飿
  //00-�޳�ͻ��01-������ָ�����ͻ��10-��������ָ�����ͻ��11-����������ָ�����ͻ
  //����rs�Ĵ���
  assign AluCsrc = ((ID_EX_RegWrite && ID_rs===ID_EX_Waddr) || (ID_Mflo && ID_EX_Mtlo) || (ID_Mfhi && ID_EX_Mthi)) ? 2'b01:
                   ((EX_MEM_RegWrite && ID_rs===EX_MEM_Waddr) || (ID_Mflo && EX_MEM_Mtlo) || (ID_Mfhi && EX_MEM_Mthi)) ? 2'b10:
                   ((MEM_WB_RegWrite && ID_rs===MEM_WB_Waddr) || (ID_Mflo && MEM_WB_Mtlo ) || (ID_Mfhi && MEM_WB_Mthi)) ? 2'b11:
                   2'b00;
  //����rt�Ĵ���
  assign AluDsrc = (ID_EX_RegWrite && ID_rt===ID_EX_Waddr) ? 2'b01:
                   (EX_MEM_RegWrite && ID_rt===EX_MEM_Waddr) ? 2'b10:
                   (MEM_WB_RegWrite && ID_rt===MEM_WB_Waddr) ? 2'b11:
                   2'b00;
endmodule
