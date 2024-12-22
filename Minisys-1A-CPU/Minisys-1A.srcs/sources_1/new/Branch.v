`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/13 14:24:55
// Design Name: ��֧����ģ�飬�����Ƿ��ڿ���ģ����ģ��������ַ���IDģ��ȽϺ��ʣ�����ֱ�ӷ���Ҫ�ĵ��źŽ϶࣬��˵��г�һ��ģ��ר�Ŵ����֧���
// Module Name: branchprocess
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


module branchprocess(
  input IF_ID_op,//IF/ID�δ����Instruction�ĸ�6λ
  //��������ת
  input Beq,
  input Bne,
  input Bgez,
  input Bgtz,
  input Blez,
  input Bltz,
  input Bgezal,
  input Bltzal,
  //Jָ��
  input Jrn,
  input Jalr,
  input Jmp,
  input Jal,
  //�����źţ�ѡ���ź�
  input CTL_Alusrc,
  input IF_WPC,
  input [1:0] FWD_AluCsrc,//����ת��ģ��
  input [1:0] FWD_AluDsrc,//����ת��ģ��
  input MemorIORead,
  input [31:0] ID_read_data_1,
  input [31:0] ID_read_data_2,
  input [31:0] ID_sign_extend,
  input [31:0] EX_ALU_result,
  input [31:0] MEM_ALU_result,
  input [31:0] MemorIOData,
  input [31:0] Wdata,
  
  output Branch,
  output nBranch,
  output IF_flush,
  output [1:0] Wpc,
  output [31:0] rs_data
);
  //����ֵ
  wire [31:0] rt_data;
  assign rs_data = (FWD_AluCsrc == 2'b00) ? ID_read_data_1 : (FWD_AluCsrc == 2'b01) ? EX_ALU_result : (FWD_AluCsrc == 2'b10) ? ((MemorIORead == 1'b1) ? MemorIOData : MEM_ALU_result) : Wdata;
  assign rt_data = (CTL_Alusrc == 1'b1) ? ID_sign_extend: (FWD_AluDsrc == 2'b00) ? ID_read_data_2 : (FWD_AluDsrc == 2'b01) ? EX_ALU_result : (FWD_AluDsrc == 2'b10) ? ((MemorIORead == 1'b1) ? MemorIOData : MEM_ALU_result) : Wdata;
 //��0��������
 wire Zero,Positive,Negative;
 assign Zero = (rs_data == rt_data);
 assign Negative = rs_data[31];
 assign Positive = (rs_data[31] == 1'b0 && rs_data != 32'd0);
 //��ָ֧������
 assign Branch = IF_ID_op == 6'b000100 || IF_ID_op == 6'b000101 || IF_ID_op == 6'b000001 || IF_ID_op == 6'b000111 || IF_ID_op == 6'b000110 ;
 //��������תʧ��
 assign nBranch = ((Beq && !Zero) || (Bne && Zero) || (Bgez && Negative) || (Bgtz && !Positive) || (Blez && Positive) || (Bltz && !Negative) || (Bgezal && Negative) || (Bltzal && !Negative)) && IF_WPC;
 //��ˮ�߳�ˢ������֧ʧ��ʱ��Ҳ����˵����Ԥ���֧�ܻ�ɹ�
 assign IF_flush = nBranch || Jalr || Jrn || Jmp || Jal;
 //дPC�����
 //Wpc��ֵ
  assign Wpc = (Branch) ? 2'b01 :
               (Jmp || Jal) ? 2'b10 :
               (Jalr || Jrn) ? 2'b11 :
               2'b00;
  
endmodule
