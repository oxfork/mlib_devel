`ifndef subtractor
`define subtractor
////`include "/home/jack/physics_svn/gmrt_beamformer/trunk/projects/xeng_opt/hdl/iverilog_xeng/general_lib/delay.v"

`timescale 1ns / 1ps

module subtractor(
    clk,
    a,
    b,
    c
    );

    parameter A_WIDTH = 4;      //width of input A
    parameter B_WIDTH = 4;      //width of input B
    parameter A_IS_SIGNED = "TRUE";
    parameter B_IS_SIGNED = "TRUE";
    parameter REGISTER_OUTPUT = "FALSE";
    
    localparam OUTPUT_WIDTH = A_WIDTH>B_WIDTH ? A_WIDTH+1 : B_WIDTH+1;
    
    input clk;
    input [A_WIDTH-1:0] a;
    input [B_WIDTH-1:0] b;
    output [OUTPUT_WIDTH-1:0] c;
    
    // sign extend the inputs
    wire a_sign = a[A_WIDTH-1];
    wire [OUTPUT_WIDTH-1:0] a_ext;
    wire b_sign = b[B_WIDTH-1];
    wire [OUTPUT_WIDTH-1:0] b_ext;
    generate
        if (A_IS_SIGNED == "TRUE") begin
            assign a_ext = {{(OUTPUT_WIDTH-A_WIDTH){a_sign}}, a};
        end else begin
            assign a_ext = {{(OUTPUT_WIDTH-A_WIDTH){1'b0}}, a};
        end
    endgenerate

    generate
        if (B_IS_SIGNED == "TRUE") begin
            assign b_ext = {{(OUTPUT_WIDTH-B_WIDTH){b_sign}}, b};
        end else begin
            assign b_ext = {{(OUTPUT_WIDTH-B_WIDTH){1'b0}}, b};
        end
    endgenerate

    // addition circuit
    wire [OUTPUT_WIDTH-1:0] c_int = a_ext - b_ext;
    
    //optional output register
    generate
        if (REGISTER_OUTPUT == "TRUE") begin : output_reg_gen
            delay # (
                .WIDTH(OUTPUT_WIDTH),
                .DELAY(1)
            ) add_delay (
                .clk(clk),
                .ce(1'b1),
                .din(c_int),
                .dout(c)
            );

        end else begin
            assign c = c_int;
        end
    endgenerate

endmodule

`endif
