`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/12/16 21:30:57
// Design Name: 存储模块，采用交叉存储器的结构
// Module Name: MEM
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

//根据设计图，将64KB的数据RAM分为四个16KB的RAM，并且采用交叉存储的方式
module MEM(
  input ram_clk_input,//RAM模块的时钟信号，四块RAM共用一个
  input ram_we_input,//来自控制模块
  input [1:0] Mem_Dwidth,//读写数据的长度，有字节读，半字读，全字读
  input ram_sign,
  input [15:0] ram_addr_input,//由memorio模块传入，来自执行单元计算出的alu_result
  input [31:0] ram_data_input,//对应S类型指令，要写入存储器的数据
  output reg[31:0] ram_data_output,//对应L类型指令，输出存储器中读到的数据
  output reg bit_error//比特错误
    );
  //接下来是一些信号
  wire ram_clk = ram_clk_input;
  reg [3:0] ram_we;
  wire [7:0] ram0_data, ram1_data, ram2_data, ram3_data;
  
  //熟悉的元件例化过程,从高位到低位，依次是ram3210
    ram0 ram0 (
       .clka     (ram_clk),
       .wea      (ram_we[0]),
       .addra    (ram_addr_input[15:2]),
       .dina     (ram_data_input[7:0]),
       .douta    (ram0_data)
   );
   
     ram1 ram1 (
        .clka     (ram_clk),
        .wea      (ram_we[1]),
        .addra    (ram_addr_input[15:2]),
        .dina     (ram_data_input[15:8]),
        .douta    (ram1_data)
    );
    
      ram2 ram2 (
         .clka     (ram_clk),
         .wea      (ram_we[2]),
         .addra    (ram_addr_input[15:2]),
         .dina     (ram_data_input[23:16]),
         .douta    (ram2_data)
     );
     
       ram3 ram3 (
          .clka     (ram_clk),
          .wea      (ram_we[3]),
          .addra    (ram_addr_input[15:2]),
          .dina     (ram_data_input[31:24]),
          .douta    (ram3_data)
      );
      
 //下面这个进程完成写使能端置位
   always @(*) begin
     ram_we = 4'd0;//初始时，四个RAM的写使能都不置位
     bit_error = 1'b0;//比特位错误也不置
     case(Mem_Dwidth)
       2'b00:begin//字节读，看地址低位是否被4整除
         ram_we[0] = (ram_addr_input[1:0] == 2'b00) && ram_we_input;
         ram_we[1] = (ram_addr_input[1:0] == 2'b01) && ram_we_input;
         ram_we[2] = (ram_addr_input[1:0] == 2'b10) && ram_we_input;
         ram_we[3] = (ram_addr_input[1:0] == 2'b11) && ram_we_input;
       end
       2'b01:begin
         //当给出的地址不是2的倍数时，说明这里的半字读写出现了问题
         bit_error = ram_addr_input[0];//当地址最后一位为1说明并不能被2整除
         ram_we[1:0] = {2{(ram_addr_input[1] == 1'b0) && ram_we_input}};
         ram_we[3:2] = {2{(ram_addr_input[1] == 1'b1) && ram_we_input}};
       end
       2'b11:begin
         //当给出的地址不是4的倍数时候，发生错误
         bit_error = (!(ram_addr_input[1:0] == 2'b00));
         ram_we = {4{ram_we_input}}; 
       end
       default:bit_error = ram_we_input;//默认为0，不发生写为0，发生写的时候上面已经处理
     endcase
   end
 //下面这个进程完成存储器的读
   always @(*) begin
     case(Mem_Dwidth)
       2'b00:begin//字节读写
         case(ram_addr_input[1:0])
           2'b00:begin ram_data_output[7:0] = ram0_data;end
           2'b01:begin ram_data_output[7:0] = ram1_data;end
           2'b10:begin ram_data_output[7:0] = ram2_data;end
           2'b11:begin ram_data_output[7:0] = ram3_data;end
         endcase
         ram_data_output[31:8] = {24{ram_sign & ram_data_output[7]}};//前24位采用符号扩展或者0扩展
       end
       2'b01:begin
         if(!bit_error) begin
           case(ram_addr_input[1])
             1'b0:begin ram_data_output[15:0] = {ram1_data, ram0_data};end
            1'b1:begin ram_data_output[15:0] = {ram3_data, ram2_data};end
           endcase
           ram_data_output[31:16] = {16{ram_sign & ram_data_output[15]}};
         end
       end
       2'b11:begin
         if(!bit_error)
           ram_data_output = {ram3_data, ram2_data, ram1_data, ram0_data};
       end
     endcase
   end
endmodule
