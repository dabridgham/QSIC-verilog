//	-*- mode: Verilog; fill-column: 96 -*-
//
// A simple switch register for testing
//
// Copyright 2016 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

module switch_register
  (
   input 	 qclk, // 20MHz
   // the bus
   input [12:0]  RAL, // latched address
   input 	 RBS7,
   input [15:0]  RDL, // data lines
   output [15:0] TDL, 
   // control lines
   input [17:0]  addr, // default should be 777570
   output 	 addr_match,
   input 	 assert_vector,
   input 	 write_pulse
   );

   //
   // QBUS Interface
   //

   reg [15:0] 	switch_register = 16'o0777;


   assign addr_match = ((RBS7 == 1) &&		    // I/O page
			(RAL[12:0] == addr[12:0])); // my address

   assign TDL = switch_register;

   // write register
   always @(posedge qclk) begin
      // write data to register
      if (addr_match && write_pulse) begin
	 switch_register <= RDL;
      end
   end

endmodule // rkv11
