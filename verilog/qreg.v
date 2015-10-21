//	-*- mode: Verilog; fill-column: 96 -*-
//
// The QBUS to device registers and interrupt control.
//
// Copyright 2015 Noel Chiappa and David Bridgham

// Mediates between the asynchronous QBUS and the FPGA internal, synchronous operation of
// various I/O devices.  Handles data reads and writes from/to device registers.  Also runs the
// interrupt request protocol.
module qreg
  #(parameter
    RA_BITS = 3)		// how many bits are needed to address the device's registers
   (
    // Configuration
    input [12:0] 	     io_addr_base,
    input [8:0] 	     int_vector,
    input [1:0] 	     int_priority,

    input 		     clk, // 20MHz
   
    // The QBUS
    output reg 		     DALbe_L, // enable BDAL output onto the bus (active low)
    output reg 		     DALtx, // enable BDAL output through level-shifter
    output reg 		     DALst, // strobe data output to BDAL
    inout [21:0] 	     ZDAL,
    inout 		     ZBS7,
    inout 		     ZWTBT,
    input 		     RSYNC,
    input 		     RDIN,
    input 		     RDOUT,
    output reg 		     TRPLY,

    // to device registers
    output reg [RA_BITS-1:0] reg_addr, // the register address within the block
    output reg 		     addr_mine, // the address matches
    output reg 		     write_cycle,
    output 		     read_cycle
   );


   reg 			     write_flag; // remember RWTBT during address phase
   assign read_cycle = RSYNC & ~write_flag;
   

   // Asynchronously latch the addressing information whenever it comes along
   always @(posedge RSYNC) begin
      if (ZBS7 &&		// I/O page
	  !ZDAL[0] &&		// not an odd address
	  (ZDAL[12:RA_BITS+1] == io_addr_base[12:RA_BITS+1])) begin
	 reg_addr <= ZDAL[RA_BITS:0];
	 addr_mine <= 1;
	 write_cycle <= ZWTBT;
      end else
	addr_mine <= 0;
   end

   always @(*) begin
      DALbe_L <= 1;		// idle
      
      if (addr_mine && RDIN)
	DALbe_L <= 0;
   end

   always @(*) begin
      DALtx <= 0;

      if (addr_mine && read_cycle)
	DALtx <= 1;
   end // always @ begin

   always @(*) begin
      TRPLY <= 0;

      if (addr_mine && (RDIN || RDOUT))
	TRPLY <= 1;
   end



   // Synchronize RDIN and RDOUT to internal clock
   reg [1:0] DINra, DOUTra;
   always @(posedge clk) DINra <= { DINra[0], RDIN };
   always @(posedge clk) DOUTra <= { DOUTra[0], RDOUT };
   wire      sDIN = DINra[1];	// a synchronized version of RDIN
   wire      sDOUT = DOUTra[1];	// a synchronized version of RDOUT

   // Synchronously strobe the register data (which should be already sitting on ZDAL) into the
   // latch in the Am2908.  Since sDIN is synchronized with clk, it is delayed from RDIN by 1 to
   // 2 clock cycles (50 to 100 ns).  However, the QBUS spec says we have up to 125ns to put our
   // data on the bus after asserting RPLY so we don't have to delay RPLY any.
   always @(posedge clk) begin
      DALst <= 0;

      if (sDIN)
	DALst <= 1;
   end

   // Synchronously strobe the bus data into the device register.  The dance with write_state is
   // so write_cycle is only asserted for one clock cycle each time sDOUT cycles.
   reg 	write_state = 0;
   always @(posedge clk) begin
      write_cycle <= 0;
      if (sDOUT) begin
	 if (write_state == 0)
	   write_cycle <= 1;
	 write_state <= 1;
      end else
	write_state <= 0;
   end

endmodule // qsync
