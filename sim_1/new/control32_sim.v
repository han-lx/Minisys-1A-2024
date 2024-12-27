`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/12/27 21:09:19
// Design Name: 这是控制模块的仿真文件，由于控制模块只涉及信号的判断，这里所有的指令串行
// Module Name: control32_sim
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


module control32_sim(

    );
    reg [31:0] Instruction = 32'h00000000;
    reg s_format = 1'b0;
    reg l_format = 1'b0;
    reg [21:0] Alu_resultHigh = 22'd0;
    
    wire Regdst;
    wire Alusrc;
    wire MemIOtoReg;
    wire RegWrite;
    wire MemWrite;
    wire MemRead;
    wire IORead;
    wire IOWrite;
    wire Jmp;
    wire Jal;
    wire Jalr;
    wire Jrn;
    wire Beq;
    wire Bne;
    wire Bgez;
    wire Bgtz;
    wire Blez;
    wire Bltz;
    wire Bgezal;
    wire Bltzal;
    wire Mfhi;
    wire Mflo;
    wire Mfc0;
    wire Mthi;
    wire Mtlo;
    wire Mtc0;
    wire I_format;
    wire S_format;
    wire L_format;
    wire Sftmd;
    wire Div;
    wire[1:0] ALUop;
    wire Mem_sign;
    wire[1:0] Mem_Dwidth;
    wire Break;
    wire Syscall;
    wire Eret;
    wire Rsvd;
    
    control32 control_test(
          .Instruction      (Instruction),
          .s_format         (s_format),
          .l_format         (l_format),
          .Alu_resultHigh   (Alu_resultHigh),
          .Regdst           (Regdst),
          .Alusrc           (Alusrc),
          .MemIOtoReg       (MemIOtoReg),
          .RegWrite         (RegWrite),
          .MemWrite         (MemWrite),
          .MemRead          (MemRead),
          .IORead           (IORead),
          .IOWrite          (IOWrite),
          .Jmp              (Jmp),
          .Jal              (Jal),
          .Jalr             (Jalr),
          .Jrn              (Jrn),
          .Beq              (Beq),
          .Bne              (Bne),
          .Bgez             (Bgez),
          .Bgtz             (Bgtz),
          .Blez             (Blez),
          .Bltz             (Bltz),
          .Bgezal           (Bgezal),
          .Bltzal           (Bltzal),
          .Mfhi             (Mfhi),
          .Mflo             (Mflo),
          .Mfc0             (Mfc0),
          .Mthi             (Mthi),
          .Mtlo             (Mtlo),
          .Mtc0             (Mtc0),
          .I_format         (I_format),
          .S_format         (S_format),
          .L_format         (L_format),
          .Sftmd            (Sftmd),
          .Div              (Div),
          .ALUop            (ALUop),
          .Mem_sign         (Mem_sign),
          .Mem_Dwidth       (Mem_Dwidth),
          .Break            (Break),
          .Syscall          (Syscall),
          .Eret             (Eret),
          .Rsvd             (Rsvd)
    );
    initial begin
      #200 begin end
      #200 begin Instruction = 32'h3c08ffff; end
      #200 begin Instruction = 32'h2409003d; end
      #200 begin Instruction = 32'h30b20002; end
      #200 begin Instruction = 32'h01090018; end
      #200 begin Instruction = 32'h00005010; end
      #200 begin Instruction = 32'h01044022; end
      #200 begin Instruction = 32'h1500fffe; end
      #200 begin Instruction = 32'h10210002; end
      #200 begin Instruction = 32'h04010001; end
      #200 begin Instruction = 32'h00000008; end
      #200 begin Instruction = 32'h19200001; end
      #200 begin Instruction = 32'h1d200001; end
      #200 begin Instruction = 32'h08000054; end
      #200 begin Instruction = 32'h05800001; end
      #200 begin Instruction = 32'h05910002; end
      #200 begin Instruction = 32'h0c000000; end
      #200 begin Instruction = 32'h05300003; end
      #200 begin Instruction = 32'h08000014; end
    end
endmodule
