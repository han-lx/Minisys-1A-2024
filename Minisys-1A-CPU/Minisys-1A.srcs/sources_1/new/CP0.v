`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/13 15:33:29
// Design Name: Э������CP0���������жϺ��쳣����˵�жϺ��쳣�Ƿŵ�д�ؽ׶ε�
// Module Name: coprocessor0
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


module coprocessor0(
  input reset,//��λ�ź�
  input clock,//ʱ���ź�
  //��֮ǰ�Ľ׶��׳����쳣�ź�
  input OF,//�Ӽ�����쳣
  input Div_0,//��0�쳣
  input Rsvd,//δ����ָ���쳣�������쳣��
  //3����Ȩָ��
  input Mfc0,
  input Mtc0,
  input Eret,
  //2���ж�ָ��
  input Break,
  input Syscall,
  input [5:0] part_of_IM,//��ʾ6���ⲿ�ж�
  input recover,//���жϻָ�����һ��ָ����Eret
  input [31:0] PC,//����EPC
  input [4:0] rd,
  input [31:0] rt_data,
  
  output reg Wcp0,//дЭ������ʹ���ź�
  output reg [31:0] CP0_data_out,
  output reg [31:0] CP0_pc_out
);
  //����һЩ������ź�λ
  wire [4:0] CAUSE_ExcCode;
  reg wen;
  reg [31:0] cp0[0:31];//cp0�е�32���Ĵ���
  reg STATUS_IE;//�ж������ź�
  reg [1:0] STATUS_KSU;//00����̬��10�û�̬
  
  //�ⲿ�жϵ����ȼ���ߣ�����ȿ����ⲿ�ж�
  assign CAUSE_ExcCode = (part_of_IM[0] == 1'b1) ? 5'b00000:
                         (part_of_IM[1] == 1'b1) ? 5'b01101:
                         (part_of_IM[2] == 1'b1) ? 5'b01110:
                         (part_of_IM[3] == 1'b1) ? 5'b01111:
                         (part_of_IM[4] == 1'b1) ? 5'b10000:
                         (part_of_IM[5] == 1'b1) ? 5'b10001:
                         (Break == 1'b1) ? 5'b01001:
                         (Syscall == 1'b1) ? 5'b01000:
                         (Rsvd == 1'b1) ? 5'b01010:
                         (Div_0 == 1'b1) ? 5'b00111:
                         (OF == 1'b1) ? 5'b01100:
                         5'b11111;
  integer i;
  always @(negedge clock) begin
    if(reset) begin//��ʼ���Ĵ�����
      for(i=0;i<32;i=i+1)
        cp0[i] = 32'd0;
      cp0[12][0] = 1'b1;//�ж�ʹ��λIE
      cp0[12][15:10] = 6'b111111;//6���ⲿ�ж϶��У���ʼ����ֵ
    end
    wen = (CAUSE_ExcCode != 5'b11111) && !recover && cp0[12][0];//��ʱ�����жϵ����
    Wcp0 = wen || Eret;//дCPOҪô���жϣ�Ҫô���з��ص�ַ
    if (Mtc0 == 1'b1) begin
      cp0[rd] = rt_data;
    end
    else if (Eret == 1'b1) begin
    //��ǰ��Eret,��ô��һ��״̬��Ҫ���ն˻ָ���
      cp0[12][4:3] = STATUS_KSU;//�ָ����ж�ǰ��״̬����һ�����û�̬��������������һ���Ĵ�������¼�ж�ǰ��KSUֵ
      cp0[12][0] = 1'b1;//IE��1�����е��жϺ��쳣���ܴ���
      CP0_pc_out = cp0[14];//��EPC�л�÷��ص�ַ
    end
    else if (wen == 1'b1) begin
    //�жϷ��������
      cp0[12][0] = 1'b0;//�ж����Σ���ʱר�Ĵ���ǰ�жϣ������쳣���ж϶���ʹ��
      STATUS_KSU = cp0[12][4:3];//�ݴ��жϴ���ǰ��̬
      cp0[12][4:3] = 2'b00;//�������̬�����ж�
      cp0[13][6:2] = CAUSE_ExcCode;//���뵼���жϵ�ԭ��
      cp0[14] = PC;//EPC
      CP0_pc_out = 32'h0000F500;//�����жϴ������
    end
  end
  
  always @(*) begin
    if(reset) begin
      CP0_data_out = 32'd0;
    end
    else begin
      if(Mfc0 == 1'b1) begin//���һ����Ȩָ��Ĵ���
        CP0_data_out = cp0[rd];
      end
    end
  end
endmodule
