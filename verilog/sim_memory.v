//	-*- mode: Verilog; fill-column: 96 -*-
//
// Simulated memory for testing the QBUS modules
//
// Copyright 2015 Noel Chiappa and David Bridgham


module sim_mem
  (
   output reg 	DALtx,
   inout [21:0] DAL,
   output reg 	TRPLY,
   input 	RDIN, 
   input 	RDOUT,
   input 	RSYNC,
   input 	RBS7
   );

   reg [15:0] 	mem[0:2**21-1];	   // the actual memory
   reg [21:0] 	mem_addr = 0;
   reg 		io_page = 0;
   reg 		drive_DAL;	// this is the same as DALtx but it exists only in this
				// module so it doesn't leak

   wire 	addr_match = !io_page; // since I'm implementing the full address space,
				       // the address matches so long as it's not the I/O
				       // page.

`ifdef SIM
   // initialize memory for testing purposes
   integer 	i;
   initial begin
      // only initializing the first 2^15 words to keep it fast
      for (i = 0; i < 2**15-1; i = i + 1)
	 mem[i] <= 'o505050;
   end
`endif
   
   // Drive the DAL lines with the register contents when DALtx, otherwise tri-state
   assign DAL = drive_DAL ? { 6'o0, mem[mem_addr] } : 22'bZ;

   // Latch the address whenever it comes along
   always @(posedge RSYNC) begin
      mem_addr <= DAL[12:0];
      io_page <= RBS7;
   end

   // Latch the data on a write
   always @(posedge RDOUT)
     if (addr_match)
       mem[mem_addr] <= DAL[15:0];

   // Look for read and write operations and drive the bus
   always @(*) begin
      drive_DAL <= 0;
      DALtx <= 0;
      TRPLY <= 0;

      if (addr_match) begin
	 if (RDIN) begin
	    DALtx <= 1;
	    drive_DAL <= 1;
	    TRPLY <= 1;
	 end else if (RDOUT) begin
	    TRPLY <= 1;
	 end
      end
   end

endmodule // sim_mem
