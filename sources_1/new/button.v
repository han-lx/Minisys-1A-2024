`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: Jiangnan Sun
// 
// Create Date: 2025/01/03 21:10:24
// Design Name: 外部按钮
// Module Name: button
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


module button(
    input clock,
    input [4:0] button,
    output reg[4:0] button_interrupt
    );
    reg        state;
    reg[15:0]  count;

    initial begin
         state = 1'b0;
    end
    
    always @(posedge clock) begin
        case(state)
            1'b0:begin
                count = 16'd0;
                button_interrupt = 5'b00000;
                if(button!=5'b00000)
                    state = 1'b1;
            end
            1'b1:begin // 去抖处理
                if(count != 16'h6612)//约100ms
                    count = count + 8'd1;
                else if(button == 5'b00000) begin  //如果这时候全为0 说明抖动了 或者按钮放开了 回到初始状态
                    state = 1'b0;
                    count = 16'd0;
                end else begin  //如果仍然不全为0 说明真的有button输入 进入中断
                    button_interrupt = button;
                end
            end
       endcase
    end

endmodule