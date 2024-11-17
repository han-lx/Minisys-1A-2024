`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/13 13:02:32
// Design Name: 转发处理模块。由于我们初步的设计是做单发射的流水线，因此需要处理的相关有
//              数据相关：RAW相关，控制相关：PC寄存器的RAW相关，最后的输出应该是执行模块的几个src选择信号，到底是选择当前读出的寄存器值还是前面几条指令的结果
// Module Name: forward
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


module forward(
  //关于分支指令，最多用到两个寄存器的值rs和rt
  input [4:0] ID_rs,
  input [4:0] ID_rt,
  input ID_Mflo,
  input ID_Mfhi,
  //关于非分支指令，用到的两个操作数来源于EX阶段
  input [4:0] EX_rs,
  input [4:0] EX_rt,
  input EX_Mflo,
  input EX_Mfhi,
  //
  input ID_EX_RegWrite,
  input [4:0] ID_EX_Waddr,
  input ID_EX_Mtlo,
  input ID_EX_Mthi,
  //
  input EX_MEM_RegWrite,
  input [4:0] EX_MEM_Waddr,
  input EX_MEM_Mtlo,
  input EX_MEM_Mthi,
  input MEM_WB_RegWrite,
  input [4:0] MEM_WB_Waddr,
  input MEM_WB_Mtlo,
  input MEM_WB_Mthi,
  //Mfc0,Mtc0涉及到了rd寄存器
  //input [4:0] EX_rd,
  
  output [1:0] AluAsrc,//选择第一操作数
  output [1:0] AluBsrc,//选择第二操作数
  output [1:0] AluCsrc,
  output [1:0] AluDsrc,
  output [1:0] AluMsrc//选择写入MEM的数据
);
  //case1:当前指令读寄存器的值，但是上一条指令写寄存器，且当前指令读的寄存器和上/上上条指令读的寄存器值相同
  //存在写后读RAW相关
  //对于第一操作数来说，AluAsrc 00-无冲突，01-与上条指令冲突，10-与上上条指令冲突
  assign AluAsrc[0] = (EX_MEM_RegWrite && EX_rs == EX_MEM_Waddr)||//普通指令之间
                      (EX_Mflo && EX_MEM_Mtlo) || (EX_Mfhi && EX_MEM_Mthi);//本条指令读HI/LO，上条指令写HI/IO
  assign AluAsrc[1] = (MEM_WB_RegWrite && EX_rs == MEM_WB_Waddr && !(EX_MEM_RegWrite && EX_rs == EX_MEM_Waddr))||//与上条指令不冲突且与上上条指令冲突，若同时冲突我们只需要考虑与上条指令冲突即可，因为我们取的是最新的寄存器里的值
                      (EX_Mflo && MEM_WB_Mtlo && !EX_MEM_Mtlo) || (EX_Mfhi && MEM_WB_Mthi && !EX_MEM_Mthi);//同理HI/LO寄存器之间的冲突
  //对于第二操作数来说，情况与第一操作数类似，比较简单的是，由于关于HI/LO读写指令跟rs相关，我们只需要在上面讨论即可，这里的情况更为简单
  assign AluBsrc[0] = (EX_MEM_RegWrite && EX_rt == EX_MEM_Waddr);
  assign AluBsrc[1] = (MEM_WB_RegWrite && EX_rt == MEM_WB_Waddr && !(EX_MEM_RegWrite && EX_rt == EX_MEM_Waddr));
  //只有Mfc0涉及到了读rd寄存器的值，因此这里也涉及到了rd寄存器的RAW冒险，00-无冲突，直接选择当前指令中rt的值。01-与上条指令冲突，10-与上上条指令冲突
  //assign AluMsrc[0] = (EX_MEM_RegWrite && EX_rd == EX_MEM_Waddr);
  //assign AluMsrc[1] = (MEM_WB_RegWrite && EX_rd == MEM_WB_Waddr && !(EX_MEM_RegWrite && EX_rd == EX_MEM_Waddr));
  
  //case2:控制相关，当分支指令执行时，由于PC值的跳转会导致之前预取的PC值无效，流水线要清空重来
  //分支指令Beq,Bne涉及rs于rt寄存器的计算，需要进到执行模块，其他分支语句也许不用进到执行模块？
  //00-无冲突，01-与上条指令发生冲突，10-与上上条指令发生冲突，11-与上上上条指令发生冲突
  //对于rs寄存器
  assign AluCsrc = ((ID_EX_RegWrite && ID_rs===ID_EX_Waddr) || (ID_Mflo && ID_EX_Mtlo) || (ID_Mfhi && ID_EX_Mthi)) ? 2'b01:
                   ((EX_MEM_RegWrite && ID_rs===EX_MEM_Waddr) || (ID_Mflo && EX_MEM_Mtlo) || (ID_Mfhi && EX_MEM_Mthi)) ? 2'b10:
                   ((MEM_WB_RegWrite && ID_rs===MEM_WB_Waddr) || (ID_Mflo && MEM_WB_Mtlo ) || (ID_Mfhi && MEM_WB_Mthi)) ? 2'b11:
                   2'b00;
  //对于rt寄存器
  assign AluDsrc = (ID_EX_RegWrite && ID_rt===ID_EX_Waddr) ? 2'b01:
                   (EX_MEM_RegWrite && ID_rt===EX_MEM_Waddr) ? 2'b10:
                   (MEM_WB_RegWrite && ID_rt===MEM_WB_Waddr) ? 2'b11:
                   2'b00;
endmodule
