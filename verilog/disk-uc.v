//	-*- mode: Verilog; fill-column: 96 -*-
//
// The interface between a disk and the micro-controller control bus.
//
// Copyright 2015 Noel Chiappa and David Bridgham

`include "qsic.vh"

module disk_uc
  // all these parameters need to be set
  #(parameter 
    uDEV = 0,
    DEFAULT_ADDR = 0,
    DEFAULT_INT_VEC = 0,
    DEFAULT_INT_PRI = 0)
   (
    input 	      init,
    input 	      qclk,

    // The internal micro-controller bus
    input [15:0]      uADDR,
    inout [15:0]      uDATA,
    input 	      uWRITE,
    input 	      uCLK,
    output reg 	      uWAIT, // wired-OR
    output reg [7:0]  uINTERRUPT,

    // Configuration information output
    output reg [12:0] io_addr_base = DEFAULT_ADDR,
    output reg [8:0]  int_vec = DEFAULT_INT_VEC,
    output reg [1:0]  int_priority = DEFAULT_INT_PRI,
    output reg [1:0]  mode,
    output [7:0]      loaded, // a "disk pack" is loaded and working
    output [7:0]      write_protect, // the disk pack is write protected

    // Read register input
    input [2:0]       cmd,
    input [2:0]       drive_select,
    input [31:0]      lba,
    input 	      interrupt
    );

   localparam UBASE = 4 * uDEV;

   // synchronize loaded and write_protect to qclk.  we don't worry about the ADDR and INT
   // registers because those are loaded at init and then not changed.  it shouldn't ever
   // be a problem but they could be synchronized the same way.
   reg [7:0] 	      uwrite_protect, uloaded;
   reg [7:0] 	      swrite_protect[0:1];
   reg [7:0] 	      sloaded[0:1];
   always @(posedge qclk) begin
      swrite_protect[0] <= swrite_protect[1];
      swrite_protect[1] <= uwrite_protect;
      sloaded[0] <= sloaded[1];
      sloaded[1] <= uloaded;
   end
   assign write_protect = swrite_protect[0];
   assign loaded = sloaded[0];

   // an interrupt request sets the uINTERRUPT line asynchronously, while reading the CMD
   // register clears it
   always @(posedge uCLK, interrupt)
     if (interrupt)
       uINTERRUPT[uDEV] <= 1;
     else if (!uWRITE && (uADDR == UBASE+`DEV_CMD))
       uINTERRUPT[uDEV] <= 0;

   // Reading the registers
   reg [15:0] 	      udata_reg;
   assign uDATA = udata_reg;

   always @(*) begin
      udata_reg <= 16'bZ;

      if (!uWRITE)		// if read
	case (uADDR)
	  UBASE+`DEV_CMD: udata_reg <= { 9'b0, drive_select, 1'b0, cmd };
	  UBASE+`DEV_DA_LOW: udata_reg <= lba[15:0];
	  UBASE+`DEV_DA_HI: udata_reg <= lba[31:16];
	  UBASE+`DEV_FIFO: udata_reg <= 0; // connect to write FIFO !!!
	endcase
   end // always @ begin

   // Controlling the uWAIT signal
   always @(*) begin
      if (uADDR == UBASE+`DEV_FIFO)
	if (uWRITE)
	  uWAIT <= 0;		// connect to read FIFO !!!
	else
	  uWAIT <= 0;		// connect to write FIFO !!!
      else
	if (init)
	  uWAIT <= 1;
	else 
	  uWAIT <= 0;
   end // always @ begin

   // Writing registers, also an asynchronous initialization of the configuration
   always @(posedge uCLK, init)
     if (init) begin
	io_addr_base <= DEFAULT_ADDR;
	int_vec <= DEFAULT_INT_VEC;
	int_priority <= DEFAULT_INT_PRI;
	mode <= `MODE_DISABLED;
	uloaded <= 0;
	uwrite_protect <= 0;
     end else if (uWRITE)
       case (uADDR)
	 UBASE+`DEV_ADDR: io_addr_base <= uDATA[12:0];
	 UBASE+`DEV_INT: { mode, int_priority, int_vec } <= { uDATA[15:14], uDATA[10:0] };
	 UBASE+`DEV_STAT: { uwrite_protect, uloaded } <= uDATA;
//	  UBASE+`DEV_FIFO:  // connect to write FIFO !!!
       endcase

endmodule // disk_uc
