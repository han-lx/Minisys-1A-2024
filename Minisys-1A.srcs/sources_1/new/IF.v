`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/10 16:11:35
// Design Name: CPUȡָ��Ԫ����������PC�ĵ�ַͨ������ģ���е�Wpc������������ʱ��ûʵ�ַ�֧Ԥ��
// Module Name: ifetch32
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


module ifetch32(
   input reset,//��λ�ź� �ߵ�ƽ��Ч
   input clock,//ʱ���ź�
   input Wpc,//����ģ�鴫���дPC�źţ�����ѡ��д�ĸ�PC
   input IF_stall,//�����ź�
   input Wir,//ָ��Ĵ���дʹ�ܣ�ͬʱҲ����PC<=next_PC?
   //����PC��ַ�ļ���
   input [31:0] Jpc,//����ģ�鴫�����תֵ������JMPָ���JALָ�����ת
   input [31:0] read_data_1,//����ģ�鴫���rs�Ĵ�����ֵ������JR��JALRָ�����ת
   input [31:0] ID_Npc,//����ģ�鴫���PC+4��ֵ��ͬ������ѡ�����ļ���
   
   output reg[31:0] PC,//��ǰָ���PCֵ
   output [31:0] opcplus4,//����JAL��JALRָ���ֵ���PC+4�Ѿ�����2λ
   output [31:0] Instruction,//����IF_IDģ���д��IR�Ĵ�����ֵ
   //���ڳ���ROM�Ķ���
   output [13:0] rom_read_addr,//64KB,���ֽڱ�ַ�����ֻ��14λ���ɣ���λ��Ϊ0���������ROM���Ѿ�������λ��д�洢������ע��һ��
   input [31:0] Jpadr,//�ӳ���ROM�ж�ȡ��ָ������
   //�ж��쳣����
   input [31:0] Interrupt_pc,//�жϴ�������λ��
   input recover,//Ϊ1ʱ��ʾ���жϻָ�
   input Wcp0,//Ϊ1ʱдCP0 
   output reg IF_recover//�жϷ���,�Ĵ�������¼״̬
    );
    
    reg [31:0] next_PC;//����ָ��ĵ�ַ
   wire [31:0] pc_plus_4;//�������PC+4��ֵ,����IF_IDģ���NPCֵ
    
    
    assign Instruction = Jpadr;//�ӳ���ROM��ȡ����ָ��
    assign rom_read_addr = PC[15:2];//ָ���ַ�ĵ�2λʼ��Ϊ0���������ʡ��
    assign pc_plus_4 = { PC[31:2] + 1 , 2'b00};//����PC+4��ֵ
    assign opcplus4 = { 2'b00 , pc_plus_4[31:2]};//PC+4��ֵ����2λ
    
    //��ʼ����next_PC��ֵ�����̼���(����2λ��Ľ����
    always @* begin
      if (Wcp0) next_PC = Interrupt_pc >> 2;//���дCP0ʹ�ܣ���ô������жϴ����������ָ��Ϊ�жϴ���������
      else if (Wpc == 2'b01) next_PC = {2'b00 , pc_plus_4[31:2]} + {{16{Instruction[15]}} , Instruction[15:0]};//��ת����
      else if (Wpc == 2'b10) next_PC = Jpc >> 2 ;//JMP��JALָ��
      else if (Wpc == 2'b11) next_PC = read_data_1 >> 2;//JR��JALRָ��
      else next_PC = ID_Npc >> 2;//һ�������PC+4
    end
    
    //ʱ���½���дPC
    always @(negedge clock) begin
      IF_recover = recover;
      if (reset) PC = 32'h00000000;//��λʱPC�ص�ȫ0��ʼֵ
      else if (Wir && IF_stall!=1'b1) PC = next_PC << 2;//���ﻹû������
    end
    
endmodule
