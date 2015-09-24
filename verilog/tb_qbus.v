//	-*- mode: Verilog; fill-column: 96 -*-
//
// Testbench for the low-level QBUS interface
//
// Copyright 2015 Noel Chiappa and David Bridgham

`timescale 10 ns / 10 ns

module tb_qbus();
   
   // The raw QBUS signals, they're all open-collector
   wand [21:0] BDAL;
   wand        BBS7, BWTBT, BSYNC, BDIN, BDOUT, BRPLY, BREF, BIRQ4, BIRQ5, BIRQ6, BIRQ7,
	       BDMR, BSACK, BINIT, BIAKO, BDMGO, BIAKI, BDMGI, BDCOK, BPOK, BEVNT, BHALT;
   
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

   // a couple registers to poke at
   areg_block #(.addr('o17774), .count(1)) reg1(DALtx, DAL, TRPLY, RDIN, RDOUT, RSYNC, RBS7);
   areg_block #(.addr('o17772), .count(1)) reg2(DALtx, DAL, TRPLY, RDIN, RDOUT, RSYNC, RBS7);
   


   initial begin
      $dumpfile("tb_qbus.lxt");
      $dumpvars(0, tb_qbus);

      // bus idle
      #0 tbDAL = 0;
      { tbBS7, tbWTBT, tbSYNC, tbDIN, tbDOUT, tbRPLY, tbREF, tbIRQ4, tbIRQ5, tbIRQ6, tbIRQ7,
	tbDMR, tbSACK, tbINIT, tbIAKO, tbDMGO, tbIAKI, tbDMGI, tbDCOK, tbPOK, tbEVNT, tbHALT } = 0;
      
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
