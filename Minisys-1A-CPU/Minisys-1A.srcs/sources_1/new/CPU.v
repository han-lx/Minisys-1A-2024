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
  wire [31:0] B_rs_data;
  
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
  wire [4:0] write_address_1, write_address_0;
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
  wire [4:0] Waddr;
  wire Positive,Negative;
  
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
  wire EX_MEM_Positive,EX_MEM_Negative;
  
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
  wire MEM_WB_Negative;
  wire keyboardInterrupt, digitalTubeInterrupt;//???????
  
  //WB�����������CP0Э������ģ��
  wire Wcp0;
  //wire CP0_mfc0;//???????
  wire [31:0] CP0_data_out, CP0_pc_out;
  wire [31:0] Wdata;
  
  //����Ҫ��ʼ������C
  //ȡָ��Ԫ
  ifetch32 If(
            //����
            .reset          (reset),
            .clock          (clk),
            .EX_stall       (EX_stall),
            .WPC            (WPC),
            .Wpc            (Wpc),
            .Jpc            (ID_Jpc),
            .read_data_1    (B_rs_data),//����ȱһ�����ݣ����濴��Ҫ��Ҫ����
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
   IFtoID If_Id(
            .clock          (clk),
            .reset          (reset),
            .flush          (IF_flush || Wcp0),
            .Wir            (WPC),
            .EX_stall       (EX_stall),
            .recover        (IF_recover),
            .IF_opcplus4    (opcplus4),
            .IF_instruction (Instruction),
            .IF_PC          (PC),
            
            .IF_ID_Npc      (IF_ID_Npc),
            .IF_ID_IR       (IF_ID_IR),
            .IF_ID_recover  (IF_ID_recover),
            .IF_ID_PC       (IF_ID_PC)
   );
   //Branch����ģ��
   branchprocess branch(
            .IF_ID_op       (IROM_instruction[31:26]),
            .Beq            (Beq),
            .Bne            (Bne),
            .Bgez           (Bgez),
            .Bgtz           (Bgtz),
            .Blez           (Blez),
            .Bltz           (Bltz),
            .Bgezal         (Bgezal),
            .Bltzal         (Bltzal),
            .Jrn            (Jrn),
            .Jalr           (Jalr),
            .Jmp            (Jmp),
            .Jal            (Jal),
            .CTL_Alusrc     (Alusrc),
            .IF_WPC         (WPC),
            .FWD_AluCsrc    (AluCsrc),
            .FWD_AluDsrc    (AluCsrc),
            .MemorIORead    (EX_MEM_MemRead || MEM_IORead),
            .ID_read_data_1 (read_data_1),
            .ID_read_data_2 (read_data_2),
            .ID_sign_extend (sign_extend),
            .EX_ALU_result  (EX_ALU_result),
            .MEM_ALU_result (EX_MEM_ALU_result),
            .MemorIOData    (read_data),
            .Wdata          (ID_write_data),
            
            .nBranch        (nBranch),
            .IF_flush       (IF_flush),
            .Wpc            (Wpc),
            .B_rs_data      (B_rs_data)
   );
   //controlģ��
   control32 control(
            .Instruction    (IF_ID_IR),
            .Alu_resultHigh (EX_ALU_result[31:10]),
            .l_format       (ID_EX_L_format),
            .s_format       (ID_EX_S_format),
            
            .Regdst         (RegDst),
            .Alusrc         (Alusrc),
            .MemIOtoReg     (MemIOtoReg),
            .RegWrite       (RegWrite),
            .MemWrite       (MemWrite),
            .MemRead        (MemRead),
            .IORead         (IORead),
            .IOWrite        (IOWrite),
            //.Wir            (),
            //.Waluresult     (),
            .Jmp            (Jmp),
            .Jal            (Jal),
            .Jalr           (Jalr),
            .Jrn            (Jrn),
            .Beq            (Beq),
            .Bne            (Bne),
            .Bgez           (Bgez),
            .Bgtz           (Bgtz),
            .Blez           (Blez),
            .Bltz           (Bltz),
            .Bgezal         (Bgezal),
            .Bltzal         (Bltzal),
            .Mfhi           (Mfhi),
            .Mflo           (Mflo),
            .Mfc0           (Mfc0),
            .Mthi           (Mthi),
            .Mtlo           (Mtlo),
            .Mtc0           (Mtc0),
            .I_format       (I_format),
            .S_format       (S_format),
            .L_format       (L_format),
            .Sftmd          (Sftmd),
            .Div            (Div),
            .ALUop          (ALUop),
            .Mem_sign       (Mem_sign),
            .Mem_Dwidth     (Mem_Dwidth),
            .Break          (Break),
            .Syscall        (Syscall),
            .Eret           (Eret),
            .Rsvd           (Rsvd)
   );
   //IDģ��
   idecode32 Id(
            .reset          (reset),
            .clock          (clk),
            .ID_opcplus4    (MEM_WB_opcplus4),
            .Instruction    (IF_ID_IR),
            .Wdata          (Wdata),
            .Waddr          (MEM_WB_Waddr),
            .Jal            (MEM_WB_Jal),
            .Jalr           (MEM_WB_Jalr),
            .Bgezal         (MEM_WB_Bgezal),
            //.EBgezal        (),
            .Bltzal         (MEM_WB_Bltzal),
            //.EBltzal        (),
            .Negative       (MEM_WB_Negative),
            .RegWrite       (MEM_WB_RegWrite),
            
            .ID_Jpc         (ID_Jpc),
            .read_data_1    (read_data_1),
            .read_data_2    (read_data_2),
            .write_address_1(write_address_1),
            .write_address_0(write_address_0),
            .write_data     (ID_write_data),
            .write_register_address(write_register_address),
            .sign_extend    (sign_extend),
            .rs             (rs),
            .rd_data        (ID_rd_data)
   );
   //ID/EXģ��
   IDtoEX Id_Ex(
            .clock          (clk),
            .reset          (reset),
            .flush          (Wcp0),
            .EX_stall       (EX_stall),
            .ID_stall       (ID_stall),
            .IF_ID_recover  (IF_ID_recover),
            .ID_opcplus4    (IF_ID_Npc),
            .IF_ID_PC       (IF_ID_PC),
            .ID_read_data_1 (read_data_1),
            .ID_read_data_2 (read_data_2),
            .ID_func        (IF_ID_IR[5:0]),
            .ID_op          (IF_ID_IR[31:26]),
            .ID_shamt       (IF_ID_IR[10:6]),
            .ID_sign_extend (sign_extend),
            .ID_write_address_0(write_address_0),
            .ID_write_address_1(write_address_1),
            .ID_rs          (rs),
            .ID_rd_data     (ID_rd_data),
            .CTL_ALUop      (ALUop),
            .CTL_Alusrc     (Alusrc),
            .CTL_Regdst     (RegDst),
            .CTL_Sftmd      (Sftmd),
            .CTL_Div        (Div),
            .CTL_I_format   (I_format),
            .CTL_S_format   (S_format),
            .CTL_L_format   (L_format),
            .CTL_Jrn        (Jrn),
            .CTL_Jalr       (Jalr),
            .CTL_Jmp        (Jmp),
            .CTL_Jal        (Jal),
            .CTL_RegWrite   (RegWrite),
            .CTL_MemIOtoReg (MemIOtoReg),
            .CTL_MemWrite   (MemWrite),
            .CTL_MemRead    (MemRead),
            .CTL_IORead     (IORead),
            .CTL_IOWrite    (IOWrite),
            .CTL_Mem_sign   (Mem_sign),
            .CTL_Mem_Dwidth (Mem_Dwidth),
            .CTL_Beq        (Beq),
            .CTL_Bne        (Bne),
            .CTL_Bgez       (Bgez),
            .CTL_Bgtz       (Bgtz),
            .CTL_Blez       (Blez),
            .CTL_Bltz       (Bltz),
            .CTL_Bgezal     (Bgezal),
            .CTL_Bltzal     (Bltzal),
            .CTL_Mfhi       (Mfhi),
            .CTL_Mflo       (Mflo),
            .CTL_Mfc0       (Mfc0),
            .CTL_Mtc0       (Mtc0),
            .CTL_Mthi       (Mthi),
            .CTL_Mtlo       (Mtlo),
            .CTL_Break      (Break),
            .CTL_Syscall    (Syscall),
            .CTL_Eret       (Eret),
            .CTL_Rsvd       (Rsvd),
            
            .ID_EX_recover  (ID_EX_recover),
            .ID_EX_opcplus4 (ID_EX_opcplus4),
            .ID_EX_PC       (ID_EX_PC),
            .ID_EX_A        (ID_EX_A),
            .ID_EX_B        (ID_EX_B),
            .ID_EX_func     (ID_EX_func),
            .ID_EX_op       (ID_EX_op),
            .ID_EX_shamt    (ID_EX_shamt),
            .ID_EX_IMM      (ID_EX_IMM),
            .ID_EX_write_address_0(ID_EX_write_address_0),
            .ID_EX_write_address_1(ID_EX_write_address_1),
            .ID_EX_rs       (ID_EX_rs),
            .ID_EX_rd_data  (ID_EX_rd_data),
            .ID_EX_Aluop    (ID_EX_Aluop),
            .ID_EX_Alusrc   (ID_EX_Alusrc),
            .ID_EX_Regdst   (ID_EX_Regdst),
            .ID_EX_Sftmd    (ID_EX_Sftmd),
            .ID_EX_Div      (ID_EX_Div),
            .ID_EX_I_format (ID_EX_I_format),
            .ID_EX_S_format (ID_EX_S_format),
            .ID_EX_L_format (ID_EX_L_format),
            .ID_EX_Jrn      (ID_EX_Jrn),
            .ID_EX_Jalr     (ID_EX_Jalr),
            .ID_EX_Jmp      (ID_EX_Jmp),
            .ID_EX_Jal      (ID_EX_Jal),
            .ID_EX_RegWrite (ID_EX_RegWrite),
            .ID_EX_MemIOtoReg(ID_EX_MemIOtoReg),
            .ID_EX_MemWrite (ID_EX_MemWrite),
            .ID_EX_MemRead  (ID_EX_MemRead),
            .ID_EX_IORead   (ID_EX_IORead),
            .ID_EX_IOWrite  (ID_EX_IOWrite),
            .ID_EX_Mem_sign (ID_EX_Mem_sign),
            .ID_EX_Mem_Dwidth(ID_EX_Mem_Dwidth),
            .ID_EX_Beq      (ID_EX_Beq),
            .ID_EX_Bne      (ID_EX_Bne),
            .ID_EX_Bgez     (ID_EX_Bgez),
            .ID_EX_Bgtz     (ID_EX_Bgtz),
            .ID_EX_Blez     (ID_EX_Blez),
            .ID_EX_Bltz     (ID_EX_Bltz),
            .ID_EX_Bgezal   (ID_EX_Bgezal),
            .ID_EX_Bltzal   (ID_EX_Bltzal),
            .ID_EX_Mfhi     (ID_EX_Mfhi),
            .ID_EX_Mflo     (ID_EX_Mflo),
            .ID_EX_Mfc0     (ID_EX_Mfc0),
            .ID_EX_Mtc0     (ID_EX_Mtc0),
            .ID_EX_Mthi     (ID_EX_Mthi),
            .ID_EX_Mtlo     (ID_EX_Mtlo),
            .ID_EX_Break    (ID_EX_Break),
            .ID_EX_Syscall  (ID_EX_Syscall),
            .ID_EX_Eret     (ID_EX_Eret),
            .ID_EX_Rsvd     (ID_EX_Rsvd)
   );
   //����ģ������
   stall Idstall(
            .EX_MemRead     (EX_MEM_MemRead || ID_EX_IORead),
            .ID_rt          (write_address_0),
            .ID_rs          (rs),
            .EX_rt          (Waddr),
            .EX_Mfc0        (ID_EX_Mfc0),
            
            .ID_stall       (ID_stall),
            .WPC            (WPC)
   );
   //ת��ģ��
   forward fwd(
            //��ǰָ�����ID�׶Σ�
            .ID_rs          (rs),
            .ID_rt          (write_address_0),
            .ID_Mflo        (Mflo),
            .ID_Mfhi        (Mfhi),
           //��һ��ָ�����EX�׶Σ�
            .EX_rs          (ID_EX_rs),
            .EX_rt          (ID_EX_write_address_0),
            .EX_Mflo        (ID_EX_Mflo),
            .EX_Mfhi        (ID_EX_Mfhi),
            .ID_EX_RegWrite (ID_EX_RegWrite),
            .ID_EX_Waddr    (Waddr),
            .ID_EX_Mtlo     (ID_EX_Mtlo),
            .ID_EX_Mthi     (ID_EX_Mthi),
            //������ָ�����MEM�׶Σ�
            .EX_MEM_RegWrite(EX_MEM_RegWrite),
            .EX_MEM_Waddr   (EX_MEM_Waddr),
            .EX_MEM_Mtlo    (EX_MEM_Mtlo),
            .EX_MEM_Mthi    (EX_MEM_Mthi),
            //��������ָ�����WB�׶Σ�
            .EX_WB_RegWrite (MEM_WB_RegWrite),
            .MEM_WB_Waddr   (MEM_WB_Waddr),
            .MEM_WB_Mtlo    (MEM_WB_Mtlo),
            .MEM_WB_Mthi    (MEM_WB_Mthi),
            
            //.EX_rd          (),
            
            .AluAsrc        (AluAsrc),
            .AluBsrc        (AluBsrc),
            .AluCsrc        (AluCsrc),
            .AluDsrc        (AluDsrc),
            .AluMsrc        (AluMsrc)
   );
   //����ִ��ģ���ˣ��������
   executs32 Ex(
            .clock          (clk),
            .EX_opcplus4    (MEM_WB_opcplus4),//?????Ϊʲô���������PC+4��
            .EX_A           (ID_EX_A),
            .EX_B           (ID_EX_B),
            .EX_rd_data     (ID_EX_rd_data),
            .EX_IMM         (ID_EX_IMM),
            .EX_func        (ID_EX_func),
            .EX_op          (ID_EX_op),
            .EX_shamt       (ID_EX_shamt),
            .EX_write_address_0(ID_EX_write_address_0),
            .EX_write_address_1(ID_EX_write_address_1),
            .EX_Aluop       (ID_EX_Aluop),
            .EX_Sftmd       (ID_EX_Sftmd),
            .EX_Div         (ID_EX_Div),
            .EX_Alusrc      (ID_EX_Alusrc),
            .AluAsrc        (AluAsrc),
            .AluBsrc        (AluBsrc),
            .AluMsrc        (AluMsrc),
            .EX_I_format    (ID_EX_I_format),
            .EX_Jrn         (ID_EX_Jrn),
            .EX_Jalr        (ID_EX_Jalr),
            .EX_Jal         (ID_EX_Jal),
            .EX_Regdst      (ID_EX_Regdst),
            .EX_Mfhi        (ID_EX_Mfhi),
            .EX_Mflo        (ID_EX_Mflo),
            .EX_Mthi        (ID_EX_Mthi),
            .EX_Mtlo        (ID_EX_Mtlo),
            .EX_MEM_ALU_result(EX_MEM_ALU_result),
            .Wdata          (ID_write_data),//??�����ʺ�
            
            .rd_data        (EX_rd_data),
            .EX_stall       (EX_stall),
            .Zero           (Zero),
            .Positive       (Positive),
            .Negative       (Negative),
            .Overflow       (Overflow),
            .Div_0          (Div_0),
            .Waddr          (Waddr),
            .EX_ALU_result  (EX_ALU_result),
            .EX_rt_data     (EX_rt_data)
   );
   //EX/MEM�μ�Ĵ���
   EXtoMEM Ex_Mem(
            .reset          (reset),
            .clock          (clk),
            .flush          (Wcp0),
            .EX_stall       (EX_stall),
            .EX_Zero        (Zero),
            .EX_Positive    (Positive),
            .EX_Negative    (Negative),
            .ID_EX_recover  (ID_EX_recover),
            .EX_rd_data     (ID_EX_rd_data),
            .EX_rt_data     (EX_rt_data),
            .ID_EX_Jrn      (ID_EX_Jrn),
            .ID_EX_Jalr     (ID_EX_Jalr),
            .ID_EX_Jmp      (ID_EX_Jmp),
            .ID_EX_Jal      (ID_EX_Jal),
            .ID_EX_Beq      (ID_EX_Beq),
            .ID_EX_Bne      (ID_EX_Bne),
            .ID_EX_Bgez     (ID_EX_Bgez),
            .ID_EX_Bgtz     (ID_EX_Bgtz),
            .ID_EX_Bltz     (ID_EX_Bltz),
            .ID_EX_Blez     (ID_EX_Blez),
            .ID_EX_Bgezal   (ID_EX_Bgezal),
            .ID_EX_Bltzal   (ID_EX_Bltzal),
            .ID_EX_RegWrite (ID_EX_RegWrite),
            .ID_EX_MemIOtoReg(ID_EX_MemIOtoReg),
            .ID_EX_Mfhi     (ID_EX_Mfhi),
            .ID_EX_Mflo     (ID_EX_Mflo),
            .ID_EX_Mthi     (ID_EX_Mthi),
            .ID_EX_Mtlo     (ID_EX_Mtlo),
            .ID_EX_Mfc0     (ID_EX_Mfc0),
            .ID_EX_Mtc0     (ID_EX_Mtc0),
            .ID_EX_Break    (ID_EX_Break),
            .ID_EX_Syscall  (ID_EX_Syscall),
            .ID_EX_Eret     (ID_EX_Eret),
            .ID_EX_Rsvd     (ID_EX_Rsvd),
            .ID_EX_MemWrite (ID_EX_MemWrite),
            .ID_EX_MemRead  (ID_EX_MemRead),
            .ID_EX_IOWrite  (ID_EX_IOWrite),
            .ID_EX_IORead   (ID_EX_IORead),
            .ID_EX_Mem_sign (ID_EX_Mem_sign),
            .ID_EX_Mem_Dwidth(ID_EX_Mem_Dwidth),
            .ID_EX_opcplus4 (ID_EX_opcplus4),
            .ID_EX_PC       (ID_EX_PC),
            .EX_Div_0       (Div_0),
            .EX_Overflow    (Overflow),
            .EX_ALU_result  (EX_ALU_result),
            .EX_Waddr       (Waddr),

            .EX_MEM_Zero    (EX_MEM_Zero),
            .EX_MEM_Positive(EX_MEM_Positive),
            .EX_MEM_Negative(EX_MEM_Negative),
            .EX_MEM_recover (EX_MEM_recover),
            .EX_MEM_rd_data (EX_MEM_rd_data),
            .EX_MEM_Jrn     (EX_MEM_Jrn),
            .EX_MEM_Jalr    (EX_MEM_Jalr),
            .EX_MEM_Jmp     (EX_MEM_Jmp),
            .EX_MEM_Jal     (EX_MEM_Jal),
            .EX_MEM_Beq     (EX_MEM_Beq),
            .EX_MEM_Bne     (EX_MEM_Bne),
            .EX_MEM_Bgez    (EX_MEM_Bgez),
            .EX_MEM_Bgtz    (EX_MEM_Bgtz),
            .EX_MEM_Bltz    (EX_MEM_Bltz),
            .EX_MEM_Blez    (EX_MEM_Blez),
            .EX_MEM_Bgezal  (EX_MEM_Bgezal),
            .EX_MEM_Bltzal  (EX_MEM_Bltzal),
            .EX_MEM_MemWrite(EX_MEM_MemWrite),
            .EX_MEM_IOWrite (EX_MEM_IOWrite),
            .EX_MEM_MemRead (EX_MEM_MemRead),
            .EX_MEM_IORead  (EX_MEM_IORead),
            .EX_MEM_RegWrite(EX_MEM_RegWrite),
            .EX_MEM_MemIOtoReg(EX_MEM_MemIOtoReg),
            .EX_MEM_Mem_sign(EX_MEM_Mem_sign),
            .EX_MEM_Mem_Dwidth(EX_MEM_Mem_Dwidth),
            .EX_MEM_Mfhi    (EX_MEM_Mfhi),
            .EX_MEM_Mflo    (EX_MEM_Mflo),
            .EX_MEM_Mthi    (EX_MEM_Mthi),
            .EX_MEM_Mtlo    (EX_MEM_Mtlo),
            .EX_MEM_Div_0   (EX_MEM_Div_0),
            .EX_MEM_OF      (EX_MEM_OF),
            .EX_MEM_Mfc0    (EX_MEM_Mfc0),
            .EX_MEM_Mtc0    (EX_MEM_Mtc0),
            .EX_MEM_Break   (EX_MEM_Break),
            .EX_MEM_Syscall (EX_MEM_Syscall),
            .EX_MEM_Eret    (EX_MEM_Eret),
            .EX_MEM_Rsvd    (EX_MEM_Rsvd),
            .EX_MEM_opcplus4(EX_MEM_opcplus4),
            .EX_MEM_PC      (EX_MEM_PC),
            .EX_MEM_ALU_result(EX_MEM_ALU_result),
            .EX_MEM_Wdata   (EX_MEM_Wdata),
            .EX_MEM_Waddr   (EX_MEM_Waddr)
   );
   //��������ѡ��ʱ��,�ڽ���MEM�׶�ǰ����Ҫ�ж϶�д���󵽵���MEM����IO�豸
   MemorIO memorio(
            .ALU_result     (EX_MEM_ALU_result),
            .CTL_MemRead    (EX_MEM_MemRead),
            .CTL_MemWrite   (EX_MEM_MemWrite),
            .CTL_IORead     (EX_MEM_IORead),
            .CTL_IOWrite    (EX_MEM_IOWrite),
            .Mem_data       (Mem_read_data),
            .IO_data        (IO_read_data),
            .write_data     (EX_MEM_Wdata),
            
            .read_data      (read_data),
            .write_data_o   (write_data),
            .write_address  (write_address),
            
            .timerCTL       (timerCTL),
            .keyboardCTL    (keyboardCTL),
            .digitalTubeCTL (digitalTubeCTL),
            .buzzerCTL      (buzzerCTL),
            .watchdogCTL    (watchdogCTL),
            .pwmCTL         (pwmCTL),
            .ledCTL         (ledCTL),
            .switchCTL      (switchCTL)
   );
   //MEM/WB�μ�Ĵ���
   MEMtoWB Mem_Wb(
            .reset          (reset),
            .clock          (clk),
            .flush          (Wcp0),
            .EX_MEM_RegWrite(EX_MEM_RegWrite),
            .EX_MEM_MemIOtoReg(EX_MEM_MemIOtoReg),
            .EX_MEM_Mfhi    (EX_MEM_Mfhi),
            .EX_MEM_Mflo    (EX_MEM_Mflo),
            .EX_MEM_Mthi    (EX_MEM_Mthi),
            .EX_MEM_Mtlo    (EX_MEM_Mtlo),
            .EX_MEM_opcplus4(EX_MEM_opcplus4),
            .EX_MEM_PC      (EX_MEM_PC),
            .EX_MEM_ALU_result(EX_MEM_ALU_result),
            .EX_MEM_rt_data (EX_MEM_Wdata),
            .EX_MEM_rd_data (EX_MEM_rd_data),
            .EX_MEM_Waddr   (EX_MEM_Waddr),
            .EX_MEM_Jal     (EX_MEM_Jal),
            .EX_MEM_Jalr    (EX_MEM_Jalr),
            .EX_MEM_Bgezal  (EX_MEM_Bgezal),
            .EX_MEM_Bltzal  (EX_MEM_Bltzal),
            .EX_MEM_Negative(EX_MEM_Negative),
            .EX_MEM_OF      (EX_MEM_OF),
            .EX_MEM_Div_0   (EX_MEM_Div_0),
            .EX_MEM_Mfc0    (EX_MEM_Mfc0),
            .EX_MEM_Mtc0    (EX_MEM_Mtc0),
            .EX_MEM_Break   (EX_MEM_Break),
            .EX_MEM_Syscall (EX_MEM_Syscall),
            .EX_MEM_Eret    (EX_MEM_Eret),
            .EX_MEM_Rsvd    (EX_MEM_Rsvd),
            .EX_MEM_recover (EX_MEM_recover),
            .MEM_MemorIOData(read_data),
            
            .MEM_WB_recover (MEM_WB_recover),
            .MEM_WB_RegWrite(MEM_WB_RegWrite),
            .MEM_WB_MemIOtoReg(MEM_WB_MemIOtoReg),
            .MEM_WB_Mfhi    (MEM_WB_Mfhi),
            .MEM_WB_Mflo    (MEM_WB_Mflo),
            .MEM_WB_Mthi    (MEM_WB_Mthi),
            .MEM_WB_Mtlo    (MEM_WB_Mtlo),
            .MEM_WB_Jal     (MEM_WB_Jal),
            .MEM_WB_Jalr    (MEM_WB_Jalr),
            .MEM_WB_Bgezal  (MEM_WB_Bgezal),
            .MEM_WB_Bltzal  (MEM_WB_Bltzal),
            .MEM_WB_Negative(MEM_WB_Negative),
            .MEM_WB_OF      (MEM_WB_OF),
            .MEM_WB_Div_0   (MEM_WB_Div_0),
            .MEM_WB_Mfc0    (MEM_WB_Mfc0),
            .MEM_WB_Mtc0    (MEM_WB_Mtc0),
            .MEM_WB_Break   (MEM_WB_Break),
            .MEM_WB_Syscall (MEM_WB_Syscall),
            .MEM_WB_Eret    (MEM_WB_Eret),
            .MEM_WB_Rsvd    (MEM_WB_Rsvd),
            .MEM_WB_opcplus4(MEM_WB_opcplus4),
            .MEM_WB_PC      (MEM_WB_PC),
            .MEM_WB_ALU_result(MEM_WB_ALU_result),
            .MEM_WB_rt_data (MEM_WB_rt_data_cp0),
            .MEM_WB_rd_data (MEM_WB_rd_data_cp0),
            .MEM_WB_Waddr   (MEM_WB_Waddr),
            .MEM_WB_MemorIOData(MEM_WB_MemorIOData)
   );
   //�쳣����CP0,����WB�׶�
   coprocessor0 cp0(
            .reset           (reset),
            .clock           (clk),
            .OF              (MEM_WB_OF),
            .Div_0           (MEM_WB_Div_0),
            .Rsvd            (MEM_WB_Rsvd),
            .Mfc0            (MEM_WB_Mfc0),
            .Mtc0            (MEM_WB_Mtc0),
            .Eret            (MEM_WB_Eret),
            .Break           (MEM_WB_Break),
            .Syscall         (MEM_WB_Syscall),
            .part_of_IM      (interrupt),//�ⲿ�ж�
            .recover         (MEM_WB_recover),
            .PC              (MEM_WB_PC),
            .rd              (MEM_WB_rd_data_cp0[4:0]),//????��֪��Ϊɶ
            .rt_data         (MEM_WB_rt_data_cp0),
            .mem_error       (mem_error),
            
            .Wcp0            (Wcp0),
            .CP0_data_out    (CP0_data_out),
            .CP0_pc_out      (CP0_pc_out)
   );
   //���һ��WBģ��
   write32 Wb(
            .MemorIOData     (MEM_WB_MemorIOData),
            .ALU_result      (MEM_WB_ALU_result),
            .CP0_data        (CP0_data_out),
            .MemIOtoReg      (MEM_WB_MemIOtoReg),
            .Mfc0            (MEM_WB_Mfc0),
            
            .Wdata           (Wdata)
   );
endmodule
