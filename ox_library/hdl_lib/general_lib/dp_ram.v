// A parameterized, inferable, true dual-port, dual-clock block RAM in Verilog.

module bram_tdp #(
    parameter DATA = 72,
    parameter ADDR = 10
) (
    // Port A
    input   wire                a_clk,
    input   wire                a_wr,
    input   wire    [ADDR-1:0]  a_addr,
    input   wire    [DATA-1:0]  a_din,
    output  reg     [DATA-1:0]  a_dout,
    
    // Port B
    input   wire                b_clk,
    input   wire                b_wr,
    input   wire    [ADDR-1:0]  b_addr,
    input   wire    [DATA-1:0]  b_din,
    output  reg     [DATA-1:0]  b_dout
);

// Shared memory
reg [DATA-1:0] mem [(2**ADDR)-1:0];

//Initialise ram contents
integer k;
initial begin
    for(k=0; k<(2**ADDR); k=k+1) begin
        mem[k][DATA-1:0] = {DATA{1'b0}};
    end
end

// Port A
// read before write
always @(posedge a_clk) begin
    a_dout      <= mem[a_addr];
    if(a_wr) begin
        mem[a_addr] <= a_din;
    end
end

// Port B
// read before write
always @(posedge b_clk) begin
    b_dout      <= mem[b_addr];
    if(b_wr) begin
        mem[b_addr] <= b_din;
    end
end

endmodule

