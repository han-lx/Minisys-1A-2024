`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU
// Engineer: ShuBo Xue
// 
// Create Date: 2025/01/02 17:06:04
// Design Name: 
// Module Name: timer
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


module timer(
    input clock,
    input reset,
    input pluse0,
    input pluse1,
    input read_enable,              // 读信号
    input write_enable,             // 写信号
    input [2:0] address,            // 方式寄存器：0/2，初始值寄存器：4/6
    input[15:0] write_data_in,      // 写到CTC模块的数据
    output reg[15:0] read_data_out,// 从CTC模块读到CPU的数据
    output reg CTC0_output,        // 低电平有效
    output reg CTC1_output
    );
    reg [15:0] CNT0,CNT1;           // 当前值寄存器(只读寄存器)（0XFFFFFC24, 0XFFFFFC26）
    reg [15:0] init0,init1;         // 初始值寄存器(只写寄存器)（0XFFFFFC24, 0XFFFFFC26）
    reg [15:0] mode0,mode1;         // 方式寄存器(只写寄存器)（0XFFFFFC20, 0XFFFFFC22）
    reg [15:0] status0,status1;     // 状态寄存器(只读寄存器)（0XFFFFFC20, 0XFFFFFC22）

    always @(posedge clock) begin
        if(reset == 1) begin
            CTC0_output = 1'b1;
            CTC1_output = 1'b1;
            init0 = 16'h0000;
            init1 = 16'h0000;
            CNT0 = init0;
            CNT1 = init1;
            mode0 = 16'h0000;
            mode1 = 16'h0000;
            status0 = 16'h0000;
            status1 = 16'h0000;
        end else if(read_enable == 1)begin
            case(address) // 处理对只读寄存器的访问
                3'b000: begin
                    read_data_out = status0;
                    status0 = 16'h0000;
                end
                3'b010: begin
                    read_data_out = status1;
                    status1 = 16'h0000; // 状态寄存器在被读取后被清零
                end
                3'b100:read_data_out = CNT0;
                3'b110:read_data_out = CNT1;
            endcase
        end else if(write_enable==1) begin
            case(address) // 处理对只读寄存器的访问
                3'b000: begin
                    mode0 = write_data_in;
                    status0[15] = 1'b0;// 方式寄存器设置后还没有写计数初始值时，状态寄存器有效位置0
                    end
                3'b010: begin
                    mode1 = write_data_in;
                    status1[15] = 1'b0;
                    end
                3'b100: begin 
                    init0 = write_data_in;
                    CNT0 = init0;
                    status0[15] = 1'b1;// 写好计数初始值后，状态寄存器有效位置1
                    end
                3'b110:begin
                    init1 = write_data_in;
                    CNT1 = init1;
                    status1[15] = 1'b1;
                    end
            endcase
        end
        if(status0[15])begin                // 定时/计数有效
            CNT0 <= CNT0 - 16'd1;           // 当前值-1
            CTC0_output = 1'b1;
            if (mode0[0] == 1'b0) begin     // 定时模式  
                if (CNT0 == 16'd1) begin   
                    status0[15] = 1'b0;     // 表示定时无效
                    status0[0] = 1'b1;      // 表示定时到
                    CTC0_output = 1'b0;     // 定时方式中，在时钟作用下计时器做减1操作，到1的时候设置状态寄存器的相应位，并在相应的COUT脚输出一个时钟的低电平（平时COUT是高电平）
                end
            end else begin                  // 计数模式
                if (CNT0 == 16'd0) begin    
                    status0[15] = 1'b0;     // 表示计数无效
                    status0[1] = 1'b1;      // 表示计数到
                    //CTC0_output = 1'b0;
                end
            end
        end
        if (CTC0_output == 1'b0) begin
            if (mode0[1] == 1'b1) begin // 重复模式
                status0[15] = 1'b1;
                status0[0] = 1'b0; 
                CNT0 = init0;
                // CTC0_output = 1'b1;
            end else begin // 非重复模式
                status0[15] = 1'b0;
                CNT0 = 16'h0000;
            end
        end
        if(status1[15])begin            // 定时/计数有效
            CNT1 <= CNT1 - 16'd1;           // 当前值-1
            CTC1_output = 1'b1;
            if (mode1[0] == 1'b0) begin     // 定时模式  
                if (CNT1 == 16'd1) begin    // 设置状态寄存器有效位为0，
                    status1[15] = 1'b0;     // 表示定时无效
                    status1[0] = 1'b1;      // 表示定时到
                    CTC1_output = 1'b0;     
                end
            end else begin                  // 计数模式
                if (CNT1 == 16'd0) begin    // 设置状态寄存器有效位为0，计数到位为1
                    status1[15] = 1'b0;     // 表示计数无效
                    status1[1] = 1'b1;      // 表示计数到
                    //CTC1_output = 1'b0;
                end
            end
        end
        if (CTC1_output == 1'b0) begin
            if (mode1[1] == 1'b1) begin // 重复模式
                status1[15] = 1'b1;
                status1[0] = 1'b0; 
                CNT1 = init1;
                // CTC1_output = 1'b1;
        end else begin // 非重复模式
                status1[15] = 1'b0;
                CNT1 = 16'h0000;
            end
        end
    end

//    always @(posedge clock) begin

//    end
    
//    // 重复模式检测
//    always @(negedge clock) begin

//    end
  
endmodule
