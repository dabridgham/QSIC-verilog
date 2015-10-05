//	-*- mode: Verilog; fill-column: 96 -*-
//
// A multi-tap delay line
//
// Copyright 2015 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

module delay_line
  (
   input in,
   output reg [1:5] out
   );

   always @(in) begin
      #50 out[1] <= in;
      #50 out[2] <= in;
      #50 out[3] <= in;
      #50 out[4] <= in;
      #50 out[5] <= in;
   end

endmodule // delay_line
