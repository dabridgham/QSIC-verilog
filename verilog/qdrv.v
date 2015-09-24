//	-*- mode: Verilog; fill-column: 96 -*-
//
// The QBUS Driver Interface for QSIC
//
// Copyright 2015 Noel Chiappa and David Bridgham

`include "qsic.vh"

// This is implemented in hardware on the QSIC board.  It's reflected here in Verilog for
// the purposes of simulation and testing.
//
// The QBUS lines are brought in through driver chips and level converters.  Some bus lines are
// bi-directional with a direction control signal while some are connected to only driver or
// receiver chips.
module qdrv
  (
   // The raw QBUS signals, they're all open-collector
   inout [21:0] BDAL, // all 22 lines bidir for Q22 memory as well as Q22 DMA
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
   input 	BDCOK, // is this useful if not a CPU?
   input 	BPOK, // is this useful if not a CPU?
`ifdef CPU
   input 	BEVNT,
   input 	BHALT,
`endif

   // The QBUS signals as seen by the FPGA
   input 	DALtx, // Direction control from the FPGA for the BDAL lines
   inout [21:0] DAL, // bidirectional to save FPGA pins
   output 	RBS7,
   output 	RWTBT,
   output 	RSYNC,
   output 	RDIN,
   output 	RDOUT,
   output 	RRPLY,
   output 	RREF, // option for DMA block-mode when acting as memory
   output 	RIRQ4,
   output 	RIRQ5,
   output 	RIRQ6,
   output 	RIRQ7,
`ifdef CPU
   output 	RDMR,
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

`ifdef CPU
   input 	TBS7,
`endif
   input 	TWTBT, // option 1, allow byte write DMA cycles
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

   // The BDAL lines are kept bidirectional to save lines (at the cost of a direction control line)
   assign BDAL = DALtx ? `DRIVE(DAL) : 22'bZ;
   assign DAL = !DALtx ? `DRIVE(BDAL) : 22'bZ;

   // All the rest of the bidirectional lines are split into in (R) and out (T)
   assign RBS7 = `DRIVE(BBS7);
   assign RWTBT = `DRIVE(BWTBT);
   assign RSYNC = `DRIVE(BSYNC);
   assign RDIN = `DRIVE(BDIN);
   assign RDOUT = `DRIVE(BDOUT);
   assign RRPLY = `DRIVE(BRPLY);
   assign RREF = `DRIVE(BREF);
   assign RIRQ4 = `DRIVE(BIRQ4);
   assign RIRQ5 = `DRIVE(BIRQ5);
   assign RIRQ6 = `DRIVE(BIRQ6);
   assign RIRQ7 = `DRIVE(BIRQ7);
`ifdef CPU
   assign RDMR = `DRIVE(BDMR);
   assign RSAK = `DRIVE(BSACK);
`endif
   assign RINIT = `DRIVE(BINIT);
   assign RIAKI = `DRIVE(BIAKI);
   assign RDMGI = `DRIVE(BDMGI);
   assign RDCOK = `DRIVE(BDCOK);
   assign RPOK = `DRIVE(BPOK);
`ifdef CPU
   assign REVNT = `DRIVE(BEVNT);
   assign RHALT = `DRIVE(BHALT);

   assign BBS7 = `DRIVE(TBS7);
`endif
   assign BWTBT = `DRIVE(TWTBT);	// option 1, allow byte write DMA cycles
   assign BSYNC = `DRIVE(TSYNC);
   assign BDIN = `DRIVE(TDIN);
   assign BDOUT = `DRIVE(TDOUT);
   assign BRPLY = `DRIVE(TRPLY);
   assign BREF = `DRIVE(TREF);
   assign BIRQ4 = `DRIVE(TIRQ4);
   assign BIRQ5 = `DRIVE(TIRQ5);
   assign BIRQ6 = `DRIVE(TIRQ6);
   assign BIRQ7 = `DRIVE(TIRQ7);
   assign BDMR = `DRIVE(TDMR);
   assign BSACK = `DRIVE(TSACK);
`ifdef CPU
   assign BINIT = `DRIVE(TINIT);
`endif
   assign BIAKO = `DRIVE(TIAKO);
   assign BDMGO = `DRIVE(TDMGO);
   
endmodule // qdrv

