`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/09 13:55:19
// Design Name: CPU���Ƶ�Ԫ��ֻ���������źŵĴ���������ð�մ���
// Module Name: control32
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


module control32(
   input [31:0] Instruction,
   input s_format,//��������ָ��
   input l_format,//ȡ������ָ��
   input [21:0] Alu_resultHigh,
   input Zero,//Ϊ�����������תָ��
   input [31:0] read_data_1,//Ϊ�����������תָ����ж�
   input clock,//������״̬�任
   input reset,//��λ�ź�
   
   output Regdst,//Ŀ��Ĵ�����1Ϊrd��0Ϊrt
   output Alusrc,//????����ʺţ�������ô����
   output MemIOtoReg,//�Ӵ洢����IO�豸ȡ���ݵ��Ĵ���
   output RegWrite,//д�Ĵ���
   output MemWrite,//д�洢��
   output MemRead,//���洢��
   output IORead,//IO��
   output IOWrite,//IOд
   output Wir,//Ϊ1дIR�Ĵ���
   output Waluresult,//Ϊ1дALU_result�Ĵ���
   //��������תָ��
   output Jmp,//Jmpָ��
   output Jal,//Jalָ��
   output Jalr,//Jalrָ�Minisys-1A�¼�
   output Jrn,//Jrnָ��
   //������תָ��
   output [1:0] Wpc,//������תָ����ж��ڿ���ģ�����
   output Beq,
   output Bne,
   output Bgez,
   output Bgtz,
   output Blez,
   output Bltz,
   output Bgezal,//д$31
   output Bltzal,//д$31
   //�����Ĵ������ָ��
   output Mfhi,//MFHIָ��
   output Mflo,//MFLOָ��
   output Mfc0,//MFC0ָ��
   output Mthi,//MTHIָ��
   output Mtlo,//MTLOָ��
   output Mtc0,//MTC0ָ��
   //�����ź�
   output I_format,//��ָ��Ϊ����������ת������ȡ�������ָ��
   output S_format,//��ָ��Ϊ�洢��дϵ��ָ��
   output L_format,//��ָ��Ϊ�洢����ϵ��ָ��
   output Sftmd,//��ָ��Ϊ��λϵ��ָ��
   output Div,//��ָ��Ϊ����ָ��������ֳ˳���
   output [1:0] ALUop,//��R-���ͻ�I_format=1ʱλ1Ϊ1, ������תָ����λ0Ϊ1
   output Mem_sign,//�ֽڣ�����ָ����������չ
   output [1:0] Mem_Dwidth,//��д�洢��������λ���������������2λ
   //�쳣�ж�����ź�
   output Break,//BREAKָ��
   output Syscall,//SYSCALLָ��
   output Eret,//ERETָ��
   output Rsvd//����ָ��
 );
   //״̬��״̬����
   reg[2:0] state;
   reg[2:0] next_state;
   parameter[2:0] sinit = 3'b000,
                    sif = 3'b001,
                    sid = 3'b010,
                    sex = 3'b011,
                    smem = 3'b100,
                    swb = 3'b101;
    //ָ���ȡ
    wire R_format;//R��ָ�������
    wire [5:0] op,func;//R��ָ����еĹ����룬�Լ�����ָ��Ĳ�����
    wire[4:0]   rs,rt;
    assign op = Instruction[31:26];
    assign func = Instruction[5:0];
    assign rs = Instruction[25:21];
    assign rt = Instruction[20:16];
    //R����ָ��
    assign R_format = (op==6'b000000|| op==6'b010000);//����MFC0,MTC0,ERET
    assign Jrn = (op==6'b000000&&func==6'b001000);
    assign Jalr = (op==6'b000000&&func==6'b001001);
    assign Mfhi = (op==6'b000000&&func==6'b010000);
    assign Mflo = (op==6'b000000&&func==6'b010010);
    assign Mthi = (op==6'b000000&&func==6'b010001);
    assign Mtlo = (op==6'b000000&&func==6'b010011);
    assign Mfc0 = (op==6'b010000&&func[5:3]==3'b000);
    assign Mtc0 = (op==6'b010000&&func[5:3]==3'b000);
    assign Break = (op==6'b000000&&func==6'b001101);
    assign Syscall = (op==6'b000000&&func==6'b001100);
    assign Eret = (op==6'b010000&&func==6'b011000);
    //I����ָ��
    assign I_format = (op[5:3]==3'b001);//������ת��ָ���ȡָ��
    assign L_format = (op[5:3]==3'b100);//�Ӵ洢����
    assign S_format = (op[5:3]==3'b101);//д�洢��
     //����ת��ָ��Wpc=01,J/Jalָ��Wpc=10,Jr/Jalrָ��Wpc=11;
    wire EBeq,EBne,EBgez,EBgtz,EBlez,EBltz,EBgezal,EBltzal;
    wire Branchs;
    assign Beq = (op==6'b000100);
    assign EBeq = (op==6'b000100&&Zero);
    assign Bne = (op==6'b000101);
    assign EBne = (op==6'b000101&&~Zero);
    assign Bgez = (op==6'b000001&&rt==5'b00001);
    assign EBgez = (op==6'b000001&&rt==5'b00001&&read_data_1[31]==1'b0);
    assign Bgtz = (op==6'b000111&&rt==5'b00000);
    assign EBgtz = (op==6'b000111&&rt==5'b00000&&read_data_1[31]==1'b0&&read_data_1!=32'd0);
    assign Blez = (op==6'b000110&&rt==5'b00000);
    assign EBlez = (op==6'b000110&&rt==5'b00000&&read_data_1[31]==1'b1);
    assign Bltz = (op==6'b000001&&rt==5'b00000);
    assign EBltz = (op==6'b000001&&rt==5'b00000&&read_data_1[31]==1'b1&&read_data_1!=32'd0);
    assign Bgezal = (op==6'b000001&&rt==5'b10001);
    assign Bltzal = (op==6'b000001&&rt==5'b00000);
    assign EBgezal = (Bgezal&&read_data_1[31]==1'b0);
    assign EBltzal = (Bltzal&&read_data_1[31]==1'b1&&read_data_1!=32'd0);
    assign Branchs = (EBeq||EBne||EBgez||EBgtz||EBlez||EBltz||EBgezal||EBltzal);
    //Jָ��
    assign Jmp = (op==6'b000010);
    assign Jal = (op==6'b000011);
    //Wpc��ֵ
    assign Wpc = (Branchs) ? 2'b01 :
                 (Jmp || Jal) ? 2'b10 :
                 (Jrn || Jalr) ? 2'b11 :
                 2'b00;
     //��д�ź�
     assign MemRead = L_format&&(Alu_resultHigh!=22'b1111111111111111111111);
     assign IORead = L_format&&(Alu_resultHigh==22'b1111111111111111111111);
     assign MemWrite = S_format&&(Alu_resultHigh!=22'b1111111111111111111111);
     assign IOWrite = S_format&&(Alu_resultHigh==22'b1111111111111111111111);
     assign MemIOtoReg = L_format;
     //�����ź�
     assign Sftmd = (op==6'b000000&&func[5:3]==3'b000);
     assign Div = (op==6'b000000&&func[5:1]==5'b01101);
     assign Mem_sign = !op[2];//������չʱΪ1
     assign Mem_Dwidth = op[1:0];//8λΪ00��16λΪ01��32λΪ11
     assign ALUop = {(R_format || I_format),(Beq || Bne || Bgez || Bgtz || Blez ||Bltz || Bgezal || Bltzal)}; 
     assign Alusrc = I_format||L_format||S_format;
     assign RegWrite = R_format? (func[5:3]==3'b100||func[5:1]==5'b10101||Jalr||Sftmd||Mfc0||Mfhi||Mflo):(I_format||L_format||Bgezal||Bltzal||Jal);
     assign Regdst = (R_format && !Mfc0);
     //�����ź�
     assign Rsvd = !(R_format||I_format||L_format||S_format||Beq || Bne || Bgez || Bgtz || Blez ||Bltz || Bgezal || Bltzal||Jmp||Jal);
     
   
endmodule
