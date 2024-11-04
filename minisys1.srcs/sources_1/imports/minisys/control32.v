`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module control32(Opcode,Function_opcode,Alu_resultHigh,Jrn,RegDST,ALUSrc,MemorIOtoReg,RegWrite,MemRead,MemWrite,IORead,IOWrite,Branch,nBranch,Jmp,Jal,I_format,Sftmd,ALUOp,);
    //输入部分是指令码
    input[5:0]   Opcode;            // 来自取指单元instruction[31..26]
    input[5:0]   Function_opcode;  	// r-form instructions[5..0]
    input[21:0]  Alu_resultHigh;
    //输出部分是各种控制信号如何取值
    output       Jrn;              // 为1表明当前指令是jr
    output       RegDST;           // 为1表明目的寄存器是rd,否则目的寄存器是rt
    output       ALUSrc;            // 决定第二个操作数是寄存器还是立即数
    output       MemorIOtoReg;         // 为1表明需要从存储器读数据到寄存器
    output       RegWrite;         // 为1表明该指令需要写寄存器
    output       MemWrite;         // 为1表明该指令需要写存储器
    output       MemRead;
    output       IOWrite;
    output       IORead;
    output       Branch;           // 为1表明是beq指令
    output       nBranch;          // 为1表明是bne指令
    output       Jmp;              // 为1表明是jmp指令
    output       Jal;              // 为1表明是jal指令
    output       I_format;         // 为1表明该指令是除beq,bne,lw,sw之外的其他I类型指令
    output       Sftmd;            // 为1表明是移位指令
    output[1:0]  ALUOp;            // 是R类型或I_format为1时位1为1，beq,bne指令则位0为1
     
    wire Jmp,I_format,Jal,Branch,nBranch;
    wire R_format,Lw,Sw;
    
    //RegDST在R型指令时为1
    assign R_format = (Opcode==6'b000000)? 1'b1:1'b0;    	//--00h 
    assign RegDST = R_format;                               //说明目标是rd，否则是rt
    
    //RegWrite信号
    //是R类型除去jr指令
    assign Jrn = (Function_opcode==6'b001000)&&(Opcode==6'b000000);      //为1表明是jr指令
    
    //ALUsrc信号
    assign I_format = (Opcode[5:3] == 3'b001);
    assign ALUSrc = (Opcode[5:3] != 3'b000);
   
   //MemtoReg在lw指令时为1
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