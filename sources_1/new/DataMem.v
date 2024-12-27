`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2024/12/16 21:30:57
// Design Name: �洢ģ�飬���ý���洢���Ľṹ
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

//�������ͼ����64KB������RAM��Ϊ�ĸ�16KB��RAM�����Ҳ��ý���洢�ķ�ʽ
module MEM(
  input ram_clk_input,//RAMģ���ʱ���źţ��Ŀ�RAM����һ��
  input ram_we_input,//���Կ���ģ��
  input [1:0] Mem_Dwidth,//��д���ݵĳ��ȣ����ֽڶ������ֶ���ȫ�ֶ�
  input ram_sign,
  input [15:0] ram_addr_input,//��memorioģ�鴫�룬����ִ�е�Ԫ�������alu_result
  input [31:0] ram_data_input,//��ӦS����ָ�Ҫд��洢��������
  output reg[31:0] ram_data_output,//��ӦL����ָ�����洢���ж���������
  output reg bit_error//���ش���
    );
  //��������һЩ�ź�
  wire ram_clk = ram_clk_input;
  reg [3:0] ram_we;
  wire [7:0] ram0_data, ram1_data, ram2_data, ram3_data;
  
  //��Ϥ��Ԫ����������,�Ӹ�λ����λ��������ram3210
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
      
 //��������������дʹ�ܶ���λ
   always @(*) begin
     ram_we = 4'd0;//��ʼʱ���ĸ�RAM��дʹ�ܶ�����λ
     bit_error = 1'b0;//����λ����Ҳ����
     case(Mem_Dwidth)
       2'b00:begin//�ֽڶ�������ַ��λ�Ƿ�4����
         ram_we[0] = (ram_addr_input[1:0] == 2'b00) && ram_we_input;
         ram_we[1] = (ram_addr_input[1:0] == 2'b01) && ram_we_input;
         ram_we[2] = (ram_addr_input[1:0] == 2'b10) && ram_we_input;
         ram_we[3] = (ram_addr_input[1:0] == 2'b11) && ram_we_input;
       end
       2'b01:begin
         //�������ĵ�ַ����2�ı���ʱ��˵������İ��ֶ�д����������
         bit_error = ram_addr_input[0];//����ַ���һλΪ1˵�������ܱ�2����
         ram_we[1:0] = {2{(ram_addr_input[1] == 1'b0) && ram_we_input}};
         ram_we[3:2] = {2{(ram_addr_input[1] == 1'b1) && ram_we_input}};
       end
       2'b11:begin
         //�������ĵ�ַ����4�ı���ʱ�򣬷�������
         bit_error = (!(ram_addr_input[1:0] == 2'b00));
         ram_we = {4{ram_we_input}}; 
       end
       default:bit_error = ram_we_input;//Ĭ��Ϊ0��������дΪ0������д��ʱ�������Ѿ�����
     endcase
   end
 //�������������ɴ洢���Ķ�
   always @(*) begin
     case(Mem_Dwidth)
       2'b00:begin//�ֽڶ�д
         case(ram_addr_input[1:0])
           2'b00:begin ram_data_output[7:0] = ram0_data;end
           2'b01:begin ram_data_output[7:0] = ram1_data;end
           2'b10:begin ram_data_output[7:0] = ram2_data;end
           2'b11:begin ram_data_output[7:0] = ram3_data;end
         endcase
         ram_data_output[31:8] = {24{ram_sign & ram_data_output[7]}};//ǰ24λ���÷�����չ����0��չ
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
