`ifndef bram_delay_top2
`define bram_delay_top2
//`include "/home/jack/physics_svn/gmrt_beamformer/trunk/projects/xeng_opt/hdl/iverilog_xeng/general_lib/bram_delay.v"
`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:15:48 10/11/2011 
// Design Name: 
// Module Name:    bram_delay_top 
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
module bram_delay_top2(
    clk,
    ce,
    din,
    dout
    );
    
    `include "/home/jack/github/oxfork/mlib_devel/ox_library/hdl_lib/general_lib/math_func.txt"
    parameter WIDTH = 128; //Interface width in bits
    parameter DELAY = 128; //Delay to implement in clocks
    parameter LATENCY = 2; //bram latency (1 or 2)
    parameter TARGET_DEVICE = "VIRTEX5"; //VIRTEX5 or VIRTEX6
    
    //What is the required address width to generate this delay?
    localparam BRAM_DEPTH = DELAY-LATENCY;                                      //Bram storage is supplemented by registers
    localparam ADDR_WIDTH = `log2(BRAM_DEPTH) < 9 ? 9 : `log2(BRAM_DEPTH);    //Minimum address width is 9 bits
    
    
    //Inputs/Outputs
    input clk;                //clock input
    input ce;                 //for simulink
    input [WIDTH-1:0] din;    //data input
    output [WIDTH-1:0] dout;  //delayed data output  

    

    
    //Choose the RAM configuration based on the amount of storage required
    //and the fact that 36Kb brams have a greater allowed depth than 18Kb
    localparam TARGET_BRAM = (WIDTH*BRAM_DEPTH > 1024*18) || (ADDR_WIDTH > 14) ? "36Kb" : "18Kb";
    
    //What is the available IO width given this ADDR_WIDTH?
    //The second term adds in the available parity bits (1 bit per 8 bits of IO)
    localparam IO_WIDTH = (TARGET_BRAM=="36Kb") ?
            ((1<<(15-ADDR_WIDTH)) / 8 ) * 9:
            ((1<<(14-ADDR_WIDTH)) / 8 ) * 9;

    //Calculate the number of brams required based on the input width and the available IO
    localparam N_BRAMS = (WIDTH + IO_WIDTH - 1) / IO_WIDTH; //ceiling division
        
    //wire [N_BRAMS*IO_WIDTH-1:0] in_padded = {8'b0,din};//{{N_BRAMS*IO_WIDTH-WIDTH{1'b0}},din};
    wire [N_BRAMS*IO_WIDTH-1:0] in_padded = {{(N_BRAMS*IO_WIDTH-WIDTH){1'b0}},din};
    wire [N_BRAMS*IO_WIDTH-1:0] out_padded;


    //Instantiate array of BRAMS
    bram_delay #(
        .WIDTH(IO_WIDTH),
        .DELAY(DELAY),
        .TARGET_BRAM(TARGET_BRAM),
        .TARGET_DEVICE(TARGET_DEVICE),
        .LATENCY(LATENCY)
        ) bram_delay_inst [N_BRAMS-1:0] (
        .clk(clk),
        .ce(ce),
        .din(in_padded),
        .dout(out_padded)
        );
        
    assign dout = out_padded[WIDTH-1:0];

endmodule

`endif
