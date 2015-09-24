//	-*- mode: Verilog; fill-column: 96 -*-
//
// A block of synchronous QBUS registers
//
// Copyright 2015 Noel Chiappa and David Bridgham

module sreg_block 
  (
   input 	 clk,

   // The FPGA internal I/O bus
   input [12:0]  iADDR, // I/O address
   input 	 iBS7, // address is on the I/O page
   input 	 iWTBT, // operation will be a write
   output 	 iADDR_MATCH, // some device indicates it has this address

   input [15:0]  iWDATA,
   input 	 iWRITE,
   output [15:0] iRDATA,

   // configuration
   input [12:0]  addr_base
   );
   
   parameter count = 2;		// how many registers in the block (at least 2)
   localparam cbits = $clog2(count);

   wire [cbits-1:0] reg_index = iADDR[cbits:1];
   wire 	    match;
   
   // this decouples match from iADDR_MATCH so it doesn't feed back in even though it's declared
   // as output
   assign iADDR_MATCH = match ? 1 : 0;

   //
   // The rest of this file would be modified to be specific to the device being implemented
   //
   
   reg [15:0] 	 reg_data[0:count-1];	    // the actual registers

   // figure out if we're being addressed
   assign match
     = (iBS7 && !iADDR[0] &&	// address is on the I/O page and is not odd
	(iADDR[12:cbits+1] == addr_base[12:cbits+1])); // and matches the high bits

   // if we match the address, then place the register data on iRDATA just in case it needs to
   // be read
   assign iRDATA = match ? reg_data[reg_index] : 16'bZ;

   // write data to register
   always @(posedge clk)
     if (iWRITE)
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

