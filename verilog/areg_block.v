//	-*- mode: Verilog; fill-column: 96 -*-
//
// A block of asynchronous QBUS registers
//
// Copyright 2015 Noel Chiappa and David Bridgham
//
// 2015-09-21 dab	initial version

module areg_block
  (
   output reg 	DALtx,
   inout [21:0] DAL,
   output reg 	TRPLY,
   input 	RDIN, 
   input 	RDOUT,
   input 	RSYNC,
   input 	RBS7
   );

   parameter addr = 'o777777;	// base address of the register block
   parameter count = 1;		// how many registers in the block
   
   reg [15:0] 	reg_data[0:count-1]; // the actual registers
   reg [12:1] 	io_addr_base = addr[12:1];
   reg [12:1] 	io_addr = 0;
   reg 		io_page = 0;
   wire [12:1] 	reg_index = io_addr - io_addr_base;
   wire 	addr_match = RSYNC && (reg_index < count) && io_page;
   reg 		drive_DAL;	// this is the same as DALtx but it exists only in this
				// module so it doesn't leak

   // initialize the registers' contents for testing purposes
`ifdef SIM
   integer 	i;
   initial begin
      for (i = 0; i < count; i = i + 1)
	reg_data[i] = 'o123456;
   end
`endif
   
   // Drive the DAL lines with the register contents when DALtx, otherwise tri-state
   assign DAL = drive_DAL ? { 6'b0, reg_data[reg_index] } : 22'bZ;

   // Latch the address whenever it comes along
   always @(posedge RSYNC) begin
      io_page <= RBS7;
      io_addr <= DAL[12:1] ;
   end

   // Latch the data
   always @(posedge RDOUT)
     if (addr_match)
       reg_data[reg_index] <= DAL[15:0];

   // Look for read and write operations
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

endmodule // areg_block

