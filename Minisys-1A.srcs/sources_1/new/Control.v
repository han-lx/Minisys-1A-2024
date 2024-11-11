`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/09 13:55:19
// Design Name: CPU控制单元，只包含控制信号的处理，不包含冒险处理
// Module Name: control32
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


module control32(
   input [31:0] Instruction,
   input s_format,//存数类型指令
   input l_format,//取数类型指令
   input [21:0] Alu_resultHigh,
   input Zero,//为了完成条件跳转指令
   input [31:0] read_data_1,//为了完成条件跳转指令的判断
   input clock,//上升沿状态变换
   input reset,//复位信号
   
   output Regdst,//目标寄存器，1为rd，0为rt
   output Alusrc,//????打个问号，后面怎么处理
   output MemIOtoReg,//从存储器或IO设备取数据到寄存器
   output RegWrite,//写寄存器
   output MemWrite,//写存储器
   output MemRead,//读存储器
   output IORead,//IO读
   output IOWrite,//IO写
   output Wir,//为1写IR寄存器
   output Waluresult,//为1写ALU_result寄存器
   //无条件跳转指令
   output Jmp,//Jmp指令
   output Jal,//Jal指令
   output Jalr,//Jalr指令，Minisys-1A新加
   output Jrn,//Jrn指令
   //条件跳转指令
   output [1:0] Wpc,//条件跳转指令的判断在控制模块完成
   output Beq,
   output Bne,
   output Bgez,
   output Bgtz,
   output Blez,
   output Bltz,
   output Bgezal,//写$31
   output Bltzal,//写$31
   //新增寄存器相关指令
   output Mfhi,//MFHI指令
   output Mflo,//MFLO指令
   output Mfc0,//MFC0指令
   output Mthi,//MTHI指令
   output Mtlo,//MTLO指令
   output Mtc0,//MTC0指令
   //其余信号
   output I_format,//该指令为除了条件跳转，存数取数以外的指令
   output S_format,//该指令为存储器写系列指令
   output L_format,//该指令为存储器读系列指令
   output Sftmd,//该指令为移位系列指令
   output Div,//该指令为除法指令，用来区分乘除法
   output [1:0] ALUop,//是R-类型或I_format=1时位1为1, 条件跳转指令则位0为1
   output Mem_sign,//字节，半字指令作何种扩展
   output [1:0] Mem_Dwidth,//读写存储器的数据位数，三种情况，用2位
   //异常中断相关信号
   output Break,//BREAK指令
   output Syscall,//SYSCALL指令
   output Eret,//ERET指令
   output Rsvd//保留指令
 );
   //状态机状态定义
   reg[2:0] state;
   reg[2:0] next_state;
   parameter[2:0] sinit = 3'b000,
                    sif = 3'b001,
                    sid = 3'b010,
                    sex = 3'b011,
                    smem = 3'b100,
                    swb = 3'b101;
    //指令读取
    wire R_format;//R型指令的所有
    wire [5:0] op,func;//R型指令具有的功能码，以及所有指令的操作码
    wire[4:0]   rs,rt;
    assign op = Instruction[31:26];
    assign func = Instruction[5:0];
    assign rs = Instruction[25:21];
    assign rt = Instruction[20:16];
    //R类型指令
    assign R_format = (op==6'b000000|| op==6'b010000);//加上MFC0,MTC0,ERET
    assign Jrn = (op==6'b000000&&func==6'b001000);
    assign Jalr = (op==6'b000000&&func==6'b001001);
    assign Mfhi = (op==6'b000000&&func==6'b010000);
    assign Mflo = (op==6'b000000&&func==6'b010010);
    assign Mthi = (op==6'b000000&&func==6'b010001);
    assign Mtlo = (op==6'b000000&&func==6'b010011);
    assign Mfc0 = (op==6'b010000&&func[5:3]==3'b000);
    assign Mtc0 = (op==6'b010000&&func[5:3]==3'b000);
    assign Break = (op==6'b000000&&func==6'b001101);
    assign Syscall = (op==6'b000000&&func==6'b001100);
    assign Eret = (op==6'b010000&&func==6'b011000);
    //I类型指令
    assign I_format = (op[5:3]==3'b001);//除条件转移指令及存取指令
    assign L_format = (op[5:3]==3'b100);//从存储器读
    assign S_format = (op[5:3]==3'b101);//写存储器
     //条件转移指令Wpc=01,J/Jal指令Wpc=10,Jr/Jalr指令Wpc=11;
    wire EBeq,EBne,EBgez,EBgtz,EBlez,EBltz,EBgezal,EBltzal;
    wire Branchs;
    assign Beq = (op==6'b000100);
    assign EBeq = (op==6'b000100&&Zero);
    assign Bne = (op==6'b000101);
    assign EBne = (op==6'b000101&&~Zero);
    assign Bgez = (op==6'b000001&&rt==5'b00001);
    assign EBgez = (op==6'b000001&&rt==5'b00001&&read_data_1[31]==1'b0);
    assign Bgtz = (op==6'b000111&&rt==5'b00000);
    assign EBgtz = (op==6'b000111&&rt==5'b00000&&read_data_1[31]==1'b0&&read_data_1!=32'd0);
    assign Blez = (op==6'b000110&&rt==5'b00000);
    assign EBlez = (op==6'b000110&&rt==5'b00000&&read_data_1[31]==1'b1);
    assign Bltz = (op==6'b000001&&rt==5'b00000);
    assign EBltz = (op==6'b000001&&rt==5'b00000&&read_data_1[31]==1'b1&&read_data_1!=32'd0);
    assign Bgezal = (op==6'b000001&&rt==5'b10001);
    assign Bltzal = (op==6'b000001&&rt==5'b00000);
    assign EBgezal = (Bgezal&&read_data_1[31]==1'b0);
    assign EBltzal = (Bltzal&&read_data_1[31]==1'b1&&read_data_1!=32'd0);
    assign Branchs = (EBeq||EBne||EBgez||EBgtz||EBlez||EBltz||EBgezal||EBltzal);
    //J指令
    assign Jmp = (op==6'b000010);
    assign Jal = (op==6'b000011);
    //Wpc的值
    assign Wpc = (Branchs) ? 2'b01 :
                 (Jmp || Jal) ? 2'b10 :
                 (Jrn || Jalr) ? 2'b11 :
                 2'b00;
     //读写信号
     assign MemRead = L_format&&(Alu_resultHigh!=22'b1111111111111111111111);
     assign IORead = L_format&&(Alu_resultHigh==22'b1111111111111111111111);
     assign MemWrite = S_format&&(Alu_resultHigh!=22'b1111111111111111111111);
     assign IOWrite = S_format&&(Alu_resultHigh==22'b1111111111111111111111);
     assign MemIOtoReg = L_format;
     //其余信号
     assign Sftmd = (op==6'b000000&&func[5:3]==3'b000);
     assign Div = (op==6'b000000&&func[5:1]==5'b01101);
     assign Mem_sign = !op[2];//符号扩展时为1
     assign Mem_Dwidth = op[1:0];//8位为00，16位为01，32位为11
     assign ALUop = {(R_format || I_format),(Beq || Bne || Bgez || Bgtz || Blez ||Bltz || Bgezal || Bltzal)}; 
     assign Alusrc = I_format||L_format||S_format;
     assign RegWrite = R_format? (func[5:3]==3'b100||func[5:1]==5'b10101||Jalr||Sftmd||Mfc0||Mfhi||Mflo):(I_format||L_format||Bgezal||Bltzal||Jal);
     assign Regdst = (R_format && !Mfc0);
     //保留信号
     assign Rsvd = !(R_format||I_format||L_format||S_format||Beq || Bne || Bgez || Bgtz || Blez ||Bltz || Bgezal || Bltzal||Jmp||Jal);
     
   
endmodule
