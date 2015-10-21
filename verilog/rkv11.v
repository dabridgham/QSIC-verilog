//	-*- mode: Verilog; fill-column: 96 -*-
//
// An implementation of the RKV11 (extended for Q22).
//
// Copyright 2015 Noel Chiappa and David Bridgham

`include "qsic.vh"

module rkv11
  (
   // The QBUS
   output 	DALbe_L, // enable BDAL output onto the bus (active low)
   output 	DALtx, // enable BDAL output through level-shifter
   output 	DALst, // strobe data output to BDAL
   inout [21:0] ZDAL,
   inout 	ZBS7,
   inout 	ZWTBT,
   input 	RSYNC,
   input 	RDIN,
   input 	RDOUT,
   input 	RINIT,
   output 	TRPLY,


   // The internal microcontroller bus
   input [15:0] uADDR,
   inout [15:0] uDATA,
   input 	uWRITE,
   input 	uCLK,
   output 	uWAIT, // wired-OR
   output [7:0] uINTERRUPT
   );

   //
   // Connect up to the uC bus
   //

   wire [12:0] addr_base;
   wire [8:0]  int_vec;
   wire [1:0]  int_priority;
   wire [1:0]  mode;
   wire [7:0]  loaded;		// a "disk pack" is loaded and working
   wire [7:0]  write_protect;	// the disk is write protected
   reg [2:0]   ucmd;
   reg 	       uint_req;

   disk_uc #(.uDEV(`uDEV_RK),
	     .DEFAULT_ADDR(13'o14_400),
	     .DEFAULT_INT_VEC(9'o220),
	     .DEFAULT_INT_PRI(`INTP_5))
   uc(.init(init), .qclk(qclk),
      .uADDR(uADDR), .uDATA(uDATA), .uWRITE(uWRITE), .uCLK(uCLK), .uWAIT(uWAIT),
      .uINTERRUPT(uINTERRUPT),
      .io_addr_base(addr_base), .int_vec(int_vec), .int_priority(int_priority),
      .mode(mode), .loaded(loaded), .write_protect(write_protect),
      .cmd(ucmd), .drive_select(DR_SEL), .lba({ 19'b0, lba }), .interrupt(uint_req) );
	      

   //
   // QBUS Interface
   //

   wire [2:0]  reg_addr;
   wire        addr_mine, write_cycle, read_cycle;

   qreg #(.RA_BITS(3))
   qreg(.io_addr_base(addr_base), .int_vector(int_vec), .int_priority(int_priority),
	.clk(qclk), 
    	.DALbe_L(DALbe_L), .DALtx(DALtx), .DALst(DALst), .ZDAL(ZDAL), .ZBS7(ZBS7), .ZWTBT(ZWTBT),
	.RSYNC(RSYNC), .RDIN(RDIN), .RDOUT(RDOUT), .TRPLY(TRPLY), 
	.reg_addr(reg_addr), .addr_mine(addr_mine), .write_cycle(write_cycle), .read_cycle(read_cycle));
   
   // All the bits in the various device registers
   // RKDS - Drive Status
   reg [2:0]   ID;		// Drive ID [15..13]
   reg 	       DPL;		// Drive Power Low [12]
   wire        RK05 = 1;	// RK05 [11]
   reg 	       DRU;		// Drive Unsafe [10]
   reg 	       SIN;		// Seek Incomplete [9]
   reg 	       SOK;		// Sector Counter OK [8]
   reg 	       DRY;		// Drive Ready [7]
   reg 	       RWS_RDY;		// Read/Write/Seek Ready [6]
   reg 	       WPS;		// Write Protect Status [5]
   wire        SCeqSA = (SC == SA); // Sector Counter = Sector Address [4]
   reg [3:0]   SC;		    // Sector Counter [3..0]
   // RKER - Error
   reg 	       DRE;		// Drive Error [15]
   reg 	       OVR;		// Overrun [14]
   reg 	       WLO;		// Write Lock Out Violation [13]
   reg 	       SKE;		// Seek Error [12]
   reg 	       PGE;		// Programming Error [11]
   reg 	       NXM;		// Non-Existent Memory [10]
   reg 	       DLT;		// Data Late [9]
   reg 	       TE;		// Timing Error [8]
   reg 	       NXD;		// Non-Existent Disk [7]
   reg 	       NXC;		// Non-Existent Cylinder [6]
   reg 	       NXS;		// Non-Existent Sector [5]
				// unused [4..2]
   reg 	       CSE;		// Checksum Error [1]
   reg 	       WCE;		// Write Check Error [0]
   // RKCS - Control Status
   wire        ERROR = HE | CSE | WCE; // Error [15]
   wire        HE = DRE | OVR | WLO | SKE | PGE | NXM | DLT | TE | NXD | NXC | NXS; // Hard Error [14]
   reg 	       SCP;		// Search Complete [13]
				// unused [12]
   reg 	       INH_BA;		// Inhibit Bus Address Increment [11]
   reg 	       FMT;		// Format [10]
				// unused [9]
   reg 	       SSE;		// Stop on Soft Error [8]
   reg 	       RDY;		// Control Ready [7]
   reg 	       IDE;		// Interrupt on Done Enable [6]
				// Memory Extension [5..4] (see BAE[1:0])
   reg [2:0]   FUNC;		// Function [3..1]
   reg 	       GO;		// Go [0]
   // RKWC - Word Count
   reg [15:0]  WC;
   // RKBA - Current Bus Address
   reg [15:0]  BA;
   // RKDA - Disk Address
   reg [2:0]   DR_SEL;	       // Drive Select
   reg [7:0]   CYL_ADD;	       // Cylinder Address (0..202)
   reg 	       SUR;	       // Surface (0 = upper)
   reg [3:0]   SA;	       // Sector Address (0..11)
   // RKXA - Extended Bus Address (not in RK11, added for Q22)
   reg [5:0]   BAE;		// Bus Address Extension
   // RKDB - Data Buffer
   reg [15:0]  DB;
   
   // RK11 Registers
   localparam
     RKDS = 4'b0000,		// Drive Status
     RKER = 4'b0010,		// Error
     RKCS = 4'b0100,		// Control Status
     RKWC = 4'b0110,		// Word Count
     RKBA = 4'b1000,		// Current Bus Address
     RKDA = 4'b1010,		// Disk Address
     RKXA = 4'b1100,		// Extended Bus Address
     RKDB = 4'b1110;		// Data Buffer

   // read registers
   reg [15:0] 	     data_out;
   assign ZDAL = { 6'bZ, data_out };
   always @(*) begin
      data_out = 16'bZ;

      if (addr_mine && read_cycle)
	// gate the data out as soon as we match in case it's a read
	case (reg_addr)
	  RKDS:
	    data_out = { ID, DPL, RK05, DRU, SIN, SOK, DRY, RWS_RDY, WPS, SCeqSA, SC };
	  RKER:
	    data_out = { DRE, OVR, WLO, SKE, PGE, NXM, DLT, TE, NXD, NXC, NXS, 3'b000, CSE, WCE };
	  RKCS:
	    data_out = { ERROR, HE, SCP, 1'b0, INH_BA, 1'b0, FMT, SSE, RDY, IDE, BAE[1:0], FUNC, GO };
	  RKWC:
	    data_out = WC;
	  RKBA:
	    data_out = BA;
	  RKDA:
	    data_out = { DR_SEL, CYL_ADD, SUR, SA };
	  RKXA:
	    if (mode == `MODE_Q22)
	      // this register didn't exist on the RKV11 but the RKV11 didn't do Q22
	      // either so if someone turns on Q22 mode for this device, they need to
	      // update their device driver anyway.
	      data_out = { 12'b0, BAE };
	    else
	      // this was a maintenance register on the RK11-C.  that's not emulated.
	      data_out = 0;
	  RKDB:
	    data_out = DB;
	endcase
   end

   localparam 
     SECTORS = 12,
     SURFACES = 2,
     CYLINDERS = 203;
   // Convert cylinder/surface/sector into linear block address
   wire [12:0] 	     lba = SA + (SECTORS * (SUR + (SURFACES * CYL_ADD)));
   // Calculate the next disk address
   wire [12:0] 	     next = { next_cylinder, next_surface, next_sector };
   reg [3:0] 	     next_sector;
   reg 		     next_surface;
   reg [7:0] 	     next_cylinder;
   always @(*) begin
      if (SA + 1 == SECTORS) begin
	 next_sector <= 0;
	 if (SUR == 1) begin
	    next_surface <= 0;
	    next_cylinder <= CYL_ADD + 1; // overrun is caught elsewhere
	 end else begin
	    next_surface <= 1;
	    next_cylinder <= CYL_ADD;
	 end
      end else
	next_sector <= SA + 1;
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
   wire init = RINIT || (GO && (FUNC == CONTROL_RESET));

   // simulate the sectors flying by on the disk.  we only have a single sector counter,
   // not one for each disk.  it seems sufficient.
   reg [5:0] clk_div;		// divide down the QBUS clock (20MHz) to get a sector clock
   always @(posedge qclk) begin
      if (init) begin
	 SC <= 0;
	 clk_div <= 0;
      end else begin
	 clk_div <= clk_div + 1;
	 if (clk_div == 0)
	   SC <= SC + 1;
      end
   end

   // either the device or commands from the QBUS may write protect a disk
   wire [7:0]  write_protect_flag = write_protect | protect;
   reg [7:0]   protect = 0;

   always @(posedge qclk) begin
      // write data to a register
      if (addr_mine && write_cycle) begin
	 case (reg_addr)
	   RKCS:
	     { INH_BA, FMT, SSE, IDE, BAE[1:0], FUNC, GO } 
	       <= { ZDAL[11], ZDAL[10], ZDAL[8], ZDAL[6], ZDAL[5:4], ZDAL[3:1], ZDAL[0] };
	   RKWC:
	     WC <= ZDAL[15:0];
	   RKBA:
	     BA <= ZDAL[15:0];
	   RKDA:
	     { DR_SEL, CYL_ADD, SUR, SA } <= ZDAL[15:0];
	   RKXA:		// RKXA - Extended Address
	     if (mode == `MODE_Q22)
	       BAE <= ZDAL[5:0];
	 endcase // case (iADDR[3:0])
      end

      else if (init) begin
	 { ID, DPL, DRU, SIN, SOK, DRY, RWS_RDY, WPS } <= 0;
	 { DRE, OVR, WLO, SKE, PGE, NXM, DLT, TE, NXD, NXC, NXS, CSE, WCE } <= 0;
	 { SCP, INH_BA, FMT, SSE, RDY, IDE, FUNC, GO } <= 0;
	 WC <= 0;
	 BA <= 0;
	 { DR_SEL, CYL_ADD, SUR, SA } <= 0;
	 BAE <= 0;
	 DB <= 0;
	 protect <= 0;
      end

      // initiate a command
      else if (GO) begin
	 GO <= 0;
	 case (FUNC)
//	   CONTROL_RESET: handled by the init signal
	   WRITE: 
	     begin
		ucmd <= `CMD_WRITE;
		uint_req <= 1;
	     end
	   READ:
	     begin
		ucmd <= `CMD_READ;
		uint_req <= 1;
	     end
`ifdef NOTDEF
	   // gotta figure these out !!!
	   WRITE_CHECK:
	     SEEK:
	     READ_CHECK:
	       DRIVE_RESET:
`endif
	   WRITE_LOCK:
	     protect[DR_SEL] <= 1;
	 endcase // case (FUNC)
      end
   end

endmodule // rkv11
