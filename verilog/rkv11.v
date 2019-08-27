//	-*- mode: Verilog; fill-column: 96 -*-
//
// An implementation of the RKV11 (extended for Q22).
//
// Copyright 2015 - 2018 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

`include "qsic.vh"

module rkv11
  (
   input 	     clk, // 20MHz

   // The Bus
   input [12:0]      RAL, // latched address input
   input 	     RBS7,
   output [21:0]     TAL, // address output
   input [15:0]      RDL, // data lines
   output reg [15:0] TDL, 
   input 	     RINIT,

   // control lines
   output 	     addr_match,
   input 	     assert_vector,
   input 	     write_pulse,
   input 	     dma_read_pulse,
   output 	     dma_read_req,
   output 	     dma_write_req,
   input 	     dma_bus_master,
   input 	     dma_complete,
   input 	     dma_nxm,
   output reg 	     interrupt_request,

   // indicator panel
   input 	     ip_clk,
   input 	     ip_latch,
   output 	     ip_out,

   // configuration information
   input [15:0]      cylinders,	// number of cylinders for the current disk (from the load table)

   // connection to the storage device
   input [7:0] 	     sd_loaded, // "disk" loaded and ready
   input [7:0] 	     sd_write_protect, // the "disk" is write protected
   output [2:0]      sd_dev_sel, // "disk" drive select
   output reg [12:0] sd_lba, // linear block address
   output reg 	     sd_read, // initiate a block read
   output reg 	     sd_write, // initiate a block write
   input 	     sd_ready_u, // selected disk is ready for a command (unsynchronized)
   output [15:0]     sd_write_data,
   output reg 	     sd_write_enable, // enables writing data to the write FIFO
   input 	     sd_write_full, // write FIFO is full
   input [15:0]      sd_read_data,
   output reg 	     sd_read_enable, // enables reading data from the read FIFO
   input 	     sd_read_empty, // no data in the read FIFO
   output reg 	     sd_fifo_rst    // clear both FIFOs
   );


   // these values need to come from the configuration system !!!
   wire [12:0] addr_base = 13'o17_400;
   wire [8:0]  int_vec = 9'o220;
   wire [1:0]  mode = `MODE_Q22;


   // synchronize the device ready signal from the storage device
   reg [1:0]   sdrdy;
   wire        sd_ready = sdrdy[1];
   always @(posedge clk) sdrdy <= { sdrdy[0], sd_ready_u };

   //
   // All the bits in the various device registers.  Device register addresses are shown as addr[3:1]
   //

   localparam RKDS = 3'b000;	// Drive Status
   reg [2:0] ID;		// Drive ID [15..13]
   wire      DPL = 0;		// Drive Power Low [12]
   wire      RK05 = 1;		// RK05 [11]
   wire      DRU = 0;		// Drive Unsafe [10]
   wire      SIN = 0;		// Seek Incomplete [9]
   wire      SOK = 1;		// Sector Counter OK [8]
   wire      DRY;		// Drive Ready [7]
   wire	     RWS_RDY;		// Read/Write/Seek Ready [6]
   wire      WPS;		// Write Protect Status [5]
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
   reg 	     GO = 1;		// Go [0]  (Initializing to 1 may be obsolete!!!)

   localparam RKWC = 3'b011;	// Word Count
   reg [15:0] WC;		// WC is the 2s complement of the number of words to transfer,

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
     CYLINDERS = 203,
     SURFACES = 2,
     SECTORS = 12;
   // Convert cylinder/surface/sector into linear block address
   wire [12:0] lba = { 9'b0, SA } + (SECTORS * ({ 12'b0, SUR } + (SURFACES * { 4'b0, CYL_ADD })));
   // Calculate the next disk address
   reg [3:0]   next_sector;
   reg 	       next_surface;
   reg [7:0]   next_cylinder;
   always @(*) begin
      if ((SA + 1) == SECTORS) begin
	 next_sector = 0;
	 if (SUR == 1) begin
	    next_surface = 0;
	    next_cylinder = CYL_ADD + 1; // overrun is caught below
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
   wire overrun_sectors = (SA >= SECTORS);
   wire overrun_cylinders = ({ 8'b0, CYL_ADD } >= cylinders);
   wire overrun = overrun_sectors || overrun_cylinders;
   
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
//   wire init = (GO && (FUNC == CONTROL_RESET));	// !!! for testing

   // simulate the sectors flying by on the disk.  we only have a single sector counter,
   // not one for each disk.  it seems sufficient.
   reg [5:0] clk_div = 0;	// divide down the QBUS clock (20MHz) to get a sector clock
   always @(posedge clk)
      { SC, clk_div } <= { SC, clk_div } + 1;

   // either the device or commands from the QBUS may write protect a disk
   wire [7:0] write_protect_flag = sd_write_protect | protect;
   reg [7:0]  protect = 0;

   assign WPS = protect[DR_SEL];
   assign DRY = sd_loaded[DR_SEL];
   assign RWS_RDY = sd_loaded[DR_SEL] & sd_ready;

   //
   // QBUS Interface
   //

   assign addr_match = ((RBS7 == 1) &&			 // I/O page
			(RAL[0] != 1) &&		 // not an odd address
			(RAL[12:4] == addr_base[12:4])); // my address
   
   // data line mux
   always @(*) begin
      if (dma_bus_master) begin
	 TDL = DB;

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
   reg sd_write_zero;		// zero out the data when filling out a partial block
   assign sd_write_data = sd_write_zero ? 0 : RDL; // send DMA data to the write FIFO
   assign sd_dev_sel = DR_SEL;	// send drive select to the storage device
   assign DB = sd_read_data;	// send the read FIFO to the Data Buffer register
   
   // internal state if we're in a read or write operation
   reg dma_read = 0,		// disk write
       dma_write = 0;		// disk read
   // whenever there are words to move and the FIFO allows, request DMA
//   assign dma_read_req = dma_read & ~WC_zero & ~sd_write_full;
   // testing!!! should be using the FIFO_full signal
   assign dma_read_req = dma_read & ~WC_zero & ~sector_done;
   assign dma_write_req = dma_write & ~WC_zero & ~sd_read_empty;

   
   // State Machine
   reg [15:0] WC_display;	// grab a copy of WC
   reg 	      WC_zero = 0;	// flag when the Word Count (WC) rolls over
   reg [7:0]  saddr = 0;	// word count within a sector
   reg 	      sector_done = 0;	// saddr overflow
   reg [12:0] state = 1;	// start in state INIT
   localparam
     INIT = 0,
     READY = 1,
     WRITE_LOOP = 2,
     WRITE_WAIT = 3,
     WRITE_WAIT_DONE = 4,
     READ_START = 5,
     READ_LOOP = 6,
     READ_FLUSH = 7,
     CMD_DONE = 8;

   task set_state;
      input integer s;
      begin
	 state[s] <= 1'b1;
      end
   endtask // set_state

   task dma_step;
      begin
	 if (!INH_BA)
	   RK_BAR <= RK_BAR + 1;
	 { WC_zero, WC} <= WC + 1;
      end
   endtask

   task sector_next;
      begin
	 { CYL_ADD, SUR, SA } <= { next_cylinder, next_surface, next_sector };
      end
   endtask

   task sector_incr;
      begin
	 { sector_done, saddr } <= saddr + 1;
      end
   endtask

   always @(posedge clk) begin
      state <= 0;
      sd_read_enable <= 0;
      sd_write_enable <= 0;
      sd_write_zero <= 0;
      sd_write <= 0;
      sd_read <= 0;
      interrupt_request <= 0;
      RDY <= 0;
      sd_fifo_rst <= 0;
      
      // register writes from the host processor
      //
      // these share an always block with the state machine because both write to the RK11
      // visible registers.  However, since the state machine only ever modifies these registers
      // as a result of a DMA operation completing, the two cannot conflict since the QBUS can
      // only be doing one or the other at a given time.
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
	   default:
	     ;			// silently ignore writes to other registers
	 endcase // case (RAL[3:1])
      end

      // the main RK11 state machine
      if (RINIT)
	set_state(INIT);
      else
	case (1'b1)
	  state[INIT]:
	    begin
	       ID <= 0;
	       { SCP, INH_BA, FMT, SSE, IDE, FUNC, GO } <= 0;
	       WC <= 0;
	       WC_display <= 0;
	       WC_zero <= 0;
	       RK_BAR <= 0;
	       { DR_SEL, CYL_ADD, SUR, SA } <= 0;
	       { DRE, OVR, WLO, SKE, PGE, NXM, DLT, TE, NXD, NXC, NXS, CSE, WCE } <= 0;
	       protect <= 0;
	       dma_write <= 0;
	       dma_read <= 0;
	       saddr <= 0;
	       sector_done <= 0;
	       sd_fifo_rst <= 1;
	       set_state(READY);
	    end

	  state[READY]:
	    begin
	       RDY <= 1;	// the RK11 is ready for commands

	       // initiate a command
	       if (GO) begin
		  GO <= 0;
		  WC_zero <= 0;

		  case (FUNC)
		    CONTROL_RESET:
		      set_state(INIT);
		    
		    WRITE: 
		      begin
			 // !!! need to check drive ready and write protect
			 dma_read <= 1;
			 saddr <= 0;
			 sector_done <= 0;
			 WC_display <= -WC;
			 if (overrun) begin
			    if (overrun_cylinders)
			      NXC <= 1;
			    else // overrun_sectors
			      NXS <= 1;
			    set_state(CMD_DONE);
			 end else
			   set_state(WRITE_LOOP);
		      end
		    READ:
		      begin
			 // !!! need to check drive ready
			 dma_write <= 1;
			 saddr <= 0;
			 sector_done <= 0;
			 WC_display <= -WC;
			 if (overrun) begin
			    if (overrun_cylinders)
			      NXC <= 1;
			    else // overrun_sectors
			      NXS <= 1;
			    set_state(CMD_DONE);
			 end else begin
			    sd_lba <= lba;
			    sd_read <= 1; // start the first read from the storage device
			    set_state(READ_START);
			 end
		      end

		    // gotta figure these out !!!
		    WRITE_CHECK:	set_state(CMD_DONE);
		    SEEK:		set_state(CMD_DONE);
		    READ_CHECK:		set_state(CMD_DONE);
		    DRIVE_RESET:	set_state(CMD_DONE);

		    WRITE_LOCK:
		      begin
			 protect[DR_SEL] <= 1;
			 set_state(CMD_DONE);
		      end
		  endcase // case (FUNC)
	       end else
		 set_state(READY);
	    end

	  state[WRITE_LOOP]:
	    begin
	       // on each DMA cycle, increment the counters and write the data to the FIFO
	       if (dma_complete) begin
		  dma_step();
		  sector_incr();
		  sd_write_enable <= 1;
	       end

	       // If we see a NXM, just bail out.  This may leave data in the write FIFO but NXM
	       // is a hard error and requires reseting the RK11 which will reset the FIFOs.
	       if (dma_nxm) begin
		  NXM <= 1;
		  set_state(CMD_DONE);
	       end else if (sector_done) begin
		  if (sd_ready) begin
		     // when a sector finishes, issue the write command to the storage device
		     if (overrun) begin
			OVR <= 1;
			set_state(CMD_DONE);
		     end else begin
			sd_lba <= lba;
			sd_write <= 1;
			set_state(WRITE_WAIT);
		     end
		  end else
		    // if the storage device isn't ready, just loop until it is.  sector_done
		    // being set will pause DMA for now.
		    set_state(WRITE_LOOP);
	       end else begin
		  if (WC_zero) begin
		     // the sector's not done but we're out of words to transfer, fill out the
		     // sector with zeros
		     sd_write_zero <= 1;
		     sd_write_enable <= 1;
		     sector_incr();
		  end
		  set_state(WRITE_LOOP);
	       end
	    end

	  state[WRITE_WAIT]:
	    if (sd_ready) begin
	       // wait for the storage device to see the write command
	       sd_write <= 1;
	       set_state(WRITE_WAIT);
	    end else begin
	       // once the storage device accepts the command, bump the disk address
	       sector_next();
	       if (WC_zero)
		 // a sector is finished, the words are all transferred, then we're done.
		 set_state(WRITE_WAIT_DONE);
	       else begin
		  // the sector's done but more words to go
		  sector_done <= 0;
		  set_state(WRITE_LOOP);
	       end
	    end // else: !if(sd_ready)

	  state[WRITE_WAIT_DONE]:
	    // wait for the write command to finish.  eventually I need to check for write
	    // errors here
	    if (sd_ready)
	      if (WC_zero)
		set_state(CMD_DONE);
	      else begin
		 sector_done <= 0;
		 set_state(WRITE_LOOP);
	      end
	    else
	      set_state(WRITE_WAIT_DONE);

	  state[READ_START]:
	    if (sd_ready) begin
	       sd_read <= 1;
	       set_state(READ_START);
	    end else begin
	       // busy wait until the storage device sees the command, then increment the disk address
	       sector_next();
	       set_state(READ_LOOP);
	    end

	  state[READ_LOOP]:
	    begin
	       // whenever the DMA engine goes to read data, get it out of the FIFO
	       if (dma_read_pulse)
		 sd_read_enable <= 1;

	       if (dma_complete) begin
		  dma_step();
		  sector_incr();
	       end

	       // If we see a NXM, then just abandon everything, flush the FIFO, and we're done
	       if (dma_nxm) begin
		  NXM <= 1;
		  set_state(READ_FLUSH);
	       end else if (sector_done) // Four cases of { sector_done, WC_zero } ...
		 if (WC_zero)
		   // if saddr and WC hit 0 together, then we're done
		   set_state(CMD_DONE);
		 else begin
		    if (sd_ready) begin
		       // saddr has rolled over but there are still words to read so read the next
		       // block from the storage device
		       if (overrun) begin
			  OVR <= 1;
			  set_state(CMD_DONE);
		       end else begin
			  sd_lba <= lba;
			  sd_read <= 1;
			  sector_done <= 0;
			  set_state(READ_START);
		       end
		    end else
		      set_state(READ_LOOP);
		 end
	       else
		 if (WC_zero)
		   // all the words are transfered to memory but we have more data in the sector
		   // so we need to flush out the FIFO
		   set_state(READ_FLUSH);
		 else
		   // WC and saddr are still non-zero so just keep going
		   set_state(READ_LOOP);
	    end

	  state[READ_FLUSH]:
	    if (~sd_ready)	// wait for the storage device to finish reading
	      set_state(READ_FLUSH);
	    else if (sector_done)
	      set_state(CMD_DONE);
	    else begin
	       sd_read_enable <= 1;
	       sector_incr();
	       set_state(READ_FLUSH);
	    end

	  state[CMD_DONE]:
	    begin
	       dma_write <= 0;
	       dma_read <= 0;
	       if (IDE)
		 interrupt_request <= 1;
	       ID <= DR_SEL;
	       set_state(READY);
	    end
	  

	endcase // case (1'b1)
   end // always @ (posedge clk)
   

   // Indicator Panel - The RK11-C has connectors for an indicator panel but we've never been
   // able to find any examples of them or even pictures.  Our supposition is that DEC, in fact,
   // never made any RK11 indicator panels.  From the print set and those connectors, we could
   // determine the light layout that DEC used (or intended) but we've gone our own way here.
   wire [7:0] drive_ready;
   wire [7:0] drive_read;
   wire [7:0] drive_write;

   genvar     i;
   for (i = 0; i < 8; i=i+1) begin
      assign drive_ready[i] = (DR_SEL == i) ? sd_ready & sd_loaded[i] : sd_loaded[i];
      assign drive_read[i] = (DR_SEL == i) ? dma_write : 0;
      assign drive_write[i] = (DR_SEL == i) ? dma_read : 0;
   end

   indicator
     rk11_ip(ip_clk, ip_latch, ip_out,
	     { ERROR, HE, SCP, INH_BA, SSE, RDY, IDE, 1'b0, FUNC, 1'b0, GO, 1'b0, RK_BAR, 1'b0 },
	     { DRE, OVR, WLO, NXM, NXD, NXC, 1'b0, NXS, CSE, WCE, 1'b0, 3'b0, interrupt_request,
	       1'b0, dma_read_req, dma_write_req, 1'b0, 1'b0, WC_display },
	     { 2'b01, 2'b01, 1'b0, DR_SEL, 8'b0, CYL_ADD, 7'b0, SUR, SA },
	     { mode == `MODE_Q22, mode == `MODE_Q18, WC_zero, sector_done, // 2'b0,
	      drive_ready[7], write_protect_flag[7], drive_read[7], drive_write[7],
	      drive_ready[6], write_protect_flag[6], drive_read[6], drive_write[6],
	      drive_ready[5], write_protect_flag[5], drive_read[5], drive_write[5],
	      drive_ready[4], write_protect_flag[4], drive_read[4], drive_write[4],
	      drive_ready[3], write_protect_flag[3], drive_read[3], drive_write[3],
	      drive_ready[2], write_protect_flag[2], drive_read[2], drive_write[2],
	      drive_ready[1], write_protect_flag[1], drive_read[1], drive_write[1],
	      drive_ready[0], write_protect_flag[0], drive_read[0], drive_write[0] }
	     );


endmodule // rkv11
