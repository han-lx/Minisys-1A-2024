`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/10 17:58:08
// Design Name: IF/ID�μ�Ĵ���������,�μ�Ĵ�����NPC,IR,recover�����������ͨ·ͼ�¼ӵģ�
// Module Name: IFtoID
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


module IFtoID(
  input clock,//ʱ���ź�
  input reset,//��λ�ź�
  input flush,//����ź�
  input Wir,//дIR�Ĵ��������ź�
  input stall,//Ϊ1ʱ����
  input recover,//���жϷ���
  
  //�μ�Ĵ���������
  //NPC�Ĵ���
  input [31:0] IF_opcplus4,//IF�׶εõ��ĵ�ǰָ���PC+4ֵ
  output reg [31:0] IF_ID_Npc,//IF/ID�μ�Ĵ���NPC
  //IR�Ĵ���
  input [31:0] IF_instruction,//IF�׶�ȡָ�õ���ָ������
  output reg [31:0] IF_ID_IR,//IF/ID�μ�Ĵ���IR
  //recover�Ĵ���
  output reg IF_ID_recover//��¼�ָ������´��ݣ��Ӷ��ָ���ǰCPU״̬
 );
 
 //ʱ���½��ػ���reset�����أ�����reset��λ�ź���Ч��ʱд�μ�Ĵ���
  always @(negedge clock or posedge reset) begin
    IF_ID_recover = recover;
    if (reset) begin //��λ�źŰ����мĴ�������λ
       IF_ID_Npc = 32'd0;
       IF_ID_IR = 32'd0;
    end
    else if (flush) begin //��ˢ�ź�ͬ����0
        IF_ID_Npc = 32'd0;
        IF_ID_IR = 32'd0;
    end
    else if (Wir && stall!=1'b1) begin //дIR�Ĵ�����Ŀǰ��ˮ�߲�����
        IF_ID_Npc = IF_opcplus4;//����ע��IF�׶εõ���PC+4�Ѿ�����������2λ�Ĳ���������Ҫ�ָ�����
        IF_ID_IR = IF_instruction;
    end
  end
endmodule
