//	-*- mode: Verilog; fill-column: 96 -*-
//
// A simple, asynchronous QBUS register for testing
//
// Copyright 2015 Noel Chiappa and David Bridgham
//
// 2015-09-18 dab	initial version

module areg
  (
   output reg 	DALtx,

   // The QBUS signals as seen by the FPGA
   inout [21:0] DAL, // bidirectional to save FPGA pins
   input 	RDOUT,
   output reg 	TDOUT,
   input 	RRPLY,
   output reg 	TRPLY,
   input 	RDIN,
   output reg 	TDIN,
   input 	RSYNC,
   output reg 	TSYNC,
   input 	RIRQ4,
   output reg 	TIRQ4,
   input 	RIRQ5,
   output reg 	TIRQ5,
   input 	RIRQ6,
   output reg 	TIRQ6,
   input 	RIRQ7,
   output reg 	TIRQ7,
   input 	RWTBT,
   output reg 	TWTBT, // option 1, allow byte write DMA cycles
   input 	RREF, // option for DMA burst mode when acting as memory
   output reg 	TREF, // option for DMA burst mode

   input 	RINIT,
   input 	RDCOK,
   input 	RPOK,
   input 	RBS7,
   input 	RIAKI,
   input 	RDMGI,

   output reg 	TDMR,
   output reg 	TSACK,
   output reg 	TIAKO,
   output reg 	TDMGO
   );

   parameter addr = 'o777777;

   reg [15:0] 	reg_data = 'o123456;	// the actual register
   reg [12:0] 	io_addr = 0;
   reg 		io_page = 0;
   wire 	addr_match = RSYNC && (io_addr == addr) && io_page;
   reg 		drive_DAL;	// this is the same as DALtx but it exists only in this
				// module, it doesn't leak out

   // Drive the DAL lines with the register contents when DALtx, otherwise tri-state
   assign DAL = drive_DAL ? { 6'b0, reg_data } : 22'bZ;

   // Latch the address whenever it comes along
   always @(posedge RSYNC) begin
      io_page <= RBS7;
      io_addr <= DAL[12:0];
   end

   // Latch the data
   always @(posedge RDOUT)
     if (RSYNC && addr_match)
       reg_data <= DAL[15:0];

   // Look for read and write operations
   always @(*) begin
      drive_DAL <= 0;
      DALtx <= 0;
      TDOUT <= 0;
      TRPLY <= 0;
      TDIN <= 0;
      TSYNC <= 0;
      TIRQ4 <= 0;
      TIRQ5 <= 0;
      TIRQ6 <= 0;
      TIRQ7 <= 0;
      TWTBT <= 0;
      TREF <= 0;
      TDMR <= 0;
      TSACK <= 0;
      TIAKO <= 0;
      TDMGO <= 0;
      
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

endmodule // qreg
