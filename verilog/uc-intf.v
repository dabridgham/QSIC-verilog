//	-*- mode: Verilog; fill-column: 96 -*-
//
// Interface from the FPGA to the micro-controller
//
// Copyright 2015 Noel Chiappa and David Bridgham

module uc_intf
  (
   // signals to/from the microcontroller
   inout [15:0]  data,
   input 	 addr_set, // set the address, else it's data
   input 	 write, // direction
   input 	 strobe, // strobe data
   output 	 not_ready, // register is not ready to read or write
   output 	 interrupt, // somebody wants attention

   // signals for the internal microcontroller bus
   output [15:0] uADDR,
   inout [15:0]  uDATA,
   output 	 uWRITE,
   output 	 uCLK,
   input 	 uWAIT,
   input [7:0] 	 uINTERRUPT
   );

   // address of the data to read or write
   reg [15:0] 	addr;
   assign uADDR = addr;
   
   // reading the address gets who's requesting attention
   wire [15:0] 	data_data = addr_set ? { 8'b0, uINTERRUPT } : uDATA;
   assign data = write ? 16'bZ : data_reg;
   assign not_ready = addr_set ? 0 : uWAIT;
   // only pass the clock if we're not reading or writing the address
   assign uCLK = strobe & ~addr_set;

   // grab the address
   always @(posedge strobe)
      if (write && addr_set)
	addr <= data;

endmodule // uc_intf
