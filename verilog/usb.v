//	-*- mode: Verilog; fill-column: 96 -*-
//
// A USB interface
//
// Copyright 2016 Noel Chiappa and David Bridgham

module nrzi_decode
  (
   input      reset,
   input      clk4x, // a clock at four times the data rate
   input      dp, // differential input, assumes full-speed so swap thse for low-speed
   input      dn,
   output reg clkout,
   output reg bits_out,
   output reg se0		// indicates end-of-packet, reset, or disconnected
   );

   reg [2:0] state;
   reg 	     prev_value;
   
   always @(posedge clk4x) begin
      if (reset) begin
	 state = 0;
	 clkout = 0;
	 bits_out = 0;
	 se0 = 0;
	 prev_value = 0;
      end else begin
	 case (state)
	   0:			// idle
	     begin
		
	     end
      end
   end

endmodule // nrzi_decode
