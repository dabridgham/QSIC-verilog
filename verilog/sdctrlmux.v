//	-*- mode: Verilog; fill-column: 96 -*-
//
// Connect the control signals from multiple  Disk Controllers to multiple Storage Devices
//
// Copyright 2020 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

`include "qsic.vh"

module sdctlmux
  (
   input 	 clk, // everything runs on the bus clock, 20MHz
   input 	 reset,

   // Disk Controller #0
   input [2:0] 	 c0_sdsel, // Storage Device select
   input 	 c0_read, // start a read operation
   input 	 c0_write, // start a write operation
   input [21:0]  c0_ba, // Bus Address
   input [31:0]  c0_lba, // Linear Block Address
   input [15:0]  c0_wc, // Word Count
   input 	 c0_iba, // Inhibit Incrementing Bus Address
   input 	 c0_q22, // use 22-bit addressing (otherwise it's 18-bits)
   output 	 c0_devrdy, // Device is ready
   output 	 c0_cmdrdy, // Device is ready for a command
   output 	 c0_word_st, // strobes once for each word moved
   output 	 c0_nxm, // hit non-existent memory
   output 	 c0_crcerr, // a CRC error

   // Disk Controller #1
   input [2:0]	 c1_sdsel,
   input 	 c1_read,
   input 	 c1_write,
   input [21:0]  c1_ba,
   input [31:0]  c1_lba,
   input [15:0]  c1_wc,
   input 	 c1_iba,
   input 	 c1_q22,
   output 	 c1_devrdy,
   output 	 c1_cmdrdy,
   output 	 c1_word_st,
   output 	 c1_nxm,
   output 	 c1_crcerr,

   // Storage Device #0 (SD #0)
   output 	 s0_read,
   output 	 s0_write,
   output [21:0] s0_ba,
   output [31:0] s0_lba,
   output [15:0] s0_wc,
   output 	 s0_iba,
   output 	 s0_q22,
   input 	 s0_devrdy,
   input 	 s0_cmdrdy,
   input 	 s0_word_st,
   input 	 s0_nxm,
   input 	 s0_crcerr,

   // Storage Device #1 (SD #1)
   output 	 s1_read,
   output 	 s1_write,
   output [21:0] s1_ba,
   output [31:0] s1_lba,
   output [15:0] s1_wc,
   output 	 s1_iba,
   output 	 s1_q22,
   input 	 s1_devrdy,
   input 	 s1_cmdrdy,
   input 	 s1_word_st,
   input 	 s1_nxm,
   input 	 s1_crcerr,

   // Storage Device #2 (RAM Disk)
   output 	 s2_read,
   output 	 s2_write,
   output [21:0] s2_ba,
   output [31:0] s2_lba,
   output [15:0] s2_wc,
   output 	 s2_iba,
   output 	 s2_q22,
   input 	 s2_devrdy,
   input 	 s2_cmdrdy,
   input 	 s2_word_st,
   input 	 s2_nxm,
   input 	 s2_crcerr,

   // Storage Device #3 (USB)
   output 	 s3_read,
   output 	 s3_write,
   output [21:0] s3_ba,
   output [31:0] s3_lba,
   output [15:0] s3_wc,
   output 	 s3_iba,
   output 	 s3_q22,
   input 	 s3_devrdy,
   input 	 s3_cmdrdy,
   input 	 s3_word_st,
   input 	 s3_nxm,
   input 	 s3_crcerr
   );

   reg active = 0;		// one of the channels is in use
   reg busy = 0;		// the select storage device is doing a transfer
   reg [1:0] controller;	// which disk controller is active
   reg [2:0] sdsel;		// which storage device is active

   // multiplex control signals
   wire [21:0] ba[0:1] = { c0_ba, c1_ba };
   assign s0_ba = ba[controller];
   assign s1_ba = ba[controller];
   assign s2_ba = ba[controller];
   assign s3_ba = ba[controller];
   
   wire [31:0] lba[0:1] = { c0_lba, c1_lba };
   assign s0_lba = lba[controller];
   assign s1_lba = lba[controller];
   assign s2_lba = lba[controller];
   assign s3_lba = lba[controller];
   
   wire [15:0] wc[0:1] = { c0_wc, c1_wc };
   assign s0_wc = wc[controller];
   assign s1_wc = wc[controller];
   assign s2_wc = wc[controller];
   assign s3_wc = wc[controller];
   
   wire iba[0:1] = { c0_iba, c1_iba };
   assign s0_iba = iba[controller];
   assign s1_iba = iba[controller];
   assign s2_iba = iba[controller];
   assign s3_iba = iba[controller];
   
   wire q22[0:1] = { c0_q22, c1_q22 };
   assign s0_q22 = q22[controller];
   assign s1_q22 = q22[controller];
   assign s2_q22 = q22[controller];
   assign s3_q22 = q22[controller];

   // The read and write command signals are multiplexed similarly but are only passed through
   // when there's an active controller
   wire read[0:1] = { c0_read, c1_read };
   always @(*) begin
      s0_read = 0;
      s1_read = 0;
      s2_read = 0;
      s3_read = 0;
      if (active)
	case (sdsel)
	  PACK_SD0: s0_read = read[controller];
	  PACK_SD1: s1_read = read[controller];
	  PACK_RAMDISK: s2_read = read[controller];
	  default: s3_read = read[controller];
	endcase // case (sdsel)
   end
   
   wire write[0:1] = { c0_write, c1_write };
   always @(*) begin
      s0_write = 0;
      s1_write = 0;
      s2_write = 0;
      s3_write = 0;
      if (active)
	case (sdsel)
	  PACK_SD0: s0_write = write[controller];
	  PACK_SD1: s1_write = write[controller];
	  PACK_RAMDISK: s2_write = write[controller];
	  default: s3_write = write[controller];
	endcase // case (sdsel)
   end
   
   // Control signals coming back from the storage devices are also multiplexed only when the
   // that device is active.
   wire word_st[0:7] = { s0_word_st, s1_word_st, s2_word_st, s3_word_st, s3_word_st, s3_word_st, s3_word_st, s3_word_st };
   assign c0_word_st = active && (controller == 0) ? word_st[c0_sdsel] : 0;
   assign c1_word_st = active && (controller == 1) ? word_st[c1_sdsel] : 0;

   wire nxm[0:7] = { s0_nxm, s1_nxm, s2_nxm, s3_nxm, s3_nxm, s3_nxm, s3_nxm, s3_nxm };
   assign c0_nxm = active && (controller == 0) ? nxm[c0_sdsel] : 0;
   assign c1_nxm = active && (controller == 1) ? nxm[c1_sdsel] : 0;

   wire crcerr[0:7] = { s0_crcerr, s1_crcerr, s2_crcerr, s3_crcerr, s3_crcerr, s3_crcerr, s3_crcerr, s3_crcerr };
   assign c0_crcerr = active && (controller == 0) ? crcerr[c0_sdsel] : 0;
   assign c1_crcerr = active && (controller == 1) ? crcerr[c1_sdsel] : 0;

   // devrdy is passed through all the time, so that the controller can see
   wire devrdy[0:7] = { s0_devrdy, s1_devrdy, s2_devrdy, s3_devrdy, s3_devrdy, s3_devrdy, s3_devrdy, s3_devrdy };
   assign c0_devrdy = devrdy[c0_sdsel];
   assign c1_devrdy = devrdy[c1_sdsel];

   // cmdrdy is faked out.  if another controller is using the device, just say it's cmdrdy for now.
   wire cmdrdy[0:7] = { s0_cmdrdy, s1_cmdrdy, s2_cmdrdy, s3_cmdrdy, s3_cmdrdy, s3_cmdrdy, s3_cmdrdy, s3_cmdrdy };
   assign c0_cmdrdy = (active && (controller == 0)) || !active ? cmdrdy[c0_sdsel] : 1;
   assign c1_cmdrdy = (active && (controller == 1)) || !active ? cmdrdy[c1_sdsel] : 1;

   // look for transfer requests comming from controllers and set up the muxes to make it happen
   always @(posedge clk) begin
      if (reset) begin
	 active <= 0;
	 busy < = 0;
      end else if (active) begin
	 if (busy) begin
	    // if we're in the middle of a transfer, look for it to end
	    if (cmdrdy[sdsel] == 1) begin
	       active <= 0;
	       busy <= 0;
	    end
	 end else begin
	    // active but the transfer hasn't yet begin, look for it to begin	    
	    if (cmdrdy[sdsel] == 1)
	      busy <= 1;
	 end
      end else begin // if (active)
	 // not doing anything, so look for commands to come from a controller
	 if (c0_read || c0_write) begin
	    controller <= 0;
	    sdsel <= c0_sdsel;
	    active <= 1;
	 end else if (c1_read || c1_write) begin
	    controller <= 1;
	    sdsel <= c1_sdsel;
	    active <= 1;
	 end
      end
   end

endmodule // sdctlmux
