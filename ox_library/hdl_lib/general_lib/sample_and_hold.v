`ifndef sample_and_hold
`define sample_and_hold
////`include "/home/jack/physics_svn/gmrt_beamformer/trunk/projects/xeng_opt/hdl/iverilog_xeng/general_lib/delay.v"

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:26:58 12/03/2011 
// Design Name: 
// Module Name:    sample_and_hold 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module sample_and_hold(
    clk,
    sync,
    din,
    dout
    );
    
    //`include "/home/jack/github/oxfork/mlib_devel/ox_library/hdl_lib/general_lib/math_func.txt"
    parameter WIDTH = 1;    //data bus width
    parameter PERIOD = 128; //sampling period in clocks
    
    localparam PERIOD_BITS = `log2(PERIOD);
    
    input clk;
    input sync;
    input  [WIDTH-1:0] din;
    output [WIDTH-1:0] dout;
    
    // couting logic
    reg [PERIOD_BITS-1:0] ctr = 0;
    always @(posedge(clk)) begin
        if(sync || ctr == (PERIOD-1)) begin
            ctr <= {PERIOD_BITS{1'b0}};
        end else begin
            ctr <= ctr + 1'b1;
        end
    end
    
    //sampling logic
    reg [WIDTH-1:0] dout_reg = {WIDTH{1'b0}};
    wire dout_reg_enable;
    delay #(
        .DELAY(1),
        .WIDTH(1)
    ) dout_reg_enable_delay_inst (
        .clk(clk),
        .din((sync || ctr == (PERIOD-1))),
        .dout(dout_reg_enable)
    );
    
    always @(posedge(clk)) begin
        if(dout_reg_enable) begin
            dout_reg <= din;
        end
    end

    assign dout = dout_reg;
    
endmodule

`endif
