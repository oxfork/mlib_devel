// A parameterized, inferable (hopefully) block RAM in Verilog.
//`include "/home/jack/physics_svn/gmrt_beamformer/trunk/projects/xeng_opt/hdl/iverilog_xeng/general_lib/delay.v"

module sp_ram #(
    parameter D_WIDTH = 72,
    parameter A_WIDTH = 10,
    parameter LATENCY = 2
) (
    input              clk,
    input              we,
    input  [A_WIDTH-1:0]  addr,
    input  [D_WIDTH-1:0] din,
    output [D_WIDTH-1:0] dout
);

// memory
reg [D_WIDTH-1:0] mem [(2**A_WIDTH)-1:0];

// dout
reg [D_WIDTH-1:0] dout_int;

// Inherent latency of 1
// read before write
always @(posedge clk) begin
    dout_int      <= mem[addr];
    if(we) begin
        mem[addr] <= din;
    end
end

//Additional latency
delay #(
    .WIDTH(D_WIDTH),
    .DELAY(LATENCY-1)
) bram_delay_inst (
    .clk(clk),
    .din(dout_int),
    .dout(dout)
);

endmodule

