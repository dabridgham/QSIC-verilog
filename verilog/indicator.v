//	-*- mode: Verilog; fill-column: 96 -*-
//
// Indicator Panel - wires up a bunch of signals to a bitsteam for sending to an indicator
// panel.
//
// Copyright 2016 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

module indicator
  (
   input 	clk,		// 100kHz - 250kHz
   input 	latch,
   output 	out,
   input [35:0] d0,		// the four lines of display
   input [35:0] d1,
   input [35:0] d2,
   input [35:0] d3
   );

   reg [143:0] 	sr;		// the output shift register

   assign out = sr[143];

   // Shift the data on negedge as it's clocked into the LED driver on posedge
   always @(negedge clk) begin
      if (latch) begin
	 // this is messy because the mapping of the bits in the bit stream to where they
	 // show up on the panel was drven by what made the pcb layout easy
	 sr[143:128] <= { d2[0], d3[0], d2[1], d3[1], d3[2], d2[2], d3[3], d2[3],
			  d1[3], d0[3], d1[2], d0[2], d0[1], d1[1], d0[0], d1[0] };
	 sr[127:112] <= { d2[4], d3[4], d2[5], d3[5], d3[6], d2[6], d3[7], d2[7],
			  d1[7], d0[7], d1[6], d0[6], d0[5], d1[5], d0[4], d1[4] };
	 sr[111:96] <= { d2[8], d3[8], d2[9], d3[9], d3[10], d2[10], d3[11], d2[11],
			 d1[11], d0[11], d1[10], d0[10], d0[9], d1[9], d0[8], d1[8] };
	 sr[95:80] <= { d2[12], d3[12], d2[13], d3[13], d3[14], d2[14], d3[15], d2[15],
			d1[15], d0[15], d1[14], d0[14], d0[13], d1[13], d0[12], d1[12] };
	 sr[79:64] <= { d2[16], d3[16], d2[17], d3[17], d3[18], d2[18], d3[19], d2[19],
			d1[19], d0[19], d1[18], d0[18], d0[17], d1[17], d0[16], d1[16] };
	 sr[63:48] <= { d2[20], d3[20], d2[21], d3[21], d3[22], d2[22], d3[23], d2[23],
			d1[23], d0[23], d1[22], d0[22], d0[21], d1[21], d0[20], d1[20] };
	 sr[47:32] <= { d2[24], d3[24], d2[25], d3[25], d3[26], d2[26], d3[27], d2[27],
			d1[27], d0[27], d1[26], d0[26], d0[25], d1[25], d0[24], d1[24] };
	 sr[31:16] <= { d2[28], d3[28], d2[29], d3[29], d3[30], d2[30], d3[31], d2[31],
			d1[31], d0[31], d1[30], d0[30], d0[29], d1[29], d0[28], d1[28] };
	 sr[15:0] <= { d2[32], d3[32], d2[33], d3[33], d3[34], d2[34], d3[35], d2[35],
		       d1[35], d0[35], d1[34], d0[34], d0[33], d1[33], d0[32], d1[32] };
      end else begin
	 sr <= sr << 1;
      end
   end

endmodule // indicator

