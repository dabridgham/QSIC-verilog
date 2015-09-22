//	-*- mode: Verilog; fill-column: 96 -*-
//
// Testbench for the low-level QBUS interface
//
// Copyright 2015 Noel Chiappa and David Bridgham
//
// 2015-09-18 dab	initial version

`timescale 10 ns / 10 ns

module tb_qbus();
   
   // The raw QBUS signals, they're all open-collector
   wand [21:0] BDAL;
   wand        BDOUT, BRPLY, BDIN, BSYNC, BIRQ4, BIRQ5, BIRQ6, BIRQ7, BWTBT, BREF,
	       BINIT, BDCOK, BPOK, BBS7, BIAKI, BDMGI, BDMR, BSACK, BIAKO, BDMGO;
   
   // So the TB can drive the QBUS signals
   reg [21:0] tbDAL;
   reg 	      tbDOUT, tbRPLY, tbDIN, tbSYNC, tbIRQ4, tbIRQ5, tbIRQ6, tbIRQ7, tbWTBT, tbREF,
	      tbINIT, tbDCOK, tbPOK, tbBS7, tbIAKI, tbDMGI, tbDMR, tbSACK, tbIAKO, tbDMGO;
   assign
     { BDAL, BDOUT, BRPLY, BDIN, BSYNC } = { ~tbDAL, ~tbDOUT, ~tbRPLY, ~tbDIN, ~tbSYNC },
     { BIRQ4, BIRQ5, BIRQ6, BIRQ7, BWTBT } = { ~tbIRQ4, ~tbIRQ5, ~tbIRQ6, ~tbIRQ7, ~tbWTBT },
     { BREF, BINIT, BDCOK, BPOK, BBS7, BIAKI } = { ~tbREF, ~tbINIT, ~tbDCOK, ~tbPOK, ~tbBS7, ~tbIAKI },
     { BDMGI, BDMR, BSACK, BIAKO, BDMGO } = { ~tbDMGI, ~tbDMR, ~tbSACK, ~tbIAKO, ~tbDMGO };

   // The QBUS signals as seen by the FPGA
   wor 	      DALtx;		// Direction control from the FPGA for the BDAL lines
   tri [21:0] DAL;		// bidirectional to save FPGA pins
   wire       RDOUT, RRPLY, RDIN, RSYNC, RIRQ4, RIRQ5, RIRQ6, RIRQ7,
	      RWTBT, RREF, RINIT, RDCOK, RPOK, RBS7, RIAKI, RDMGI;
   wor 	      TDOUT, TRPLY, TDIN, TSYNC, TIRQ4, TIRQ5, TIRQ6, TIRQ7,
	      TWTBT, TREF, TDMR, TSACK, TIAKO, TDMGO;
   // need to have a null driver for each of these 'wor' lines
   assign { TDOUT, TRPLY, TDIN, TSYNC, TIRQ4, TIRQ5, TIRQ6, TIRQ7, TWTBT, TREF, TDMR, TSACK, TIAKO, TDMGO } = 0;

   integer count = 0;		// counts up the tests we run.  it's printed out in error
				// messages and we can look at the signal trace to see
				// where the problem is.

   // The QBUS Interface
   qintf qintf(BDAL, BDOUT, BRPLY, BDIN, BSYNC, BIRQ4, BIRQ5, BIRQ6, BIRQ7, BWTBT, BREF,
	       BINIT, BDCOK, BPOK, BBS7, BIAKI, BDMGI, BDMR, BSACK, BIAKO, BDMGO,
	       DALtx,
	       DAL, RDOUT, TDOUT, RRPLY, TRPLY, RDIN, TDIN, RSYNC, TSYNC, RIRQ4, TIRQ4,
	       RIRQ5, TIRQ5, RIRQ6, TIRQ6, RIRQ7, TIRQ7, RWTBT, TWTBT, RREF, TREF, RINIT, 
	       RDCOK, RPOK, RBS7, RIAKI, RDMGI, TDMR, TSACK, TIAKO, TDMGO);

   // a couple registers to poke at
   areg_block #(.addr('o17774), .count(1)) reg1(DALtx, DAL, TRPLY, RDIN, RDOUT, RSYNC, RBS7);
   areg_block #(.addr('o17772), .count(1)) reg2(DALtx, DAL, TRPLY, RDIN, RDOUT, RSYNC, RBS7);
   


   initial begin
      $dumpfile("tb_qbus.lxt");
      $dumpvars(0, tb_qbus);

      // bus idle
      #0 tbDAL = 0;
      { tbDOUT, tbRPLY, tbDIN, tbSYNC, tbIRQ4, tbIRQ5, tbIRQ6, tbIRQ7, tbWTBT, tbREF,
	tbINIT, tbDCOK, tbPOK, tbBS7, tbIAKI, tbDMGI, tbDMR, tbSACK, tbIAKO, tbDMGO } = 0;
      
      // read from 17774
      count = count + 1;
      #20 tbDAL = 'o17777774;  tbBS7 = 1;
      #15 tbSYNC = 1;
      #10 tbDAL = 0; tbBS7 = 0; tbDIN = 1;
      #15 if (!RRPLY)
	$display("Error NXM (%1d)", count);
      else if (~BDAL != 22'o123456)
	$display("Error (%1d): %o", count, ~BDAL);
      tbDIN = 0; tbSYNC = 0;

      // read from 17770 (should be NXM).  This is not a proper NXM check.  I should be
      // waiting for RPLY and timing out.  And I shouldn't read the data for 150ns after
      // RPLY is asserted either.  The DMA engine will have to do this right.
      count = count + 1;
      #20 tbDAL = 'o17777770;  tbBS7 = 1;
      #15 tbSYNC = 1;
      #10 tbDAL = 0; tbBS7 = 0; tbDIN = 1;
      #15 if (RRPLY)
	$display("Error (%1d): Should have been NXM but wasn't", count);
      tbDIN = 0; tbSYNC = 0;

      // read again from 17774 without setting the high address bits in DAL
      count = count + 1;
      #20 tbDAL = 'o17774;  tbBS7 = 1;
      #15 tbSYNC = 1;
      #10 tbDAL = 0; tbBS7 = 0; tbDIN = 1;
      #15 if (~BDAL != 22'o123456)
	$display("Error (%1d): %o", count, ~BDAL);
      tbDIN = 0; tbSYNC = 0;

      // write to 17774
      count = count + 1;
      #20 tbDAL = 'o17777774; tbBS7 = 1; tbWTBT = 1; 
      #15 tbSYNC = 1;
      #10 tbDAL = 'o054321; tbBS7 = 0; tbWTBT = 0;
      #10 tbDOUT = 1;
      #15 tbDOUT = 0;
      #10 tbDAL = 0; tbSYNC = 0;

      // read new value back from 17774
      count = count + 1;
      #20 tbDAL = 'o17777774; tbBS7 = 1; 
      #15 tbSYNC = 1;
      #10 tbDAL = 0; tbBS7 = 0;
      #10 tbDIN = 1;
      #15 if (~BDAL != 22'o054321)
	$display("Error (%1d): %o", count, ~BDAL);
      tbDIN = 0; tbSYNC = 0;

      // read from 17772
      count = count + 1;
      #20 tbDAL = 'o17777772; tbBS7 = 1;
      #15 tbSYNC = 1;
      #10 tbDAL = 0; tbBS7 = 0;
      #10 tbDIN = 1;
      #15 if (~BDAL != 22'o123456)
	$display("Error (%1d): %o", count, ~BDAL);
      tbDIN = 0; tbSYNC = 0;

      // read-modify-write (DATAIO) to 17772
      count = count + 1;
      #20 tbDAL = 'o17777772; tbBS7 = 1;
      #15 tbSYNC = 1;
      #10 tbDAL = 0; tbBS7 = 0;
      #10 tbDIN = 1;
      #15 if (~BDAL != 22'o123456)
	$display("Error (%1d): %o", count, ~BDAL);
      tbDIN = 0;
      // finished the read, start writing.  supposed to wait at least 200ns after negation
      // of RPLY before asserting DOUT but must assert DAL 100ns before DOUT.
      #10 tbDAL = 'o54545;
      #10 tbDOUT = 1;
      #15 tbDOUT = 0; 
      #10 tbDAL = 0; tbSYNC = 0;

      // check that write worked
      count = count + 1;
      #20 tbDAL = 'o17777772; tbBS7 = 1;
      #15 tbSYNC = 1;
      #10 tbDAL = 0; tbBS7 = 0;
      #10 tbDIN = 1;
      #15 if (~BDAL != 22'o54545)
	$display("Error (%1d): %o", count, ~BDAL);
      tbDIN = 0; tbSYNC = 0;

      #20 $finish_and_return(0);
   end


endmodule // tb_qbus
