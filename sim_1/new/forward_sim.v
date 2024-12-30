`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/12/28 23:58:33
// Design Name: 转发模块仿真数据，几个简单的小指令
// Module Name: forward_sim
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


module forward_sim(

    );
    reg [4:0] ID_rs = 5'd0;
    reg [4:0] ID_rt = 5'd0;
    reg ID_Mflo = 1'b0;
    reg ID_Mfhi = 1'b0;
    reg [4:0] EX_rs = 5'd0;
    reg [4:0] EX_rt = 5'd0;
    reg EX_Mflo = 1'b0;
    reg EX_Mfhi = 1'b0;
    reg ID_EX_RegWrite = 1'b0;
    reg [4:0] ID_EX_Waddr = 5'd0;
    reg ID_EX_Mtlo = 1'b0;
    reg ID_EX_Mthi = 1'b0;
    reg EX_MEM_RegWrite = 1'b0;
    reg [4:0] EX_MEM_Waddr = 5'd0;
    reg EX_MEM_Mtlo = 1'b0;
    reg EX_MEM_Mthi = 1'b0;
    reg MEM_WB_RegWrite = 1'b0;
    reg [4:0] MEM_WB_Waddr = 5'd0;
    reg MEM_WB_Mtlo = 1'b0;
    reg MEM_WB_Mthi = 1'b0;
    reg [4:0] EX_rd = 5'd0;
    
    wire [1:0] AluAsrc;
    wire [1:0] AluBsrc;
    wire [1:0] AluCsrc;
    wire [1:0] AluDsrc;
    wire [1:0] AluMsrc;
    
    forward forward_test(
          .ID_rs        (ID_rs),
          .ID_rt        (ID_rt),
          .ID_Mflo      (ID_Mflo),
          .ID_Mfhi      (ID_Mfhi),
          .EX_rs        (EX_rs),
          .EX_rt        (EX_rt),
          .EX_Mflo      (EX_Mflo),
          .EX_Mfhi      (EX_Mfhi),
          .ID_EX_RegWrite(ID_EX_RegWrite),
          .ID_EX_Waddr  (ID_EX_Waddr),
          .ID_EX_Mtlo   (ID_EX_Mtlo),
          .ID_EX_Mthi   (ID_EX_Mthi),
          .EX_MEM_RegWrite(EX_MEM_RegWrite),
          .EX_MEM_Waddr (EX_MEM_Waddr),
          .EX_MEM_Mtlo  (EX_MEM_Mtlo),
          .EX_MEM_Mthi  (EX_MEM_Mthi),
          .MEM_WB_RegWrite(MEM_WB_RegWrite),
          .MEM_WB_Waddr (MEM_WB_Waddr),
          .MEM_WB_Mtlo  (MEM_WB_Mtlo),
          .MEM_WB_Mthi  (MEM_WB_Mthi),
          .EX_rd        (EX_rd),
          
          .AluAsrc      (AluAsrc),
          .AluBsrc      (AluBsrc),
          .AluCsrc      (AluCsrc),
          .AluDsrc      (AluDsrc),
          .AluMsrc      (AluMsrc)
    );
   
   initial begin
     #200 begin end//取指
     #200 begin//译码
            ID_rs = 5'b00010;
            ID_rt = 5'b00011;
          end
     #200 begin//执行
            ID_rs = 5'b00001;
            ID_rt = 5'b00101;
            EX_rs = 5'b00010;
            EX_rt = 5'b00011;
            ID_EX_RegWrite = 1'b1;
            ID_EX_Waddr = 5'b00001;
            EX_rd = 5'b00001;
          end
     #200 begin
            ID_rs = 5'b00010;
            ID_rt = 5'b00001;
            EX_rs = 5'b00001;
            EX_rt = 5'b00101;
            ID_EX_RegWrite = 1'b1;
            ID_EX_Waddr = 5'b00010;
            EX_MEM_RegWrite = 1'b1;
            EX_MEM_Waddr = 5'b00001;
            EX_rd = 5'b00010;
          end
     #200 begin
            ID_rs = 5'b01000;
            ID_rt = 5'b00010;
            EX_rs = 5'b00010;
            EX_rt = 5'b00001;
            ID_EX_RegWrite = 1'b1;
            ID_EX_Waddr = 5'b01000;
            EX_MEM_RegWrite = 1'b1;
            EX_MEM_Waddr = 5'b00010;
            MEM_WB_RegWrite = 1'b1;
            MEM_WB_Waddr = 5'b00001;
            EX_rd = 5'b01000;
          end
     #200 begin
            ID_rs = 5'b00000;
            ID_rt = 5'b00000;
            EX_rs = 5'b01000;
            EX_rt = 5'b00010;
            ID_EX_RegWrite = 1'b0;
            ID_EX_Waddr = 5'b00000;
            EX_MEM_RegWrite = 1'b1;
            EX_MEM_Waddr = 5'b01000;
            MEM_WB_RegWrite = 1'b1;
            MEM_WB_Waddr =  5'b00010;
            EX_rd = 5'b00000;    
          end
     #200 begin
             EX_rs = 5'b00000;
             EX_rt = 5'b00000;
             EX_MEM_RegWrite = 1'b0;
             EX_MEM_Waddr = 5'b00000;
             MEM_WB_RegWrite = 1'b1;
             MEM_WB_Waddr =  5'b01000;
          end
     #200 begin
            MEM_WB_RegWrite = 1'b0;
            MEM_WB_Waddr = 5'b00000;
          end 
   end
endmodule
