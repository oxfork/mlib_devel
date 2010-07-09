module x64_adc_retime (
  input             wr_clk,
  input             rd_clk,
  input     [95:0]  din,
  input             dvld,
  input             rst,
  output    [23:0]  dout,
  output            dout_sync,
  output            fifo_of, 
  output            fifo_uf,
  output            dout_vld
  );

  wire [23:0] mux_dout;
  wire        mux_dout_valid;
  wire        mux_dout_sync;

  x64_adc_mux_adc_streams x64_adc_mux_adc_streams_inst (
    .clk        (wr_clk),
    .rst        (rst),
    .din        (din),
    .dinvld     (dvld),
    .dout       (mux_dout),
    .doutvld    (mux_dout_valid),
    .dout_sync  (mux_dout_sync)
  );
  
  wire [24:0] dout_int;
  wire fifo_empty;
  wire fifo_full;
  wire fifo_uf_int;
  wire fifo_of_int;

  fifo_generator_v5_3 async_data_fifo_inst (
    .din        ({mux_dout_sync, mux_dout}),
    .rd_clk     (rd_clk),
    .rd_en      (~fifo_empty),
    .rst        (rst),
    .wr_clk     (wr_clk),
    .wr_en      (mux_dout_valid),
    .dout       (dout_int),
    .empty      (fifo_empty),
    .full       (fifo_full),
    .overflow   (fifo_of_int),
    .underflow  (fifo_uf_int)
  );

  assign dout       =  dout_int[23:0];
  assign dout_sync  =  dout_int[24];

  reg fifo_full_reg;
  reg fifo_empty_reg;

  always @(posedge rd_clk) begin
  fifo_full_reg  <= fifo_full;
  fifo_empty_reg <= fifo_empty;
  end


  assign fifo_of = fifo_full_reg;
  assign fifo_uf = fifo_empty_reg;

endmodule

