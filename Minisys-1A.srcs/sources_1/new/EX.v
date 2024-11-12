`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/11/11 18:57:02
// Design Name: CPU执行模块，负责进行各种运算，HI和LO寄存器也部署在这个模块
// Module Name: executs32
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


module executs32(
  input clock,//时钟信号
  input [31:0] EX_opcplus4,//从ID/EX模块传来PC+4值
  input [31:0] EX_A,//第一操作数
  input [31:0] EX_B,//第二操作数
  input [31:0] EX_rd_data,//从ID/EX模块传来的rd寄存器的值
  input [31:0] EX_IMM,//立即数扩展的结果
  input [5:0]  EX_func,//功能码
  input [5:0]  EX_op,//操作码
  input [4:0]  EX_shamt,//移位数
  input [4:0]  EX_write_address_0,
  input [4:0]  EX_write_address_1,
  //由控制模块产生，传入段间寄存器的控制信号
  input [1:0] EX_Aluop,
  input EX_Sftmd,
  input EX_Div,
  input EX_Alusrc,//用于选择第二操作数是立即数还是从寄存器组中读取的数据
  //接下来的信号是由转发处理模块（属于控制模块）传来的，用于解决数据冒险的一部分
  input [1:0] AluAsrc,//有3种选择，这是多路选择器的控制信号
  input [1:0] AluBsrc,
  input [1:0] AluFsrc,//目前看来这个操作不知道是做什么的
  
  input EX_I_format,
  input EX_Jrn,
  input EX_Jalr,
  input EX_Jal,
  input EX_Regdst,
  //乘除法相关，其中乘除法选择指令放在了上面
  input EX_Mfhi,
  input EX_Mflo,
  input EX_Mthi,
  input EX_Mtlo,
  //用于转发选择的数据
  input [31:0] EX_MEM_ALU_result,//当指令与前一条指令存在RAW冒险时，可以直接将前一条指令的运算结果转发过来进行运算
  input [31:0] Wdata,//最终写入寄存器的数据，这里也许是ALU的运算结果，也可能是从IO或者MEM中读出的数据，当当前指令与上上条指令存在RAW冒险时传入多路选择器
  
  output [31:0] rd_data,
  output reg EX_stall,//当进行乘除法运算时，乘除法的执行阶段占用多个时钟周期，此时流水线所有阶段都需要阻塞
  output Zero,//运算结果为0，传入控制单元
  //output Positive,//rs的值为正
  //output Negative,//rs的值为负，这一部分是否可以直接提前到译码阶段？
  output Overflow,//加减法结果溢出
  output reg Div_0,//除0操作，抛出异常
  output [4:0] Waddr,//写的寄存器号
  output reg [31:0] EX_ALU_result,//ALU计算结果
  output [31:0] EX_rt_data
  //output [31:0] PC_addr_result//计算出的分支指令的地址
);
  
  //首先选择到底哪个值进入ALU运算单元进行计算
  wire [31:0] A_input,B_input;//经过多路选择后最终进入ALU运算的操作数、
  //没有RAW-00，有RAW且与上条指令数据冲突-01，有RAW且与上上条指令数据冲突-10
  assign A_input = (AluAsrc == 2'b00) ? EX_A : (AluAsrc == 2'b01) ? EX_MEM_ALU_result : Wdata;
  //第二操作数要多加一层立即数的选择，立即数一定不会冲突，其余情况和第一操作数相同
  assign B_input = (EX_Alusrc == 1'b1) ? EX_IMM : (AluBsrc == 2'b00) ? EX_B : (AluBsrc == 2'b01) ? EX_MEM_ALU_result : Wdata;
  //同时要刷新流水线上的后面可能用到的寄存器的值
  assign EX_rt_data = (AluBsrc == 2'b00) ? EX_B : (AluBsrc == 2'b01) ? EX_MEM_ALU_result : Wdata;
  assign EX_rd_data = (AluFsrc == 2'b00) ? EX_rd_data : (AluFsrc == 2'b01) ? EX_MEM_ALU_result : Wdata;//这个后面做到转发的时候应该会明白
  
  //case1:处理移位指令
  reg [31:0] Sftmd_input;//存放移位指令的结果
  wire signed [31:0] S_A_input;//有符号数
  wire signed [31:0] S_B_input;//有符号数
  assign S_A_input = A_input;
  assign S_B_input = B_input;
  
  always @* begin
    if (EX_Sftmd) 
      case (EX_func[2:0])//后三位区分是什么指令
        3'b000: Sftmd_input = B_input << EX_shamt;//SLL
        3'b010: Sftmd_input = B_input >> EX_shamt;//SRL
        3'b011: Sftmd_input = S_B_input >>> EX_shamt;//SRA
        3'b100: Sftmd_input = B_input << A_input;//SLLV
        3'b110: Sftmd_input = B_input >> A_input;//SRLV
        3'b111: Sftmd_input = S_B_input >>> A_input;//SRAV
        default: Sftmd_input = B_input;
       endcase
     else Sftmd_input = B_input;//这两句其实没啥用
  end
  
  // case2:分支指令跳转地址计算(这个动作貌似已经在取指模块自己完成了?)
  //assign PC_addr_result = {ID_EX_opcplus4[29:0] , 2'b00} + {ID_EX_IMM[29:0] , 2'b00};
  
  //case3:算术/逻辑运算,不包含乘除法
  //控制码：最多8种运算
  wire[2:0] ALU_ctl;//控制码
  wire[5:0] Exe_code; //运算码
  //R型指令：运算码为功能码  
  //I型非存取及分支：运算码为000+操作码后三位
  assign Exe_code = (EX_I_format==0) ? EX_func:{3'b000,EX_op[2:0]};
  //000 & and,andi
  assign ALU_ctl = (EX_Aluop == 2'b10) ? Exe_code[2:0] : (EX_Aluop == 2'b01)? 3'b010 :3'b000;
  reg[32:0] Alu_output_mux;
  
  always @* begin
    case(ALU_ctl)
      3'b000: Alu_output_mux = S_A_input + S_B_input;//有符号加，add,addi,L_format,S_format
      3'b001: Alu_output_mux = A_input + B_input;//无符号加，addu,addiu
      3'b010: Alu_output_mux = S_A_input - S_B_input;//有符号减，sub,slt,slti,beq,bne
      3'b011: Alu_output_mux = A_input - B_input;//无符号减，subu,sltu,sltiu
      3'b100: Alu_output_mux = A_input & B_input;//与，and,andi
      3'b101: Alu_output_mux = A_input | B_input;//或，or,ori
      3'b110: Alu_output_mux = A_input ^ B_input;//同或，xor,xori
      3'b111: Alu_output_mux = ~(A_input | B_input);//异或，nor,lui
      default: Alu_output_mux = 32'd0;
    endcase
  end
   
  //一些输出的处理
  assign Zero = (Alu_output_mux[31:0] == 32'd0) ? 1'b1 : 1'b0;//结果为0信号
  //assign Positive = (EX_A[31] == 0 && EX_A[31:0]!=32'd0);
  //assign Negative = EX_A[31];
  //溢出判断
  assign Overflow = (ALU_ctl != 3'b000 && ALU_ctl != 3'b010) ? 1'b0 ://不是有符号加减运算
         (ALU_ctl == 3'b000) ? (S_A_input[31] == S_B_input[31] && S_A_input[31] != Alu_output_mux[31])://同号相加结果符号相反
         (S_A_input[31] != S_B_input[31] && S_B_input[31] != Alu_output_mux[31]);//异号相减结果符号与减数相同
         
  //case4:乘除法运算
  reg [31:0] HI;//结果高32位
  reg [31:0] LO;//结果低32位
  wire Mult,Multu,Div,Divu;
  assign Mult = (EX_op == 6'b000000 && EX_func == 6'b011000);
  assign Multu = (EX_op == 6'b000000 && EX_func == 6'b011001);
  assign Div = (EX_op == 6'b000000 && EX_func == 6'b011010);
  assign Divu = (EX_op == 6'b000000 && EX_func == 6'b011011);
  wire [63:0] Multi_result_signed;//有符号乘
  wire [63:0] Multi_result_unsigned;//无符号乘
  wire [63:0] Divd_result_signed;//有符号除
  wire [63:0] Divd_result_unsigned;//无符号除
  //有符号乘法，元件例化
  mult mult(.A(A_input),
            .B(B_input),
            .P(Multi_result_signed)
            );
  //无符号乘法，元件例化
  multu multu(.A(A_input),
              .B(B_input),
              .P(Multi_result_unsigned)
              );
  wire div_dout_tvalid;
  wire divu_dout_tvalid;
  wire div_zero;
  wire divu_zero;
  //有符号除法，元件例化
  div div(
    .aclk(clock),
    .s_axis_divisor_tvalid(EX_Div),
    .s_axis_divisor_tdata(B_input),//除数
    .s_axis_dividend_tvalid(EX_Div),
    .s_axis_dividend_tdata(A_input),//被除数
    .m_axis_dout_tvalid(div_dout_tvalid),//除法成功，有结果
    .m_axis_dout_tuser(div_zero),//除0
    .m_axis_dout_tdata(Divd_result_signed)
   ); 
  //无符号除法，元件例化
  divu divu(
    .aclk(clock),
    .s_axis_divisor_tvalid(EX_Div),
    .s_axis_divisor_tdata(B_input),//除数
    .s_axis_dividend_tvalid(EX_Div),
    .s_axis_dividend_tdata(A_input),//被除数
    .m_axis_dout_tvalid(divu_dout_tvalid),//除法成功，有结果
    .m_axis_dout_tuser(divu_zero),//除0
    .m_axis_dout_tdata(Divd_result_unsigned)
   ); 
  //乘除法阻塞流水线
  //初始状态阻塞信号为0
  initial begin
    EX_stall = 1'b0;
  end
  //需要寄存器来记录停顿周期数，只有当完成操作才能将流水线阻塞信号复位
  //由于我们现在对乘除法需要的时钟周期数并不清楚，因此我们在这里先预设一个比较大的停顿周期数
  reg [5:0] mult_stall;
  reg [5:0] multu_stall;
  reg [5:0] div_stall;
  reg [5:0] divu_stall;
  
  always @(posedge clock) begin
    if(Mult) begin
      mult_stall = mult_stall - 6'd1;
      if (mult_stall > 0) EX_stall = 1'b1;
      else EX_stall = 1'b0;
    end
    else begin
      mult_stall = 6'd10;//这个值不确定
    end
    if(Multu) begin
      multu_stall = multu_stall - 6'd1;
      if (multu_stall > 0) EX_stall = 1'b1;
      else EX_stall = 1'b0;
    end
    else begin
      multu_stall = 6'd10;//这个值不确定
    end
    if(Div) begin
      div_stall = div_stall - 6'd1;
      if (div_stall > 0) EX_stall = 1'b1;
      else EX_stall = 1'b0;
    end
    else begin
      div_stall = 6'd50;//这个值不确定
    end
    if(Divu) begin
      divu_stall = divu_stall - 6'd1;
      if (divu_stall > 0) EX_stall = 1'b1;
      else EX_stall = 1'b0;
    end
    else begin
      divu_stall = 6'd50;//这个值不确定
    end
  end
  //之后将乘除法的结果放入HI,LO寄存器，这里还包含单纯读写寄存器的指令
  always @(posedge clock) begin
    if (EX_Mthi)
      HI <= A_input;
    else if (EX_Mtlo)
      LO <= A_input;
    else if (Mult)
      {HI,LO} <= Multi_result_signed;
    else if (Multu)
      {HI,LO} <= Multi_result_unsigned;
    else if (EX_Div) begin//除法操作跟乘法不同
      if (Div) begin
        if (div_dout_tvalid)//除法成功才能赋值
          {HI,LO} <= Divd_result_signed;
        Div_0 <= div_zero;//后面需要抛出除0异常
      end
      else if (Divu) begin
        if (divu_dout_tvalid)
          {HI,LO} <= Divd_result_unsigned;
        Div_0 <= divu_zero;
      end
    end
  end
  
  //最后这个进程是完成计算之后将结果写入段间寄存器的操作
  always @* begin
    if (EX_Mfhi)
      EX_ALU_result = HI;
    else if (EX_Mflo)
      EX_ALU_result = LO;
    else if ((ALU_ctl == 3'b111) && (EX_I_format == 1'b1))//处理lui指令
      EX_ALU_result = {B_input[15:0] , 16'd0};
    else if ((ALU_ctl [2:1] == 2'b01) && (EX_Aluop[1] == 1'b1) && (Exe_code[5:3] != 3'b100))//SLT系列指令
      EX_ALU_result = {31'd0 , Alu_output_mux[32]};
    else if (EX_Sftmd)//移位指令
      EX_ALU_result = Sftmd_input;
    else if (EX_Jal || EX_Jalr)
      EX_ALU_result = EX_opcplus4;
    else
      EX_ALU_result = Alu_output_mux[31:0];
  end
  
endmodule
