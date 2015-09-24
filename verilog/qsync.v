//	-*- mode: Verilog; fill-column: 96 -*-
//
// The QBUS to Synchronous Interface for QSIC
//
// Copyright 2015 Noel Chiappa and David Bridgham

`include "qsic.vh"

// Mediates between the asynchronous QBUS and the FPGA internal, synchronous operation of
// various I/O devices.  Handles data reads and writes from/to device registers.
// Interrupt and DMA multiplexing are handled elsewhere.
module qsync
  (
   input 	     clk,
   
   // The QBUS signals coming from the driver circuitry. (I bet I can get rid of a lot of
   // these)
   output reg 	     DALtx, // Direction control for the BDAL lines
   inout [21:0]      DAL,
   input 	     RBS7,
   input 	     RWTBT,
   input 	     RSYNC,
   input 	     RDIN,
   input 	     RDOUT,
   output reg 	     TRPLY,

   // The FPGA internal I/O bus
   output reg [12:0] iADDR, // I/O address
   output reg 	     iBS7, // address is on the I/O page
   output reg 	     iWTBT, // operation will be a write
   input 	     iADDR_MATCH, // some device indicates it has this address

   output reg [15:0] iWDATA,
   output reg 	     iWRITE,
   input [15:0]      iRDATA 	 
   );

   reg [15:0] 	     read_reg;	// stage data for reads
   reg [21:0] 	     TDAL;	// for driving the DAL lines
   assign DAL = TDAL;

   // Asynchronously latch the addressing information whenever it comes along
   always @(posedge RSYNC) begin
      iADDR <= DAL[12:0];
      iBS7 <= RBS7;
      iWTBT <= RWTBT;
   end

   // synchronize SYNC for internal use
   reg [1:0] sSYNC;
   always @(posedge clk) sSYNC[0] <= RSYNC;
   always @(posedge clk) sSYNC[1] <= sSYNC[0];
   wire      sREAD = sSYNC[1];	// a synchronized version of RSYNC

   // Generate the iSTART strobe, also stage read data into the staging register
   reg 	     start_state = 0;
   always @(posedge clk) begin
      if (sREAD) begin
	 if ((start_state == 0) && // only once,
	     iADDR_MATCH)	   // and some device has the address
	   read_reg <= iRDATA;	   // then move the data into the staging register
	 start_state <= 1;
      end else
	start_state <= 0;
   end // always @ (posedge clk)
	  
   // asynchronously generate RPLY
   always @(*) begin
      // idle
      DALtx <= 0;
      TDAL <= 22'bZ;
      TRPLY <= 0;

      // on reads, drive DAL with the already-staged read data
      if (RDIN && iADDR_MATCH) begin
	 DALtx <= 1;
	 TDAL <= { 6'b0, read_reg };
	 TRPLY <= 1;
      end
      // writes just assert RPLY, the data is latched and moved to the sync register
      // elsewhere
      else if (RDOUT && iADDR_MATCH) begin
	 TRPLY <= 1;
      end 
   end

   // Asynchronously latch write data
   always @(posedge RDOUT) begin
      iWDATA <= DAL[15:0];
   end

   // Synchronize RDOUT to write to internal registers
   reg [1:0] sDOUT;
   always @(posedge clk) sDOUT[0] <= RDOUT;
   always @(posedge clk) sDOUT[1] <= sDOUT[0];
   wire sWRITE = sDOUT[1];

   // Generate the iWRITE strobe
   reg 	write_state = 0;
   always @(posedge clk) begin
      iWRITE <= 0;
      if (sWRITE) begin
	 if (write_state == 0)
	   iWRITE <= 1;
	 write_state <= 1;
      end else
	write_state <= 0;
   end

endmodule // qsync
