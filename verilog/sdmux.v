//	-*- mode: Verilog; fill-column: 96 -*-
//
// Connect a Disk Controller to multiple Storage Devices
//
// Copyright 2018 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns


module sdmux
  (
   // Disk Controller
   output 	     command_ready, // ready to accept a read or write command
   input 	     read_cmd,
   input 	     write_cmd,
   output 	     fifo_clk, 
   output 	     write_data_enable,
   output reg [15:0] read_data,
   output 	     read_data_enable,

   // selects which Storage Device to use
   input [1:0] 	     sd_select, 

   // Storage Devices
   input [0:3] 	     sd_command_ready,
   output [0:3]      sd_read_cmd,
   output [0:3]      sd_write_cmd,
   input [0:3] 	     sd_fifo_clk,
   input [0:3] 	     sd_write_data_enable,
   input [0:3] 	     sd_read_data_enable,

   // Data lines are separated because Verilog can't use arrays in ports.  That's just stupid
   input [15:0]      sd0_read_data,
   input [15:0]      sd1_read_data,
   input [15:0]      sd2_read_data,
   input [15:0]      sd3_read_data
   );

   assign command_ready = sd_command_ready[sd_select];
   assign fifo_clk = sd_fifo_clk[sd_select];
   assign write_data_enable = sd_write_data_enable[sd_select];
   assign read_data_enable = sd_read_data_enable[sd_select];

   genvar 	 i;
   for (i=0; i<4; i=i+1) begin
      assign sd_read_cmd[i] = (sd_select == i) ? read_cmd : 0;
      assign sd_write_cmd[i] = (sd_select == i) ? write_cmd : 0;
   end

   always @(*) begin
      case (sd_select)
	0: read_data = sd0_read_data;
	1: read_data = sd1_read_data;
	2: read_data = sd2_read_data;
	3: read_data = sd3_read_data;
      endcase
   end

endmodule // sdmux
