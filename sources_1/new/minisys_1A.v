`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2025/01/03 20:53:42
// Design Name: 最后的连线文件啦，最顶层的封装
// Module Name: minisys_1A
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


module minisys_1A(
  input FPGA_reset,//板上的复位信号
  input FPGA_clock,//板上的时钟信号，频率为100Mhz
  //接下来是一些外设设备相关
  input [4:0] button,//五位，每一位代表一个按钮开关
  input [23:0] switch2N4,//拨码开关的输入
  input [3:0] keyboard_input,//键盘输入
  
  output [3:0] keyboard_output,//键盘输出
  output [23:0] led2N4,//LED结果输出
  output [7:0] digitalTube,//8位数码管控制器
  output [7:0] digitalTube_en,//数码管使能信号（低电平有效）
  //output pwm_output,//PWM控制器输出
  output buzzer_output//蜂鸣管输出
);
  wire cpu_clk;//时钟供给CPU
  wire upg_clk;//用于uart的时钟信号
  wire rst;
  wire wdt_output;
  
  assign rst = FPGA_reset;

  //接下来就是各个模块的输出，用线相连
  //程序ROM单元输出
  wire [31:0] Jpadr;
  //数据RAM单元输出
  wire [31:0] ram_data_output;
  wire bit_error;
  //CPU模块输出
  wire [31:0] IROM_address;
  wire [31:0] write_data;
  wire [31:0] write_address;
  wire MEM_MemWrite;
  wire MEM_data_sign;
  wire MEM_IOWrite;
  wire MEM_IORead;
  wire [1:0] MEM_Mem_Dwidth;
  wire ledCTL;
  wire switchCTL;
  wire timerCTL;
  wire keyboardCTL;
  wire digitalTubeCTL;
  wire buzzerCTL;
  wire watchdogCTL;
  wire pwmCTL;
  //中断相关
  wire [5:0] interrupt;
  wire keyboard_interrupt;
  //接口相关
  wire ctc0_output;
  wire ctc1_output;
  wire [15:0] ioread_data_keyboard;
  wire [15:0] ioread_data_switch;
  wire [15:0] ioread_data_timer;
  wire [15:0] ioread_data;
  
    
  //元件例化开始
  cpuclk cpuclk(
    .clk_in1        (FPGA_clock),
    .clk_out1       (cpu_clk),
    .clk_out2       (upg_clk)
  );
  
  //按键去抖
  wire [4:0] button_interrupt;
  button five_buttons(
    .button        (button),
    .clock         (cpu_clk),
    .button_interrupt(button_interrupt)
  );
  
  //味大的CPU
  CPU cpu(
    .reset          (rst),
    .clk            (cpu_clk),
    .IROM_instruction(Jpadr),
    .Mem_read_data  (ram_data_output),
    .IO_read_data   (ioread_data),
    .interrupt      (interrupt),
    
    .IROM_address   (IROM_address),
    .write_data     (write_data),
    .write_address  (write_address),
    .MEM_MemWrite   (MEM_MemWrite),
    .MEM_data_sign  (MEM_data_sign),
    .MEM_IOWrite    (MEM_IOWrite),
    .MEM_IORead     (MEM_IORead),
    .MEM_Mem_Dwidth (MEM_Mem_Dwidth),
    .ledCTL         (ledCTL),
    .switchCTL      (switchCTL),
    .timerCTL       (timerCTL),
    .keyboardCTL    (keyboardCTL),
    .digitalTubeCTL (digitalTubeCTL),
    .buzzerCTL      (buzzerCTL),
    .watchdogCTL    (watchdogCTL),
    .pwmCTL         (pwmCTL)
  );
  
  //指令ROM
  IROM instruction_rom(
    .ROM_clk_i        (upg_clk),
    .rom_read_addr    (IROM_address),
    
    .Jpadr            (Jpadr)
  );
  
  //数据RAM
  MEM data_ram(
    .ram_clk_input        (upg_clk),
    .ram_we_input         (MEM_MemWrite),
    .Mem_Dwidth           (MEM_Mem_Dwidth),
    .ram_sign             (MEM_data_sign),
    .ram_addr_input       (write_address[15:0]),
    .ram_data_input       (write_data),
    
    .ram_data_output      (ram_data_output),
    .bit_error            (bit_error)
  );
  
  //ioread
  IOread ioread(
    .reset        (rst),
    .ioread       (MEM_IORead),
    .switchCTL    (switchCTL),
    .ioread_data_switch(ioread_data_switch),
    .keyboardCTL  (keyboardCTL),
    .ioread_data_keyboard(ioread_data_keyboard),
    .timerCTL     (timerCTL),
    .ioread_data_timer(ioread_data_timer),
    
    .ioread_data  (ioread_data)
  );
  
  //接口例化
   LED led24(
         .ledrst         (rst),
         .led_clk        (cpu_clk),
         .ledwrite       (MEM_IOWrite && ledCTL),
         .ledcs          (ledCTL),
         .ledaddr        (write_address[1:0]),
         .ledwdata       (write_data[15:0]),
         .ledout         (led2N4)
     );
     
     switch switch24(
         .switrst        (rst),
         .switclk        (cpu_clk),
         .switchread     (MEM_IORead && switchCTL),
         .switchaddr     (write_address[1:0]),
         .switchcs       (switchCTL),
         .switch_i       (switch2N4),//input,从板上读的24位开关数据
         .switchrdata    (ioread_data_switch)//output
     );
 
     keyboard keyboard(
         .clock          (cpu_clk),
         .reset          (rst),
         .read_enable    (MEM_IORead && keyboardCTL),
         .address        (write_address[2:0]),
         .column         (keyboard_input),
         .row            (keyboard_output),
         .interrupt      (keyboard_interrupt),
         .read_data_output(ioread_data_keyboard)//output
     );
 
     digitalTube digitaltube(
         .clock          (cpu_clk),
         .reset          (rst),
         .write_enable   (MEM_IOWrite && digitalTubeCTL),
         .address        (write_address[2:0]),
         .write_data_in  (write_data[15:0]),
         .enable         (digitalTube_en),
         .value          (digitalTube)
     );
     
//     PWM pwm(
//         .clock          (cpu_clk),
//         .reset          (rst),
//         .write_enable   (MEM_IOWrite && pwmCTL),
//         .address        (write_address[2:0]),
//         .write_data_in  (write_data[15:0]),
//         .PWM_output     (pwm_output)
//     );
     
     timer timer(
         .clock          (cpu_clk),
         .reset          (rst),
         .read_enable    (MEM_IORead && timerCTL),
         .write_enable   (MEM_IOWrite && timerCTL),
         .address        (write_address[2:0]),
         .write_data_in  (write_data[15:0]),
         .read_data_out  (ioread_data_timer),
         .CTC0_output    (ctc0_output),
         .CTC1_output    (ctc1_output)
     );
     
     watchdog wdt(
         .clock          (cpu_clk),
         .reset          (rst),
         .write_enable   (MEM_IOWrite && watchdogCTL),
         .WDT_output     (wdt_output)
     );
     
     buzzer buzzer(
         .clock          (cpu_clk),
         .reset          (rst),
         .write_enable   (MEM_IOWrite && buzzerCTL),
         .write_data_in  (write_data[15:0]),
         .buzzer_output  (buzzer_output)
     );
endmodule
