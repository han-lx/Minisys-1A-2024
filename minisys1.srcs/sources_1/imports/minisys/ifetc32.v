`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module Ifetc32(Instruction,PC_plus_4_out,Add_result,Read_data_1,Branch,nBranch,Jmp,Jal,Jrn,Zero,clock,reset,opcplus4);
    output[31:0] Instruction;			// 输出指令
    output[31:0] PC_plus_4_out;
    input[31:0]  Add_result;
    input[31:0]  Read_data_1;
    input        Branch;
    input        nBranch;
    input        Jmp;
    input        Jal;
    input        Jrn;
    input        Zero;
    input        clock,reset;
    output[31:0] opcplus4;

    
    wire[31:0]   PC_plus_4;
    reg[31:0]	  PC;
    reg[31:0]    next_PC; 
    wire[31:0]   Jpadr;
    reg[31:0]    opcplus4;
    
   //分配64KB ROM，编译器实际只用 64KB ROM
    prgrom instmem(
        .clka(clock),         // input wire clka
        .addra(PC[15:2]),     // input wire [13 : 0] addra
        .douta(Jpadr)         // output wire [31 : 0] douta
    );
    

    assign Instruction = Jpadr;              //  取出指令
    
    //PC=PC+4
    assign PC_plus_4[31:2] = PC[31:2]+1;
    assign PC_plus_4[1:0] = PC[1:0];
    assign PC_plus_4_out = PC_plus_4[31:0];

    always @* begin      // beq $n ,$m if $n=$m branch   bne if $n /=$m branch jr
    
    //beq
    if(Branch && Zero) begin
      next_PC = Add_result;
    //bne
    end else if (nBranch && !Zero) begin
      next_PC = Add_result;
    //jrn
    end else if (Jrn) begin
      next_PC = Read_data_1;
    //普通情况
    end else begin
      next_PC = PC_plus_4;
    end
    end
    
   always @(negedge clock) begin
   //reset
   if(~reset) begin
     PC = 32'h00000000;
     opcplus4 = 32'h00000000;
   end else begin
       if(Jal) begin
         opcplus4 = PC_plus_4;
         PC = {4'b0000,Jpadr[25:0],2'b00};
       end else if(Jmp) begin
         opcplus4 = 32'h00000000;
         PC = {4'b0000,Jpadr[25:0],2'b00};
       end else begin
         PC = next_PC;
       end 
      
   end
   
   end
endmodule
