`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/12/27 13:41:47
// Design Name: 执行模块测试仿真
// Module Name: execute32_sim
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


module execute32_sim(

    );
    reg clock = 1'b0;
    reg [31:0] EX_opcplus4 = 32'h00000000;
    reg [31:0] EX_A = 32'h00000000;
    reg [31:0] EX_B = 32'h00000000;
    reg [31:0] EX_rd_data = 32'h00000000;
    reg [31:0] EX_IMM = 32'h00000000;
    reg [5:0] EX_func = 6'b000000;
    reg [5:0] EX_op = 6'b000000;
    reg [4:0] EX_shamt = 5'b00000;
    reg [4:0] EX_write_address_0 = 5'b00000;
    reg [4:0] EX_write_address_1 = 5'b00000;
    reg [1:0] EX_Aluop = 2'b00;
    reg EX_Sftmd = 1'b0;
    reg EX_Div = 1'b0;
    reg EX_Alusrc = 1'b0;
    reg [1:0] AluAsrc = 2'b00;
    reg [1:0] AluBsrc = 2'b00;
    reg [1:0] AluMsrc = 2'b00;
    reg EX_I_format = 1'b0;
    reg EX_Jrn = 1'b0;
    reg EX_Jalr = 1'b0;
    reg EX_Jal = 1'b0;
    reg EX_Regdst = 1'b0;
    reg EX_Mfhi = 1'b0;
    reg EX_Mflo = 1'b0;
    reg EX_Mthi = 1'b0;
    reg EX_Mtlo = 1'b0;
    reg [31:0] EX_MEM_ALU_result = 32'h00000000;
    reg [31:0] Wdata = 32'h00000000;
    
    wire [31:0] rd_data;
    wire EX_stall;
    wire Zero;
    wire Positive;
    wire Negative;
    wire Overflow;
    wire Div_0;
    wire [4:0] Waddr;
    wire [31:0] EX_ALU_result;
    wire [31:0] EX_rt_data;
    
    executs32 ex_test(
          .clock        (clock),
          .EX_opcplus4  (EX_opcplus4),
          .EX_A         (EX_A),
          .EX_B         (EX_B),
          .EX_rd_data   (EX_rd_data),
          .EX_IMM       (EX_IMM),
          .EX_func      (EX_func),
          .EX_op        (EX_op),
          .EX_shamt     (EX_shamt),
          .EX_write_address_0(EX_write_address_0),
          .EX_write_address_1(EX_write_address_1),
          .EX_Aluop     (EX_Aluop),
          .EX_Sftmd     (EX_Sftmd),
          .EX_Div       (EX_Div),
          .EX_Alusrc    (EX_Alusrc),
          .AluAsrc      (AluAsrc),
          .AluBsrc      (AluBsrc),
          .AluMsrc      (AluMsrc),
          .EX_I_format  (EX_I_format),
          .EX_Jrn       (EX_Jrn),
          .EX_Jalr      (EX_Jalr),
          .EX_Jal       (EX_Jal),
          .EX_Regdst    (EX_Regdst),
          .EX_Mfhi      (EX_Mfhi),
          .EX_Mflo      (EX_Mflo),
          .EX_Mthi      (EX_Mthi),
          .EX_Mtlo      (EX_Mtlo),
          .EX_MEM_ALU_result(EX_MEM_ALU_result),
          .Wdata        (Wdata),
          .rd_data      (rd_data),
          .EX_stall     (EX_stall),
          .Zero         (Zero),
          .Positive     (Positive),
          .Negative     (Negative),
          .Overflow     (Overflow),
          .Div_0        (Div_0),
          .Waddr        (Waddr),
          .EX_ALU_result(EX_ALU_result),
          .EX_rt_data   (EX_rt_data)
    );
    initial begin
      #200 begin
             EX_Sftmd = 1'b1;
             EX_Regdst = 1'b1;
           end
      #200 begin//lui $8 0xffff
             EX_Sftmd = 1'b0;
             EX_Regdst = 1'b0;
             EX_B = 32'h00000008;
             EX_Aluop = 2'b10;
             EX_IMM = 32'hffffffff;
             EX_func = 6'b111111;
             EX_op = 6'b001111;
             EX_shamt = 5'b11111;
             EX_write_address_0 = 5'h8;
             EX_write_address_1 = 5'b11111;
             EX_Alusrc = 1'b1;
             EX_I_format = 1'b1;
           end
      #200 begin//addiu $9 $0 61
             EX_B = 32'h00000009;
             EX_Aluop = 2'b10;
             EX_IMM = 32'h0000003d;
             EX_func = 6'h3d;
             EX_op = 6'b001001;
             EX_shamt = 5'h00;
             EX_write_address_0 = 5'h09;
             EX_write_address_1 = 5'h00;
             EX_Alusrc = 1'b1;
             AluAsrc = 2'b10;
             EX_I_format = 1'b1;
             EX_MEM_ALU_result = 32'hffff0000;
           end
      #200 begin//andi $10,$5,2
             EX_opcplus4 = 32'h00000001;
             EX_A = 32'h00000005;
             EX_B = 32'h0000000a;
             EX_Aluop = 2'b10;
             EX_IMM = 32'h00000002;
             EX_func = 6'b000010;
             EX_op = 6'b001100;
             EX_shamt = 5'h00;
             EX_write_address_0 = 5'h0a;
             EX_write_address_1 = 5'h00;
             EX_Alusrc = 1'b1;
             EX_I_format = 1'b1;
             EX_MEM_ALU_result = 32'h0000003d;
             Wdata = 32'hffff0000;
           end
      #200 begin//mult $8,$9
             EX_opcplus4 = 32'h00000002;
             EX_A = 32'hffff0000;//已经写进去了
             EX_B = 32'h00000009;//还没写进去，存在数据冒险
             EX_Aluop = 2'b10;
             EX_IMM = 32'h00000018;//这里并没用，只是要这么传进来
             EX_func = 6'b011000;
             EX_op = 6'b000000;
             EX_shamt = 5'h00;
             EX_write_address_0 = 5'h09;
             EX_write_address_1 = 5'h00;
             EX_Alusrc = 1'b0;//R型指令
             AluAsrc = 2'b00;
             AluBsrc = 2'b10;//与上上条指令冲突
             EX_I_format = 1'b0;
             EX_Regdst = 1'b1;
             EX_MEM_ALU_result = 32'h00000000;
             Wdata = 32'h0000003d;
           end
      #200 begin//mfhi $10
             EX_opcplus4 = 32'h00000003;
             EX_A = 32'h00000000;
             EX_B = 32'h00000000;
             EX_Aluop = 2'b10;
             EX_IMM = 32'h00005010;
             EX_func = 6'b010000;
             EX_op = 6'b000000;
             EX_shamt = 5'b00000;
             EX_write_address_0 = 5'b00000;
             EX_write_address_1 = 5'h0a;
             EX_Alusrc = 1'b0;
             AluAsrc = 2'b00;
             AluBsrc = 2'b00;
             EX_I_format = 1'b0;
             EX_Regdst = 1'b1;
             EX_Mfhi = 1'b1;
             EX_MEM_ALU_result = 32'hffff003d;
             Wdata = 32'h00000000;
           end
       #200 begin//mflo $11
             EX_opcplus4 = 32'h00000004;
             EX_A = 32'h00000000;
             EX_B = 32'h00000000;
             EX_Aluop = 2'b10;
             EX_IMM = 32'h00005812;
             EX_func = 6'b010010;
             EX_op = 6'b000000;
             EX_shamt = 5'b00000;
             EX_write_address_0 = 5'b00000;
             EX_write_address_1 = 5'h0b;
             EX_Alusrc = 1'b0;
             AluAsrc = 2'b00;
             AluBsrc = 2'b00;
             EX_I_format = 1'b0;
             EX_Regdst = 1'b1;
             EX_Mfhi = 1'b0;
             EX_Mflo = 1'b1;
             EX_MEM_ALU_result = 32'hffffffff;
             Wdata = 32'hffff003d;
           end
      #200 begin //sll $11 $1 6
             EX_opcplus4 = 32'h00000005;
             EX_A = 32'h00000000;
             EX_B = 32'h00000001;
             EX_Aluop = 2'b10;
             EX_IMM = 32'h00005980;
             EX_func = 6'b000000;
             EX_op = 6'b000000;
             EX_shamt = 6'h06;
             EX_write_address_0 = 5'h01;
             EX_write_address_1 = 5'h0b;
             EX_Sftmd = 1'b1;
             EX_Alusrc = 1'b0;
             AluAsrc = 2'b00;
             AluBsrc = 2'b00;
             EX_I_format = 1'b0;
             EX_Regdst = 1'b1;
             EX_Mflo = 1'b0;
             EX_MEM_ALU_result = 32'hffc30000;
             Wdata = 32'hffffffff;
           end
      #200 begin //beq $12,$1,loop
             EX_opcplus4 = 32'h00000006;
             EX_A = 32'h0000000c;
             EX_B = 32'h00000001;
             EX_Aluop = 2'b01;
             EX_IMM = 32'hffffffff;
             EX_func = 6'h3f;
             EX_op = 6'b000100;
             EX_shamt = 5'h1f;
             EX_write_address_0 = 5'h01;
             EX_write_address_1 = 5'h1f;
             EX_Sftmd = 1'b0;
             EX_Alusrc = 1'b0;
             AluAsrc = 2'b00;
             AluBsrc = 2'b00;
             EX_I_format = 1'b0;
             EX_Regdst = 1'b0;
             EX_MEM_ALU_result = 32'h00000040;
             Wdata = 32'hffc30000;
           end
    end
endmodule
