`ifndef bl_order_gen
`define bl_order_gen

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:03:50 11/23/2011 
// Design Name: 
// Module Name:    bl_order_gen 
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
module bl_order_gen(
    clk,
    sync,
    en,
    ant_a,
    ant_b,
    buf_sel
    );
    
    `include "/home/jack/github/oxfork/mlib_devel/ox_library/hdl_lib/general_lib/math_func.txt"
    parameter N_ANTS = 16;
    localparam ANT_BITS = `log2(N_ANTS);
    
    input clk;
    input sync;
    input en;
    output [ANT_BITS-1:0] ant_a;
    output [ANT_BITS-1:0] ant_b;
    output buf_sel;
    
    reg [ANT_BITS-1:0] a=0;
    reg [ANT_BITS-1:0] b=0;
    reg [ANT_BITS-1:0] offset=0;
    reg buf_sel_reg=0;

    always @(posedge(clk)) begin
        if (sync) begin
            buf_sel_reg <= 1'b0;
        end else if(a==N_ANTS-1 && b==N_ANTS-1 && en) begin
            buf_sel_reg <= ~buf_sel_reg;
        end
    end
    
    always @(posedge(clk)) begin
        if (sync) begin
            b <= 0;
            a <= N_ANTS/2;
            offset <= N_ANTS/2+1;
        end else if (en) begin
            if(a==b) begin
                b <= b+1'b1;
                a <= offset;
                offset <= offset+1'b1;
            end else begin
                a <= a+1'b1;
            end 
        end
    end
    
    assign ant_a = a;
    assign ant_b = b;
    assign buf_sel = ant_a <= ant_b ? buf_sel_reg : ~buf_sel_reg;

endmodule

`endif
