//	-*- mode: Verilog; fill-column: 96 -*-
//
// QBUS Control - Handles the QBUS signals and divies them up between the DMA controller, the
// interrupt controller, and regular I/O registers or memory.
//
// This is for the PMo with the Ztex FPGA module where we use Am2908s for the Data/Address
// lines.  This saves us some FPGA pins but adds an extra layer of buffering that needs to be
// taken into account.  The ultimate plan for when we do our own custom QSIC board is to do away
// with that so this controller will be replaced then.
//
// Copyright 2020 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

`include "qsic.vh"

module qctl_2908
  (
   input	 clk, // 20 MHz clock
   input	 reset,

   // The QBUS signals as seen by the FPGA
   output	 DALbe_L, // Enable transmitting on BDAL (active low)
   output	 DALtx, // set level-shifters to output and disable input from Am2908s
   output	 DALst, // latch the BDAL output
   inout [21:0]	 ZDAL,
   inout	 ZBS7,
   inout	 ZWTBT,

   input	 RSYNC,
   input	 RDIN,
   input	 RDOUT,
   output	 TRPLY,

   // DMA Controller
   input	 dma_assert_dal,
   input [21:0]	 dma_dal,
   input	 dma_twtbt, 
   input	 dma_dalbe,
   input	 dma_daltx,
   input	 dma_dalst,

   // Interrupt Control
   input	 int_assert_vector,

   // Register Control
   output [21:0] reg_addr,
   output	 reg_bs7,
   output	 reg_read_cycle,
   input	 reg_addr_match,
   input [15:0]	 reg_rdata,
   output [15:0] reg_wdata,
   output	 reg_write
   );

   // Receive side of the tri-state signals
   wire [21:0] 	RDAL = ZDAL;	// Receive Data/Address Lines
   wire 	RBS7 = ZBS7;
   wire 	RWTBT = ZWTBT;

   // The direction of the bi-directional lines are controlled with DALtx
   reg [21:0] 	TDAL;		// Transmit Data/Address Lines
   assign ZDAL = DALtx ? TDAL : 22'bZ;
   assign ZBS7 = DALtx ? 0 : 1'bZ; // the DMA controller will need to hook in here !!!
   assign ZWTBT = DALtx ? dma_twtbt : 1'bZ;

   // Grab the addressing information when it comes by
   reg [21:0] 	addr_reg = 0;
   reg 		bs7_reg = 0;
   reg 		read_cycle = 0;
   always @(posedge RSYNC) begin
      addr_reg <= RDAL;
      bs7_reg <= RBS7;
      read_cycle <= ~RWTBT;
   end
   assign reg_addr = addr_reg; // pass the latched address on to the register controller
   assign reg_bs7 = bs7_reg;
   assign reg_read_cycle = read_cycle;
   assign reg_wdata = RDAL[15:0];
   
   // MUX for the data/address lines
   reg 	       addr_match = 0;
   reg 	       assert_vector = 0;
   always @(*) begin
      addr_match = 0;
      assert_vector = 0;
      TDAL = 0;
      
      if (dma_assert_dal)
	TDAL = dma_dal;
      else if (RSYNC)		// must be doing DATI or DATO cycle
	if (reg_addr_match) begin
	   addr_match = 1;
	   TDAL = { 6'b0, reg_rdata };
	end
      else if (int_assert_vector) begin // look for in interrupt vector read
	 assert_vector = 1;
	 TDAL = { 6'b0, reg_rdata };
      end
   end // always @ (*)
   

   //
   // Convert to synchronous to do register operations, extra bits here for sequencing the
   // Am2908s
   //
  
   // synchronize addr_match
   reg [1:0]   addr_match_ra = 0;
   always @(posedge clk) addr_match_ra <= { addr_match_ra[0], addr_match };
   wire        saddr_match = addr_match_ra[1];

   // synchronize assert_vector
   reg [3:0]   assert_vector_ra = 0;
   always @(posedge clk) assert_vector_ra <= { assert_vector_ra[2:0], assert_vector };
   wire        sassert_vector = assert_vector_ra[1];

   // synchronize RDOUT
   reg [2:0]   RDOUTra = 0;
   always @(posedge clk) RDOUTra <= { RDOUTra[1:0], RDOUT };
   wire        sRDOUT = RDOUTra[1];
   wire        sRDOUTpulse = RDOUTra[2:1] == 2'b01;
   assign reg_write = sRDOUTpulse;
   
   // synchronize RDIN
   reg [3:0]   RDINra = 0;
   always @(posedge clk) RDINra <= { RDINra[2:0], RDIN };
   wire        sRDIN = RDINra[1];
   wire        sRDINpulse = RDINra[2:1] == 2'b01;

   // implement reads or writes to registers
   reg 	       rwDALbe = 0;	// local control of these signals
   reg 	       rwDALst = 0;
   reg 	       rwDALtx = 0;
   reg 	       rwTRPLY = 0;
   always @(posedge clk) begin
      // bus is idle by default
      rwTRPLY <= 0;
      rwDALst <= 0;
      rwDALbe <= 0;
      rwDALtx <= 0;
      
      if (saddr_match) begin	// if we're in a slave cycle for me
	 if (sRDIN) begin
	    rwDALtx <= 1;

	    // this is running off RDINra[3] to delay it by an extra clock cycle to let the
	    // signals in the ribbon cable settle down a bit.  when we get rid of the ribbon
	    // cable, I'm assuming we can drop back to RDINra[2].
	    if (RDINra[3]) begin
	       // This may look like it's asserting TRPLY too soon but the QBUS spec allows up
	       // to 125ns from asserting TRPLY until the data on the bus must be valid, so we
	       // could probably assert it even earlier
	       rwTRPLY <= 1;
	       rwDALbe <= 1;
	       rwDALst <= 1;
	    end
	 end else if (sRDOUT) begin
	    rwTRPLY <= 1;
	 end
      end else if (sassert_vector) begin // if we're reading an interrupt vector
	 rwDALtx <= 1;			 // start the data towards the Am2908s

	 // like above with RDIN, wait until assert_vector_ra[3] to give time for the signals in
	 // the ribbon cable to settle down
	 if (assert_vector_ra[3]) begin
	    rwTRPLY <= 1;	// should be able to assert TRPLY sooner than this !!!
	    rwDALbe <= 1;
	    rwDALst <= 1;
	 end
      end
   end // always @ (posedge clk)

   // mix the control signals from the DMA controller and the register controller
   assign DALbe_L = ~(rwDALbe | dma_dalbe);
   assign DALst = rwDALst | dma_dalst;
   assign DALtx = rwDALtx | dma_assert_dal;
   assign TRPLY = rwTRPLY;

endmodule // qctl_2908

