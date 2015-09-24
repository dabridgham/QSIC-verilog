//	-*- mode: Verilog; fill-column: 96 -*-
//
// Common definitions for the Verilog in QSIC
//
// Copyright 2015 Noel Chiappa and David Bridgham
//

// Define this to add the extra bus lines to let the QSIC be a processor board
//`define CPU 1

// Define this if the bus driver and level converters are inverting
`define INVERTING_DRIVER 1

`ifdef INVERTING_DRIVER
 `define DRIVE(x) ~x
 `define ASSERT(x) x = 1
 `define CLEAR(x) = 0
 `define ASSERTED(x) (x == 1)
 `define TRIGGER(x) posedge x
`else
 `define DRIVE(x) x
 `define ASSERT(x) x = 0
 `define CLEAR(x) = 1
 `define ASSERTED(x) (x == 0)
 `define TRIGGER(x) negedge x
`endif
