`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/10 21:55:09
// Design Name: ID/EX�μ�Ĵ���,��¼����ģ���Լ�����ģ��Ŀ����ź��Լ����ݣ�ֻ�Ǽ򵥴�ֵ����
// Module Name: IDtoEX
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


module IDtoEX(
  //�Ѳ��������롢ȡָģ�飬�Լ����Ƶ�Ԫ�漰�����źŶ��üĴ�������
  input clock,//ʱ���ź�
  input reset,//��λ�ź�
  input flush,//��ˢ�ź�
  input EX_stall,//ȡֵ��Ԫ�����ź�
  input ID_stall,//���뵥Ԫ�����ź�
  input IF_ID_recover,//��ǰһ���μ�Ĵ��������Ļָ��ź�
  input [31:0] ID_opcplus4,//PC+4��ֵ
  input [31:0] IF_ID_PC,//PCֵ
  input [31:0] ID_read_data_1,//������rs�Ĵ�����ֵ
  input [31:0] ID_read_data_2,//������rt�Ĵ�����ֵ
  input [5:0] ID_func,//ָ���ж����Ĺ�����(R)
  input [5:0] ID_op,//ָ���ж����Ĳ�����
  input [4:0] ID_shamt,//ָ���ж�������λ��
  input [31:0] ID_sign_extend,//�����ķ�����չ�����Ҳ����0��չ
  input [4:0] ID_write_address_0,//rt
  input [4:0] ID_write_address_1,//rd
  input [4:0] ID_rs,//rs
  input [31:0] ID_rd_data,
  //����ģ�������ֵ
  input [1:0] CTL_ALUop,
  input CTL_Alusrc,
  input CTL_Regdst,
  input CTL_Sftmd,
  input CTL_Div,
  input CTL_I_format,
  input CTL_S_format,
  input CTL_L_format,
  input CTL_Jrn,
  input CTL_Jalr,
  input CTL_Jmp,
  input CTL_Jal,
  input CTL_RegWrite,
  input CTL_MemIOtoReg,
  input CTL_MemWrite,
  input CTL_MemRead,
  input CTL_IORead,
  input CTL_IOWrite,
  input CTL_Mem_sign,
  input [1:0] CTL_Mem_Dwidth,
  input CTL_Beq,
  input CTL_Bne,
  input CTL_Bgez,
  input CTL_Bgtz,
  input CTL_Blez,
  input CTL_Bltz,
  input CTL_Bgezal,
  input CTL_Bltzal,
  input CTL_Mfhi,
  input CTL_Mflo,
  input CTL_Mfc0,
  input CTL_Mtc0,
  input CTL_Mthi,
  input CTL_Mtlo,
  input CTL_Break,
  input CTL_Syscall,
  input CTL_Eret,
  input CTL_Rsvd,
  
  output reg ID_EX_recover,
  output reg [31:0] ID_EX_opcplus4,
  output reg [31:0] ID_EX_PC,
  output reg [31:0] ID_EX_A,
  output reg [31:0] ID_EX_B,
  output reg [5:0] ID_EX_func,
  output reg [5:0] ID_EX_op,
  output reg [4:0] ID_EX_shamt,
  output reg [31:0] ID_EX_IMM,//��Ӧ����ķ�����չ���
  output reg [4:0] ID_EX_write_address_0,
  output reg [4:0] ID_EX_write_address_1,
  output reg [4:0] ID_EX_rs,
  output reg [31:0] ID_EX_rd_data,
  output reg [1:0] ID_EX_Aluop,
  output reg ID_EX_Alusrc,
  output reg ID_EX_Regdst,
  output reg ID_EX_Sftmd,
  output reg ID_EX_Div,
  output reg ID_EX_I_format,
  output reg ID_EX_S_format,
  output reg ID_EX_L_format,
  output reg ID_EX_Jrn,
  output reg ID_EX_Jalr,
  output reg ID_EX_Jmp,
  output reg ID_EX_Jal,
  output reg ID_EX_RegWrite,
  output reg ID_EX_MemIOtoReg,
  output reg ID_EX_MemWrite,
  output reg ID_EX_MemRead,
  output reg ID_EX_IORead,
  output reg ID_EX_IOWrite,
  output reg ID_EX_Mem_sign,
  output reg [1:0] ID_EX_Mem_Dwidth,
  output reg ID_EX_Beq,
  output reg ID_EX_Bne,
  output reg ID_EX_Bgez,
  output reg ID_EX_Bgtz,
  output reg ID_EX_Blez,
  output reg ID_EX_Bltz,
  output reg ID_EX_Bgezal,
  output reg ID_EX_Bltzal,
  output reg ID_EX_Mfhi,
  output reg ID_EX_Mflo,
  output reg ID_EX_Mfc0,
  output reg ID_EX_Mtc0,
  output reg ID_EX_Mthi,
  output reg ID_EX_Mtlo,
  output reg ID_EX_Break,
  output reg ID_EX_Syscall,
  output reg ID_EX_Eret,
  output reg ID_EX_Rsvd
);
//��ʼ��ֵ
  always @(negedge clock or posedge reset or posedge flush) begin
    ID_EX_recover = IF_ID_recover;
    ID_EX_rd_data = ID_rd_data;
    if (reset || flush) begin  //��λ�ͳ�ˢֱ����0��0Ϊ��ʼֵ
      ID_EX_opcplus4 = 32'd0;
      ID_EX_PC = 32'd0;
      ID_EX_A = 32'd0;
      ID_EX_B = 32'd0;
      ID_EX_func = 6'd0;
      ID_EX_op = 6'd0;
      ID_EX_shamt = 5'd0;
      ID_EX_IMM = 32'd0;
      ID_EX_write_address_0 = 4'd0;
      ID_EX_write_address_1 = 4'd0;
      ID_EX_rs = 5'd0;
      ID_EX_Aluop = 2'd0;
      ID_EX_Alusrc = 1'd0;
      ID_EX_Regdst = 1'd0;
      ID_EX_Sftmd = 1'd0;
      ID_EX_Div = 1'd0;
      ID_EX_I_format = 1'd0;
      ID_EX_S_format = 1'd0;
      ID_EX_L_format = 1'd0;
      ID_EX_Jrn = 1'd0;
      ID_EX_Jalr = 1'd0;
      ID_EX_Jmp = 1'd0;
      ID_EX_Jal = 1'd0;
      ID_EX_RegWrite = 1'd0;
      ID_EX_MemIOtoReg = 1'd0;
      ID_EX_MemWrite = 1'd0;
      ID_EX_MemRead = 1'd0;
      ID_EX_IORead = 1'd0;
      ID_EX_IOWrite = 1'd0;
      ID_EX_Mem_sign = 1'd0;
      ID_EX_Mem_Dwidth = 1'd0;
      ID_EX_Beq = 1'd0;
      ID_EX_Bne = 1'd0;
      ID_EX_Bgez = 1'd0;
      ID_EX_Bgtz = 1'd0;
      ID_EX_Blez = 1'd0;
      ID_EX_Bltz = 1'd0;
      ID_EX_Bgezal = 1'd0;
      ID_EX_Bltzal = 1'd0;
      ID_EX_Mfhi =1'd0;
      ID_EX_Mflo = 1'd0;
      ID_EX_Mthi = 1'd0;
      ID_EX_Mtlo = 1'd0;
      ID_EX_Mfc0 = 1'd0;
      ID_EX_Mtc0 = 1'd0;
      ID_EX_Break = 1'd0;
      ID_EX_Syscall = 1'd0;
      ID_EX_Eret = 1'd0;
      ID_EX_Rsvd = 1'd0;
    end
    else if (ID_stall) begin //��ǰID�׶�������ֻ��֮ǰ��ֵ������������
      ID_EX_opcplus4 = ID_opcplus4;
      ID_EX_PC = IF_ID_PC;
      ID_EX_A = ID_read_data_1;
      ID_EX_B = ID_read_data_2;
      ID_EX_func = ID_func;
      ID_EX_op = ID_op;
      ID_EX_shamt = ID_shamt;
      ID_EX_IMM = ID_sign_extend;
      ID_EX_write_address_0 = ID_write_address_0;
      ID_EX_write_address_1 = ID_write_address_1;
      ID_EX_rs = ID_rs;
      ID_EX_Aluop = 2'd0;
      ID_EX_Alusrc = 1'd0;
      ID_EX_Regdst = 1'd0;
      ID_EX_Sftmd = 1'd0;
      ID_EX_Div = 1'd0;
      ID_EX_I_format = 1'd0;
      ID_EX_S_format = 1'd0;
      ID_EX_L_format = 1'd0;
      ID_EX_Jrn = 1'd0;
      ID_EX_Jalr = 1'd0;
      ID_EX_Jmp = 1'd0;
      ID_EX_Jal = 1'd0;
      ID_EX_RegWrite = 1'd0;
      ID_EX_MemIOtoReg = 1'd0;
      ID_EX_MemWrite = 1'd0;
      ID_EX_MemRead = 1'd0;
      ID_EX_IORead = 1'd0;
      ID_EX_IOWrite = 1'd0;
      ID_EX_Mem_sign = 1'd0;
      ID_EX_Mem_Dwidth = 1'd0;
      ID_EX_Beq = 1'd0;
      ID_EX_Bne = 1'd0;
      ID_EX_Bgez = 1'd0;
      ID_EX_Bgtz = 1'd0;
      ID_EX_Blez = 1'd0;
      ID_EX_Bltz = 1'd0;
      ID_EX_Bgezal = 1'd0;
      ID_EX_Bltzal = 1'd0;
      ID_EX_Mfhi =1'd0;
      ID_EX_Mflo = 1'd0;
      ID_EX_Mthi = 1'd0;
      ID_EX_Mtlo = 1'd0;
      ID_EX_Mfc0 = 1'd0;
      ID_EX_Mtc0 = 1'd0;
      ID_EX_Break = 1'd0;
      ID_EX_Syscall = 1'd0;
      ID_EX_Eret = 1'd0;
      ID_EX_Rsvd = 1'd0;
    end
    else if (EX_stall != 1) begin//ID�β�������ǰ���£�IF��ҲҪ��������������������
      ID_EX_opcplus4 = ID_opcplus4;
      ID_EX_PC = IF_ID_PC;
      ID_EX_A = ID_read_data_1;
      ID_EX_B = ID_read_data_2;
      ID_EX_func = ID_func;
      ID_EX_op = ID_op;
      ID_EX_shamt = ID_shamt;
      ID_EX_IMM = ID_sign_extend;
      ID_EX_write_address_0 = ID_write_address_0;
      ID_EX_write_address_1 = ID_write_address_1;
      ID_EX_rs = ID_rs;  
      ID_EX_Aluop = CTL_ALUop;
      ID_EX_Alusrc = CTL_Alusrc;
      ID_EX_Regdst = CTL_Regdst;
      ID_EX_Sftmd = CTL_Sftmd;
      ID_EX_Div = CTL_Div;
      ID_EX_I_format = CTL_I_format;
      ID_EX_S_format = CTL_S_format;
      ID_EX_L_format = CTL_L_format;
      ID_EX_Jrn = CTL_Jrn;
      ID_EX_Jalr = CTL_Jalr;
      ID_EX_Jmp = CTL_Jmp;
      ID_EX_Jal = CTL_Jal;
      ID_EX_RegWrite = CTL_RegWrite;
      ID_EX_MemIOtoReg = CTL_MemIOtoReg;
      ID_EX_MemWrite = CTL_MemWrite;
      ID_EX_MemRead = CTL_MemRead;
      ID_EX_IORead = CTL_IORead;
      ID_EX_IOWrite = CTL_IOWrite;
      ID_EX_Mem_sign = CTL_Mem_sign;
      ID_EX_Mem_Dwidth = CTL_Mem_Dwidth;
      ID_EX_Beq = CTL_Beq;
      ID_EX_Bne = CTL_Bne;
      ID_EX_Bgez = CTL_Bgez;
      ID_EX_Bgtz = CTL_Bgtz;
      ID_EX_Blez = CTL_Blez;
      ID_EX_Bltz = CTL_Bltz;
      ID_EX_Bgezal = CTL_Bgezal;
      ID_EX_Bltzal = CTL_Bltzal;
      ID_EX_Mfhi = CTL_Mfhi;
      ID_EX_Mflo = CTL_Mflo;
      ID_EX_Mthi = CTL_Mthi;
      ID_EX_Mtlo = CTL_Mtlo;
      ID_EX_Mfc0 = CTL_Mfc0;
      ID_EX_Mtc0 = CTL_Mtc0;
      ID_EX_Break = CTL_Break;
      ID_EX_Syscall = CTL_Syscall;
      ID_EX_Eret = CTL_Eret;
      ID_EX_Rsvd = CTL_Rsvd;
    end
  end
endmodule
