//	-*- mode: Verilog; fill-column: 96 -*-
//
// An implementation of the RKV11 (extended for Q22).
//
// Copyright 2015 - 2017 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

`include "qsic.vh"

module rkv11
  (
   input 	     clk, // 20MHz

   // The Bus
   input [21:0]      RAL, // latched address input
   input 	     RBS7,
   output [21:0]     TAL, // address output
   input [15:0]      RDL, // data lines
   output reg [15:0] TDL, 
   input 	     RINIT,

   // control lines
   output 	     addr_match,
   input 	     assert_vector,
   input 	     write_pulse,
   output 	     dma_read_req,
   output 	     dma_write_req,
   input 	     dma_bus_master,
   input 	     dma_complete,
   input 	     dma_nxm,
   output reg 	     interrupt_request,

   // connection to the storage device
   input [7:0] 	     sd_loaded, // "disk" loaded and ready
   input [7:0] 	     sd_write_protect, // the "disk" is write protected
   output [2:0]      sd_dev_sel, // "disk" drive select
   output reg [12:0] sd_lba, // linear block address
   output reg 	     sd_read, // initiate a block read
   output reg 	     sd_write, // initiate a block write
   input 	     sd_ready, // selected disk is ready for a command
   output [15:0]     sd_write_data,
   output reg 	     sd_write_enable, // enables writing data to the write FIFO
   input 	     sd_write_full, // write FIFO is full
   input [15:0]      sd_read_data,
   output reg 	     sd_read_enable, // enables reading data from the read FIFO
   input 	     sd_read_empty // no data in the read FIFO
   );


   // these values need to come from the configuration system !!!
   wire [12:0] addr_base = 13'o17_400;
   wire [8:0]  int_vec = 9'o220;
   wire [1:0]  mode = `MODE_Q22;


   //
   // All the bits in the various device registers.  Device register addresses are shown as addr[3:1]
   //

   localparam RKDS = 3'b000;	// Drive Status
   reg [2:0] ID;		// Drive ID [15..13]
   reg 	     DPL;		// Drive Power Low [12]
   wire      RK05 = 1;		// RK05 [11]
   reg 	     DRU;		// Drive Unsafe [10]
   reg 	     SIN;		// Seek Incomplete [9]
   reg 	     SOK;		// Sector Counter OK [8]
   reg 	     DRY;		// Drive Ready [7]
   reg 	     RWS_RDY;		// Read/Write/Seek Ready [6]
   reg 	     WPS;		// Write Protect Status [5]
   wire      SCeqSA = (SC == SA); // Sector Counter = Sector Address [4]
   reg [3:0] SC = 0;		  // Sector Counter [3..0]

   localparam RKER = 3'b001;	// Error
   reg 	     DRE;		// Drive Error [15]
   reg 	     OVR;		// Overrun [14]
   reg 	     WLO;		// Write Lock Out Violation [13]
   reg 	     SKE;		// Seek Error [12]
   reg 	     PGE;		// Programming Error [11]
   reg 	     NXM;		// Non-Existent Memory [10]
   reg 	     DLT;		// Data Late [9]
   reg 	     TE;		// Timing Error [8]
   reg 	     NXD;		// Non-Existent Disk [7]
   reg 	     NXC;		// Non-Existent Cylinder [6]
   reg 	     NXS;		// Non-Existent Sector [5]
				// unused [4..2]
   reg 	     CSE;		// Checksum Error [1]
   reg 	     WCE;		// Write Check Error [0]

   localparam RKCS = 3'b010;	// Control Status
   wire      ERROR = HE | CSE | WCE; // Error [15]
   wire      HE = DRE | OVR | WLO | SKE | PGE | NXM | DLT | TE | NXD | NXC | NXS; // Hard Error [14]
   reg 	     SCP;		// Search Complete [13]
				// unused [12]
   reg 	     INH_BA;		// Inhibit Bus Address Increment [11]
   reg 	     FMT;		// Format [10]
				// unused [9]
   reg 	     SSE;		// Stop on Soft Error [8]
   reg 	     RDY;		// Control Ready [7]
   reg 	     IDE;		// Interrupt on Done Enable [6]
				// Memory Extension [5..4] (see BAE[1:0])
   reg [2:0] FUNC = CONTROL_RESET; // Function [3..1]
   reg 	     GO = 1;		// Go [0]

   localparam RKWC = 3'b011;	// Word Count
   reg [15:0] WC;		// WC is the 2s complement of the negative of the number of words to transfer,

   localparam RKBA = 3'b100;	// Current Bus Address
//   reg [15:0] BA;

   localparam RKDA = 3'b101;	// Disk Address
   reg [2:0]  DR_SEL;		// Drive Select [15..13]
   reg [7:0]  CYL_ADD;		// Cylinder Address (0..202) [12..5]
   reg 	      SUR;		// Surface (0 = upper) [4]
   reg [3:0]  SA;		// Sector Address (0..11) [3..0]

   localparam RKXA = 3'b110;	// Extended Bus Address
//   reg [5:0]  BAE;		// Bus Address Extension

   localparam RKDB = 3'b111;	// Data Buffer
   wire [15:0] DB;		// connected to the read FIFO

   reg [21:1] RK_BAR;		// The full bus address register (low bit assumed = 0)
   assign TAL = { RK_BAR, 1'b0 }; // send it out the address lines


   localparam 
//     CYLINDERS = 203,
     CYLINDERS = 2,		// reduced for the RAM disk !!!
     SURFACES = 2,
     SECTORS = 12;
   // Convert cylinder/surface/sector into linear block address
   wire [12:0] lba = SA + (SECTORS * (SUR + (SURFACES * CYL_ADD)));
   // Calculate the next disk address
   wire [12:0] next_disk_address = { next_cylinder, next_surface, next_sector };
   reg [3:0]   next_sector;
   reg 	       next_surface;
   reg [7:0]   next_cylinder;
   always @(*) begin
      if ((SA + 1) == SECTORS) begin
	 next_sector = 0;
	 if (SUR == 1) begin
	    next_surface = 0;
	    next_cylinder = CYL_ADD + 1; // overrun is caught elsewhere
	 end else begin
	    next_surface = 1;
	    next_cylinder = CYL_ADD;
	 end
      end else begin
	 next_sector = SA + 1;
	 next_surface = SUR;
	 next_cylinder = CYL_ADD;
      end
   end // always @ begin
   // Detect Overrun
   wire overrun = (SA >= SECTORS) || (CYL_ADD >= CYLINDERS);
   
   // Function Commands
   localparam
     CONTROL_RESET = 3'b000,
     WRITE = 3'b001,
     READ = 3'b010,
     WRITE_CHECK = 3'b011,
     SEEK = 3'b100,
     READ_CHECK = 3'b101,
     DRIVE_RESET = 3'b110,
     WRITE_LOCK = 3'b111;

   // internal initialization signal
//   wire init = RINIT || (GO && (FUNC == CONTROL_RESET));
   wire init = (GO && (FUNC == CONTROL_RESET));	// !!! for testing

   // simulate the sectors flying by on the disk.  we only have a single sector counter,
   // not one for each disk.  it seems sufficient.
   reg [5:0] clk_div = 0;	// divide down the QBUS clock (20MHz) to get a sector clock
   always @(posedge clk)
      { SC, clk_div } <= { SC, clk_div } + 1;

   // either the device or commands from the QBUS may write protect a disk
   wire [7:0] write_protect_flag = sd_write_protect | protect;
   reg [7:0]  protect = 0;


   reg [7:0]  saddr;			 // word count within a sector

   
   //
   // QBUS Interface
   //

   assign addr_match = ((RBS7 == 1) &&			 // I/O page
			(RAL[0] != 1) &&		 // not an odd address
			(RAL[12:4] == addr_base[12:4])); // my address
   
   // data line mux
//   wire [15:0] rd_data = ram_disk[rd_addr]; // lookup in the RAM disk
   always @(*) begin
      if (dma_bus_master) begin
//	 TDL = rd_data;
	 TDL = DB;		// Not tested!!! just trying to get ram_disk to use block RAM

      end else if (assert_vector) begin
	 TDL = { 7'b0, int_vec };

      end else begin
	 case (RAL[3:1])
	   RKDS:
	     TDL = { ID, DPL, RK05, DRU, SIN, SOK, DRY, RWS_RDY, WPS, SCeqSA, SC };
	   RKER:
	     TDL = { DRE, OVR, WLO, SKE, PGE, NXM, DLT, TE, NXD, NXC, NXS, 3'b000, CSE, WCE };
	   RKCS:
	     TDL = { ERROR, HE, SCP, 1'b0, INH_BA, 1'b0, FMT, SSE, RDY, IDE, RK_BAR[17:16], FUNC, GO };
	   RKWC:
	     TDL = WC;
	   RKBA:
	     TDL = { RK_BAR[15:1], 1'b0};
	   RKDA:
	     TDL = { DR_SEL, CYL_ADD, SUR, SA };
	   RKXA:
	     if (mode == `MODE_Q22)
	       // this register didn't exist on the RKV11 but the RKV11 didn't do Q22
	       // either so if someone turns on Q22 mode for this device, they need to
	       // update their device driver anyway.
	       TDL = { 10'b0, RK_BAR[21:16] };
	     else
	       // this was a maintenance register on the RK11-C; don't know what it did and
	       // we're not trying to emulate it.  on the RK11-D it just returned 0.
	       TDL = 0;
	   RKDB:
	     TDL = DB;
	 endcase // case (RAL[3:0])
      end
   end

   //
   // write registers and execute commands
   //

   // send some signals out to the storage device
   assign sd_write_data = RDL;	// send DMA data to the write FIFO
   assign sd_dev_sel = DR_SEL;	// send drive select to the storage device
   assign DB = sd_read_data;	// send the read FIFO to the Data Buffer register
   
   // internal state if we're in a read or write operation
   reg dma_read = 0,		// disk write
       dma_write = 0;		// disk read
   // whenever there are words to move and the FIFO allows, request the DMA
   assign dma_read_req = dma_read & (WC != 0) & !sd_write_full;
   assign dma_write_req = dma_write & (WC != 0) & !sd_read_empty;

   reg [15:8] block_count = 0;	// keep track of number of blocks written to the FIFO
   reg 	      sd_ready_wait = 0;
   reg 	      WC_zero = 0;	// flag when the Word Count (WC) rolls over
   
   always @(posedge clk) begin
      interrupt_request <= 0;
      sd_read_enable <= 0;
      sd_write_enable <= 0;
      sd_ready_wait <= 0;
      sd_write <= 0;
      sd_read <= 0;

      // write data to a register
      if (addr_match && write_pulse) begin
	 case (RAL[3:1])
	   RKCS:		// Control/Status
	     { INH_BA, FMT, SSE, IDE, RK_BAR[17:16], FUNC, GO } 
	       <= { RDL[11], RDL[10], RDL[8], RDL[6], RDL[5:4], RDL[3:1], RDL[0] };
	   RKWC:		// Word Count
	     { WC_zero, WC } <= { 1'b0, RDL };
	   RKBA:		// Bus Address
	     RK_BAR[15:1] <= RDL[15:1];
	   RKDA:
	     { DR_SEL, CYL_ADD, SUR, SA } <= RDL;
	   RKXA:		// RKXA - Extended Address
	     // The extended address was not implemented in any DEC RK11 controller but this is
	     // done similarly to how it was handled in the RLV12.  Notice that RK_BAR[17:16] can
	     // be set either through RKCS or through RKXA.  Again, this is like the RLV12.
	     if (mode == `MODE_Q22)
	       RK_BAR[21:16] <= RDL[5:0];
`ifdef NOTDEF
	   // the data buffer will likely be replaced by one end of a FIFO and then no longer be
	   // writable.  for now it's useful to be able to write values into it.  !!!
	   RKDB:		// Data Buffer
	     DB <= RDL;
`endif
	 endcase // case (RAL[3:1])
      end

      else if (init) begin
	 { ID, DPL, DRU, SIN, SOK, DRY, RWS_RDY, WPS } <= 0;
	 { DRE, OVR, WLO, SKE, PGE, NXM, DLT, TE, NXD, NXC, NXS, CSE, WCE } <= 0;
	 { SCP, INH_BA, FMT, SSE, RDY, IDE, FUNC, GO } <= 0;
	 WC <= 0;
	 WC_zero <= 0;
	 RK_BAR <= 0;
	 { DR_SEL, CYL_ADD, SUR, SA } <= 0;
	 protect <= 0;
	 dma_write <= 0;
	 dma_read <= 0;
	 interrupt_request <= 0;
	 block_count <= 0;
	 RDY <= 1;
      end

      // handle DMA cycles
      else if (dma_read || dma_write) begin
	 // move the data to/from a FIFO and update counters
	 if (dma_complete) begin
	    // control writing/reading the storage device FIFO
	    if (dma_read)
	      sd_write_enable <= 1;
	    else if (dma_write)
	      sd_read_enable <= 1;

	    // increment the various counters
	    if (!INH_BA)
	      RK_BAR <= RK_BAR + 1;
	    { block_count, saddr } <= { block_count, saddr } + 1;
	    { WC_zero, WC} <= WC + 1;
	 end // if (dma_complete)

	 // kick the storage device to read or write a block
	 // I don't think this really works if the write FIFO is larger than two blocks and
	 // block_count is ever greater than 1  !!!
	 else if (block_count != 0) begin
	    if (sd_ready) begin
	       sd_lba <= lba;	// set the lba from the current disk address
	       if (dma_read)
		 sd_write <= 1;	// tell the storage device to start writing
	       else if (dma_write)
		 sd_read <= 1;	// tell the storage device to start reading
	       sd_ready_wait <= 1; // flag that we're waiting for the storage device to read the command
	    end else if (sd_ready_wait) begin
	       // wait until now to increment the disk address
	       { CYL_ADD, SUR, SA } <= { next_cylinder, next_surface, next_sector };
	       block_count <= block_count - 1;
	    end
	 end

	 // If all the words have been DMAd (WC_zero) and all the SD read/write commands have
	 // been issued (block_count == 0) and the SD is ready, then we're done.  Also done if
	 // there's a NXM.
	 else if ((WC_zero && (block_count == 0) && sd_ready) ||
		  dma_nxm) begin
	    // need to implement partial block read/write here !!!
	    RDY <= 1;
	    dma_read <= 0;
	    dma_write <= 0;
	    block_count <= 0;
	    if (dma_nxm)
	      NXM <= 1;
	    if (IDE)
	      interrupt_request <= 1;
	 end
      end

      // initiate a command
      else if (GO) begin
	 GO <= 0;
	 case (FUNC)
//	   CONTROL_RESET: handled by the init signal
	   WRITE: 
	     begin
		// !!! need to check drive ready
		sd_lba <= lba;
		dma_read <= 1;
		saddr <= 0;
		block_count <= 0;
		WC_zero <= 0;
		RDY <= 0;
	     end
	   READ:
	     begin
		// !!! need to check drive ready
		sd_lba <= lba;
		dma_write <= 1;
		saddr <= 0;
		block_count <= 1; // this will trigger the first read from the storage device
		WC_zero <= 0;
		RDY <= 0;
	     end
`ifdef NOTDEF
	   // gotta figure these out !!!
	   WRITE_CHECK: ;
	   SEEK: ;
	   READ_CHECK: ;
	   DRIVE_RESET: ;
`endif
	   WRITE_LOCK:
	     protect[DR_SEL] <= 1;
	 endcase // case (FUNC)
      end

   end

endmodule // rkv11
