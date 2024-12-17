`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/12/17 20:08:13
// Design Name: �Ѹ���ģ�����������ߣ���޶����������,����Ӳ�����ַ�Ϊ��CPU+IROM+DRAM+IO�ӿ�
// Module Name: CPU
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


module CPU(
  //ͳһ�������ź�
  input reset,
  input clk,
  
  input [31:0] IROM_instruction,//��ָ��ROM������ָ��
  output [13:0] IROM_address,//��ָ��ROM�ĵ�ַ
  input [31:0] Mem_read_data,//��MEM����������
  input [15:0] IO_read_data,//��IO�豸����������
  output [31:0] write_data,//Ҫд������
  output [31:0] write_address,//д���ݵĵ�ַ
  output wire MEM_MemWrite,
  output wire MEM_data_sign,
  output wire MEM_IOWrite,
  output wire MEM_IORead,
  output wire [1:0] MEM_Mem_Dwidth,
  output wire ledCTL,
  output wire switchCTL,
  output wire timerCTL,
  output wire keyboardCTL,
  output wire digitalTubeCTL,
  output wire buzzerCTL,
  output wire watchdogCTL,
  output wire pwmCTL,
  
  input [5:0] interrupt,//�ⲿ�ж�
  input mem_error
  );
  
  //IFģ�����
  wire [31:0] Instruction;//��ROM��ȡ����ָ��
  wire [31:0] opcplus4;//PC+4
  wire [31:0] PC;//PCֵ
  wire IF_recover;
  //IF�λ���һ�������Ϊ����CPUģ����������ָ��ROM
  
  //IF/IDģ�����
  wire [31:0] IF_ID_IR;//�μ�Ĵ����洢��ָ������
  wire [31:0] IF_ID_Npc;//�μ�Ĵ����ݴ�next PC,��ʵ������һ�������opcplus4
  wire [31:0] IF_ID_PC;//�ݴ���һ�ε�PC
  wire IF_ID_recover;
  
  //�ڽ�������ģ��֮ǰ���ȿ�����֧����ģ��
  wire nBranch;//���ַ�֧�����޷�ʵ��
  wire IF_flush;//ˢϴ��ˮ��
  wire [1:0] Wpc;//��֧�ж�
  
  //Ȼ����������Ҫ�Ŀ���ģ��,�м�����������û�õ��źţ���������ע�͵���
  wire RegDst;
  wire Alusrc;
  wire MemIOtoReg;
  wire MemRead,MemWrite,IORead,IOWrite;
  wire RegWrite;
  //wire Wir,Waluresult;
  wire Jmp,Jal,Jalr,Jrn;
  wire Beq,Bne,Bgez,Bgtz,Blez,Bltz,Bgezal,Bltzal;
  wire Mfhi,Mflo,Mfc0,Mthi,Mtlo,Mtc0;
  wire I_format,S_format,L_format;
  wire Sftmd;
  wire Div;
  wire [1:0] ALUop;
  wire Mem_sign;
  wire [1:0] Mem_Dwidth;
  wire Break,Syscall,Eret,Rsvd;
  
  //���������ڵ���IDģ��
  wire [31:0] ID_Jpc;
  wire [31:0] read_data_1, read_data_2;
  wire [4:0] write_address_1, write_address_2;
  wire [31:0] ID_write_data;
  wire [4:0] write_register_address;
  wire [31:0] sign_extend;
  wire [4:0] rs;
  wire [31:0] ID_rd_data;
  
  //����ģ�飬���load-useð��
  wire WPC;
  wire ID_stall;
  
  //ID/EX�μ�Ĵ���ģ��
  wire ID_EX_recover;
  wire [31:0] ID_EX_opcplus4, ID_EX_PC;
  wire [31:0] ID_EX_A, ID_EX_B;
  wire [5:0] ID_EX_func, ID_EX_op;
  wire [4:0] ID_EX_shamt;
  wire [31:0] ID_EX_IMM;
  wire [4:0] ID_EX_write_address_0, ID_EX_write_address_1,ID_EX_rs;
  wire [31:0] ID_EX_rd_data;
  wire [1:0] ID_EX_Aluop, ID_EX_Mem_Dwidth;
  wire ID_EX_Alusrc, ID_EX_Regdst, ID_EX_Sftmd, ID_EX_Div;
  wire ID_EX_I_format, ID_EX_S_format, ID_EX_L_format;
  wire ID_EX_Jrn, ID_EX_Jalr, ID_EX_Jmp, ID_EX_Jal;
  wire ID_EX_RegWrite, ID_EX_MemIOtoReg;
  wire ID_EX_MemWrite, ID_EX_MemRead, ID_EX_IORead, ID_EX_IOWrite;
  wire ID_EX_Mem_sign;
  wire ID_EX_Beq, ID_EX_Bne, ID_EX_Bgez, ID_EX_Bgtz, ID_EX_Blez, ID_EX_Bltz, ID_EX_Bgezal, ID_EX_Bltzal;
  wire ID_EX_Mfhi, ID_EX_Mflo, ID_EX_Mfc0, ID_EX_Mtc0, ID_EX_Mtlo, ID_EX_Mthi;
  wire ID_EX_Break, ID_EX_Syscall, ID_EX_Eret,ID_EX_Rsvd;
  
  //ת��ģ�����
  wire [1:0] AluAsrc, AluBsrc, AluCsrc, AluDsrc, AluMsrc;
  
  //EXģ�����
  wire EX_stall, Zero, Overflow, Div_0;
  wire [31:0] EX_rd_data;
  wire [31:0] EX_ALU_result;
  wire [31:0] EX_rt_data;
  
  //EX/MEMģ�����
  wire EX_MEM_Zero, EX_MEM_recover;
  wire [31:0] EX_MEM_rd_data;
  wire EX_MEM_Jrn, EX_MEM_Jalr, EX_MEM_Jmp, EX_MEM_Jal;
  wire EX_MEM_Beq, EX_MEM_Bne, EX_MEM_Bgez, EX_MEM_Bgtz, EX_MEM_Bltz, EX_MEM_Blez, EX_MEM_Bgezal, EX_MEM_Bltzal;
  wire EX_MEM_MemWrite, EX_MEM_IOWrite, EX_MEM_MemRead, EX_MEM_IORead;
  wire EX_MEM_RegWrite, EX_MEM_MemIOtoReg;
  wire EX_MEM_Mem_sign;
  wire [1:0] EX_MEM_Mem_Dwidth;
  wire EX_MEM_Mfhi, EX_MEM_Mflo, EX_MEM_Mthi, EX_MEM_Mtlo, EX_MEM_Mfc0, EX_MEM_Mtc0;
  wire EX_MEM_Div_0, EX_MEM_OF;
  wire EX_MEM_Break, EX_MEM_Syscall, EX_MEM_Eret, EX_MEM_Rsvd;
  wire [31:0] EX_MEM_opcplus4, EX_MEM_PC, EX_MEM_ALU_result, EX_MEM_Wdata;
  wire [4:0] EX_MEM_Waddr;
  
  //MemorIOģ������������������������CPUģ������
  wire [31:0] read_data;
  
  //MEM/WBģ�����
  wire MEM_WB_recover;
  wire MEM_WB_RegWrite, MEM_WB_MemIOtoReg;
  wire MEM_WB_Mfhi, MEM_WB_Mflo, MEM_WB_Mthi, MEM_WB_Mtlo, MEM_WB_Mfc0, MEM_WB_Mtc0;
  wire MEM_WB_Jal, MEM_WB_Jalr;
  wire MEM_WB_Bgezal, MEM_WB_Bltzal;
  wire MEM_WB_OF, MEM_WB_Div_0;
  wire MEM_WB_Break, MEM_WB_Syscall, MEM_WB_Eret, MEM_WB_Rsvd;
  wire [31:0] MEM_WB_opcplus4, MEM_WB_PC, MEM_WB_ALU_result;
  wire [31:0] MEM_WB_rt_data_cp0, MEM_WB_rd_data_cp0;
  wire [4:0] MEM_WB_Waddr;
  wire [31:0] MEM_WB_MemorIOData;
  wire keyboardInterrupt, digitalTubeInterrupt;//???????
  
  //WB�����������CP0Э������ģ��
  wire Wcp0;
  wire CP0_mfc0;//???????
  wire [31:0] CP0_data_out, CP0_pc_out;
  wire [31:0] Wdata;
  
  //����Ҫ��ʼ������C
  //ȡָ��Ԫ
  ifetch32 IF(
            //����
            .reset          (reset),
            .clock          (clk),
            .EX_stall       (ID_stall),
            .WPC            (WPC),
            .Wpc            (Wpc),
            .Jpc            (ID_Jpc),
            //.read_data_1  (),//����ȱһ�����ݣ����濴��Ҫ��Ҫ����
            .ID_Npc         (IF_ID_Npc),
            .Jpadr          (IROM_instruction),
            .Interrupt_pc   (CP0_pc_out),
            .recover        (MEM_WB_Eret),
            .cp0_wen        (Wcp0),
            //���
            .PC             (PC),
            .opcplus4       (opcplus4),
            .Instruction    (Instruction),
            .rom_read_addr  (IROM_address),
            .IF_recover     (IF_recover)
    );
   //IF/ID�μ�Ĵ���
   IFtoID IF_ID(
            .clock          (clk),
            .reset          (reset),
            .flush          (IF_flush || Wcp0),
            .Wir            (WPC),
            .EX_stall       (ID_stall),
            .recover        (IF_recover),
            .IF_opcplus4    (opcplus4),
            .IF_instruction (Instruction),
            .IF_PC          (PC),
            
            .IF_ID_Npc      (IF_ID_Npc),
            .IF_ID_IR       (IF_ID_IR),
            .IF_ID_recover  (IF_ID_recover),
            .IF_ID_PC       (IF_ID_PC)
   );
endmodule
