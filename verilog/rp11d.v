//	-*- mode: Verilog; fill-column: 96 -*-
//
// An implementation of the RP11-D
//
// Copyright 2020 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

`include "qsic.vh"

module rp11d
  #(parameter CONF_ADDR,
    parameter UNIT)
  (
   input 	     clk, // 20MHz
   input 	     reset,

   // Configuration Register Control
   input [15:0]      c_addr, // address of configuration register
   input [15:0]      c_wdata, // data lines
   output reg [15:0] c_rdata,
   output reg 	     c_addr_match, // if c_addr is one of ours
   input 	     c_write, // write strobe

   // The Bus
   input [12:0]      b_addr, // bus address address input
   input 	     b_iopag, // the I/O page on the bus, aka RBS7
   input [15:0]      b_wdata, // data lines
   output reg [15:0] b_rdata, 

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

   // connection to the storage device
   input [7:0] 	     sd_loaded, // "disk pack" loaded and ready
   input [7:0] 	     sd_write_protect, // the "disk" is write protected
   output [2:0]      sd_dev_sel, // drive select
   output reg [23:0] sd_lba, // linear block address
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


   //
   // Device Configuration
   //
   reg 	      enabled = 1;
   reg 	      q22 = 1;		// default to off on the USIC !!!
   reg 	      extended = 0;
   reg [12:0] addr_base = 13'o17_700;
   reg [1:0]  int_pri = INTP_5;
   reg [8:0]  int_vec = 9'o254;

   reg 	      pack_enabled[0:7];  // this pack is enabled
   reg 	      pack_extended[0:7]; // set if it's an extended pack, neither RP02 nor RP03
   reg 	      pack_rp03[0:7];	// set if it's an RP03 else RP02
   reg [2:0]  pack_sd[0:7];	// which storage device this pack is on
   reg [31:0] pack_offset[0:7];	// location of start of pack on Storage Device
   reg [15:0] pack_size[0:7];	// largest cylinder number for extended packs

   // read config registers and compute the address match
   always @(*) begin
      c_addr_match = 1;
      case (c_addr)
	CONF_ADDR: c_rdata = { enabled, q22, extended, addr_base };
	CONF_ADDR+1: c_rdata = {2'b0, int_pri, 3'b0, int_vec };
	// Load Table
	CONF_ADDR+2: c_rdata = { pack_enabled[0], pack_extended[0], pack_rp03[0], 10'b0, pack_sd[0] };
	CONF_ADDR+3: c_rdata = pack_offset[0][15:0];
	CONF_ADDR+4: c_rdata = pack_offset[0][31:16];
	CONF_ADDR+5: c_rdata = pack_size[0];
	
	CONF_ADDR+6: c_rdata = { pack_enabled[1], pack_extended[1], pack_rp03[1], 10'b0, pack_sd[1] };
	CONF_ADDR+7: c_rdata = pack_offset[1][15:0];
	CONF_ADDR+8: c_rdata = pack_offset[1][31:16];
	CONF_ADDR+9: c_rdata = pack_size[1];
	
	CONF_ADDR+10: c_rdata = { pack_enabled[2], pack_extended[2], pack_rp03[2], 10'b0, pack_sd[2] };
	CONF_ADDR+11: c_rdata = pack_offset[2][15:0];
	CONF_ADDR+12: c_rdata = pack_offset[2][31:16];
	CONF_ADDR+13: c_rdata = pack_size[2];
	
	CONF_ADDR+14: c_rdata = { pack_enabled[3], pack_extended[3], pack_rp03[3], 10'b0, pack_sd[3] };
	CONF_ADDR+15: c_rdata = pack_offset[3][15:0];
	CONF_ADDR+16: c_rdata = pack_offset[3][31:16];
	CONF_ADDR+17: c_rdata = pack_size[3];
	
	CONF_ADDR+18: c_rdata = { pack_enabled[4], pack_extended[4], pack_rp03[4], 10'b0, pack_sd[4] };
	CONF_ADDR+19: c_rdata = pack_offset[4][15:0];
	CONF_ADDR+20: c_rdata = pack_offset[4][31:16];
	CONF_ADDR+21: c_rdata = pack_size[4];
	
	CONF_ADDR+22: c_rdata = { pack_enabled[5], pack_extended[5], pack_rp03[5], 10'b0, pack_sd[5] };
	CONF_ADDR+23: c_rdata = pack_offset[5][15:0];
	CONF_ADDR+24: c_rdata = pack_offset[5][31:16];
	CONF_ADDR+25: c_rdata = pack_size[5];
	
	CONF_ADDR+26: c_rdata = { pack_enabled[6], pack_extended[6], pack_rp03[6], 10'b0, pack_sd[6] };
	CONF_ADDR+27: c_rdata = pack_offset[6][15:0];
	CONF_ADDR+28: c_rdata = pack_offset[6][31:16];
	CONF_ADDR+29: c_rdata = pack_size[6];
	
	CONF_ADDR+30: c_rdata = { pack_enabled[7], pack_extended[7], pack_rp03[7], 10'b0, pack_sd[7] };
	CONF_ADDR+31: c_rdata = pack_offset[7][15:0];
	CONF_ADDR+32: c_rdata = pack_offset[7][31:16];
	CONF_ADDR+33: c_rdata = pack_size[7];
	
	default: 
	  begin
	     c_addr_match = 0;
	     c_rdata = 16'bx;
	  end
      endcase // case (c_addr)
   end

   // write config registers
   always @(posedge clk)
     if (c_addr_match && c_write)
       case (c_addr)
	 CONF_ADDR:
	   begin
	      enabled <= c_wdata[15];
	      q22 <= c_wdata[14];
	      extended <= c_wdata[13];
	      addr_base[12:5] <= c_wdata[12:5]; // must be 16 word aligned
	   end
	 CONF_ADDR+1:
	   begin
	      int_pri <= c_wdata[13:12];
	      int_vec <= c_wdata[8:0];
	   end

	 CONF_ADDR+2: { pack_enabled[0], pack_extended[0], pack_rp03[0], pack_sd[0] } <= { c_wdata[15:13}, c_wdata[2:0] };
	 CONF_ADDR+3: pack_offset[0][15:0] <= c_wdata;
	 CONF_ADDR+4: pack_offset[0][31:16] <= c_wdata;
	 CONF_ADDR+5: pack_size[0] <= c_wdata;

	 CONF_ADDR+6: { pack_enabled[1], pack_extended[1], pack_rp03[1], pack_sd[1] } <= { c_wdata[15:13}, c_wdata[2:0] };
	 CONF_ADDR+7: pack_offset[1][15:0] <= c_wdata;
	 CONF_ADDR+8: pack_offset[1][31:16] <= c_wdata;
	 CONF_ADDR+9: pack_size[1] <= c_wdata;

	 CONF_ADDR+10: { pack_enabled[2], pack_extended[2], pack_rp03[2], pack_sd[2] } <= { c_wdata[15:13}, c_wdata[2:0] };
	 CONF_ADDR+11: pack_offset[2][15:0] <= c_wdata;
	 CONF_ADDR+12: pack_offset[2][31:16] <= c_wdata;
	 CONF_ADDR+13: pack_size[2] <= c_wdata;

	 CONF_ADDR+14: { pack_enabled[3], pack_extended[3], pack_rp03[3], pack_sd[3] } <= { c_wdata[15:13}, c_wdata[2:0] };
	 CONF_ADDR+15: pack_offset[3][15:0] <= c_wdata;
	 CONF_ADDR+16: pack_offset[3][31:16] <= c_wdata;
	 CONF_ADDR+17: pack_size[3] <= c_wdata;

	 CONF_ADDR+18: { pack_enabled[4], pack_extended[4], pack_rp03[4], pack_sd[4] } <= { c_wdata[15:13}, c_wdata[2:0] };
	 CONF_ADDR+19: pack_offset[4][15:0] <= c_wdata;
	 CONF_ADDR+20: pack_offset[4][31:16] <= c_wdata;
	 CONF_ADDR+21: pack_size[4] <= c_wdata;

	 CONF_ADDR+22: { pack_enabled[5], pack_extended[5], pack_rp03[5], pack_sd[5] } <= { c_wdata[15:13}, c_wdata[2:0] };
	 CONF_ADDR+23: pack_offset[5][15:0] <= c_wdata;
	 CONF_ADDR+24: pack_offset[5][31:16] <= c_wdata;
	 CONF_ADDR+25: pack_size[5] <= c_wdata;

	 CONF_ADDR+26: { pack_enabled[6], pack_extended[6], pack_rp03[6], pack_sd[6] } <= { c_wdata[15:13}, c_wdata[2:0] };
	 CONF_ADDR+27: pack_offset[6][15:0] <= c_wdata;
	 CONF_ADDR+28: pack_offset[6][31:16] <= c_wdata;
	 CONF_ADDR+29: pack_size[6] <= c_wdata;

	 CONF_ADDR+30: { pack_enabled[7], pack_extended[7], pack_rp03[7], pack_sd[7] } <= { c_wdata[15:13}, c_wdata[2:0] };
	 CONF_ADDR+31: pack_offset[7][15:0] <= c_wdata;
	 CONF_ADDR+32: pack_offset[7][31:16] <= c_wdata;
	 CONF_ADDR+33: pack_size[7] <= c_wdata;
       endcase // case (c_addr)

   //
   // RP11-D Device Registers.  Device register addresses are shown as addr[4:1]
   //

   localparam RPPS = 4'b0010;	// Pack Size
   reg [15:0] PS;		// Largest valid cylinder number of selected unit.  0 means a
				// legacy pack, either an RP02 or RP03.
   
   localparam RPXA = 4'b0011;	// Extended Address
   reg [5:0]  BAE;		// Bus Address Extension [5..0]

   localparam RPDS = 4'b0100;	// Drive Status
   wire       SU_RDY;		// Selected Unit Ready [15]
   wire       SU_OL;		// Selected Unit Online [14]
   wire       SU_RP03 = 1;	// Selected Unit is an RP03 [13]
   wire       HNF = 0;		// Header Not Found [12]
   wire       SU_SI = 0;	// Selected Unit Seek Incomplete (seeks always complete) [11]
   wire       SU_SU = 0;	// Selected Unit Seek Underway (seeks complete immediately) [10]
   wire       SU_FU = 0;	// Selected Unit File Unsafe [9]
   wire       SU_WP;		// Selected Unit Write Protect [8]
   wire [7:0] ATTN = 0;		// Drive Attention [7..0] (need to implement !!!)

   localparam RPER = 4'b0101;   // Error
   reg 	      WPV = 0;		// Write Protect Violattion [15]
   wire       FUV = 0;		// File Unsafe Violation [14]
   reg 	      NXC = 0;		// Non-existent Cylinder [13]
   reg 	      NXT = 0;		// Non-existent Track [12]
   reg 	      NXS = 0;		// Non-existent Sector [11]
   reg 	      PROG = 0;		// Programming Error [10]
   wire       FMTE = 0;		// Format Error [9]
   wire       MODE = 0;		// Mode Error [8]
   wire       LPE = 0;		// Longitudinal Parity Error [7]
   wire       WPE = 0;		// Word Parity Errir [6]
   reg 	      CSME = 0;		// Checksum Error [5]
   wire       TIMEE = 0;	// Timing Error [4]
   reg 	      WCE = 0;		// Write Check Error [3]
   reg 	      NXM = 0;		// Non-existence Memory [2]
   reg 	      EOP = 0;		// End of Pack [1]
   wire       DSK_ERR = 0;	// Disk Error (OR | HNF) [0]

   localparam RPCS = 4'b0110;	// Control Status
   wire       ERR = HE | CSME;	// Error [15]
   wire       HE = EOP | NXM | WCE | PROG | NXS | NXT | NXC | WPV; // Hard Error [14]
   reg 	      AIE = 0;		// Attention Interrupt Enable [13]	
   wire       MODE = 0;		// Mode [12] (should generate an error !!!)
   wire       HDR = 0;		// Header [11] (should generate an error !!!)
   reg 	      DRV_SEL = 0;	// Drive Select [10..8]
   reg 	      RDY = 0;		// Controller Ready [7]
   reg 	      IDE = 0;		// Interrupt on Done Enable [6]
   wire [1:0] MEX = BAE[1:0];	// Memory Extended Address [5..4]
   reg [2:0]  COM = 0;		// Function (Command) [3..1]
   reg 	      GO = 0;		// Go [0]

   localparam RPWC = 4'b0111;	// Word Count
   reg [15:0] WC;		// WC is the 2's complement of the number of words to transfer

   localparam RPBA = 4'b1000;	// Bus Address
   reg [15:1] BA;		// combined with BAE to make the full, 22-bit bus address
   wire [21:0] BAR = { BAE, BA, 1'b0}; // the full Address Register, low bit is always = 0

   localparam RPCA = 4'b1001;	// Cylinder Address
   reg [15:9]  ECA = 0;		// Extended Cylinder Address
   reg [8:0]   CA = 0;		// Cylinder Address

   localparam RPDA = 4'b1010;	// Disk Address
   reg [15:13] ETA = 0;		// Extended Track Address
   reg [12:8]  TA = 0;		// Track Address
   reg [3:0]   CUR_SA = 0;	// Current Sector 7..4]
   reg [3:0]   SA = 0;		// Sector Address [3..0]

   localparam RPM1 = 4'b1011;	// Maintenance 1 (unused)
   localparam RPM2 = 4'b1100;	// Maintenance 2 (unused)
   localparam RPM3 = 4'b1101;	// Maintenance 3 (unused)

   localparam SUCA = 4'b1110;	// Selected Unit Cylinder Address
   wire [15:0] SU_CA;		// If not extended, then only use [8..0]

   localparam SILO = 4'b1111;	// Silo Memory Buffer (not implemented)
     
   // Function Commands
   localparam
     RESET = 3'b000,
     WRITE = 3'b001,
     READ = 3'b010,
     WRITE_CHECK = 3'b011,
     SEEK = 3'b100,
     WRITE_NO_SEEK = 3'b101,
     HOME_SEEK = 3'b110,
     READ_NO_SEEK = 3'b111;

   // Disk size computations
   localparam 
     RP02_CYLINDERS = 203,
     RP03_CYLINDERS = 406,
     TRACKS = 20,
     SECTORS = 10;
   // Convert cylinder/track/sector into linear block address
   wire [16:0] rp_lba = { 13'b0, SA } + (SECTORS * ({ 12'b0, TA } + (TRACKS * { 8'b0, CA })));
   wire [23:0] ext_lba = { ECA, CA, ETA, TA, SA }; // extended packs are easy
   // Calculate the next disk address
   reg [3:0]   next_sector;
   reg [7:0]   next_track;
   reg [15:0]   next_cylinder;
   always @(*) begin
      if ((SA + 1) == SECTORS) begin
	 next_sector = 0;
	 if ((track + 1) == TRACKS) begin
	    next_track = 0;
	    next_cylinder = { ECA, CA } + 1; // overrun is caught below
	 end else begin
	    next_track = TA + 1;
	    next_cylinder = { ECA, CA };
	 end
      end else begin
	 next_sector = SA + 1;
	 next_track = TA;
	 next_cylinder = { ECA, CA };
      end
   end // always @ begin
   // Detect Overrun - this is just for legacy packs, not extended packs
   wire overrun_sectors = (SA >= SECTORS);
   wire overrun_tracks = (TA >= TRACKS);
   wire overrun_cylinders = (CA >= (RP03 ? RP03_CYLINDERS : RP03_CYLINDERS));
   wire overrun = overrun_sectors || overrun_tracks || overrun_cylinders;

   
   // simulate the sectors flying by on the disk.  we only have a single sector counter,
   // not one for each disk.  that seems sufficient.
   reg [5:0] clk_div = 0;	// divide down the 20MHz clock to get a sector clock
   always @(posedge clk)
      { CUR_SA, clk_div } <= { CUR_SA, clk_div } + 1;


   assign SU_WP = sd_write_protect[DRV_SEL];
   assign SU_OL = sd_loaded[DRV_SEL];
   assign SU_RDY = sd_loaded[DRV_SEL] & sd_ready; // check this !!!

   // Each disk drive maintains its own cylinder address
   reg [15:0] DRV_CA [7:0] = 0;
   assign SU_CA = DRV_CA[DRV_SEL];
   
   
   //
   // BUS Interface
   //

   assign addr_match = (enabled &&			    // device enabled
		        (b_iopag == 1) &&		    // I/O page
		        (b_addr[0] != 1) &&		    // not an odd address
		        (b_addr[12:5] == addr_base[12:5])); // my address block
   
   // read registers -- data line mux
   always @(*) begin
      if (assert_vector)
	b_wdata = { 7'b0, int_vec };
      else 
	case (b_addr[4:1])
	  RPPS: b_rdata = extended ? PS : 0;
	  RPXA: b_rdata = q22 ? { 10'b0, BAE } : 0;
	  RPDS: b_rdata = { SU_RDY, SU_OL, SU_RP03, HNF, SU_SI, SU_SU, SU_FU, SU_WP, ATTN };
	  RPER: b_rdata = { WPV, FUV, NXC, NXT, NXS, PROG, FMTE, MODE, LPE, WPE,
	    CSME, TIMEE, WCE, NXM, EOP, DSK_ERR };
	  RPCS: b_rdata = { ERR, HE, AIE, MODE, HDR, DVR_SEL, RDY, IDE, MEX, COM, 1'b0 };
	  RPWC: b_rdata = WC;
	  RPBA: b_rdata = { BA, 1'b0 };
	  RPCA: b_rdata = extended ? { ECA, CA } : { 7'b0, CA };
	  RPDA: b_rdata = extended ? { ETA, TA, CUR_SA, SA } : { 3'b0, TA, CUR_SA, SA };
	  SUCA: b_rdata = SU_CA;
	  default: b_rdata = 0;
	endcase // case (b_addr[4:1])
   end



   
   //
   // write registers and execute commands
   //

   // send some signals out to the storage device
   reg sd_write_zero;		// zero out the data when filling out a partial block
   assign sd_write_data = sd_write_zero ? 0 : RDL; // send DMA data to the write FIFO
   assign sd_dev_sel = DRV_SEL;	// send drive select to the storage device
   
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
	 { BAE, BA } <= { BAE, BA} + 1;
	 { WC_zero, WC} <= WC + 1;
      end
   endtask

   task sector_next;
      begin
	 { { ECA, CA }, SUR, SA } <= { next_cylinder, next_surface, next_sector };
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
      // these share an always block with the state machine because both write to the RP11
      // visible registers.  However, since the state machine only ever modifies these registers
      // as a result of a DMA operation completing, the two cannot conflict since the Bus can
      // only be doing one or the other at a given time.
      if (addr_match && write_pulse) begin
	 case (b_addr[4:1])
	   RPXA: if (q22) BAE <= b_wdata[5:0];
	   RPDS: ATTN <= ATTN & ~b_wdata[7:0]; // a 1 clears the associated ATTN bit
	   RPCS: { AIE, DRV_SEL, IDE, BAE[1:0], COM, GO }
	     <= { b_wdata[13], b_wdata[10:8], b_wdata[6], b_wdata[5:4], b_wdata[3:1], b_wdata[0] };
	   RPWC: WC <= b_wdata;
	   RPBA: BA <= b_wdata[15:1];
	   RPCA: { ECA, CA } <= extended ? b_wdata : { 7'b0, b_wdata[8:0] };
	   RPDA:
	     begin
		{ ETA, TA } <= extended ? b_wdata[15:8] : { 3'b0, b_wdata[12:8] };
		SA <= b_wdata[3:0];
	     end

	   default: ;		// silently ignore writes to other registers
	 endcase // case (b_addr[4:1])
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
	       { DR_SEL, ECA, CA, SUR, SA } <= 0;
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
	       RDY <= 1;	// the RP11 is ready for commands

	       // initiate a command
	       if (GO) begin
		  GO <= 0;
		  WC_zero <= 0;

		  case (FUNC)
		    RESET:
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
		    WRITE_NO_SEEK:	set_state(CMD_DONE);
		    HOME_SEEK:		set_state(CMD_DONE);
		    READ_NO_SEEK:	set_state(CMD_DONE);

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
   

   //
   // Indicator Panel - This is our combined RK/RP indicator panel design, not the original DEC
   // layout for the RP11.
   wire [7:0] drive_ready;
   wire [7:0] drive_read;
   wire [7:0] drive_write;

   genvar     i;
   for (i = 0; i < 8; i=i+1) begin
      assign drive_ready[i] = (DRV_SEL == i) ? sd_ready & sd_loaded[i] : sd_loaded[i];
      assign drive_read[i] = (DRV_SEL == i) ? dma_write : 0;
      assign drive_write[i] = (DRV_SEL == i) ? dma_read : 0;
   end

   reg int7, int6, int5, int4;
   always @(*) begin
      int7 <= 0;
      int6 <= 0;
      int5 <= 0;
      int4 <= 0;
      case (int_pri)
	INTP_7: int7 <= interrupt_request;
	INTP_6: int6 <= interrupt_request;
	INTP_5: int5 <= interrupt_request;
	INTP_4: int4 <= interrupt_request;
      endcase // case (int_pri)
   end // always @ (*)
   

   indicator
     rp11_ip(ip_clk, ip_latch, ip_out,
	     { ERROR, HE, SCP, INH_BA, SSE, RDY, IDE, 1'b0, FUNC, 1'b0, GO, 1'b0, BAR },
	     { DRE, OVR, WLO, NXM, NXD, NXC, NXT, NXS, CSE, WCE, 1'b0, int7, int6, int5, int4,
	       1'b0, dma_read_req, dma_write_req, 1'b0, 1'b0, WC_display },
	     { 2'b10, UNIT, extended, DRV_SEL, ECA, CA, ETA, TA, SA },
	     { q22, ~q22, 2'b0,
	      drive_ready[7], write_protect_flag[7], drive_read[7], drive_write[7],
	      drive_ready[6], write_protect_flag[6], drive_read[6], drive_write[6],
	      drive_ready[5], write_protect_flag[5], drive_read[5], drive_write[5],
	      drive_ready[4], write_protect_flag[4], drive_read[4], drive_write[4],
	      drive_ready[3], write_protect_flag[3], drive_read[3], drive_write[3],
	      drive_ready[2], write_protect_flag[2], drive_read[2], drive_write[2],
	      drive_ready[1], write_protect_flag[1], drive_read[1], drive_write[1],
	      drive_ready[0], write_protect_flag[0], drive_read[0], drive_write[0] }
	     );

endmodule // rp11d
