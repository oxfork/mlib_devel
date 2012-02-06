`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   14:49:24 10/05/2011
// Design Name:   delay
// Module Name:   /home/jack/physics_svn/gmrt_beamformer/trunk/projects/xeng_opt/hdl/xengine/general_lib//delay_tb.v
// Project Name:  xengine
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: delay
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module bram_delay_behave_tb;

    localparam WIDTH = 32;
    localparam DELAY = 128;
    localparam LATENCY = 2;

	// Inputs
	reg clk;
	wire [31:0] in;

	// Outputs
	wire [31:0] out;
    
    //Counter signal
    reg [31:0] ctr;

	// Instantiate the Unit Under Test (UUT)
	bram_delay_behave #(
        .WIDTH(WIDTH),
        .DELAY(DELAY),
        .LATENCY(LATENCY)
        ) uut (
		.clk(clk), 
        .ce(1'b1),
		.din(in), 
		.dout(out)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
        ctr = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
        #(30000)
        $finish;
	end
    
    initial begin
        clk = 0;
        forever #10 clk = !clk;        
    end
    
    always @(posedge(clk)) begin
        ctr <= ctr+1;
        $display("CLOCK: %d, IN: %d, OUT: %d, DIFF: %d", ctr,in,out,(in-out));
    end  
    assign in = ctr;
    
    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
    end
      
endmodule

