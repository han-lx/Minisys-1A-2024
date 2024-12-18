`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/10 18:54:54
// Design Name: 译码模块，这里没有包含HI和LO寄存器，相关的操作还是属于这个模块但是另外写
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
  input reset,//复位信号
  input clock,//时钟信号
  input [31:0] ID_opcplus4,//从IF_ID的NPC寄存器中得到的PC+4的值，向后传递，为了之后写$31
  input [31:0] Instruction,//从指令寄存器IR中取出的指令
  input Wdata,//要写入寄存器的数据，可以是IO也可以是存储器的数据,这里针对的是WB阶段
  input Waddr,//要写的寄存器号，32个寄存器，因此是5位,这里指的是除了$31外的其他寄存器写的情况
  //要写$31的指令
  input Jal,
  input Jalr,
  input Bgezal,
  //input EBgezal,
  input Bltzal,
  //input EBltzal,
  input Negative,
  input RegWrite,//写寄存器信号
  
  output [31:0] ID_Jpc,//J指令跳转的地址
  output [31:0] read_data_1,//第一操作数，往后传入段间寄存器A
  output [31:0] read_data_2,//第二操作数，往后传入段间寄存器B
  output [4:0] write_address_1,//R类型指令写的寄存器号rd
  output [4:0] write_address_0,//I类型指令写的寄存器号rt
  output [31:0] write_data,//要写的数据
  output [4:0] write_register_address,//写的寄存器号，往后传入段间寄存器RN
  output [31:0] sign_extend,//立即数符号扩展的结果，往后传入段间寄存器IMM
  output [4:0] rs,//rs寄存器号
  output [31:0] rd_data//rd中原本存储的数据，用于解决数据冒险
   );
   reg[31:0] register[0:31];//定义32个32位寄存器
   wire immediate;//立即数
   wire [5:0] opcode;//操作码
   wire [4:0] rt;//rt寄存器号
   
   assign opcode = Instruction[31:26];
   assign rs = Instruction[25:21];
   assign rt = Instruction[20:16];
   assign write_address_1 = Instruction[15:11];
   assign write_address_0 = rt;
   assign immediate = Instruction[15:0];
   assign ID_Jpc = {6'b000000 , Instruction[25:0] << 2};//address,作0扩展
   //立即数扩展
   wire sign;
   assign sign = Instruction[15];
   assign sign_extend = (opcode==6'b001100||opcode==6'b001101||opcode==6'b001110||opcode==6'b001011) ? {16'd0,immediate} : {{16{sign}},immediate};
   //从寄存器组读取数据
   assign read_data_1 = register[rs];
   assign read_data_2 = register[rt];
   assign rd_data = register[write_address_1];
   //写寄存器操作
   assign write_data = (Jal || Jalr || Bgezal || Bltzal) ? ID_opcplus4 : Wdata;
   assign write_register_address = (Jal || (Bgezal && !Negative) || (Bltzal && Negative)) ? 5'd31:(Bgezal||Bltzal)? 5'd0: Waddr;
   //寄存器组初始化以及写寄存器
    integer i;
      always @(posedge clock) begin       // 本进程写目标寄存器
          if(reset==1) begin              // 初始化寄存器组
              for(i=0;i<32;i=i+1) begin 
                  if(i==29) register[29] = 32'h7FFF;//堆栈指针 内存最大位置
                  else register[i] = i;
              end
          end else if(RegWrite==1) begin  // 注意寄存器0恒等于0
              if(write_register_address != 5'b00000)
                  register[write_register_address] = write_data;
          end
      end
endmodule
