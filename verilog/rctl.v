//	-*- mode: Verilog; fill-column: 96 -*-
//
// Register Control - The I/O register mux.
//
// Copyright 2020 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

module rctrl
  (
   // Register Control
   output	     reg_addr_match,
   output reg [15:0] reg_rdata,

   // conf
   input	     c_match,
   input [15:0]	     c_rdata,

   // dev0
   input	     dev0_match,
   input [15:0]	     dev0_rdata,
   
   // dev1
   input	     dev1_match,
   input [15:0]	     dev1_rdata,
   
   // dev2
   input	     dev2_match,
   input [15:0]	     dev2_rdata,
   
   // dev3
   input	     dev3_match,
   input [15:0]	     dev3_rdata   
   );

   assign reg_addr_match = c_match | dev0_match | dev1_match | dev2_match | dev3_match;

   // read mux
   always @(*)
     case (1'b1)
       c_match: reg_rdata = c_rdata;
       dev0_match: reg_rdata = dev0_rdata;
       dev1_match: reg_rdata = dev1_rdata;
       dev2_match: reg_rdata = dev2_rdata;
       dev3_match: reg_rdata = dev3_rdata;
       default: reg_rdata = 16'bx;
     endcase // case (1'b1)


endmodule // rctrl
