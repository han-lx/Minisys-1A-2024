`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/12 18:52:42
// Design Name: EX/MEM段间寄存器，存放往MEM模块传递的值
// Module Name: EXtoMEM
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


module EXtoMEM(
  input reset,//复位信号
  input clock,//时钟信号
  input flush,//冲刷信号
  input EX_stall,//执行模块阻塞信号
  input EX_Zero,//结果为0
  //input EX_Positive,
  //input EX_Negative,
  input ID_EX_recover,//恢复流水信号，从上一层段间寄存器传入
  input [31:0] EX_rd_data,//rd寄存器的值，从EX模块传入
  input [31:0] EX_rt_data,//rt寄存器的值，从EX模块传入
  //为了统一命名，一律认为从上一个段间寄存器传入某些控制信号
  input ID_EX_Jrn,
  input ID_EX_Jalr,
  input ID_EX_Jmp,
  input ID_EX_Jal,
  input ID_EX_Beq,
  input ID_EX_Bne,
  input ID_EX_Bgez,
  input ID_EX_Bgtz,
  input ID_EX_Bltz,
  input ID_EX_Blez,
  input ID_EX_Bgezal,
  input ID_EX_Bltzal,
  input ID_EX_RegWrite,
  input ID_EX_MemIOtoReg,
  input ID_EX_Mfhi,
  input ID_EX_Mflo,
  input ID_EX_Mthi,
  input ID_EX_Mtlo,
  input ID_EX_Mfc0,
  input ID_EX_Mtc0,
  input ID_EX_Break,
  input ID_EX_Syscall,
  input ID_EX_Eret,
  input ID_EX_Rsvd,
  input ID_EX_MemWrite,
  input ID_EX_MemRead,
  input ID_EX_IOWrite,
  input ID_EX_IORead,
  input ID_EX_Mem_sign,
  input [1:0] ID_EX_Mem_Dwidth,
  input [31:0] ID_EX_opcplus4,
  input [31:0] ID_EX_PC,
  //以下信号从执行模块传入
  input EX_Div_0,
  input EX_Overflow,
  input [31:0] EX_ALU_result,
  input [4:0] EX_Waddr,
  input EX_Positive,
  input EX_Negative,

  output reg EX_MEM_Zero,
  output reg EX_MEM_Positive,
  output reg EX_MEM_Negative,
  output reg EX_MEM_recover,
  output reg [31:0] EX_MEM_rd_data,
  output reg EX_MEM_Jrn,
  output reg EX_MEM_Jalr,
  output reg EX_MEM_Jmp,
  output reg EX_MEM_Jal,
  output reg EX_MEM_Beq,
  output reg EX_MEM_Bne,
  output reg EX_MEM_Bgez,
  output reg EX_MEM_Bgtz,
  output reg EX_MEM_Bltz,
  output reg EX_MEM_Blez,
  output reg EX_MEM_Bgezal,
  output reg EX_MEM_Bltzal,
  output reg EX_MEM_MemWrite,
  output reg EX_MEM_IOWrite,
  output reg EX_MEM_MemRead,
  output reg EX_MEM_IORead,
  output reg EX_MEM_RegWrite,
  output reg EX_MEM_MemIOtoReg,
  output reg EX_MEM_Mem_sign,
  output reg [1:0] EX_MEM_Mem_Dwidth,
  output reg EX_MEM_Mfhi,
  output reg EX_MEM_Mflo,
  output reg EX_MEM_Mthi,
  output reg EX_MEM_Mtlo,
  output reg EX_MEM_Div_0,
  output reg EX_MEM_OF,
  output reg EX_MEM_Mfc0,
  output reg EX_MEM_Mtc0,
  output reg EX_MEM_Break,
  output reg EX_MEM_Syscall,
  output reg EX_MEM_Eret,
  output reg EX_MEM_Rsvd,
  output reg [31:0] EX_MEM_opcplus4,
  output reg [31:0] EX_MEM_PC, 
  output reg [31:0] EX_MEM_ALU_result,
  output reg [31:0] EX_MEM_Wdata,
  output reg [4:0] EX_MEM_Waddr
);
//赋值
  always @(negedge clock or posedge reset or posedge flush) begin
    EX_MEM_recover = ID_EX_recover;
    EX_MEM_rd_data = EX_rd_data;
    if (reset || flush) begin
      EX_MEM_Zero = 1'd0;
      EX_MEM_Positive = 1'd0;
      EX_MEM_Negative = 1'd0;
      EX_MEM_Jrn = 1'd0;
      EX_MEM_Jalr = 1'd0;
      EX_MEM_Jmp = 1'd0;
      EX_MEM_Jal = 1'd0;
      EX_MEM_Beq = 1'd0;
      EX_MEM_Bne = 1'd0;
      EX_MEM_Bgez = 1'd0;
      EX_MEM_Bgtz = 1'd0;
      EX_MEM_Bltz = 1'd0;
      EX_MEM_Blez = 1'd0;
      EX_MEM_Bgezal = 1'd0;
      EX_MEM_Bltzal = 1'd0;
      EX_MEM_MemWrite = 1'd0;
      EX_MEM_IOWrite = 1'd0;
      EX_MEM_MemRead = 1'd0;
      EX_MEM_IORead = 1'd0;
      EX_MEM_RegWrite = 1'd0;
      EX_MEM_MemIOtoReg = 1'd0;
      EX_MEM_Mem_sign = 1'd0;
      EX_MEM_Mem_Dwidth = 2'd0;
      EX_MEM_Mfhi = 1'd0;
      EX_MEM_Mflo = 1'd0;
      EX_MEM_Mthi = 1'd0;
      EX_MEM_Mtlo = 1'd0;
      EX_MEM_Div_0 = 1'd0;
      EX_MEM_OF = 1'd0;
      EX_MEM_Mfc0 = 1'd0;
      EX_MEM_Mtc0 = 1'd0;
      EX_MEM_Break = 1'd0;
      EX_MEM_Syscall = 1'd0;
      EX_MEM_Eret = 1'd0;
      EX_MEM_Rsvd = 1'd0;
      EX_MEM_opcplus4 = 32'd0;
      EX_MEM_PC = 32'd0;
      EX_MEM_ALU_result = 32'd0;
      EX_MEM_Wdata = 32'd0;
      EX_MEM_Waddr = 5'd0;
    end
    else if(EX_stall !=1'b1) begin
      EX_MEM_Zero = EX_Zero;
      EX_MEM_Positive = EX_Positive;
      EX_MEM_Negative = EX_Negative;
      EX_MEM_Jrn = ID_EX_Jrn;
      EX_MEM_Jalr = ID_EX_Jalr;
      EX_MEM_Jmp = ID_EX_Jmp;
      EX_MEM_Jal = ID_EX_Jal;
      EX_MEM_Beq = ID_EX_Beq;
      EX_MEM_Bne = ID_EX_Bne;
      EX_MEM_Bgez = ID_EX_Bgez;
      EX_MEM_Bgtz = ID_EX_Bgtz;
      EX_MEM_Bltz = ID_EX_Bltz;
      EX_MEM_Blez = ID_EX_Blez;
      EX_MEM_Bgezal = ID_EX_Bgezal;
      EX_MEM_Bltzal = ID_EX_Bltzal;
      EX_MEM_MemWrite = ID_EX_MemWrite;
      EX_MEM_IOWrite = ID_EX_IOWrite;
      EX_MEM_MemRead = ID_EX_MemRead;
      EX_MEM_IORead = ID_EX_IORead;
      EX_MEM_RegWrite = ID_EX_RegWrite;
      EX_MEM_MemIOtoReg = ID_EX_MemIOtoReg;
      EX_MEM_Mem_sign = ID_EX_Mem_sign;
      EX_MEM_Mem_Dwidth = ID_EX_Mem_Dwidth;
      EX_MEM_Mfhi = ID_EX_Mfhi;
      EX_MEM_Mflo = ID_EX_Mflo;
      EX_MEM_Mthi = ID_EX_Mthi;
      EX_MEM_Mtlo = ID_EX_Mtlo;
      EX_MEM_Div_0 = EX_Div_0;
      EX_MEM_OF = EX_Overflow;
      EX_MEM_Mfc0 = ID_EX_Mfc0;
      EX_MEM_Mtc0 = ID_EX_Mtc0;
      EX_MEM_Break = ID_EX_Break;
      EX_MEM_Syscall = ID_EX_Syscall;
      EX_MEM_Eret = ID_EX_Eret;
      EX_MEM_Rsvd = ID_EX_Rsvd;
      EX_MEM_opcplus4 = ID_EX_opcplus4;
      EX_MEM_PC = ID_EX_PC;
      EX_MEM_ALU_result = EX_ALU_result;
      EX_MEM_Wdata = EX_rt_data;
      EX_MEM_Waddr = EX_Waddr;     
    end
  end
endmodule
