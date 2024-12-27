`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/12/22 22:47:24
// Design Name: 
// Module Name: idecode32_sim
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


module idecode32_sim(

    );
    //input
    reg reset = 1'b1;
    reg clock = 1'b0;
    reg [31:0] ID_opcplus4 = 32'h00000000;
    reg [31:0] Instruction = 32'h00000000;
    reg [31:0] Wdata = 32'h00000000;
    reg [31:0] Waddr = 32'h00000000;
    reg Jal = 1'b0;
    reg Jalr = 1'b0;
    reg Bgezal = 1'b0;
    reg Bltzal = 1'b0;
    reg Negative = 1'b0;
    reg RegWrite = 1'b0;
    //output
    wire [31:0] ID_Jpc;
    wire [31:0] read_data_1;
    wire [31:0] read_data_2;
    wire [4:0] write_address_1;
    wire [4:0] write_address_0;
    wire [31:0] write_data;
    wire [4:0] write_register_address;
    wire [31:0] sign_extend;
    wire [4:0] rs;
    wire [31:0] rd_data;
    
    idecode32 id_test(
           .reset        (reset),
           .clock        (clock),
           .ID_opcplus4  (ID_opcplus4),
           .Instruction  (Instruction),
           .Wdata        (Wdata),
           .Waddr        (Waddr),
           .Jal          (Jal),
           .Jalr         (Jalr),
           .Bgezal       (Bgezal),
           .Bltzal       (Bltzal),
           .Negative     (Negative),
           .RegWrite     (RegWrite),
           
           .ID_Jpc       (ID_Jpc),
           .read_data_1  (read_data_1),
           .read_data_2  (read_data_2),
           .write_address_1(write_address_1),
           .write_address_0(write_address_0),
           .write_data   (write_data),
           .write_register_address(write_register_address),
           .sign_extend  (sign_extend),
           .rs           (rs),
           .rd_data      (rd_data)
    );
    
    initial begin
      #200 reset = 1'b0;
      #200 begin//1
             Instruction = 32'h3c08ffff;//lui
           end
      #100 begin//2
             Instruction = 32'h2409003d;//addiu
           end
      #100 begin//3
             Instruction = 32'h01095020;
             RegWrite = 1'b1;//模拟真实情况，写寄存器要晚3个半时钟周期，半个是因为在下降沿写
           end
      #100 begin//4
             Instruction = 32'h0c000005;//jal
             ID_opcplus4 = 32'h00000001;
             Wdata = 32'hffff0000;
             Waddr = 5'h8;
           end
      #100 begin//5
             Instruction = 32'h00000000;//stall一下
             ID_opcplus4 = 32'h00000002;
             Wdata = 32'h0000003d;
             Waddr = 5'h9;
           end
      #100 begin//6
             Instruction = 32'h05910002;//bgezal
             ID_opcplus4 = 32'h00000003;
             Wdata = 32'hffff003d;
             Waddr = 5'ha;
           end
      #100 begin//7
             Instruction = 32'h04100003;
             ID_opcplus4 = 32'h00000004;
             Wdata = 32'h00000000;
             Waddr = 5'h0;
             Jal = 1'b1;
           end
      #100 begin//8
             Instruction = 32'h00000000;
             ID_opcplus4 = 32'h00000000;
             Wdata = 32'h00000030;
             Waddr = 5'h0;
             Jal = 1'b0;
           end;
      #100 begin//9
             Instruction = 32'h0000f009;
             ID_opcplus4 = 32'h00000006;
             Wdata = 32'hfffffffb;
             Waddr = 5'h11;
             Bgezal = 1'b1;
           end
      #100 begin//10
             Instruction = 32'h00000000;
             ID_opcplus4 = 32'h00000009;
             Wdata = 32'hfffffff0;
             Waddr = 5'h10;
             Bgezal = 1'b0;
             Bltzal = 1'b1;
           end
      #100 begin//11
             Instruction = 32'h3c08ffff;
             ID_opcplus4 = 32'h00000000;
             Wdata = 32'h00000000;
             Waddr = 5'h00;
             Bltzal = 1'b0;
           end
      #100 begin//12
             ID_opcplus4 = 32'h0000000a;
             Wdata = 32'h0000000a;
             Waddr = 5'h1e;
             Jalr = 1'b1;
           end 
    end
    always #100 clock = ~clock;
endmodule
