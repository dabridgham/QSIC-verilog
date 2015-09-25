//	-*- mode: Verilog; fill-column: 96 -*-
//
// A block of synchronous QBUS registers
//
// Copyright 2015 Noel Chiappa and David Bridgham

module sreg_block 
  (
   // configuration
   input [12:0]  addr_base,

   // The FPGA internal I/O bus
   input 	 clk,
   input [12:0]  iADDR,		// I/O address
   input 	 iBS7,		// address is on the I/O page
   output 	 iREAD_MATCH,	// this device will read that address
   output 	 iWRITE_MATCH,	// this device will write that address

   input [15:0]  iWDATA,
   input 	 iWRITE,
   output [15:0] iRDATA
   );
   
   parameter count = 2;		// how many registers in the block (at least 2)
   localparam cbits = $clog2(count);

   wire [cbits-1:0] reg_index = iADDR[cbits:1];
   wire 	    match;
   
   reg [15:0] 	    reg_data[0:count-1]; // the actual registers

   // figure out if we're being addressed
   assign match
     = (iBS7 && !iADDR[0] &&	// address is on the I/O page and is not odd
	(iADDR[12:cbits+1] == addr_base[12:cbits+1])); // and matches the high bits

   // this decouples match from iREAD_MATCH and iWRITE_MATCH so they don't feed back in even
   // though they're declared as outputs
   assign iREAD_MATCH = match ? 1 : 0;
   assign iWRITE_MATCH = match ? 1 : 0;
   
   // if we match the address, then place the register data on iRDATA just in case it needs to
   // be read
   assign iRDATA = match ? reg_data[reg_index] : 16'bZ;

   // write data to register
   always @(posedge clk)
     if (iWRITE && match)
       reg_data[reg_index] <= iWDATA;

`ifdef SIM
   // initialize the registers' contents for testing purposes
   integer 	i;
   initial begin
      for (i = 0; i < count; i = i + 1)
	reg_data[i] = 'o123456;
   end
`endif


endmodule // areg_block

