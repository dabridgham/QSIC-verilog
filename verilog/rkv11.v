//	-*- mode: Verilog; fill-column: 96 -*-
//
// An implementation of the RKV11 (extended for Q22).
//
// Copyright 2015, 2016 Noel Chiappa and David Bridgham

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

   // The internal microcontroller bus
   input [15:0]      uADDR,
   inout [15:0]      uDATA,
   input 	     uWRITE,
   input 	     uCLK,
   output 	     uWAIT, // wired-OR
   output [7:0]      uINTERRUPT
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

`ifdef NOTDEF
   disk_uc #(.uDEV(`uDEV_RK),
	     .DEFAULT_ADDR(13'o17_400),
	     .DEFAULT_INT_VEC(9'o220),
	     .DEFAULT_INT_PRI(`INTP_5))
   uc(.init(init), .qclk(clk),
      .uADDR(uADDR), .uDATA(uDATA), .uWRITE(uWRITE), .uCLK(uCLK), .uWAIT(uWAIT),
      .uINTERRUPT(uINTERRUPT),
      .io_addr_base(addr_base), .int_vec(int_vec), .int_priority(int_priority),
      .mode(mode), .loaded(loaded), .write_protect(write_protect),
      .cmd(ucmd), .drive_select(DR_SEL), .lba({ 19'b0, lba }), .interrupt(uint_req) );
`else // !`ifdef NOTDEF
   assign addr_base = 13'o17_400;
   assign int_vec = 9'o220;
   assign int_priority = `INTP_5;
   assign mode = `MODE_Q22;
   assign loaded = 0;
   assign write_protect = 0;
`endif // !`ifdef NOTDEF
   
   // All the bits in the various device registers.  Device register addresses are shown as addr[3:1]

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
   reg [3:0] SC;		  // Sector Counter [3..0]

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
   reg [15:0] WC;

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
   reg [15:0] DB;		// this will probably be replaced by one end of a FIFO, but the
				// register is useful for now

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
      if (SA + 1 == SECTORS) begin
	 next_sector = 0;
	 if (SUR == 1) begin
	    next_surface = 0;
	    next_cylinder = CYL_ADD + 1; // overrun is caught elsewhere
	 end else begin
	    next_surface = 1;
	    next_cylinder = CYL_ADD;
	 end
      end else
	next_sector = SA + 1;
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
   always @(posedge clk) begin
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
   wire [7:0] write_protect_flag = write_protect | protect;
   reg [7:0]  protect = 0;


   // internal RAM disk (have to shrink the number of CYLINDERS depending on how much block RAM
   // is available inside the FPGA)
   localparam DISK_WORDS = 256 * SECTORS * SURFACES * CYLINDERS;
   reg [15:0] ram_disk[0:DISK_WORDS-1];	 // the RAM disk
   reg [7:0]  saddr;			 // word count within a sector
   wire [7:0] saddr_next;
   wire       saddr_carry;
   assign { saddr_carry, saddr_next } = saddr + 1;
   wire [20:0] rd_addr = { lba, saddr }; // index into the RAM disk

   
   //
   // QBUS Interface
   //

   assign addr_match = ((RBS7 == 1) &&			 // I/O page
			(RAL[0] != 1) &&		 // not an odd address
			(RAL[12:4] == addr_base[12:4])); // my address
   
   // data line mux
   always @(*) begin
      if (dma_bus_master) begin
	 TDL = ram_disk[rd_addr];

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
	       // this was a maintenance register on the RK11-C.  on the RK11-D it just
	       // returned 0.
	       TDL = interrupt_request; // testing !!!
	   RKDB:
	     TDL = DB;
	 endcase // case (RAL[3:0])
      end
   end

   // write registers and execute commands
   reg dma_read = 0,
       dma_write = 0;
   assign dma_read_req = dma_read & (WC != 0);
   assign dma_write_req = dma_write & (WC != 0);
   
   always @(posedge clk) begin
      interrupt_request <= 0;

      // write data to a register
      if (addr_match && write_pulse) begin
	 case (RAL[3:1])
	   RKCS:		// Control/Status
	     { INH_BA, FMT, SSE, IDE, RK_BAR[17:16], FUNC, GO } 
	       <= { RDL[11], RDL[10], RDL[8], RDL[6], RDL[5:4], RDL[3:1], RDL[0] };
	   RKWC:		// Word Count
	     WC <= RDL;
	   RKBA:		// Bus Address
	     RK_BAR[15:1] <= RDL[15:1];
	   RKDA:
	     { DR_SEL, CYL_ADD, SUR, SA } <= RDL;
	   RKXA:		// RKXA - Extended Address
	     if (mode == `MODE_Q22)
	       RK_BAR[21:16] <= RDL[5:0];
	   // the data buffer will likely be replaced by one end of a FIFO and then no longer be
	   // writable.  for now it's useful to be able to write values into it.  !!!
	   RKDB:		// Data Buffer
	     DB <= RDL;
	 endcase // case (RAL[3:0])
      end

      else if (init) begin
	 { ID, DPL, DRU, SIN, SOK, DRY, RWS_RDY, WPS } <= 0;
	 { DRE, OVR, WLO, SKE, PGE, NXM, DLT, TE, NXD, NXC, NXS, CSE, WCE } <= 0;
	 { SCP, INH_BA, FMT, SSE, RDY, IDE, FUNC, GO } <= 0;
	 WC <= 0;
	 RK_BAR <= 0;
	 { DR_SEL, CYL_ADD, SUR, SA } <= 0;
	 DB <= 0;
	 protect <= 0;
	 dma_write <= 0;
	 dma_read <= 0;
	 interrupt_request <= 0;
	 RDY <= 1;
      end

      // handle DMA cycles
      else if (dma_read || dma_write) begin
	 if (dma_complete) begin
	    if (dma_read)
	      ram_disk[rd_addr] <= RDL;
	    else if (dma_write)
	      DB <= ram_disk[rd_addr];
	    WC <= WC - 1;
	    if (!INH_BA)
	      RK_BAR <= RK_BAR + 1;
	    saddr <= saddr_next;
	    if (saddr_carry)
	      { CYL_ADD, SUR, SA } <= { next_cylinder, next_surface, next_sector };
	 end

	 if ((WC == 0) || dma_nxm) begin
	    RDY <= 1;
	    dma_read <= 0;
	    dma_write <= 0;
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
		ucmd <= `CMD_WRITE;
		uint_req <= 1;
		dma_read <= 1;
		saddr <= 0;
		RDY <= 0;
	     end
	   READ:
	     begin
		ucmd <= `CMD_READ;
		uint_req <= 1;
		dma_write <= 1;
		saddr <= 0;
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
