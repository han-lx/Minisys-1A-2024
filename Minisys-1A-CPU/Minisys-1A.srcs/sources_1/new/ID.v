`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/10 18:54:54
// Design Name: ����ģ�飬����û�а���HI��LO�Ĵ�������صĲ��������������ģ�鵫������д
// Module Name: idecode32
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


module idecode32(
  input reset,//��λ�ź�
  input clock,//ʱ���ź�
  input [31:0] ID_opcplus4,//��IF_ID��NPC�Ĵ����еõ���PC+4��ֵ����󴫵ݣ�Ϊ��֮��д$31
  input [31:0] Instruction,//��ָ��Ĵ���IR��ȡ����ָ��
  input Wdata,//Ҫд��Ĵ��������ݣ�������IOҲ�����Ǵ洢��������,������Ե���WB�׶�
  input Waddr,//Ҫд�ļĴ����ţ�32���Ĵ����������5λ,����ָ���ǳ���$31��������Ĵ���д�����
  //Ҫд$31��ָ��
  input Jal,
  input Jalr,
  input Bgezal,
  //input EBgezal,
  input Bltzal,
  //input EBltzal,
  input Negative,
  input RegWrite,//д�Ĵ����ź�
  
  output [31:0] ID_Jpc,//Jָ����ת�ĵ�ַ
  output [31:0] read_data_1,//��һ��������������μ�Ĵ���A
  output [31:0] read_data_2,//�ڶ���������������μ�Ĵ���B
  output [4:0] write_address_1,//R����ָ��д�ļĴ�����rd
  output [4:0] write_address_0,//I����ָ��д�ļĴ�����rt
  output [31:0] write_data,//Ҫд������
  output [4:0] write_register_address,//д�ļĴ����ţ�������μ�Ĵ���RN
  output [31:0] sign_extend,//������������չ�Ľ����������μ�Ĵ���IMM
  output [4:0] rs,//rs�Ĵ�����
  output [31:0] rd_data//rd��ԭ���洢�����ݣ����ڽ������ð��
   );
   reg[31:0] register[0:31];//����32��32λ�Ĵ���
   wire immediate;//������
   wire [5:0] opcode;//������
   wire [4:0] rt;//rt�Ĵ�����
   
   assign opcode = Instruction[31:26];
   assign rs = Instruction[25:21];
   assign rt = Instruction[20:16];
   assign write_address_1 = Instruction[15:11];
   assign write_address_0 = rt;
   assign immediate = Instruction[15:0];
   assign ID_Jpc = {6'b000000 , Instruction[25:0] << 2};//address,��0��չ
   //��������չ
   wire sign;
   assign sign = Instruction[15];
   assign sign_extend = (opcode==6'b001100||opcode==6'b001101||opcode==6'b001110||opcode==6'b001011) ? {16'd0,immediate} : {{16{sign}},immediate};
   //�ӼĴ������ȡ����
   assign read_data_1 = register[rs];
   assign read_data_2 = register[rt];
   assign rd_data = register[write_address_1];
   //д�Ĵ�������
   assign write_data = (Jal || Jalr || Bgezal || Bltzal) ? ID_opcplus4 : Wdata;
   assign write_register_address = (Jal || (Bgezal && !Negative) || (Bltzal && Negative)) ? 5'd31:(Bgezal||Bltzal)? 5'd0: Waddr;
   //�Ĵ������ʼ���Լ�д�Ĵ���
    integer i;
      always @(posedge clock) begin       // ������дĿ��Ĵ���
          if(reset==1) begin              // ��ʼ���Ĵ�����
              for(i=0;i<32;i=i+1) begin 
                  if(i==29) register[29] = 32'h7FFF;//��ջָ�� �ڴ����λ��
                  else register[i] = i;
              end
          end else if(RegWrite==1) begin  // ע��Ĵ���0�����0
              if(write_register_address != 5'b00000)
                  register[write_register_address] = write_data;
          end
      end
endmodule
