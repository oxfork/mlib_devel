`ifndef conv_uint
`define conv_uint

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:25:50 11/15/2011 
// Design Name: 
// Module Name:    conv_uint 
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
module conv_uint(
    din,
    dout
    );

    parameter BITWIDTH = 4;
    
    input [BITWIDTH-1:0] din;
    output [BITWIDTH-1:0] dout;
    
    assign dout[BITWIDTH-1] = ~din[BITWIDTH-1];
    assign dout[BITWIDTH-2:0] = din[BITWIDTH-2:0];

endmodule

`endif
