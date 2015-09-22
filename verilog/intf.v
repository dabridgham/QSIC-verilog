//	-*- mode: Verilog; fill-column: 96 -*-
//
// The QBUS Interface for QSIC
//
// Copyright 2015 Noel Chiappa and David Bridgham
//
// 2015-09-16 dab	initial version


// This is implemented in hardware on the QSIC board.  It's reflected here in Verilog for
// the purposes of simulation and testing.  The QBUS lines are brought in through
// inverting driver chips and level converters.  Some bus lines are bi-directional with a
// direction control signal while some are connected to only driver or receiver chips.
module qintf
  (
   // The raw QBUS signals, they're all open-collector
   inout [21:0] BDAL, // all 22 lines bidir for Q22 memory as well as Q22 DMA
   inout 	BDOUT,
   inout 	BRPLY,
   inout 	BDIN,
   inout 	BSYNC,
   inout 	BIRQ4,
   inout 	BIRQ5,
   inout 	BIRQ6,
   inout 	BIRQ7,
   inout 	BWTBT, // write or byte
   inout 	BREF, // refresh (obsolete?) or burst mode DMA
   input 	BINIT, // needs output to be CPU
   input 	BDCOK, // is this useful if not a CPU?
   input 	BPOK, // is this useful if not a CPU?
   input 	BBS7, // needs output to be CPU
   input 	BIAKI,
   input 	BDMGI,
   output 	BDMR, // needs input to be CPU
   output 	BSACK, // needs input to be CPU
   output 	BIAKO,
   output 	BDMGO,

`ifdef NOTDEF
   input 	BEVNT, // needed for CPU
   input 	BHALT, // needed for CPU
`endif

   // Direction control from the FPGA for the BDAL lines
   input 	DALtx,

   // The QBUS signals as seen by the FPGA
   inout [21:0] DAL, // bidirectional to save FPGA pins
   output 	RDOUT,
   input 	TDOUT,
   output 	RRPLY,
   input 	TRPLY,
   output 	RDIN,
   input 	TDIN,
   output 	RSYNC,
   input 	TSYNC,
   output 	RIRQ4,
   input 	TIRQ4,
   output 	RIRQ5,
   input 	TIRQ5,
   output 	RIRQ6,
   input 	TIRQ6,
   output 	RIRQ7,
   input 	TIRQ7,
   output 	RWTBT,
   input 	TWTBT, // option 1, allow byte write DMA cycles
   output 	RREF, // option for DMA burst mode when acting as memory
   input 	TREF, // option for DMA burst mode

   output 	RINIT,
   output 	RDCOK,
   output 	RPOK,
   output 	RBS7,
   output 	RIAKI,
   output 	RDMGI,

   input 	TDMR,
   input 	TSACK,
   input 	TIAKO,
   input 	TDMGO
   );

   // The BDAL lines are kept bidirectional to save lines (at the cost of a direction control line)
   assign BDAL = DALtx ? ~DAL : 22'bZ; // since BDAL is declared 'wor', do I have to explicitly set Z here?
   assign DAL = !DALtx ? ~BDAL : 22'bZ;

   // All the rest of the bidirectional lines are split into in (R) and out (T)
   assign BDOUT = ~TDOUT;
   assign RDOUT = ~BDOUT;
   
   assign BRPLY = ~TRPLY;
   assign RRPLY = ~BRPLY;
   
   assign BDIN = ~TDIN;
   assign RDIN = ~BDIN;
   
   assign BSYNC = ~TSYNC;
   assign RSYNC = ~BSYNC;
   
   assign BIRQ4 = ~TIRQ4;
   assign RIRQ4 = ~BIRQ4;
   
   assign BIRQ5 = ~TIRQ5;
   assign RIRQ5 = ~BIRQ5;
   
   assign BIRQ6 = ~TIRQ6;
   assign RIRQ6 = ~BIRQ6;
   
   assign BIRQ7 = ~TIRQ7;
   assign RIRQ7 = ~BIRQ7;
   
   assign BWTBT = ~TWTBT;	// option 1, allow byte write DMA cycles
   assign RWTBT = ~BWTBT;

   assign BREF = ~TREF;	// signal for DMA burst-mode (or old-style refresh)
   assign RREF = ~BREF;


   assign RINIT = ~BINIT;
   assign RDCOK = ~BDCOK;
   assign RPOK = ~BPOK;
   assign RBS7 = ~BBS7;
   assign RIAKI = ~BIAKI;
   assign RDMGI = ~BDMGI;

   assign BDMR = ~TDMR;
   assign BSACK = ~TSACK;
   assign BIAKO = ~TIAKO;
   assign BDMGO = ~TDMGO;
   
endmodule // apr
