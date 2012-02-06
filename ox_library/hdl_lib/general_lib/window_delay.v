`ifndef window_delay
`define window_delay
//`include "/home/jack/physics_svn/gmrt_beamformer/trunk/projects/xeng_opt/hdl/iverilog_xeng/general_lib/posedge.v"
//`include "/home/jack/physics_svn/gmrt_beamformer/trunk/projects/xeng_opt/hdl/iverilog_xeng/general_lib/negedge.v"
//`include "/home/jack/physics_svn/gmrt_beamformer/trunk/projects/xeng_opt/hdl/iverilog_xeng/general_lib/sync_delay.v"

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:09:50 12/03/2011 
// Design Name: 
// Module Name:    window_delay 
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
module window_delay(
    input clk,
    input in,
    output out
    );

    parameter DELAY = 10; //must be >2
    
    wire input_posedge;
    wire input_negedge;
    
    // Find the edges of the input signal
    edgepos posedge_inst(
        .clk(clk),
        .din(in),
        .dout(input_posedge)
    );
    
    edgeneg negedge_inst(
        .clk(clk),
        .din(in),
        .dout(input_negedge)
    );
       

    // delay each of the edge signals       
    wire input_posedge_delay;
    wire input_negedge_delay;
    
    sync_delay #(
        .DELAY_LENGTH(DELAY-1)
    ) sync_delay_inst[1:0] (
        .clk(clk),
        .din({input_posedge,input_negedge}),
        .dout({input_posedge_delay, input_negedge_delay})
    );
    
    // update output register
    reg output_reg = 1'b0;
    always @(posedge(clk)) begin
        if(input_negedge_delay == 1'b1) begin
            output_reg <= 1'b0;
        end else if(input_posedge_delay == 1'b1) begin
            output_reg <= 1'b1;
        end
    end
    
    assign out = output_reg;

endmodule

`endif
