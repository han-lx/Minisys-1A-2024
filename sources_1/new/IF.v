`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/10 16:11:35
// Design Name: CPU取指单元，其中下条PC的地址通过控制模块中的Wpc给出，并且暂时还没实现分支预测
// Module Name: ifetch32
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


module ifetch32(
   input reset,//复位信号 高电平有效
   input clock,//时钟信号
   input [1:0] Wpc,//控制模块传入的写PC信号，用于选择写哪个PC
   input EX_stall,//阻塞信号
   input WPC,//写PC寄存器
   //下条PC地址的计算
   input [25:0] Jpc,//译码模块传入的跳转值，用于JMP指令和JAL指令的跳转
   input [31:0] read_data_1,//译码模块传入的rs寄存器的值，用于JR和JALR指令的跳转
   input [31:0] ID_Npc,//译码模块传入的PC+4的值，同样用于选择器的计算
   input Branch,
   input nBranch,
   
   output reg[31:0] PC,//当前指令的PC值
   output [31:0] opcplus4,//用于JAL和JALR指令的值相比PC+4已经右移2位
   output [31:0] Instruction,//传入IF_ID模块的写入IR寄存器的值
   //关于程序ROM的读出
   output [13:0] rom_read_addr,//64KB,按字节编址，因此只需14位即可，高位均为0，传入程序ROM，已经右移两位，写存储器的人注意一下
   input [31:0] Jpadr,//从程序ROM中读取的指令内容
   //中断异常处理
   input [31:0] Interrupt_pc,//中断处理程序的位置
   input recover,//为1时表示从中断恢复
   input cp0_wen,//中断异常
   output reg IF_recover//中断返回,寄存器，记录状态
    );
    
    reg [31:0] next_PC;//下条指令的地址
   wire [31:0] pc_plus_4;//计算出的PC+4的值,传入IF_ID模块的NPC值
    
    
    assign Instruction = Jpadr;//从程序ROM中取出的指令
    assign rom_read_addr = PC[15:2];//指令地址的低2位始终为0，因此这里省略
    assign pc_plus_4 = { PC[31:2] + 1 , 2'b00};//计算PC+4的值
    assign opcplus4 = { 2'b00 , pc_plus_4[31:2]};//PC+4的值右移2位
    
    wire [15:0] offset = Instruction[15:0];
    wire sign = offset[15];
    
    //开始计算next_PC的值，立刻计算(右移2位后的结果）
    always @* begin
      if (cp0_wen) next_PC = Interrupt_pc >> 2;//如果写CP0使能，那么则进入中断处理程序，下条指令为中断处理程序入口
      else if (nBranch) next_PC = ID_Npc;//存在分支但预测失败，那么直接刷洗流水线，这里已经右移过了
      else if (Wpc == 2'b10) next_PC = {6'b000000 , Jpc} ;//JMP和JAL指令
      else if (Wpc == 2'b11) next_PC = read_data_1 >> 2;//JR和JALR指令,这里应该要右移的吧
      else if (Wpc == 2'b01) next_PC = {2'b00 ,pc_plus_4[31:2]} + { {16{sign}}, offset};//分支成功则跳转，这条一定写在nBranch下面 
      else next_PC = {2'b00, pc_plus_4[31:2]};//一般情况，PC+4
    end
    
    //时钟下降沿写PC
    always @(negedge clock) begin
      IF_recover = recover;
      if (reset) PC = 32'h00000000;//复位时PC回到全0初始值
      else if (WPC && EX_stall!=1'b1) PC = next_PC << 2;
    end
    
endmodule
