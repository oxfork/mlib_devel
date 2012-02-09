`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:40:00 12/03/2011
// Design Name:   bl_order_gen
// Module Name:   /home/jack/physics_svn/gmrt_beamformer/trunk/projects/xeng_opt/hdl/xengine/xeng_lib//bl_order_gen_tb.v
// Project Name:  xengine
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: bl_order_gen
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module bl_order_gen_tb;

    //`include "/home/jack/github/oxfork/mlib_devel/ox_library/hdl_lib/general_lib/math_func.txt"
    localparam N_ANTS = 8;
    localparam ANT_BITS = log2(N_ANTS);
    
	// Inputs
	reg clk;
	reg sync;
	reg en;

	// Outputs
	wire [ANT_BITS-1:0] ant_a;
	wire [ANT_BITS-1:0] ant_b;
    wire buf_sel;

	// Instantiate the Unit Under Test (UUT)
	bl_order_gen #(
        .N_ANTS(N_ANTS)
    ) uut (
		.clk(clk), 
		.sync(sync), 
		.en(en), 
		.ant_a(ant_a), 
		.ant_b(ant_b),
        .buf_sel(buf_sel)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		sync = 0;
		en = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
   
    parameter PERIOD = 10;

    always begin
       clk = 1'b0;
       #(PERIOD/2) clk = 1'b1;
       #(PERIOD/2);
    end  
    
    initial begin
        sync = 1;
        #PERIOD;
        sync = 0;
        en = 1'b1;
    end
    
endmodule

