`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/22 15:44:24
// Design Name: 
// Module Name: ifetch32_sim
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


module ifetch32_sim(

    );
    //input
    reg reset = 1'b1;//œ¬Ωµ—ÿ÷√Œª
    reg clock = 1'b0;
    reg [1:0] Wpc = 2'b0;
    reg EX_stall = 1'b0;
    reg WPC =  1'b0;
    reg [25:0] Jpc = 25'd0;
    reg [31:0] read_data_1 = 32'h00000000;
    reg [31:0] ID_Npc = 32'h00000000;
    reg [31:0] Jpadr = 32'h00000000;
    reg [31:0] Interrupt_pc = 32'h00000000;
    reg recover = 1'b0;
    reg cp0_wen = 1'b0;
    reg Branch = 1'b0;
    reg nBranch = 1'b0;
    
    //output
    wire [31:0] PC;
    wire [31:0] opcplus4;
    wire [31:0] Instruction;
    wire [13:0] rom_read_addr;
    wire IF_recover;
    
    ifetch32 if_test(
            .reset        (reset),
            .clock        (clock),
            .Wpc          (Wpc),
            .EX_stall     (EX_stall),
            .WPC          (WPC),
            .Jpc          (Jpc),
            .read_data_1  (read_data_1),
            .ID_Npc       (ID_Npc),
            .Jpadr        (Jpadr),
            .Interrupt_pc (Interrupt_pc),
            .recover      (recover),
            .cp0_wen      (cp0_wen),
            .Branch       (Branch),
            .nBranch      (nBranch),
            
            .PC           (PC),
            .opcplus4     (opcplus4),
            .Instruction  (Instruction),
            .rom_read_addr(rom_read_addr),
            .IF_recover   (IF_recover)
    );
    
    initial begin
      begin 
        Jpadr = 32'h00440820;
        WPC = 1'b1; 
      end
      #100 reset = 1'b0;//∏¥Œª≤‚ ‘
      #50  begin Jpadr = 32'h1181ffff;nBranch = 1'b1;ID_Npc = 32'd2;Wpc = 2'b01;end//beq
      #200 begin Jpadr = 32'h01044022;nBranch = 1'b0;Wpc = 2'b00;end//sub
      #100 begin Jpadr = 32'h1500fffe;Wpc = 2'b01;end//bne
      #100 begin Jpadr = 32'h01044022;Wpc = 2'b00;end//sub
      #100 begin Jpadr = 32'h1500fffe;nBranch = 1'b1;ID_Npc=32'd4;end//bne
      #100 begin Jpadr = 32'h10210002;nBranch = 1'b0;Wpc = 2'b01;end//beq
      #100 begin Jpadr = 32'h04010001;Wpc = 2'b01;end//bgez
      #100 begin Jpadr = 32'h19200001;nBranch = 1'b1;ID_Npc = 32'd10;end//blez
      #100 begin Jpadr = 32'h1d200001;nBranch = 1'b0;end//bgtz
      #100 begin Jpadr = 32'h05800001;nBranch = 1'b1;ID_Npc = 32'd13;end//bltz
      #100 begin Jpadr = 32'h05910002;nBranch = 1'b0;end//bgezal
      #100 begin Jpadr = 32'h05300003;nBranch = 1'b1;ID_Npc = 32'd17;end//bltzal
      #100 begin Jpadr = 32'h08000014;nBranch = 1'b0;Wpc = 2'b10;Jpc = 32'h00000014;end//j
      #100 begin Jpadr = 32'h0000f009;Wpc = 2'b11;read_data_1 = 32'd0;end//jalr
      #100 begin Jpadr = 32'h00430820;Wpc = 2'b00;end//add
    end
    always #50 clock = ~clock;
endmodule
