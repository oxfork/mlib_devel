`ifndef bram_delay_behave
`define bram_delay_behave
//`include "/home/jack/physics_svn/gmrt_beamformer/trunk/projects/xeng_opt/hdl/iverilog_xeng/general_lib/sp_ram.v"

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module bram_delay_behave(
    clk,
    ce,
    din,
    dout
    );

    `include "/home/jack/physics_svn/gmrt_beamformer/trunk/projects/xeng_opt/hdl/iverilog_xeng/general_lib/math_func.txt"
    parameter WIDTH = 32;
    parameter DELAY = 1024;              //Delay to implement in clocks.
    parameter LATENCY = 2;               //Can be either 2 or 1
    
    localparam ADDR_BITS = `log2(DELAY-LATENCY);
     
    //Inputs/Outputs
    input clk;                //clock input
    input ce;                 // clock enable (for simulink)
    input [WIDTH-1:0] din;    //data input
    output [WIDTH-1:0] dout;  //delayed data output
    
    // Counter for controlling RAM address
    reg [ADDR_BITS-1:0] ctr = 0;
   
    always @(posedge(clk)) begin
        ctr <= ctr ==  (DELAY-LATENCY-1) ? 0 : ctr + 1'b1;
    end
    
    sp_ram #(
        .A_WIDTH(ADDR_BITS),
        .D_WIDTH(WIDTH),
        .LATENCY(LATENCY)
    ) ram_delay_inst (
        .clk(clk),
        .we(1'b1),
        .addr(ctr),
        .din(din),
        .dout(dout)
    );
  
  
endmodule

`endif
