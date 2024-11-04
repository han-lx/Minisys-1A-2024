`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module control32(Opcode,Function_opcode,Alu_resultHigh,Jrn,RegDST,ALUSrc,MemorIOtoReg,RegWrite,MemRead,MemWrite,IORead,IOWrite,Branch,nBranch,Jmp,Jal,I_format,Sftmd,ALUOp,);
    //���벿����ָ����
    input[5:0]   Opcode;            // ����ȡָ��Ԫinstruction[31..26]
    input[5:0]   Function_opcode;  	// r-form instructions[5..0]
    input[21:0]  Alu_resultHigh;
    //��������Ǹ��ֿ����ź����ȡֵ
    output       Jrn;              // Ϊ1������ǰָ����jr
    output       RegDST;           // Ϊ1����Ŀ�ļĴ�����rd,����Ŀ�ļĴ�����rt
    output       ALUSrc;            // �����ڶ����������ǼĴ�������������
    output       MemorIOtoReg;         // Ϊ1������Ҫ�Ӵ洢�������ݵ��Ĵ���
    output       RegWrite;         // Ϊ1������ָ����Ҫд�Ĵ���
    output       MemWrite;         // Ϊ1������ָ����Ҫд�洢��
    output       MemRead;
    output       IOWrite;
    output       IORead;
    output       Branch;           // Ϊ1������beqָ��
    output       nBranch;          // Ϊ1������bneָ��
    output       Jmp;              // Ϊ1������jmpָ��
    output       Jal;              // Ϊ1������jalָ��
    output       I_format;         // Ϊ1������ָ���ǳ�beq,bne,lw,sw֮�������I����ָ��
    output       Sftmd;            // Ϊ1��������λָ��
    output[1:0]  ALUOp;            // ��R���ͻ�I_formatΪ1ʱλ1Ϊ1��beq,bneָ����λ0Ϊ1
     
    wire Jmp,I_format,Jal,Branch,nBranch;
    wire R_format,Lw,Sw;
    
    //RegDST��R��ָ��ʱΪ1
    assign R_format = (Opcode==6'b000000)? 1'b1:1'b0;    	//--00h 
    assign RegDST = R_format;                               //˵��Ŀ����rd��������rt
    
    //RegWrite�ź�
    //��R���ͳ�ȥjrָ��
    assign Jrn = (Function_opcode==6'b001000)&&(Opcode==6'b000000);      //Ϊ1������jrָ��
    
    //ALUsrc�ź�
    assign I_format = (Opcode[5:3] == 3'b001);
    assign ALUSrc = (Opcode[5:3] != 3'b000);
   
   //MemtoReg��lwָ��ʱΪ1
   assign MemorIOtoReg = (Opcode == 6'b100011);
   
 
   
   //Branch
   assign Branch = (Opcode == 6'b000100);
   
   //nBranch
   assign nBranch = (Opcode == 6'b000101);
   
   //Jmp
   assign Jmp = (Opcode == 6'b000010);
   
   //Jal
   assign Jal = (Opcode == 6'b000011);
   
   //Sftmd
   assign Sftmd = (Function_opcode[5:3] == 3'b000);
   
   //ALUOp
   assign ALUOp = {(R_format||I_format),(Branch||nBranch)};
   
   //RegWrite
   assign Lw = (Opcode==6'b100011)? 1'b1:1'b0;
   assign RegWrite = (R_format || Lw || Jal || I_format) && !(Jrn);
   
     //MemWrite
    assign Sw = (Opcode==6'b101011)? 1'b1:1'b0;
    assign MemWrite = ((Sw==1) && (Alu_resultHigh!=22'b1111111111111111111111))?1'b1:1'b0;
    assign MemRead = ((Lw==1) && (Alu_resultHigh!=22'b1111111111111111111111))?1'b1:1'b0;
    assign IOWrite = ((Sw==1) && (Alu_resultHigh==22'b1111111111111111111111))?1'b1:1'b0;
    assign IORead = ((Lw==1) && (Alu_resultHigh==22'b1111111111111111111111))?1'b1:1'b0;
   

endmodule