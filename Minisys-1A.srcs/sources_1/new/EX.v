`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/11 18:57:02
// Design Name: CPUִ��ģ�飬������и������㣬HI��LO�Ĵ���Ҳ���������ģ��
// Module Name: executs32
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


module executs32(
  input clock,//ʱ���ź�
  input [31:0] EX_opcplus4,//��ID/EXģ�鴫��PC+4ֵ
  input [31:0] EX_A,//��һ������
  input [31:0] EX_B,//�ڶ�������
  input [31:0] EX_rd_data,//��ID/EXģ�鴫����rd�Ĵ�����ֵ
  input [31:0] EX_IMM,//��������չ�Ľ��
  input [5:0]  EX_func,//������
  input [5:0]  EX_op,//������
  input [4:0]  EX_shamt,//��λ��
  input [4:0]  EX_write_address_0,
  input [4:0]  EX_write_address_1,
  //�ɿ���ģ�����������μ�Ĵ����Ŀ����ź�
  input [1:0] EX_Aluop,
  input EX_Sftmd,
  input EX_Div,
  input EX_Alusrc,//����ѡ��ڶ������������������ǴӼĴ������ж�ȡ������
  //���������ź�����ת������ģ�飨���ڿ���ģ�飩�����ģ����ڽ������ð�յ�һ����
  input [1:0] AluAsrc,//��3��ѡ�����Ƕ�·ѡ�����Ŀ����ź�
  input [1:0] AluBsrc,
  input [1:0] AluFsrc,//Ŀǰ�������������֪������ʲô��
  
  input EX_I_format,
  input EX_Jrn,
  input EX_Jalr,
  input EX_Jal,
  input EX_Regdst,
  //�˳�����أ����г˳���ѡ��ָ�����������
  input EX_Mfhi,
  input EX_Mflo,
  input EX_Mthi,
  input EX_Mtlo,
  //����ת��ѡ�������
  input [31:0] EX_MEM_ALU_result,//��ָ����ǰһ��ָ�����RAWð��ʱ������ֱ�ӽ�ǰһ��ָ���������ת��������������
  input [31:0] Wdata,//����д��Ĵ��������ݣ�����Ҳ����ALU����������Ҳ�����Ǵ�IO����MEM�ж��������ݣ�����ǰָ����������ָ�����RAWð��ʱ�����·ѡ����
  
  output [31:0] rd_data,
  output reg EX_stall,//�����г˳�������ʱ���˳�����ִ�н׶�ռ�ö��ʱ�����ڣ���ʱ��ˮ�����н׶ζ���Ҫ����
  output Zero,//������Ϊ0��������Ƶ�Ԫ
  //output Positive,//rs��ֵΪ��
  //output Negative,//rs��ֵΪ������һ�����Ƿ����ֱ����ǰ������׶Σ�
  output Overflow,//�Ӽ���������
  output reg Div_0,//��0�������׳��쳣
  output [4:0] Waddr,//д�ļĴ�����
  output reg [31:0] EX_ALU_result,//ALU������
  output [31:0] EX_rt_data
  //output [31:0] PC_addr_result//������ķ�ָ֧��ĵ�ַ
);
  
  //����ѡ�񵽵��ĸ�ֵ����ALU���㵥Ԫ���м���
  wire [31:0] A_input,B_input;//������·ѡ������ս���ALU����Ĳ�������
  //û��RAW-00����RAW��������ָ�����ݳ�ͻ-01����RAW����������ָ�����ݳ�ͻ-10
  assign A_input = (AluAsrc == 2'b00) ? EX_A : (AluAsrc == 2'b01) ? EX_MEM_ALU_result : Wdata;
  //�ڶ�������Ҫ���һ����������ѡ��������һ�������ͻ����������͵�һ��������ͬ
  assign B_input = (EX_Alusrc == 1'b1) ? EX_IMM : (AluBsrc == 2'b00) ? EX_B : (AluBsrc == 2'b01) ? EX_MEM_ALU_result : Wdata;
  //ͬʱҪˢ����ˮ���ϵĺ�������õ��ļĴ�����ֵ
  assign EX_rt_data = (AluBsrc == 2'b00) ? EX_B : (AluBsrc == 2'b01) ? EX_MEM_ALU_result : Wdata;
  assign EX_rd_data = (AluFsrc == 2'b00) ? EX_rd_data : (AluFsrc == 2'b01) ? EX_MEM_ALU_result : Wdata;//�����������ת����ʱ��Ӧ�û�����
  
  //case1:������λָ��
  reg [31:0] Sftmd_input;//�����λָ��Ľ��
  wire signed [31:0] S_A_input;//�з�����
  wire signed [31:0] S_B_input;//�з�����
  assign S_A_input = A_input;
  assign S_B_input = B_input;
  
  always @* begin
    if (EX_Sftmd) 
      case (EX_func[2:0])//����λ������ʲôָ��
        3'b000: Sftmd_input = B_input << EX_shamt;//SLL
        3'b010: Sftmd_input = B_input >> EX_shamt;//SRL
        3'b011: Sftmd_input = S_B_input >>> EX_shamt;//SRA
        3'b100: Sftmd_input = B_input << A_input;//SLLV
        3'b110: Sftmd_input = B_input >> A_input;//SRLV
        3'b111: Sftmd_input = S_B_input >>> A_input;//SRAV
        default: Sftmd_input = B_input;
       endcase
     else Sftmd_input = B_input;//��������ʵûɶ��
  end
  
  // case2:��ָ֧����ת��ַ����(�������ò���Ѿ���ȡָģ���Լ������?)
  //assign PC_addr_result = {ID_EX_opcplus4[29:0] , 2'b00} + {ID_EX_IMM[29:0] , 2'b00};
  
  //case3:����/�߼�����,�������˳���
  //�����룺���8������
  wire[2:0] ALU_ctl;//������
  wire[5:0] Exe_code; //������
  //R��ָ�������Ϊ������  
  //I�ͷǴ�ȡ����֧��������Ϊ000+���������λ
  assign Exe_code = (EX_I_format==0) ? EX_func:{3'b000,EX_op[2:0]};
  //000 & and,andi
  assign ALU_ctl = (EX_Aluop == 2'b10) ? Exe_code[2:0] : (EX_Aluop == 2'b01)? 3'b010 :3'b000;
  reg[32:0] Alu_output_mux;
  
  always @* begin
    case(ALU_ctl)
      3'b000: Alu_output_mux = S_A_input + S_B_input;//�з��żӣ�add,addi,L_format,S_format
      3'b001: Alu_output_mux = A_input + B_input;//�޷��żӣ�addu,addiu
      3'b010: Alu_output_mux = S_A_input - S_B_input;//�з��ż���sub,slt,slti,beq,bne
      3'b011: Alu_output_mux = A_input - B_input;//�޷��ż���subu,sltu,sltiu
      3'b100: Alu_output_mux = A_input & B_input;//�룬and,andi
      3'b101: Alu_output_mux = A_input | B_input;//��or,ori
      3'b110: Alu_output_mux = A_input ^ B_input;//ͬ��xor,xori
      3'b111: Alu_output_mux = ~(A_input | B_input);//���nor,lui
      default: Alu_output_mux = 32'd0;
    endcase
  end
   
  //һЩ����Ĵ���
  assign Zero = (Alu_output_mux[31:0] == 32'd0) ? 1'b1 : 1'b0;//���Ϊ0�ź�
  //assign Positive = (EX_A[31] == 0 && EX_A[31:0]!=32'd0);
  //assign Negative = EX_A[31];
  //����ж�
  assign Overflow = (ALU_ctl != 3'b000 && ALU_ctl != 3'b010) ? 1'b0 ://�����з��żӼ�����
         (ALU_ctl == 3'b000) ? (S_A_input[31] == S_B_input[31] && S_A_input[31] != Alu_output_mux[31])://ͬ����ӽ�������෴
         (S_A_input[31] != S_B_input[31] && S_B_input[31] != Alu_output_mux[31]);//��������������������ͬ
endmodule
