`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/12/27 22:35:53
// Design Name: 分支模块的仿真测试
// Module Name: branch_sim
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


module branch_sim(

    );
    reg [5:0] IF_ID_op = 32'h00000000;
    reg Beq = 1'b0;
    reg Bne = 1'b0;
    reg Bgez = 1'b0;
    reg Bgtz = 1'b0;
    reg Blez = 1'b0;
    reg Bltz = 1'b0;
    reg Bgezal = 1'b0;
    reg Bltzal = 1'b0;
    reg Jrn = 1'b0;
    reg Jalr = 1'b0;
    reg Jmp = 1'b0;
    reg Jal = 1'b0;
    reg CTL_Alusrc = 1'b0;
    reg IF_WPC = 1'b0;
    reg [1:0] FWD_AluCsrc = 2'b00;
    reg [1:0] FWD_AluDsrc = 2'b00;
    reg MemorIORead = 1'b0;
    reg [31:0] ID_read_data_1 = 32'h00000000;
    reg [31:0] ID_read_data_2 = 32'h00000000;
    reg [31:0] ID_sign_extend = 32'h00000000;
    reg [31:0] EX_ALU_result = 32'h00000000;
    reg [31:0] MEM_ALU_result = 32'h00000000;
    reg [31:0] MemorIOData = 32'h00000000;
    reg [31:0] Wdata = 32'h00000000;
    
    wire Branch;
    wire nBranch;
    wire IF_flush;
    wire [1:0] Wpc;
    wire [31:0] rs_data;
    
    branchprocess branch_test(
          .IF_ID_op        (IF_ID_op),
          .Beq             (Beq),
          .Bne             (Bne),
          .Bgez            (Bgez),
          .Bgtz            (Bgtz),
          .Blez            (Blez),
          .Bltz            (Bltz),
          .Bgezal          (Bgezal),
          .Bltzal          (Bltzal),
          .Jrn             (Jrn),
          .Jalr            (Jalr),
          .Jmp             (Jmp),
          .Jal             (Jal),
          .CTL_Alusrc      (CTL_Alusrc),
          .IF_WPC          (IF_WPC),
          .FWD_AluCsrc     (FWD_AluCsrc),
          .FWD_AluDsrc     (FWD_AluDsrc),
          .MemorIORead     (MemorIORead),
          .ID_read_data_1  (ID_read_data_1),
          .ID_read_data_2  (ID_read_data_2),
          .ID_sign_extend  (ID_sign_extend),
          .EX_ALU_result   (EX_ALU_result),
          .MEM_ALU_result  (MEM_ALU_result),
          .MemorIOData     (MemorIOData),
          .Wdata           (Wdata),
          .Branch          (Branch),
          .nBranch         (nBranch),
          .IF_flush        (IF_flush),
          .Wpc             (Wpc),
          .rs_data         (rs_data)
    );
    
    initial begin
      #200 begin IF_WPC = 1'b1; end
      #200 begin //add
             IF_ID_op = 6'b000000;
             CTL_Alusrc = 1'b0;
             ID_read_data_1 = 32'h00000002;
             ID_read_data_2 = 32'h00000003;
           end 
      #200 begin//beq
             IF_ID_op = 6'b000100;
             Beq = 1'b1;
             CTL_Alusrc = 1'b0;
             FWD_AluCsrc = 2'b01;
             ID_read_data_1 = 32'h00000001;
             ID_read_data_2 = 32'h00000002;
             EX_ALU_result = 32'h00000005;
           end
      #200 begin//洗刷流水线，恢复一下状态吧
             IF_ID_op = 6'b000000;
             Beq = 1'b0;
             FWD_AluCsrc = 2'b00;
             EX_ALU_result = 32'h00000003;
             MEM_ALU_result = 32'h00000005;   
           end
      #200 begin//bne
             IF_ID_op = 6'b000101;
             Bne = 1'b1;
             FWD_AluCsrc = 2'b11;
             ID_read_data_1 = 32'h00000001;
             ID_read_data_2 = 32'h00000003;
             MEM_ALU_result = 32'h00000003;
             Wdata = 32'h00000005;
           end
      #200 begin//flush
             IF_ID_op = 6'b000000;
             Bne = 1'b0;
             FWD_AluCsrc = 2'b00;
             EX_ALU_result = 32'h00000002;
             Wdata = 32'h00000003;
           end
      #200 begin//bgez
             IF_ID_op = 6'b000001;
             Bgez = 1'b1;
             ID_read_data_1 = 32'h00000008;
             ID_read_data_2 = 32'h00000005;
             MEM_ALU_result = 32'h00000002;
           end
      #200 begin//flush
             IF_ID_op = 6'b000000;
             Bgez = 1'b0;
             Wdata = 32'h00000002;
           end
      #200 begin//jal
             IF_ID_op = 6'b000011;
             Jal = 1'b1;
             ID_read_data_1 = 32'd0;
             ID_read_data_2 = 32'd0;
           end
      #200 begin//flush
             IF_ID_op = 6'b000000;
             Jal = 1'b0;
             EX_ALU_result = 32'h0000001c;
           end
      #200 begin//bgezal
             IF_ID_op = 6'b000001;
             Bgezal = 1'b1;
             MEM_ALU_result = 32'h0000001c;
             ID_read_data_1 = 32'h00000007;
             ID_read_data_2 = 32'h00000011;
           end
      #200 begin//flush
             IF_ID_op = 6'b000000;
             Bgezal = 1'b0;
             EX_ALU_result = 32'h0000002c;
             Wdata = 32'h0000001c;
           end
      #200 begin//jalr
             IF_ID_op = 6'b000000;
             Jalr = 1'b1;
             ID_read_data_1 = 32'h00000005;
             ID_read_data_2 = 32'h00000000;
             MEM_ALU_result = 32'h0000002c;
           end
      #200 begin//
             IF_ID_op = 6'b000000;
             Jalr = 1'b0;
             Wdata = 32'h0000002c;
             EX_ALU_result = 32'h00000034;
           end
    end
endmodule
