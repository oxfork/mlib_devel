`ifndef comp_vacc
`define comp_vacc

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

module comp_vacc(
    clk,
    ant_sel_a,
    ant_sel_b,
    buf_sel,
    din,
    dout_a,
    dout_b,
    sync 
    
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
    
    parameter INPUT_WIDTH = 4;
    parameter ACC_LEN_BITS = 8;
    parameter VECTOR_LENGTH = 32;
    
    localparam ACC_LEN = 1<<ACC_LEN_BITS;
    localparam VECTOR_LEN_BITS = `log2(VECTOR_LENGTH);
    localparam ACC_WIDTH = ACC_LEN_BITS + INPUT_WIDTH;
    
    input clk;                                          //clock input
    input [VECTOR_LEN_BITS-1:0] ant_sel_a;              //bram read address signal for ram A
    input [VECTOR_LEN_BITS-1:0] ant_sel_b;              //bram read address signal for ram B
    input buf_sel;                                      //1 bit buffer read index (because reading/writing is not always from same buffer)
    input sync;                                      //reset input indicating new accumulation on next clock
    input [INPUT_WIDTH-1:0] din;                        //data in
    output [INPUT_WIDTH+ACC_LEN_BITS-1:0] dout_a;         //accumulated data out for ram A
    output [INPUT_WIDTH+ACC_LEN_BITS-1:0] dout_b;         //accumulated data out for ram B
    
    reg [ACC_LEN_BITS + VECTOR_LEN_BITS-1:0] comp_ctr = 0;
    reg active_ram = 0;
    always @(posedge(clk)) begin
        if (sync) begin
            comp_ctr <= 0;
            active_ram <= 1'b0;
        end else begin
            comp_ctr <= comp_ctr == ACC_LEN*VECTOR_LENGTH-1 ? 0 : comp_ctr + 1'b1;
            active_ram <= comp_ctr == ACC_LEN*VECTOR_LENGTH-1 ? ~active_ram : active_ram; //change ram at the next round of antennas
        end 
    end

    wire [ACC_LEN_BITS + VECTOR_LEN_BITS - 1:0] acc_ctr = comp_ctr;
    
    //sign extended input for summing
    wire din_sign_bit = din[INPUT_WIDTH-1];
    wire [ACC_WIDTH-1:0] din_ext = {{ACC_WIDTH-INPUT_WIDTH{din_sign_bit}}, din};
    
    //vector index line for bram
    wire [VECTOR_LEN_BITS-1:0] vec_index = acc_ctr[ACC_LEN_BITS + VECTOR_LEN_BITS-1: ACC_LEN_BITS];
    //accumulation sample counter
    wire [ACC_LEN_BITS-1:0] sample_index = acc_ctr[ACC_LEN_BITS-1:0];
    
  
    reg [ACC_WIDTH-1:0] acc_reg = 0;
    wire acc_valid = sample_index == ACC_LEN-1 ? 1'b1 : 1'b0;
    wire [ACC_WIDTH-1:0] acc_wire = din_ext + acc_reg;
    always @(posedge(clk)) begin
        acc_reg <= sample_index == 0 ? din_ext : acc_wire;
    end
    
    wire [ACC_WIDTH-1:0] UNUSED0;
    wire [ACC_WIDTH-1:0] UNUSED1;
    wire [ACC_WIDTH-1:0] dout_a_int;
    wire [ACC_WIDTH-1:0] dout_b_int;
    
`ifdef DEBUG    
    always @(posedge(clk)) begin
        if(acc_valid) begin
            $display("ACC_VALID: writing %d for antenna %d in ram %d", acc_wire, vec_index, active_ram);
        end
    end
`endif

    bram_tdp #(
        .DATA(ACC_WIDTH),
        .ADDR(VECTOR_LEN_BITS+1)
    ) bram_tdp_inst [1:0] (
        .a_clk(clk),
        .a_wr(acc_valid),
        .a_addr({active_ram,vec_index}),
        .a_din(acc_wire),
        .a_dout({UNUSED0, UNUSED1}),
        .b_clk(clk),
        .b_wr(1'b0),
        .b_addr({buf_sel, ant_sel_a, buf_sel, ant_sel_b}),
        .b_din({ACC_WIDTH{1'b0}}),
        .b_dout({dout_a_int,dout_b_int})
    );

    //add another clock latency
    reg [ACC_WIDTH-1:0] dout_a_intZ= 0;
    reg [ACC_WIDTH-1:0] dout_b_intZ = 0;
    always @(posedge(clk)) begin
        dout_a_intZ <= dout_a_int;
        dout_b_intZ <= dout_b_int;
    end

    assign dout_a = dout_a_intZ;
    assign dout_b = dout_b_intZ;


endmodule

`endif
