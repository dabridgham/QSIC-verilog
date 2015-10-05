//	-*- mode: Verilog; fill-column: 96 -*-
//
// Testbench for the bus mastering logic
//
// Copyright 2015 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

`include "qsic.vh"

module tb_dma();
   
   // The raw QBUS signals, they're all open-collector
   wand [21:0] BDAL;
   wand        BBS7, BWTBT, BSYNC, BDIN, BDOUT, BRPLY, BREF, BIRQ4, BIRQ5, BIRQ6, BIRQ7,
	       BDMR, BSACK, BINIT, BIAKO, BDMGO, BIAKI, BDMGI, BDCOK, BPOK, BEVNT, BHALT;
   
   // These registers are so the TB can drive the QBUS lines
   reg [21:0]  tbDAL;
   reg 	       tbBS7, tbWTBT, tbSYNC, tbDIN, tbDOUT, tbRPLY, tbREF, tbIRQ4, tbIRQ5, tbIRQ6, tbIRQ7,
	       tbDMR, tbSACK, tbINIT, tbDCOK, tbPOK, tbEVNT, tbHALT;
   assign
     { BDAL, BBS7, BWTBT, BSYNC } = { ~tbDAL, ~tbBS7, ~tbWTBT, ~tbSYNC },
     { BDIN, BDOUT, BRPLY, BREF } = { ~tbDIN, ~tbDOUT, ~tbRPLY, ~tbREF },
     { BIRQ4, BIRQ5, BIRQ6, BIRQ7 } = { ~tbIRQ4, ~tbIRQ5, ~tbIRQ6, ~tbIRQ7 },
     { BDMR, BSACK, BINIT } = { ~tbDMR, ~tbSACK, ~tbINIT },
     { BDCOK, BPOK, BEVNT, BHALT } = { ~tbDCOK, ~tbPOK, ~tbEVNT, ~tbHALT },
     { BIAKO, BDMGO, BIAKI, BDMGI } = ~0;
   

   // The QBUS signals as seen by the FPGA
   wor 	       DALtx;		// Direction control from the FPGA for the BDAL lines
   tri [21:0]  DAL;		// bidirectional to save FPGA pins
   wire        RBS7, RWTBT, RSYNC, RDIN, RDOUT, RRPLY, RREF, RIRQ4, RIRQ5, RIRQ6, RIRQ7,
    	       RDMR, RSACK,
    	       RINIT, RIAKI, RDMGI, RDCOK, RPOK,
    	       REVNT, RHALT;
   wor 	       TBS7,
	       TWTBT, TSYNC, TDIN, TDOUT, TRPLY, TREF, TIRQ4, TIRQ5, TIRQ6, TIRQ7, TDMR, TSACK,
	       TINIT,
    	       TIAKO, TDMGO;
   // need to have a null driver for each of these 'wor' lines
   assign DALtx= 0;
   assign { TBS7, TWTBT, TSYNC, TDIN, TDOUT, TRPLY, TREF, TIRQ4, TIRQ5, TIRQ6, TIRQ7, 
	    TDMR, TSACK, TINIT, TIAKO, TDMGO } = 0;

   integer     count = 0;	// counts up the tests we run.  it's printed out in error
				// messages and we can look at the signal trace to see
				// where the problem is.

   // The internal I/O bus
   reg 	       qclk = 0;
   wire [12:0] iADDR;
   wire        iBS7, iWRITE;
   wire [15:0] iWDATA;
   tri [15:0]  iRDATA;
   wor 	       iREAD_MATCH, iWRITE_MATCH;
   assign { iREAD_MATCH, iWRITE_MATCH } = 0;

   reg 	       dma_read, dma_write;
   wire        assert_addr, assert_data, latch_read_data, nxm;

   // the bus arbitrator
   sim_proc processor(BDMR, BSACK, BSYNC, BRPLY, BDMGI);

   // Connect to the QBUS through driver chips and level converters
   qdrv qbus(BDAL, BBS7, BWTBT, BSYNC, BDIN, BDOUT, BRPLY, BREF, BIRQ4, BIRQ5, BIRQ6, BIRQ7,
	     BDMR, BSACK, BINIT, BIAKO, BDMGO, BIAKI, BDMGI, BDCOK, BPOK,
`ifdef CPU
	     BEVNT, BHALT,
`endif
	     DALtx, DAL,
	     RBS7, RWTBT, RSYNC, RDIN, RDOUT, RRPLY, RREF, RIRQ4, RIRQ5, RIRQ6, RIRQ7,
`ifdef CPU
    	     RDMR, RSACK,
`endif
    	     RINIT, RIAKI, RDMGI, RDCOK, RPOK,
`ifdef CPU
    	     REVNT, RHALT, TBS7,
`endif
	     TWTBT, TSYNC, TDIN, TDOUT, TRPLY, TREF, TIRQ4, TIRQ5, TIRQ6, TIRQ7, TDMR, TSACK,
`ifdef CPU
	     TINIT,
`endif
    	     TIAKO, TDMGO);


   // a bus master
   master master(qclk, RSYNC, RRPLY, RDMR, RSACK, RINIT, RDMGI, TSYNC, TDIN, TDOUT, TDMR, TSACK, TDMGO,
		 dma_read, dma_write, assert_addr, assert_data, latch_read_data, nxm);

   always @(*)
     #25 qclk <= ~qclk;		// 20 MHz clock (50ns cycle time)

   initial begin
      $dumpfile("tb_dma.lxt");
      $dumpvars(0, tb_dma);

      // bus idle
      #0 tbDAL = 0;
      { tbBS7, tbWTBT, tbSYNC, tbDIN, tbDOUT, tbRPLY, tbREF, tbIRQ4, tbIRQ5, tbIRQ6, tbIRQ7,
	tbDMR, tbSACK, tbINIT, tbDCOK, tbPOK, tbEVNT, tbHALT } = 0;
      
      dma_read <= 0;
      dma_write <= 0;

      #100 tbINIT <= 1;
      #100 tbINIT <= 0;
      
      #100 dma_read <= 1;
      while (BDIN)
	#1 tbRPLY <= 0;
      #20 tbRPLY <= 1;
      dma_read <= 0;
      while (!BDIN)
	#1 tbRPLY <= 1;
      #20 tbRPLY <= 0;

      #1500 $finish_and_return(0);
   end

endmodule // tb_dma

  
