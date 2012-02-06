`ifndef edgepos
`define edgepos

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:05:45 12/03/2011 
// Design Name: 
// Module Name:    posedge 
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
module edgepos(
    input clk,
    input din,
    output dout
    );
    
    reg din_z;
    always @(posedge(clk)) begin
        din_z <= din;
    end
    
    assign dout = (~din_z) && (din); //Output is high if din was low and is now high (i.e. posedge)


endmodule

`endif
