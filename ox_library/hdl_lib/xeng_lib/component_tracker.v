`ifndef component_tracker
`define component_tracker

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

module component_tracker(
    clk,
    din,
    din_uint,
    sync,
    acc_vld,
    re_correction_xx,
    re_correction_xy,
    re_correction_yx,
    re_correction_yy,
    im_correction_xx,
    im_correction_xy,
    im_correction_yx,
    im_correction_yy,
    last_triangle,
    buf_sel_out
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

    parameter SERIAL_ACC_LEN_BITS = 8;  //Serial accumulation length (2^?)
    parameter P_FACTOR_BITS = 0;        //Number of samples to accumulate in parallel (2^?)
    parameter BITWIDTH = 4;             //bitwidth of each real/imag part of a single sample
    parameter N_ANTS = 8;               //number of (dual pol) antenna inputs
    parameter PLATFORM = "VIRTEX5";     // FPGA platform
    parameter VALID_DELAY = 1024;       //Number of clock cycles between valid data entering tap chain and valid data leaving
    
    localparam P_FACTOR = 1 << P_FACTOR_BITS;
    localparam INPUT_WIDTH = 2*2*BITWIDTH*P_FACTOR;
    localparam CORRECTION_ACC_WIDTH = P_FACTOR_BITS+SERIAL_ACC_LEN_BITS+BITWIDTH+1+1+1;
    localparam ANT_BITS = `log2(N_ANTS);
    localparam SERIAL_ACC_LEN = 1<<SERIAL_ACC_LEN_BITS;
    localparam N_TAPS = N_ANTS/2 + 1;           //number of taps (including auto)
    
    
    input clk;
    input [INPUT_WIDTH-1:0] din;
    input [INPUT_WIDTH-1:0] din_uint;
    input sync;
    input acc_vld;
    output [CORRECTION_ACC_WIDTH-1:0] re_correction_xx;
    output [CORRECTION_ACC_WIDTH-1:0] re_correction_xy;
    output [CORRECTION_ACC_WIDTH-1:0] re_correction_yx;
    output [CORRECTION_ACC_WIDTH-1:0] re_correction_yy;
    output [CORRECTION_ACC_WIDTH-1:0] im_correction_xx;
    output [CORRECTION_ACC_WIDTH-1:0] im_correction_xy;
    output [CORRECTION_ACC_WIDTH-1:0] im_correction_yx;
    output [CORRECTION_ACC_WIDTH-1:0] im_correction_yy;
    output last_triangle;
    output buf_sel_out;
    
    //split the inputs into x/y/re/im ready for accumulating
    wire [INPUT_WIDTH/4 -1:0] x_re;
    wire [INPUT_WIDTH/4 -1:0] x_im;
    wire [INPUT_WIDTH/4 -1:0] y_re;
    wire [INPUT_WIDTH/4 -1:0] y_im;
    
    // a generate is required to hook these up, since the real/imag parts an not contiguous at the inputs
    genvar i;
    generate
        for (i=0; i<P_FACTOR; i=i+1) begin : comp_input_assign
            // We assign the uint versions of the real parts (this cancels out a constant factor later on in the correction values)
            assign x_re[(i+1)*BITWIDTH -1 : i*BITWIDTH] = din_uint[2*P_FACTOR*BITWIDTH + (2*i+2)*BITWIDTH-1 : 2*P_FACTOR*BITWIDTH + (2*i+1)*BITWIDTH];
            assign x_im[(i+1)*BITWIDTH -1 : i*BITWIDTH] = din[2*P_FACTOR*BITWIDTH + (2*i+1)*BITWIDTH-1 : 2*P_FACTOR*BITWIDTH + (2*i)*BITWIDTH];
            assign y_re[(i+1)*BITWIDTH -1 : i*BITWIDTH] = din_uint[(2*i+2)*BITWIDTH-1 : (2*i+1)*BITWIDTH];
            assign y_im[(i+1)*BITWIDTH -1 : i*BITWIDTH] = din[(2*i+1)*BITWIDTH-1 : (2*i)*BITWIDTH];
        end //comp_input_assign
    endgenerate
    
    ///////////////////////////////////////////////////////////////////////////////

    // Sum the parallel inputs
    localparam ADD_TREE_O_WIDTH = P_FACTOR_BITS+BITWIDTH;
    wire [ADD_TREE_O_WIDTH-1:0] x_re_sum;
    wire [ADD_TREE_O_WIDTH-1:0] x_im_sum;
    wire [ADD_TREE_O_WIDTH-1:0] y_re_sum;
    wire [ADD_TREE_O_WIDTH-1:0] y_im_sum;
    wire [1:0] adder_tree_sync_v;
    wire adder_tree_sync = adder_tree_sync_v[0];
    
    generate
        if (P_FACTOR_BITS != 0) begin : adder_tree_en //only construct adder tree if there is more than one simultaneous input
            adder_tree #(
                .PARALLEL_SAMPLE_BITS(P_FACTOR_BITS),
                .INPUT_WIDTH(BITWIDTH),
                .REGISTER_OUTPUTS("TRUE"),
                .IS_SIGNED("TRUE") //only the imag inputs are signed
            ) adder_tree_i_inst [1:0](
                .clk(clk),
                .sync(sync),
                .din({x_im,y_im}),
                .dout({x_im_sum,y_im_sum}),
                .sync_out(adder_tree_sync_v)
            );

            adder_tree #(
                .PARALLEL_SAMPLE_BITS(P_FACTOR_BITS),
                .INPUT_WIDTH(BITWIDTH),
                .REGISTER_OUTPUTS("TRUE"),
                .IS_SIGNED("FALSE") //only the imag inputs are signed
            ) adder_tree_r_inst [1:0](
                .clk(clk),
                .sync(sync),
                .din({x_re,y_re}),
                .dout({x_re_sum,y_re_sum}),
                .sync_out()
            );
        end else begin : adder_tree_bypass
            assign x_re_sum = x_re;
            assign y_re_sum = y_re;
            assign x_im_sum = x_im;
            assign y_im_sum = y_im;
            assign adder_tree_sync_v = {sync,sync};
        end //adder tree bypass
    endgenerate
    
    ///////////////////////////////////////////////////////////////////////////////
    
    // calculate the re+/- imag sums
    // Convert the real parts to signed binary, for sanity
    wire [ADD_TREE_O_WIDTH+1 - 1:0] x_re_sum_signed = {1'b0, x_re_sum};
    wire [ADD_TREE_O_WIDTH+1 - 1:0] y_re_sum_signed = {1'b0, y_re_sum};

    wire [ADD_TREE_O_WIDTH+1+1 -1 : 0] x_re_p_im; //+1 for conversion of real parts to signed, +1 for bit growth in add
    wire [ADD_TREE_O_WIDTH+1+1 -1 : 0] x_re_m_im;
    wire [ADD_TREE_O_WIDTH+1+1 -1 : 0] y_re_p_im;
    wire [ADD_TREE_O_WIDTH+1+1 -1 : 0] y_re_m_im;
    
    adder #(
        .A_WIDTH(ADD_TREE_O_WIDTH+1), //+1 for conversion of real parts to signed
        .B_WIDTH(ADD_TREE_O_WIDTH),
        .A_IS_SIGNED("TRUE"),
        .B_IS_SIGNED("TRUE"),
        .REGISTER_OUTPUT("FALSE")
    ) re_im_adder_inst [1:0] (
        .clk(clk),
        .a({x_re_sum_signed, y_re_sum_signed}),
        .b({x_im_sum, y_im_sum}),
        .c({x_re_p_im, y_re_p_im})
    );
    
    subtractor #(
        .A_WIDTH(ADD_TREE_O_WIDTH+1),
        .B_WIDTH(ADD_TREE_O_WIDTH),
        .A_IS_SIGNED("TRUE"),
        .B_IS_SIGNED("TRUE"),
        .REGISTER_OUTPUT("FALSE")
    ) re_im_sub_inst [1:0] (
        .clk(clk),
        .a({x_re_sum_signed, y_re_sum_signed}),
        .b({x_im_sum, y_im_sum}),
        .c({x_re_m_im, y_re_m_im})
    );

    
    ///////////////////////////////////////////////////////////////////////////////
    
    //accumulate the serial streams
    localparam SERIAL_ACC_WIDTH = ADD_TREE_O_WIDTH + 1 + 1 + SERIAL_ACC_LEN_BITS;
    wire [SERIAL_ACC_WIDTH -1 :0] x_re_p_im_acc_a;
    wire [SERIAL_ACC_WIDTH -1 :0] x_re_m_im_acc_a;
    wire [SERIAL_ACC_WIDTH -1 :0] y_re_p_im_acc_a;
    wire [SERIAL_ACC_WIDTH -1 :0] y_re_m_im_acc_a;
    wire [SERIAL_ACC_WIDTH -1 :0] x_re_p_im_acc_b;
    wire [SERIAL_ACC_WIDTH -1 :0] x_re_m_im_acc_b;
    wire [SERIAL_ACC_WIDTH -1 :0] y_re_p_im_acc_b;
    wire [SERIAL_ACC_WIDTH -1 :0] y_re_m_im_acc_b;
    
    wire [ANT_BITS-1:0] ant_a_sel;
    wire [ANT_BITS-1:0] ant_b_sel;
    
    //after last baseline, change to the other buffer
    wire buf_sel;

    comp_vacc #(
        .INPUT_WIDTH(ADD_TREE_O_WIDTH+1+1),
        .ACC_LEN_BITS(SERIAL_ACC_LEN_BITS),
        .VECTOR_LENGTH(N_ANTS)
    ) comp_vacc_inst [3:0] (
        .clk(clk),
        .ant_sel_a(ant_a_sel),
        .ant_sel_b(ant_b_sel),
        .buf_sel(buf_sel),
        .din({x_re_p_im, x_re_m_im, y_re_p_im, y_re_m_im}),
        .dout_a({x_re_p_im_acc_a, x_re_m_im_acc_a, y_re_p_im_acc_a, y_re_m_im_acc_a}),
        .dout_b({x_re_p_im_acc_b, x_re_m_im_acc_b, y_re_p_im_acc_b, y_re_m_im_acc_b}),
        .sync(adder_tree_sync)
        );
        
    ////////////////////////////////////////////////////////////////////

    //Generate the baseline output order and get corrections from the vacc bram     
    
    //It takes 2 clocks for data to be pulled from the BRAM, so we need to request data (i.e. have ant_a/b_sel signals
    //ready) two clocks in advance. To achieve this, use a sync delayed by 2 clocks less than the X-eng tap chain latency.
    reg [SERIAL_ACC_LEN_BITS-1:0] tap_out_vld_ctr = 0;
    wire gen_next_bl;
    wire bl_order_gen_sync;
    always @(posedge(clk)) begin
        if (bl_order_gen_sync) begin
            tap_out_vld_ctr <= 0;
        end else begin
            tap_out_vld_ctr <= tap_out_vld_ctr == SERIAL_ACC_LEN-1 ? 0 : tap_out_vld_ctr + 1'b1;
        end
    end

    assign gen_next_bl = (tap_out_vld_ctr < N_TAPS);

    sync_delay #(
        .DELAY_LENGTH(VALID_DELAY-2)
    ) bl_order_gen_sync_del (
        .clk(clk),
        .ce(1'b1),
        .din(sync),
        .dout(bl_order_gen_sync)
    );
    
    wire last_triangle_int;

    bl_order_gen #(
        .N_ANTS(N_ANTS)
        ) bl_order_gen_inst (
        .clk(clk),
        .sync(bl_order_gen_sync),
        .en(gen_next_bl),
        .ant_a(ant_a_sel),
        .ant_b(ant_b_sel),
        .buf_sel(buf_sel),
        .last_triangle(last_triangle_int)
    );

    delay #(
        .WIDTH(1),
        .DELAY(2)
    ) buf_sel_delay [1:0](
        .clk(clk),
        .din({last_triangle_int, buf_sel}),
        .dout({last_triangle, buf_sel_out})
    );

        

    ////////////////////////////////////////////////////////////////////
    //Perform the final arithmetic required to get the real/imag corrections
    
    adder #(
        .A_WIDTH(SERIAL_ACC_WIDTH),
        .B_WIDTH(SERIAL_ACC_WIDTH),
        .A_IS_SIGNED("TRUE"),
        .B_IS_SIGNED("TRUE"),
        .REGISTER_OUTPUT("FALSE")
    ) re_corr_adder_inst [3:0] (
        .clk(clk),
        .a({x_re_p_im_acc_a, x_re_p_im_acc_a, y_re_p_im_acc_a, y_re_p_im_acc_a}),
        .b({x_re_p_im_acc_b, y_re_p_im_acc_b, x_re_p_im_acc_b, y_re_p_im_acc_b}),
        .c({re_correction_xx, re_correction_xy, re_correction_yx, re_correction_yy})
    );
    
    subtractor #(
        .A_WIDTH(SERIAL_ACC_WIDTH),
        .B_WIDTH(SERIAL_ACC_WIDTH),
        .A_IS_SIGNED("TRUE"),
        .B_IS_SIGNED("TRUE"),
        .REGISTER_OUTPUT("FALSE")
    ) im_corr_sub_inst [3:0] (
        .clk(clk),
        .a({x_re_m_im_acc_b, x_re_m_im_acc_b, y_re_m_im_acc_b, y_re_m_im_acc_b}),
        .b({x_re_m_im_acc_a, y_re_m_im_acc_a, x_re_m_im_acc_a, y_re_m_im_acc_a}),
        .c({im_correction_xx, im_correction_yx, im_correction_xy, im_correction_yy})
    );
    
endmodule

`endif
