`ifndef sync_delay
`define sync_delay

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:33:31 10/13/2011 
// Design Name: 
// Module Name:    sync_delay 
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
module sync_delay(
    input clk,
    input ce,
    input din,
    output dout
    );

    //`include "/home/jack/github/oxfork/mlib_devel/ox_library/hdl_lib/general_lib/math_func.txt"
    parameter DELAY_LENGTH = 256; //Delay to apply to sync pulse in clocks
    localparam DELAY_BITS = `log2(DELAY_LENGTH+1);
    
    reg [DELAY_BITS-1:0] ctr_reg = 0;
    wire ctr_enable;
    
    always@(posedge(clk)) begin
        if(din) begin                    //load the counter on a new sync
            ctr_reg <= DELAY_LENGTH;
        end else if (ctr_enable) begin
            ctr_reg <= ctr_reg - 1'b1;     //decrement counter on each clock
        end
    end
    
    assign ctr_enable = (ctr_reg != 0); //Only allow decrement until ctr_reg==0
    assign dout = (ctr_reg == 1);       //Output sync after appropriate delay
    
endmodule

`endif
