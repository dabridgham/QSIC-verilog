//	-*- mode: Verilog; fill-column: 96 -*-
//
// Simulated processor for testing the QBUS modules.  It's not so much a processor as a
// bus arbitrator and interrupt handler.  Just enough to try out those functions.
//
// Copyright 2015 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

module sim_proc
  (
   input 	BDMR,
   input 	BSACK,
   output reg 	BSYNC = 1,
   output reg	BRPLY = 1,
   output reg	BDMGO = 1
   );

   always @(BDMR, BSACK) begin
      if (!BDMR && BSACK) begin
	 BSYNC <= 0; BRPLY <= 0; // suddenly pretend we're in the middle of a cycle
	 #30 BDMGO <= 0;	   // wait DMA latency
	 #60 BSYNC <= 1; BRPLY <= 1; // okay, the "processor" is done with the bus now
      end else
	#20 BDMGO <= 1;
   end

endmodule // sim_proc

