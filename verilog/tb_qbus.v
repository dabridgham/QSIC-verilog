//	-*- mode: Verilog; fill-column: 96 -*-
//
// Testbench for the low-level QBUS interface
//
// Copyright 2015 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

module tb_qbus();
   
   // The raw QBUS signals, they're all open-collector
   wand [21:0] BDAL;
   wand        BBS7, BWTBT, BSYNC, BDIN, BDOUT, BRPLY, BREF, BIRQ4, BIRQ5, BIRQ6, BIRQ7,
	       BDMR, BSACK, BINIT, BIAKO, BDMGO, BIAKI, BDMGI, BDCOK, BPOK, BEVNT, BHALT;

   // easier to watch in GTKWave
   wire [15:0] BDAL16 = BDAL[15:0];
   
   // These registers are so the TB can drive the QBUS lines
   reg [21:0]  tbDAL;
   reg 	       tbBS7, tbWTBT, tbSYNC, tbDIN, tbDOUT, tbRPLY, tbREF, tbIRQ4, tbIRQ5, tbIRQ6, tbIRQ7,
	       tbDMR, tbSACK, tbINIT, tbIAKO, tbDMGO, tbIAKI, tbDMGI, tbDCOK, tbPOK, tbEVNT, tbHALT;
   assign
     { BDAL, BBS7, BWTBT, BSYNC } = { ~tbDAL, ~tbBS7, ~tbWTBT, ~tbSYNC },
     { BDIN, BDOUT, BRPLY, BREF } = { ~tbDIN, ~tbDOUT, ~tbRPLY, ~tbREF },
     { BIRQ4, BIRQ5, BIRQ6, BIRQ7 } = { ~tbIRQ4, ~tbIRQ5, ~tbIRQ6, ~tbIRQ7 },
     { BDMR, BSACK, BINIT, BIAKO, BDMGO } = { ~tbDMR, ~tbSACK, ~tbINIT, ~tbIAKO, ~tbDMGO },
     { BIAKI, BDMGI, BDCOK, BPOK, BEVNT, BHALT } = { ~tbIAKI, ~tbDMGI, ~tbDCOK, ~tbPOK, ~tbEVNT, ~tbHALT };

   // The QBUS signals as seen by the FPGA
   wand        DALbe_L;		// Enable trnasmitting on BDAL
   wor 	       DALtx;		// Direction control from the FPGA for the BDAL lines
   wor 	       DALst;		// Strobe data into the output latches in the Am2908s
   tri [21:0]  ZDAL;		// bidirectional to save FPGA pins
   tri 	       ZBS7, ZWTBT;
   wire        RSYNC, RDIN, RDOUT, RRPLY, RREF, RIRQ4, RIRQ5, RIRQ6, RIRQ7,
    	       RDMR, RSACK,
    	       RINIT, RIAKI, RDMGI, RDCOK, RPOK,
    	       REVNT, RHALT;
   wor 	       TSYNC, TDIN, TDOUT, TRPLY, TREF, TIRQ4, TIRQ5, TIRQ6, TIRQ7, TDMR, TSACK,
	       TINIT,
    	       TIAKO, TDMGO;
   // need to have a null driver for each of these 'wor' lines
   assign DALbe_L = 1;
   assign DALtx= 0;
   assign DALst = 0;
   assign { TSYNC, TDIN, TDOUT, TRPLY, TREF, TIRQ4, TIRQ5, TIRQ6, TIRQ7, 
	    TDMR, TSACK, TINIT, TIAKO, TDMGO } = 0;

   integer     count = 0;	// counts up the tests we run.  it's printed out in error
				// messages and we can look at the signal trace to see
				// where the problem is.

   reg 	       qclk = 0;
   always @(*)
     #25 qclk <= ~qclk;		// 20 MHz clock (50ns cycle time)

   // Connect to the QBUS through driver chips and level converters
   qdrv qbus(BDAL, BBS7, BWTBT, BSYNC, BDIN, BDOUT, BRPLY, BREF, BIRQ4, BIRQ5, BIRQ6, BIRQ7,
	     BDMR, BSACK, BINIT, BIAKO, BDMGO, BIAKI, BDMGI, BDCOK, BPOK,
	     DALbe_L, DALtx, DALst, ZDAL, ZBS7, ZWTBT, 
	     RSYNC, RDIN, RDOUT, RRPLY, RREF, RIRQ4, RIRQ5, RIRQ6, RIRQ7,
    	     RDMR, RINIT, RIAKI, RDMGI, RDCOK, RPOK,
	     TSYNC, TDIN, TDOUT, TRPLY, TREF, TIRQ4, TIRQ5, TIRQ6, TIRQ7, 
	     TDMR, TSACK, TIAKO, TDMGO);

   // Connect the PMo to the QBUS
   wire        led_d8, led_d9, led_d10, led_d11, led_c12, led_d12, tp_b30;
   wire        ip_clk, ip_latch, ip_data;
   pmo pmo(qclk, led_d8, led_d9, led_c12, tp_b30,
	   ip_clk, ip_latch, ip_data,
	   DALbe_L, DALtx, DALst, ZDAL, ZBS7, ZWTBT,
	   RSYNC, RDIN, RDOUT, RRPLY, RREF, RIRQ4, RIRQ5, RIRQ6, RIRQ7,
	   RDMR, RSACK, RINIT, RIAKI, RDMGI, RDCOK, RPOK,
	   TSYNC, TDIN, TDOUT, TRPLY, TREF, TIRQ4, TIRQ5, TIRQ6, TIRQ7,
	   TDMR, TSACK, TIAKO, TDMGO);
   

`ifdef NOTDEF
   // Get some memory on the bus
   sim_mem mem(DALtx, DAL, TRPLY, RDIN, RDOUT, RSYNC, RBS7);


   // The internal I/O bus
   wire [12:0] iADDR;
   wire        iBS7, iWRITE;
   wire [15:0] iWDATA;
   tri [15:0]  iRDATA;
   wor 	       iREAD_MATCH, iWRITE_MATCH;
   assign { iREAD_MATCH, iWRITE_MATCH } = 0;
   
   // Connect the QBUS to the internal I/O bus
   qsync qsync(qclk, DALtx, DAL, RBS7, RSYNC, RDIN, RDOUT, TRPLY,
	       iADDR, iBS7, iREAD_MATCH, iWRITE_MATCH, iWDATA, iWRITE, iRDATA);

   // a couple registers to poke at
//   areg_block #(.addr('o17774), .count(1)) reg1(DALtx, DAL, TRPLY, RDIN, RDOUT, RSYNC, RBS7);
//   areg_block #(.addr('o17772), .count(1)) reg2(DALtx, DAL, TRPLY, RDIN, RDOUT, RSYNC, RBS7);

   reg [12:0]  reg1_addr = 'o440;
   reg [12:0]  reg2_addr = 'o560;
   sreg_block reg1(reg1_addr, qclk, iADDR, iBS7, iREAD_MATCH, iWRITE_MATCH, iWDATA, iWRITE, iRDATA);
   sreg_block reg2(reg2_addr, qclk, iADDR, iBS7, iREAD_MATCH, iWRITE_MATCH, iWDATA, iWRITE, iRDATA);
`endif

   initial begin
      $dumpfile("tb_qbus.lxt");
      $dumpvars(0, tb_qbus);

      // bus idle
      #0 tbDAL = 0;
      { tbBS7, tbWTBT, tbSYNC, tbDIN, tbDOUT, tbRPLY, tbREF, tbIRQ4, tbIRQ5, tbIRQ6, tbIRQ7,
	tbDMR, tbSACK, tbINIT, tbIAKO, tbDMGO, tbIAKI, tbDMGI, tbDCOK, tbPOK, tbEVNT, tbHALT } = 0;

      #100 tbINIT = 1;
      #200 tbINIT = 0;
      

      // read from 777570
      #200 count = count + 1;
      tbDAL = 'o777570; tbBS7 = 1;
      #150 tbSYNC = 1;
      #100 tbDAL = 0; tbBS7 = 0; tbDIN = 1;
      #600 if (!RRPLY)
	$display("Error NXM (%1d)", count);
      else if (~BDAL[15:0] != 16'o177777)
	$display("Error (%1d): %o", count, ~BDAL);
      tbDIN = 0;
      #100 tbSYNC = 0;

`ifdef NOTDEF
      // read from 440
      #200 count = count + 1;
      tbDAL = 'o440;  tbBS7 = 1;
      #150 tbSYNC = 1;
      #100 tbDAL = 0; tbBS7 = 0; tbDIN = 1;
      #150 if (!RRPLY)
	$display("Error NXM (%1d)", count);
      else if (~BDAL != 22'o123456)
	$display("Error (%1d): %o", count, ~BDAL);
      tbDIN = 0; tbSYNC = 0;

      // read from 400 (should be NXM).  This is not a proper NXM check.  I should be
      // waiting for RPLY and timing out.  And I shouldn't read the data for 150ns after
      // RPLY is asserted either.  The DMA engine will have to do this right.
      #200 count = count + 1;
      tbDAL = 'o400;  tbBS7 = 1;
      #150 tbSYNC = 1;
      #100 tbDAL = 0; tbBS7 = 0; tbDIN = 1;
      #150 if (RRPLY)
	$display("Error (%1d): Should have been NXM but wasn't", count);
      tbDIN = 0; tbSYNC = 0;

      // read from 440 without BS7 (should be NXM).  This is not a proper NXM check.  I should
      // be waiting for RPLY and timing out.  And I shouldn't read the data for 150ns after RPLY
      // is asserted either.  The DMA engine will have to do this right.
      #200 count = count + 1;
      tbDAL = 'o440;  tbBS7 = 0;
      #150 tbSYNC = 1;
      #100 tbDAL = 0; tbBS7 = 0; tbDIN = 1;
      #150 if (RRPLY)
	$display("Error (%1d): Should have been NXM but wasn't: %o", count, ~BDAL);
      tbDIN = 0; tbSYNC = 0;
      
      // write to 440
      #200 count = count + 1;
      tbDAL = 'o440; tbBS7 = 1; tbWTBT = 1; 
      #150 tbSYNC = 1;
      #100 tbDAL = 'o054321; tbBS7 = 0; tbWTBT = 0;
      #100 tbDOUT = 1;
      #150 tbDOUT = 0;
      #100 tbDAL = 0; tbSYNC = 0;

      // read new value back from 440
      #200 count = count + 1;
      tbDAL = 'o440; tbBS7 = 1; 
      #150 tbSYNC = 1;
      #100 tbDAL = 0; tbBS7 = 0;
      #100 tbDIN = 1;
      #150 if (~BDAL != 22'o054321)
	$display("Error (%1d): %o", count, ~BDAL);
      tbDIN = 0; tbSYNC = 0;

      // read from 560
      #200 count = count + 1;
      tbDAL = 'o560; tbBS7 = 1;
      #150 tbSYNC = 1;
      #100 tbDAL = 0; tbBS7 = 0;
      #100 tbDIN = 1;
      #150 if (~BDAL != 22'o123456)
	$display("Error (%1d): %o", count, ~BDAL);
      tbDIN = 0; tbSYNC = 0;

      // read-modify-write (DATAIO) to 560
      #200 count = count + 1;
      tbDAL = 'o560; tbBS7 = 1;
      #150 tbSYNC = 1;
      #100 tbDAL = 0; tbBS7 = 0;
      #100 tbDIN = 1;
      #150 if (~BDAL != 22'o123456)
	$display("Error (%1d): %o", count, ~BDAL);
      tbDIN = 0;
      // finished the read, start writing.  supposed to wait at least 200ns after negation
      // of RPLY before asserting DOUT but must assert DAL 100ns before DOUT.
      #100 tbDAL = 'o54545;
      #100 tbDOUT = 1;
      #150 tbDOUT = 0; 
      #100 tbDAL = 0; tbSYNC = 0;

      // check that write worked
      #200 count = count + 1;
      tbDAL = 'o560; tbBS7 = 1;
      #150 tbSYNC = 1;
      #100 tbDAL = 0; tbBS7 = 0;
      #100 tbDIN = 1;
      #150 if (~BDAL != 22'o54545)
	$display("Error (%1d): %o", count, ~BDAL);
      tbDIN = 0; tbSYNC = 0;
`endif

      #200 $finish_and_return(0);
   end


endmodule // tb_qbus

module clk_wiz_0
  (input clk48,
   output clk20,
   input  reset,
   output locked);

   // just reflect the input to the output and set the input to be 20MHz in the testbench
   assign clk20 = clk48;
   assign locked = 1;

endmodule // clk_wiz_0
