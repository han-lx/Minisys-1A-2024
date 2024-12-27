`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/12/17 19:35:20
// Design Name: ���ģ������ѡ��д/���Ķ�����IO�豸���Ǵ洢��
// Module Name: MemorIO
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


module MemorIO(
  input [31:0] ALU_result,//ִ�н׶μ�����Ľ��
  input CTL_MemRead,//���Կ���ģ��
  input CTL_MemWrite,
  input CTL_IORead,
  input CTL_IOWrite,
  input [31:0] Mem_data,//�Ӵ洢���ж���������
  input [15:0] IO_data,//��IO�豸�ж���������
  input [31:0] write_data,//��Ҫд��洢������IO�豸������
  
  output [31:0] read_data,//�Ӵ洢������IO�豸�ж���������
  output reg[31:0] write_data_o,//д�������
  output [31:0] write_address,//д���ݵĵ�ַ
  //��������һЩ����Ŀ����ź�
  output timerCTL,//2��16λ��ʱ/������
  output keyboardCTL,//4*4���̿�����
  output digitalTubeCTL,//8λ7�������
  output buzzerCTL,//������
  output watchdogCTL,//���Ź�
  output pwmCTL,//�����ȵ���
  output ledCTL,//LED��
  output switchCTL//switch���뿪��
    );
  
  assign write_address = ALU_result;//ALU�ļ���������д�ĵ�ַ
  assign read_data = (CTL_MemRead)? Mem_data : {16'h0000, IO_data[15:0]};
  //�����漰һЩIO����
  wire IO;
  assign IO = (CTL_IORead || CTL_IOWrite);
  
  assign digitalTubeCTL = ((IO) && (ALU_result[31:4] == 28'hFFFFFC0))? 1'b1:1'b0;
  assign keyboardCTL = ((IO) && (ALU_result[31:4] == 28'hFFFFFC1))? 1'b1:1'b0;
  assign timerCTL = ((IO) && (ALU_result[31:4] == 28'hFFFFFC2))? 1'b1:1'b0;
  assign pwmCTL = ((IO) && (ALU_result[31:4] == 28'hFFFFFC3))? 1'b1:1'b0;
  assign watchdogCTL = ((IO) && (ALU_result[31:4] == 28'hFFFFFC5))? 1'b1:1'b0;
  assign ledCTL = ((IO) && (ALU_result[31:4] == 28'hFFFFFC6))? 1'b1:1'b0;
  assign switchCTL = ((IO) && (ALU_result[31:4] == 28'hFFFFFC7))? 1'b1:1'b0;
  assign buzzerCTL = ((IO) && (ALU_result[31:4] == 28'hFFFFFD1))? 1'b1:1'b0;
  
  //�����������д
  always @(*) begin
    if(CTL_MemWrite || CTL_IOWrite) begin
      write_data_o = write_data;
    end
    else begin
      write_data_o = 32'hZZZZZZZZ;
    end
  end
endmodule
