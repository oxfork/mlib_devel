//`include "adder_tree.v"

`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:08:38 12/04/2011
// Design Name:   adder_tree
// Module Name:   /home/jack/physics_svn/gmrt_beamformer/trunk/projects/xeng_opt/hdl/xengine13/general_lib/adder_tree_tb.v
// Project Name:  xengine
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: adder_tree
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module adder_tree_tb;

    parameter PARALLEL_SAMPLE_BITS = 3; //Number of parallel inputs to tree (2^?)
    parameter INPUT_WIDTH = 4;          //Input width of single sample
    parameter REGISTER_OUTPUTS = "FALSE";
    parameter IS_SIGNED = "TRUE";

    localparam PARALLEL_SAMPLES = 1<<PARALLEL_SAMPLE_BITS;
    localparam PERIOD = 10;

	// Inputs
	reg clk;
	reg sync;
    reg [PARALLEL_SAMPLES*INPUT_WIDTH-1:0] din;
    reg [INPUT_WIDTH-1:0] test_val;

	// Outputs
	wire [6:0] dout;
	wire sync_out;

	// Instantiate the Unit Under Test (UUT)
	adder_tree #(
        .PARALLEL_SAMPLE_BITS(PARALLEL_SAMPLE_BITS),
        .INPUT_WIDTH(INPUT_WIDTH),
        .IS_SIGNED(IS_SIGNED),
        .REGISTER_OUTPUTS(REGISTER_OUTPUTS)
    ) uut (
		.clk(clk), 
		.sync(sync), 
		.din(din), 
		.dout(dout), 
		.sync_out(sync_out)
	);

	initial begin
		// Initialize Inputs
        test_val = 0;
		clk = 0;
		sync = 0;
		din = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
        #1000 $finish;

	end

    initial begin
        clk = 0;
        forever #PERIOD clk = !clk;        
    end
    
    always @(posedge(clk)) begin
        test_val <= test_val + 1;
    end


    always@(test_val) begin
        din = {PARALLEL_SAMPLES{test_val}};
    end

      
    initial begin
        $dumpfile("adder_tree.vcd");
        $dumpvars;
    end


endmodule

