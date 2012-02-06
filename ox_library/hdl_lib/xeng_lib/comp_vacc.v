`ifndef comp_vacc
`define comp_vacc
////\\`include "/tools/Xilinx/11.1/ISE/verilog/src/unimacro/BRAM_TDP_MACRO.v"
////\\`include "/tools/Xilinx/11.1/ISE/verilog/src/unisims/RAMB18.v"
////\\`include "/tools/Xilinx/11.1/ISE/verilog/src/unisims/ARAMB36_INTERNAL.v"
//\\`include "/home/jack/physics_svn/gmrt_beamformer/trunk/projects/xeng_opt/hdl/iverilog_xeng/general_lib/dp_ram.v"
`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:11:02 11/23/2011 
// Design Name: 
// Module Name:    vacc 
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
module comp_vacc(
    clk,
    ant_sel_a,
    ant_sel_b,
    buf_sel,
    din,
    dout_a,
    dout_b,
    new_acc
    
    );
    
    `include "/home/jack/physics_svn/gmrt_beamformer/trunk/projects/xeng_opt/hdl/iverilog_xeng/general_lib/math_func.txt"
    
    parameter INPUT_WIDTH = 4;
    parameter ACC_LEN_BITS = 8;
    parameter VECTOR_LENGTH = 32;
    parameter PLATFORM = "VIRTEX5";
    
    localparam ACC_LEN = 1<<ACC_LEN_BITS;
    localparam VECTOR_LEN_BITS = `log2(VECTOR_LENGTH);
    localparam ACC_WIDTH = ACC_LEN_BITS + INPUT_WIDTH;
    
    input clk;                                          //clock input
    input [VECTOR_LEN_BITS-1:0] ant_sel_a;              //bram read address signal for ram A
    input [VECTOR_LEN_BITS-1:0] ant_sel_b;              //bram read address signal for ram B
    input buf_sel;                                      //1 bit buffer read index (because reading/writing is not always from same buffer)
    input new_acc;                                      //reset input indicating new accumulation on next clock
    input [INPUT_WIDTH-1:0] din;                        //data in
    output [INPUT_WIDTH+ACC_LEN_BITS-1:0] dout_a;         //accumulated data out for ram A
    output [INPUT_WIDTH+ACC_LEN_BITS-1:0] dout_b;         //accumulated data out for ram B
    
    reg [ACC_LEN_BITS + VECTOR_LEN_BITS -1:0] acc_ctr = 0;
    reg active_ram = 0; //register to hold value of half of ram we are writing to
    always @(posedge(clk)) begin
        if (new_acc) begin
            acc_ctr <= 0;
        end else begin
            acc_ctr <= acc_ctr == ACC_LEN*VECTOR_LENGTH-1 ? 0 : acc_ctr+1'b1;
            active_ram <= acc_ctr == ACC_LEN*VECTOR_LENGTH-1 ? ~active_ram : active_ram;
        end 
    end
    
    //sign extended input for summing
    wire din_sign_bit = din[INPUT_WIDTH-1];
    wire [ACC_WIDTH-1:0] din_ext = {{ACC_WIDTH-INPUT_WIDTH{din_sign_bit}}, din};
    
    //vector index line for bram
    wire [VECTOR_LEN_BITS-1:0] vec_index = acc_ctr[ACC_LEN_BITS + VECTOR_LEN_BITS-1: ACC_LEN_BITS];
    //accumulation sample counter
    wire [ACC_LEN_BITS-1:0] sample_index = acc_ctr[ACC_LEN_BITS-1:0];
    
  
    reg [ACC_WIDTH-1:0] acc_reg;
    wire acc_valid = sample_index == ACC_LEN-1 ? 1'b1 : 1'b0;
    wire [ACC_WIDTH-1:0] acc_wire = din_ext + acc_reg;
    always @(posedge(clk)) begin
        acc_reg <= sample_index == 0 ? din_ext : acc_wire;
    end
    
    // Generate padded versions of the data/address lines, to match RAM port
    // widths 
    wire [17:0] data_in_padded;
    assign data_in_padded[ACC_WIDTH-1:0] = acc_wire;
    assign data_in_padded[17:ACC_WIDTH] = {(18-ACC_WIDTH){1'b0}};

    wire [13:0] addr_padded;
    assign addr_padded[3:0] = 4'b0;
    assign addr_padded[VECTOR_LEN_BITS+4-1:4] = vec_index;
    assign addr_padded[VECTOR_LEN_BITS+5-1:VECTOR_LEN_BITS+4] = active_ram;
    assign addr_padded[13:VECTOR_LEN_BITS+5] = {(14-(VECTOR_LEN_BITS+5)){1'b0}};

    wire [13:0] ant_sel_a_pad;
    assign ant_sel_a_pad[3:0] = 4'b0;
    assign ant_sel_a_pad[VECTOR_LEN_BITS+4-1:4] = ant_sel_a;
    assign ant_sel_a_pad[VECTOR_LEN_BITS+5-1:VECTOR_LEN_BITS+4] = buf_sel;
    assign ant_sel_a_pad[13:VECTOR_LEN_BITS+5] = {(14-(VECTOR_LEN_BITS+5)){1'b0}};

    wire [13:0] ant_sel_b_pad;
    assign ant_sel_b_pad[3:0] = 4'b0;
    assign ant_sel_b_pad[VECTOR_LEN_BITS+4-1:4] = ant_sel_b;
    assign ant_sel_b_pad[VECTOR_LEN_BITS+5-1:VECTOR_LEN_BITS+4] = buf_sel;
    assign ant_sel_b_pad[13:VECTOR_LEN_BITS+5] = {(14-(VECTOR_LEN_BITS+5)){1'b0}};
    
    wire [35:0] UNUSED;
    wire [17:0] dout_a_padded;
    wire [17:0] dout_b_padded;

    /*
    `ifdef XILINX

    RAMB18 #(
         .SIM_MODE("SAFE"),  // Simulation: "SAFE" vs. "FAST", see "Synthesis and Simulation Design Guide" for details
         .DOA_REG(1),        // Optional output registers on A port (0 or 1)
         .DOB_REG(1),        // Optional output registers on B port (0 or 1)
         .INIT_A(18'h0AAAA), // Initial values on A output port
         .INIT_B(18'h0AAAA), // Initial values on B output port
         .READ_WIDTH_A(18),  // Valid values are 1, 2, 4, 9 or 18
         .READ_WIDTH_B(18),  // Valid values are 1, 2, 4, 9 or 18
         .SIM_COLLISION_CHECK("ALL"),    // Collision check enable "ALL", "WARNING_ONLY", 
                                         //   "GENERATE_X_ONLY" or "NONE" 
         .SRVAL_A(18'h00000),            // Set/Reset value for A port output
         .SRVAL_B(18'h00000),            // Set/Reset value for B port output
         .WRITE_MODE_A("WRITE_FIRST"),   // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE" 
         .WRITE_MODE_B("WRITE_FIRST"),   // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE" 
         .WRITE_WIDTH_A(18),             // Valid values are 1, 2, 4, 9 or 18
         .WRITE_WIDTH_B(18)              // Valid values are 1, 2, 4, 9 or 18
         
    ) RAMB18_inst [1:0](
         .DOA(UNUSED[31:0]),                                 // 16-bit A port data output
         .DOPA(UNUSED[35:32]),                               // 2-bit A port parity data output
         .DOB({dout_a_padded[15:0],dout_b_padded[15:0]}),    // 16-bit B port data output
         .DOPB({dout_a_padded[17:16], dout_b_padded[17:16]}),// 2-bit B port parity data output
         .ADDRA(addr_padded),                                // 14-bit A port address input
         .ADDRB({ant_sel_a_pad,ant_sel_b_pad}),              // 14-bit B port address input
         .CLKA(clk),                                         // 1-bit A port clock input
         .CLKB(clk),                                         // 1-bit B port clock input
         .DIA(data_in_padded[15:0]),                         // 16-bit A port data input
         .DIB(16'h0),                                        // 16-bit B port data input
         .DIPA(data_in_padded[17:16]),                       // 2-bit A port parity data input
         .DIPB(2'b00),                                       // 2-bit B port parity data input
         .ENA(1'b1),                                         // 1-bit A port enable input
         .ENB(1'b1),                                         // 1-bit B port enable input
         .REGCEA(1'b1),                                      // 1-bit A port register enable input
         .REGCEB(1'b1),                                      // 1-bit B port register enable input
         .SSRA(1'b0),                                        // 1-bit A port set/reset input
         .SSRB(1'b0),                                        // 1-bit B port set/reset input
         .WEA({2{acc_valid}}),                               // 2-bit A port write enable input
         .WEB(2'b00)                                         // 2-bit B port write enable input
    );

    assign dout_a = dout_a_padded[ACC_WIDTH-1:0];
    assign dout_b = dout_b_padded[ACC_WIDTH-1:0];

    `else
    */

    bram_tdp #(
        .DATA(18),
        .ADDR(14)
    ) bram_tdp_inst [1:0] (
        .a_clk(clk),
        .a_wr(acc_valid),
        .a_addr(addr_padded),
        .a_din(data_in_padded[17:0]),
        .a_dout(UNUSED[35:0]),
        .b_clk(clk),
        .b_wr(1'b0),
        .b_addr({ant_sel_a_pad,ant_sel_b_pad}),
        .b_din(18'b0),
        .b_dout({dout_a_padded,dout_b_padded})
    );

    //add another clock latency
    reg [17:0] dout_a_paddedZ;
    reg [17:0] dout_b_paddedZ;
    always @(posedge(clk)) begin
        dout_a_paddedZ <= dout_a_padded;
        dout_b_paddedZ <= dout_b_padded;
    end

    assign dout_a = dout_a_paddedZ[ACC_WIDTH-1:0];
    assign dout_b = dout_b_paddedZ[ACC_WIDTH-1:0];

    /*
    `endif
    */
    

endmodule

`endif
