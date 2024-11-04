`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module Executs32(Read_data_1,Read_data_2,Sign_extend,Function_opcode,Exe_opcode,ALUOp,
                 Shamt,ALUSrc,I_format,Zero,Sftmd,ALU_Result,Add_Result,PC_plus_4
                 );
    input[31:0]  Read_data_1;		//r-form rs
    input[31:0]  Read_data_2;		//r-form rt
    input[31:0]  Sign_extend;		//i-form 立即数扩展
    input[5:0]   Function_opcode;  	//r-form instructions[5..0] 功能码，R型指令
    input[5:0]   Exe_opcode;  		//op code
    input[1:0]   ALUOp;
    input[4:0]   Shamt;             //从哪里来呢？前面好像并没有切分这一段指令
    input  		 Sftmd;
    input        ALUSrc;            //来自控制器，表明第二操作数是立即数
    input        I_format;
    output       Zero;
    output[31:0] ALU_Result;
    output[31:0] Add_Result;		//pc op        
    input[31:0]  PC_plus_4;
    
    reg[31:0] ALU_Result;
    wire[31:0] Ainput,Binput;
    reg[31:0] Cinput,Dinput;
    reg[31:0] Einput,Finput;
    reg[31:0] Ginput,Hinput;
    reg[31:0] Sinput;   //移位指令最后的结果
    reg[31:0] ALU_output_mux;
    wire[32:0] Branch_Add;
    wire[2:0] ALU_ctl;
    wire[5:0] Exe_code;
    wire[2:0] Sftm;
    wire Sftmd;
    reg s;
    
    //区别6种移位指令
    assign Sftm = Function_opcode[2:0];   // 实际有用的只有低三位(移位指令）
   
    //Exe_code赋值
    assign Exe_code = (I_format==0) ? Function_opcode : {3'b000,Exe_opcode[2:0]};
    
    //数据选择
    assign Ainput = Read_data_1;
    assign Binput = (ALUSrc == 0) ? Read_data_2 : Sign_extend[31:0]; //R/LW,SW  sft  else的时候含LW和SW
    
    //组合码表达式
    assign ALU_ctl[0] = (Exe_code[0] | Exe_code[3]) & ALUOp[1];      //24H AND 
    assign ALU_ctl[1] = ((!Exe_code[2]) | (!ALUOp[1]));
    assign ALU_ctl[2] = (Exe_code[1] & ALUOp[1]) | ALUOp[0];
 


always @* begin  // 6种移位指令
       if(Sftmd)
        case(Sftm[2:0])
            3'b000:Sinput = Binput << Shamt;			   //Sll rd,rt,shamt  00000
            3'b010:Sinput = Binput >> Shamt; 		       //Srl rd,rt,shamt  00010
            3'b100:Sinput = Binput << Ainput;                   //Sllv rd,rt,rs 000100
            3'b110:Sinput = Binput >> Ainput;                   //Srlv rd,rt,rs 000110
            3'b011:Sinput = ({32{Binput[31]}} << ~Shamt) | (Binput >> Shamt);         		//Sra rd,rt,shamt 00011
            3'b111:Sinput = ({32{Binput[31]}} << ~Ainput) | (Binput >> Ainput);		        //Srav rd,rt,rs 00111
            default:Sinput = Binput;
        endcase
       else Sinput = Binput;
    end
 
 //处理计算结果的输出
    always @* begin
        if(((ALU_ctl==3'b111) && (Exe_code[3]==1))||((ALU_ctl[2:1]==2'b11) && (I_format==1))) //slti(sub)  处理所有SLT类的问题
            ALU_Result =(Ainput < Binput)? 1'b1: 1'b0;
        else if((ALU_ctl==3'b101) && (I_format==1)) 
             ALU_Result[31:0] = (Binput<<16)&32'hFFFF0000;
        else if(Sftmd==1) ALU_Result = Sinput; 
        else  ALU_Result = ALU_output_mux[31:0]; //otherwise
    end
 
   //处理beq,bne指令
    assign Branch_Add = PC_plus_4[31:2] + Sign_extend[31:0] << 2;
    assign Add_Result = Branch_Add[31:0];   //算出的下一个PC值已经做了除4处理，所以不需左移16位
    assign Zero = (ALU_output_mux[31:0]== 32'h00000000) ? 1'b1 : 1'b0;
 
//算术运算和逻辑运算
    always @(ALU_ctl or Ainput or Binput) begin
        case(ALU_ctl)
            3'b000:ALU_output_mux = Ainput&Binput;
            3'b001:ALU_output_mux = Ainput|Binput;
            3'b010:ALU_output_mux = Ainput+Binput;
            3'b011:ALU_output_mux = Ainput+Binput;
            3'b100:ALU_output_mux = Ainput^Binput;
            3'b101:ALU_output_mux = ~(Ainput|Binput);
            3'b110:ALU_output_mux = Ainput-Binput;
            3'b111:ALU_output_mux = Ainput-Binput;
            default:ALU_output_mux = 32'h00000000;
        endcase
    end
endmodule
