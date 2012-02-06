`ifndef xeng_preproc
`define xeng_preproc
//\\`include "/home/jack/physics_svn/gmrt_beamformer/trunk/projects/xeng_opt/hdl/iverilog_xeng/xeng_lib/conv_uint.v"
//\\`include "/home/jack/physics_svn/gmrt_beamformer/trunk/projects/xeng_opt/hdl/iverilog_xeng/xeng_lib/stagger.v"

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:18:19 11/15/2011 
// Design Name: 
// Module Name:    comp_acc 
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
module xeng_preproc(
    clk,
    ce,
    sync,
    din,
    dout_uint,
    dout_uint_stag,
    sync_out
    );

  
    parameter SERIAL_ACC_LEN_BITS = 7;  //Serial accumulation length (2^?)
    parameter P_FACTOR_BITS = 2;        //Number of samples to accumulate in parallel (2^?)
    parameter BITWIDTH = 4;             //bitwidth of each real/imag part of a single sample
    parameter BRAM_LATENCY = 2;         //Latency of brams in delay chain
    parameter FIRST_DSP_REGISTERS = 2;  //number of registers on the input of the first DSP slice in the chain
    parameter DSP_REGISTERS = 2;        //number of registers on the input of all others DSP slices in the chain
    
    localparam P_FACTOR = 1<<P_FACTOR_BITS;                     //number of parallel cmults
    localparam INPUT_WIDTH = 2*BITWIDTH*2*(1<<P_FACTOR_BITS);   //width of complex in/out bus (dual pol)
    localparam N_COMPONENTS = P_FACTOR*2*2;                     //number of components to accumulate
    // localparam ACC_WIDTH = 2*BITWI  //width of complex acc in/out bus (4 stokes)
   
    input clk;                                  //clock input
    input ce;                                   //dummy clock enable (exists only for simulink)
    input sync;                                 //sync input (triggers new accumulation)
    input [INPUT_WIDTH-1:0] din;                //parallel data input stream
    output [INPUT_WIDTH-1:0] dout_uint;         //parallel data output stream (with all components uints)
    output [INPUT_WIDTH-1:0] dout_uint_stag;    //parallel data output stream (with all components uints and staggered)

    output sync_out;
    
    assign sync_out = sync;
    
    wire [INPUT_WIDTH-1:0] dout_uint_wire; //internal wire for uint data stream
    
    conv_uint #(
        .BITWIDTH(BITWIDTH)
        ) conv_uint_inst [N_COMPONENTS-1:0] (
        .din(din),
        .dout(dout_uint_wire)
        );
       
    //Stagger simultaneous samples
    stagger # (
        .N_STAGES(P_FACTOR),
        .BLOCK_SIZE(BITWIDTH*2),
        .STAGGER_OFFSET(DSP_REGISTERS-FIRST_DSP_REGISTERS)
        ) stagger_inst[1:0] (
        .clk(clk),
        .din(dout_uint_wire),
        .dout(dout_uint_stag)
        );
    
    assign dout_uint = dout_uint_wire;
       
endmodule

`endif
