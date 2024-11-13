`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/12 21:13:19
// Design Name: MEM/WB段间寄存器
// Module Name: MEMtoWB
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


module MEMtoWB(
  input reset,
  input clock,
  input flush,
  //从上一层段间寄存器传入
  input EX_MEM_RegWrite,
  input EX_MEM_MemIOtoReg,
  input EX_MEM_Mfhi,
  input EX_MEM_Mflo,
  input EX_MEM_Mthi,
  input EX_MEM_Mtlo,
  input [31:0] EX_MEM_opcplus4,
  input [31:0] EX_MEM_PC,
  input [31:0] EX_MEM_ALU_result,
  input [31:0] EX_MEM_rt_data,
  input [31:0] EX_MEM_rd_data,
  input [4:0] EX_MEM_Waddr,
  input EX_MEM_Jal,
  input EX_MEM_Jalr,
  input EX_MEM_Bgezal,
  input EX_MEM_Bltzal,
  //input EX_MEM_Negative,
  input EX_MEM_OF,
  input EX_MEM_Div_0,
  input EX_MEM_Mfc0,
  input EX_MEM_Mtc0,
  input EX_MEM_Break,
  input EX_MEM_Syscall,
  input EX_MEM_Eret,
  input EX_MEM_Rsvd,
  input EX_MEM_recover,
  //从MEM模块传入
  input [31:0] MEM_MemorIOData,
  
  output reg MEM_WB_recover,
  output reg MEM_WB_RegWrite,
  output reg MEM_WB_MemIOtoReg,
  output reg MEM_WB_Mfhi,
  output reg MEM_WB_Mflo,
  output reg MEM_WB_Mthi,
  output reg MEM_WB_Mtlo,
  output reg MEM_WB_Jal,
  output reg MEM_WB_Jalr,
  output reg MEM_WB_Bgezal,
  output reg MEM_WB_Bltzal,
  //output reg MEM_WB_Negative,
  output reg MEM_WB_OF,
  output reg MEM_WB_Div_0,
  output reg MEM_WB_Mfc0,
  output reg MEM_WB_Mtc0,
  output reg MEM_WB_Break,
  output reg MEM_WB_Syscall,
  output reg MEM_WB_Eret,
  output reg MEM_WB_Rsvd,
  output reg [31:0] MEM_WB_opcplus4,
  output reg [31:0] MEM_WB_PC,
  output reg [31:0] MEM_WB_ALU_result,
  output reg [31:0] MEM_WB_rt_data,
  output reg [31:0] MEM_WB_rd_data,
  output reg [4:0] MEM_WB_Waddr,
  output reg [31:0] MEM_WB_MemorIOData
);
  
  always @(negedge clock or posedge reset) begin
    MEM_WB_recover = EX_MEM_recover;
    MEM_WB_rd_data = EX_MEM_rd_data;
    if (reset || flush) begin
      MEM_WB_RegWrite = 1'b0;
      MEM_WB_MemIOtoReg = 1'b0;
      MEM_WB_Mfhi = 1'b0;
      MEM_WB_Mflo = 1'b0;
      MEM_WB_Mthi = 1'b0;
      MEM_WB_Mtlo = 1'b0;
      MEM_WB_Jal = 1'b0;
      MEM_WB_Jalr = 1'b0;
      MEM_WB_Bgezal = 1'b0;
      MEM_WB_Bltzal = 1'b0;
      //MEM_WB_Negative = 1'b0;
      MEM_WB_OF = 1'b0;
      MEM_WB_Div_0 = 1'b0;
      MEM_WB_Mfc0 = 1'b0;
      MEM_WB_Mtc0 = 1'b0;
      MEM_WB_Break = 1'b0;
      MEM_WB_Syscall = 1'b0;
      MEM_WB_Eret = 1'b0;
      MEM_WB_Rsvd = 1'b0;
      MEM_WB_opcplus4 = 32'd0;
      MEM_WB_PC = 32'd0;
      MEM_WB_ALU_result = 32'd0;
      MEM_WB_MemorIOData = 32'd0;
      MEM_WB_rt_data = 32'd0;
      MEM_WB_Waddr = 5'd0;      
    end
    else begin
      MEM_WB_RegWrite = EX_MEM_RegWrite;
      MEM_WB_MemIOtoReg = EX_MEM_MemIOtoReg;
      MEM_WB_Mfhi = EX_MEM_Mfhi;
      MEM_WB_Mflo = EX_MEM_Mflo;
      MEM_WB_Mthi = EX_MEM_Mthi;
      MEM_WB_Mtlo = EX_MEM_Mtlo;
      MEM_WB_Jal = EX_MEM_Jal;
      MEM_WB_Jalr = EX_MEM_Jalr;
      MEM_WB_Bgezal = EX_MEM_Bgezal;
      MEM_WB_Bltzal = EX_MEM_Bltzal;
      //MEM_WB_Negative = 1'b0;
      MEM_WB_OF = EX_MEM_OF;
      MEM_WB_Div_0 = EX_MEM_Div_0;
      MEM_WB_Mfc0 = EX_MEM_Mfc0;
      MEM_WB_Mtc0 = EX_MEM_Mtc0;
      MEM_WB_Break = EX_MEM_Break;
      MEM_WB_Syscall = EX_MEM_Syscall;
      MEM_WB_Eret = EX_MEM_Eret;
      MEM_WB_Rsvd = EX_MEM_Rsvd;
      MEM_WB_opcplus4 = EX_MEM_opcplus4;
      MEM_WB_PC = EX_MEM_PC;
      MEM_WB_ALU_result = EX_MEM_ALU_result;
      MEM_WB_MemorIOData = MEM_MemorIOData;
      MEM_WB_rt_data = EX_MEM_rt_data;
      MEM_WB_Waddr = EX_MEM_Waddr;
    end          
  end
endmodule
