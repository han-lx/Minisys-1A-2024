`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module Idecode32(read_data_1,read_data_2,Instruction,read_data,ALU_result,
                 Jal,RegWrite,MemorIOtoReg,RegDst,Sign_extend,clock,reset,
                 opcplus4,read_register_1_address);
    output[31:0] read_data_1;
    output[31:0] read_data_2;
    input[31:0]  Instruction;    //从取指模块取出的指令
    input[31:0]  read_data;   				//  从DATA RAM or I/O port取出的数据
    input[31:0]  ALU_result;   				//  需要扩展立即数到32位
    input        Jal; 
    input        RegWrite;
    input        MemorIOtoReg;
    input        RegDst;
    output[31:0] Sign_extend;
    input		 clock,reset;
    input[31:0]  opcplus4;                 // 来自取指单元，JAL中用
    output[4:0] read_register_1_address;
    
    wire[31:0] read_data_1;
    wire[31:0] read_data_2;
    reg[31:0] register[0:31];			   //寄存器组共32个32位寄存器,定义寄存器组
    reg[4:0] write_register_address;
    reg[31:0] write_data;
    wire[4:0] read_register_1_address;     //rs
    wire[4:0] read_register_2_address;    //rt
    wire[4:0] write_register_address_1;   //rd(R)
    wire[4:0] write_register_address_0;   //rt(I)
    wire[15:0] Instruction_immediate_value; //immediate
    wire[5:0] opcode;           //op
    

    wire sign;
  
    //切分指令的各个部分
    assign opcode = Instruction[31:26];
    assign read_register_1_address = Instruction[25:21];
    assign read_register_2_address = Instruction[20:16];
    assign write_register_address_1 = Instruction[15:11];
    assign write_register_address_0 = Instruction[20:16];
    assign Instruction_immediate_value = Instruction[15:0];
    
    //寄存器读的实现
    assign read_data_1 = register[ read_register_1_address];
    assign read_data_2 = register[ read_register_2_address];
    
    //立即数扩展功能
    assign sign = (opcode == 6'b001000)||(opcode == 6'b001001)||(opcode == 6'b100011)||(opcode == 6'b101011)||(opcode == 6'b000100)||(opcode == 6'b000101)||(opcode == 6'b001010);
    assign Sign_extend[31:0] = {{16{sign&Instruction[15]}},Instruction[15:0]};
    
    always @* begin                                            //这个进程指定不同指令下的目标寄存器
    
    //Jal必写31号寄存器
    if(Jal) begin
     write_register_address = 5'b11111;
    end else if(RegDst) begin
     write_register_address =  write_register_address_1;
    end else begin
      write_register_address = write_register_address_0;
    end
     
    end
    
    always @* begin  //这个进程基本上是实现结构图中右下的多路选择器,准备要写的数据
 
    if(Jal) begin
       write_data = opcplus4;
    end else if( MemorIOtoReg) begin
       write_data = read_data;
    end else begin
       write_data = ALU_result;
    end
 
    end
    
    integer i;
    always @(posedge clock) begin       // 本进程写目标寄存器
        if(reset==1) begin              // 初始化寄存器组
            for(i=0;i<32;i=i+1) register[i] <= i;
        end else if(RegWrite==1) begin  // 注意寄存器0恒等于0
          register[write_register_address] = write_data;
          register[0] <= 0;
        end
    end
endmodule
