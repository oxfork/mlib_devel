`ifndef log2
`define log2(p) log2_func(p)
`endif

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
