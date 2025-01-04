`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2025/01/04 15:26:15
// Design Name: 测试整个系统
// Module Name: Minisys_1A_sim
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


module Minisys_1A_sim(

    );
     reg prst = 1'b1;
     reg pclk = 1'b0;
     reg [23:0] switch2N4;   
     reg [3:0] keyboardIn;
     // output
     wire [23:0] led2N4;   
     wire [3:0] keyboardOut;
     wire [7:0] digitalTube,digitalTubeEnable;
     wire pwmOut,wdtOut,buzzerOut;
     minisys_1A my_minisys(
           .FPGA_reset(prst),
           .FPGA_clock(pclk),
           .switch2N4(switch2N4),         
           .led2N4(led2N4),                        // LED结果输出到板上
           .keyboard_input(keyboardIn),                // 键盘输入线(列线)
           .keyboard_output(keyboardOut),              // 键盘输出线(行线) 
           .digitalTube(digitalTube),              // 8位7段数码管控制器
           .digitalTube_en(digitalTubeEnable),  // 数码管使能信号A0-A7(低电平有效)
           .pwm_output(pwmOut),           // PWM控制器
            //wdt_output(wdtOut),           // 看门狗
           .buzzer_output(buzzerOut)     // 蜂鸣管
//           // UART Programmer Pinouts
//           .start_pg(1'b0),           // 接板上的S3按键做下载启动键
//           .rx(1'b0),                 // UART接收
//           .tx()                      // UART发送
     );
       
     initial begin
         #500  prst = 1'b0;
         switch2N4 = 24'h5a078f;   
         keyboardIn = 4'b1010;
     end
     always #5 pclk = ~pclk;
endmodule
