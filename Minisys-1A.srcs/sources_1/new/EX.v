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
         
  //case4:�˳�������
  reg [31:0] HI;//�����32λ
  reg [31:0] LO;//�����32λ
  wire Mult,Multu,Div,Divu;
  assign Mult = (EX_op == 6'b000000 && EX_func == 6'b011000);
  assign Multu = (EX_op == 6'b000000 && EX_func == 6'b011001);
  assign Div = (EX_op == 6'b000000 && EX_func == 6'b011010);
  assign Divu = (EX_op == 6'b000000 && EX_func == 6'b011011);
  wire [63:0] Multi_result_signed;//�з��ų�
  wire [63:0] Multi_result_unsigned;//�޷��ų�
  wire [63:0] Divd_result_signed;//�з��ų�
  wire [63:0] Divd_result_unsigned;//�޷��ų�
  //�з��ų˷���Ԫ������
  mult mult(.A(A_input),
            .B(B_input),
            .P(Multi_result_signed)
            );
  //�޷��ų˷���Ԫ������
  multu multu(.A(A_input),
              .B(B_input),
              .P(Multi_result_unsigned)
              );
  wire div_dout_tvalid;
  wire divu_dout_tvalid;
  wire div_zero;
  wire divu_zero;
  //�з��ų�����Ԫ������
  div div(
    .aclk(clock),
    .s_axis_divisor_tvalid(EX_Div),
    .s_axis_divisor_tdata(B_input),//����
    .s_axis_dividend_tvalid(EX_Div),
    .s_axis_dividend_tdata(A_input),//������
    .m_axis_dout_tvalid(div_dout_tvalid),//�����ɹ����н��
    .m_axis_dout_tuser(div_zero),//��0
    .m_axis_dout_tdata(Divd_result_signed)
   ); 
  //�޷��ų�����Ԫ������
  divu divu(
    .aclk(clock),
    .s_axis_divisor_tvalid(EX_Div),
    .s_axis_divisor_tdata(B_input),//����
    .s_axis_dividend_tvalid(EX_Div),
    .s_axis_dividend_tdata(A_input),//������
    .m_axis_dout_tvalid(divu_dout_tvalid),//�����ɹ����н��
    .m_axis_dout_tuser(divu_zero),//��0
    .m_axis_dout_tdata(Divd_result_unsigned)
   ); 
  //�˳���������ˮ��
  //��ʼ״̬�����ź�Ϊ0
  initial begin
    EX_stall = 1'b0;
  end
  //��Ҫ�Ĵ�������¼ͣ����������ֻ�е���ɲ������ܽ���ˮ�������źŸ�λ
  //�����������ڶԳ˳�����Ҫ��ʱ��������������������������������Ԥ��һ���Ƚϴ��ͣ��������
  reg [5:0] mult_stall;
  reg [5:0] multu_stall;
  reg [5:0] div_stall;
  reg [5:0] divu_stall;
  
  always @(posedge clock) begin
    if(Mult) begin
      mult_stall = mult_stall - 6'd1;
      if (mult_stall > 0) EX_stall = 1'b1;
      else EX_stall = 1'b0;
    end
    else begin
      mult_stall = 6'd10;//���ֵ��ȷ��
    end
    if(Multu) begin
      multu_stall = multu_stall - 6'd1;
      if (multu_stall > 0) EX_stall = 1'b1;
      else EX_stall = 1'b0;
    end
    else begin
      multu_stall = 6'd10;//���ֵ��ȷ��
    end
    if(Div) begin
      div_stall = div_stall - 6'd1;
      if (div_stall > 0) EX_stall = 1'b1;
      else EX_stall = 1'b0;
    end
    else begin
      div_stall = 6'd50;//���ֵ��ȷ��
    end
    if(Divu) begin
      divu_stall = divu_stall - 6'd1;
      if (divu_stall > 0) EX_stall = 1'b1;
      else EX_stall = 1'b0;
    end
    else begin
      divu_stall = 6'd50;//���ֵ��ȷ��
    end
  end
  //֮�󽫳˳����Ľ������HI,LO�Ĵ��������ﻹ����������д�Ĵ�����ָ��
  always @(posedge clock) begin
    if (EX_Mthi)
      HI <= A_input;
    else if (EX_Mtlo)
      LO <= A_input;
    else if (Mult)
      {HI,LO} <= Multi_result_signed;
    else if (Multu)
      {HI,LO} <= Multi_result_unsigned;
    else if (EX_Div) begin//�����������˷���ͬ
      if (Div) begin
        if (div_dout_tvalid)//�����ɹ����ܸ�ֵ
          {HI,LO} <= Divd_result_signed;
        Div_0 <= div_zero;//������Ҫ�׳���0�쳣
      end
      else if (Divu) begin
        if (divu_dout_tvalid)
          {HI,LO} <= Divd_result_unsigned;
        Div_0 <= divu_zero;
      end
    end
  end
  
  //��������������ɼ���֮�󽫽��д��μ�Ĵ����Ĳ���
  always @* begin
    if (EX_Mfhi)
      EX_ALU_result = HI;
    else if (EX_Mflo)
      EX_ALU_result = LO;
    else if ((ALU_ctl == 3'b111) && (EX_I_format == 1'b1))//����luiָ��
      EX_ALU_result = {B_input[15:0] , 16'd0};
    else if ((ALU_ctl [2:1] == 2'b01) && (EX_Aluop[1] == 1'b1) && (Exe_code[5:3] != 3'b100))//SLTϵ��ָ��
      EX_ALU_result = {31'd0 , Alu_output_mux[32]};
    else if (EX_Sftmd)//��λָ��
      EX_ALU_result = Sftmd_input;
    else if (EX_Jal || EX_Jalr)
      EX_ALU_result = EX_opcplus4;
    else
      EX_ALU_result = Alu_output_mux[31:0];
  end
  
endmodule
