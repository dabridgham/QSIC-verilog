//	-*- mode: Verilog; fill-column: 96 -*-
//
// Configuration Registers
//
// Copyright 2020 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

`include "qsic.vh"

module conf
  #(parameter ADDR_BASE = `CONF_REG_ADDR_BASE)
  (input 	     clk,
   
   // Register Control
   input [12:0]	     reg_addr,
   input	     reg_bs7,
   output	     reg_addr_match,
   output reg [15:0] reg_rdata,
   input [15:0]	     reg_wdata,
   input	     reg_write,

   // Configuration Bus
   output reg [15:0] conf_addr = 0,
   output	     conf_write,

   // various configuration sources
   input	     tl_match, // top-level conf table
   input [15:0]	     tl_rdata,
   input	     dev0_match, // dev0
   input [15:0]	     dev0_rdata,
   input	     dev1_match, // dev1
   input [15:0]	     dev1_rdata,
   input	     dev2_match, // dev2
   input [15:0]	     dev2_rdata,
   input	     dev3_match, // dev3
   input [15:0]	     dev3_rdata   
   );

   localparam
     CONF_REG_ADDR = ADDR_BASE,
     CONF_REG_DATA = ADDR_BASE + 2;

   // The Bus Registers
   assign reg_addr_match = (reg_bs7 && 
			    ((reg_addr == CONF_REG_ADDR) ||
			     (reg_addr == CONF_REG_DATA)));
   
   // Read the Bus Registers
   reg [15:0] 	     conf_data;
   always @(*)
     case (reg_addr)
       CONF_REG_ADDR: reg_rdata = conf_addr;
       CONF_REG_DATA: reg_rdata = conf_data;
       default: reg_rdata = 16'bx;
     endcase // case (reg_addr)

   // Only write to conf_addr.  Writes to conf_data are just passed through.
   always @(posedge clk)
     if (reg_addr_match && reg_write)
       if (reg_addr == CONF_REG_ADDR)
	 conf_addr <= reg_wdata;

   // Writing to the configuration data register gets passed through as a write directly to the
   // configuration register itself.
   assign conf_write = reg_write && (reg_addr == CONF_REG_DATA);

   // Read from the Configuration Registers
   always @(*)
     case (1'b1)
       tl_match: conf_data = tl_rdata;
       dev0_match: conf_data = dev0_rdata;
       dev1_match: conf_data = dev1_rdata;
       dev2_match: conf_data = dev2_rdata;
       dev3_match: conf_data = dev3_rdata;
       default: conf_data = 16'bx;
     endcase // case (1'b1)

endmodule // conf
