//	-*- mode: Verilog; fill-column: 96 -*-
//
// The QBUS Driver Interface for QSIC
//
// Copyright 2015 Noel Chiappa and David Bridgham

`include "qsic.vh"

// This is implemented in hardware on the QSIC board.  It's reflected here in Verilog for
// the purposes of simulation and testing.
//
// The QBUS lines are brought in through driver chips and level converters.  BDAL[0..21], BBS7,
// and BWTBT all come in through Am2908s and show up as bi-directional lines with a direction
// control.  They also have an edge triggered latch on output.  All the rest of the bus lines
// are separated into transmit (T) and receive (R) lines.
module qdrv
  (
   // The raw QBUS signals, they're all open-collector
   inout [21:0] BDAL,
   inout 	BBS7, // bank select 7 (indicates an I/O address)
   inout 	BWTBT, // write or byte
   inout 	BSYNC,
   inout 	BDIN,
   inout 	BDOUT,
   inout 	BRPLY,
   inout 	BREF, // refresh (obsolete?) or block-mode DMA
   inout 	BIRQ4,
   inout 	BIRQ5,
   inout 	BIRQ6,
   inout 	BIRQ7,
   inout 	BDMR,
   inout 	BSACK,
   inout 	BINIT,
   output 	BIAKO,
   output 	BDMGO,
   input 	BIAKI,
   input 	BDMGI,
   input 	BDCOK,
   input 	BPOK,
`ifdef CPU
   input 	BEVNT,
   input 	BHALT,
`endif

   // The QBUS signals as seen by the FPGA
   input 	DALbe_L, // Enable transmitting on BDAL (active low)
   input 	DALtx,	// set level-shifters to output and disable input from Am2908s
   input 	DALst,	// latch the BDAL output
   inout [21:0] ZDAL,
   inout 	ZBS7,
   inout 	ZWTBT,

   output 	RSYNC,
   output 	RDIN,
   output 	RDOUT,
   output 	RRPLY,
   output 	RREF, // option for DMA block-mode when acting as memory
   output 	RIRQ4,
   output 	RIRQ5,
   output 	RIRQ6,
   output 	RIRQ7,
   output 	RDMR,
`ifdef CPU
   output 	RSACK,
`endif
   output 	RINIT,
   output 	RIAKI,
   output 	RDMGI,
   output 	RDCOK,
   output 	RPOK,
`ifdef CPU
   output 	REVNT,
   output 	RHALT,
`endif 

   input 	TSYNC,
   input 	TDIN,
   input 	TDOUT,
   input 	TRPLY,
   input 	TREF, // option for DMA block-mode
   input 	TIRQ4,
   input 	TIRQ5,
   input 	TIRQ6,
   input 	TIRQ7,
   input 	TDMR,
   input 	TSACK,
`ifdef CPU
   input 	TINIT,
`endif
   input 	TIAKO,
   input 	TDMGO
   );

   // The BDAL lines and BBS7 and BWTBT are kept bidirectional to save lines (at the cost of 
   // direction and enable lines)
   reg [21:0] 	DAL;	// these are latched in the Am2908
   reg 		BS7, WTBT;

   always @(posedge DALst)
     if (DALtx)
       { WTBT, BS7, DAL } <= { ZWTBT, ZBS7, ZDAL };
     else
       { WTBT, BS7, DAL } <= { ~BWTBT, ~BBS7, ~BDAL };

   assign BDAL = !DALbe_L ? ~DAL : 22'bZ;
   assign ZDAL = !DALtx ? ~BDAL : 22'bZ;
   assign BBS7 = !DALbe_L ? ~BS7 : 1'bZ;
   assign ZBS7 = !DALtx ? ~BBS7 : 1'bZ;
   assign BWTBT = !DALbe_L ? ~WTBT : 1'bZ;
   assign ZWTBT = !DALtx ? ~BWTBT : 1'bZ;

   // All the rest of the bus lines are split into in (R) and out (T)
   assign RSYNC = ~BSYNC;
   assign RDIN = ~BDIN;
   assign RDOUT = ~BDOUT;
   assign RRPLY = ~BRPLY;
   assign RREF = ~BREF;
   assign RIRQ4 = ~BIRQ4;
   assign RIRQ5 = ~BIRQ5;
   assign RIRQ6 = ~BIRQ6;
   assign RIRQ7 = ~BIRQ7;
   assign RDMR = ~BDMR;
`ifdef CPU
   assign RSAK = ~BSACK;
`endif
   assign RINIT = ~BINIT;
   assign RIAKI = ~BIAKI;
   assign RDMGI = ~BDMGI;
   assign RDCOK = ~BDCOK;
   assign RPOK = ~BPOK;
`ifdef CPU
   assign REVNT = ~BEVNT;
   assign RHALT = ~BHALT;

`endif
   assign BSYNC = ~TSYNC;
   assign BDIN = ~TDIN;
   assign BDOUT = ~TDOUT;
   assign BRPLY = ~TRPLY;
   assign BREF = ~TREF;
   assign BIRQ4 = ~TIRQ4;
   assign BIRQ5 = ~TIRQ5;
   assign BIRQ6 = ~TIRQ6;
   assign BIRQ7 = ~TIRQ7;
   assign BDMR = ~TDMR;
   assign BSACK = ~TSACK;
`ifdef CPU
   assign BINIT = ~TINIT;
`endif
   assign BIAKO = ~TIAKO;
   assign BDMGO = ~TDMGO;
   
endmodule // qdrv

