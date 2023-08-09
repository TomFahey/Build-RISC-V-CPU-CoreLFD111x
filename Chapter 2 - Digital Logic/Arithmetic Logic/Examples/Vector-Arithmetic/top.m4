\TLV_version 1d: tl-x.org
\SV

   // =========================================
   // Welcome!  Try the tutorials via the menu.
   // =========================================

   // Default Makerchip TL-Verilog Code Template
   
   // Macro providing required top-level module definition, random
   // stimulus support, and Verilator config.
   module top(input wire clk, input wire reset, input wire [31:0] cyc_cnt, output wire passed, output wire failed);    /* verilator lint_save */ /* verilator lint_off UNOPTFLAT */  bit [256:0] RW_rand_raw; bit [256+63:0] RW_rand_vect; pseudo_rand #(.WIDTH(257)) pseudo_rand (clk, reset, RW_rand_raw[256:0]); assign RW_rand_vect[256+63:0] = {RW_rand_raw[62:0], RW_rand_raw};  /* verilator lint_restore */  /* verilator lint_off WIDTH */ /* verilator lint_off UNOPTFLAT */   // (Expanded in Nav-TLV pane.)
\TLV
   $reset = *reset;
   $out1[7:0] = $in1[6:0] + $in2[6:0]; 
   $out2[7:0] = $in3[4:0] * $in4[4:0];
   $out3[7:0] = $in5[7:0] / $in6[7:0];
   $out4[7:0] = $in5[7:0] % $in6[7:0];

   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 80;
   *failed = 1'b0;
\SV
   endmodule