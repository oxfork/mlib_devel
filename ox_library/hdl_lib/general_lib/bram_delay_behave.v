`ifndef bram_delay_behave
`define bram_delay_behave

`timescale 1ns / 1ps

/* Currently, Xilinx doesn't support $clog2, but iverilog doesn't support
 * constant user functions. Decide which to use here
 */
`ifndef log2
`ifdef USE_CLOG2
`define log2(p) $clog2(p)
`else
`define log2(p) log2_func(p)
`endif
`endif

module bram_delay_behave(
    clk,
    ce,
    din,
    dout
    );

    function integer log2_func;
      input integer value;
      integer loop_cnt;
      begin
        value = value-1;
        for (loop_cnt=0; value>0; loop_cnt=loop_cnt+1)
          value = value>>1;
        log2_func = loop_cnt;
      end
    endfunction

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
