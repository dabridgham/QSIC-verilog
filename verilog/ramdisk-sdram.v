//	-*- mode: Verilog; fill-column: 96 -*-
//
// A RAM Disk using external SDRAM.
//
// Copyright 2019-2020 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

module ramdisk_sdram
  (
   // AXI4 connection to the SDRAM
   // user interface signals
   input 	     ui_clk,
   input 	     ui_clk_sync_rst,
   input 	     mmcm_locked,
   // Slave Interface Write Address Ports
   output [3:0]      s_axi_awid,
   output [27:0]     s_axi_awaddr,
   output [7:0]      s_axi_awlen,
   output [2:0]      s_axi_awsize,
   output [1:0]      s_axi_awburst,
   output [0:0]      s_axi_awlock,
   output [3:0]      s_axi_awcache,
   output [2:0]      s_axi_awprot,
   output [3:0]      s_axi_awqos,
   output reg 	     s_axi_awvalid,
   input 	     s_axi_awready,
   // Slave Interface Write Data Ports
   output reg [31:0] s_axi_wdata,
   output [3:0]      s_axi_wstrb,
   output reg 	     s_axi_wlast,
   output reg 	     s_axi_wvalid,
   input 	     s_axi_wready,
   // Slave Interface Write Response Ports
   output 	     s_axi_bready,
   input [3:0] 	     s_axi_bid,
   input [1:0] 	     s_axi_bresp,
   input 	     s_axi_bvalid,
   // Slave Interface Read Address Ports
   output [3:0]      s_axi_arid,
   output [27:0]     s_axi_araddr,
   output [7:0]      s_axi_arlen,
   output [2:0]      s_axi_arsize,
   output [1:0]      s_axi_arburst,
   output [0:0]      s_axi_arlock,
   output [3:0]      s_axi_arcache,
   output [2:0]      s_axi_arprot,
   output [3:0]      s_axi_arqos,
   output reg 	     s_axi_arvalid,
   input 	     s_axi_arready,
   // Slave Interface Read Data Ports
   output reg 	     s_axi_rready,
   input [3:0] 	     s_axi_rid,
   input [31:0]      s_axi_rdata,
   input [1:0] 	     s_axi_rresp,
   input 	     s_axi_rlast,
   input 	     s_axi_rvalid,

   // connection from the disk controller
   output 	     command_ready, // ready to accept a read or write command
   input 	     read_cmd,
   input 	     write_cmd,
   input [31:0]      block_address,
   output 	     fifo_clk, 
   input [15:0]      write_data,
   output reg 	     write_data_enable,
   output reg [15:0] read_data,
   output reg 	     read_data_enable,
   output [9:0]      debug_output
   );

   wire 	     ramclk = ui_clk;
   assign fifo_clk = ramclk;	// just pass the clock through to the FIFO
   assign command_ready = ~reading & ~writing;

   wire 	     reset;
   assign reset = ui_clk_sync_rst;

   // synchronize the command signals
   reg [1:0] 	     rcra, wcra;
   wire 	     s_read_cmd = rcra[1];
   wire 	     s_write_cmd = wcra[1];
   always @(posedge ramclk) rcra <= { rcra[0], read_cmd };
   always @(posedge ramclk) wcra <= { wcra[0], write_cmd };
   

   // Read Address
   assign s_axi_arid = 0;
   assign s_axi_arlen = 127;	// transfer the whole block
   assign s_axi_arsize = 'b010;	// 4 bytes at a time
   assign s_axi_arburst = 'b01;	// INCR
   assign s_axi_arlock = 0;
   assign s_axi_arcache = 0;
   assign s_axi_arprot = 0;
   assign s_axi_arqos = 0;
   assign s_axi_araddr = { block_address[18:0], 9'o000 };

   // Read State Machine
   reg 		      reading = 0, start_read = 0, read_even = 0;
   reg [6:0] 	      read_count = 0;
   reg [15:0] 	      odd_save;
   reg 		      read_done;
   // testing !!!
   reg [9:0] 	      save_data;
   reg [2:0] 	      saving = 1;
   
   always @(posedge ramclk) begin
      read_data_enable <= 0;
      s_axi_arvalid <= 0;
      s_axi_rready <= 0;

      case (1'b1)
	reset:
	  begin
	     reading <= 0;
	     start_read <= 0;
	     read_even <= 0;
	  end

	start_read:
	  if (s_axi_rvalid) begin
	     start_read <= 0;
	     s_axi_rready <= 1;
	     read_even <= 1;
	     { read_done, read_count } <= read_count + 1;
	  end

	reading:
	  if (read_even) begin
	     read_even <= 0;
	     read_data_enable <= 1;
	     { odd_save, read_data } <= s_axi_rdata;
	  end else begin
	     read_data_enable <= 1;
	     read_data <= odd_save;
	     if (read_done)
	       reading <= 0;
	     else
	       start_read <= 1;
	  end
	
	default:
	  if (s_read_cmd && s_axi_arready) begin
	     reading <= 1;
	     start_read <= 1;
	     read_count <= 0;
	     read_done <= 0;
	     s_axi_arvalid <= 1;	     
	  end
      endcase // case (1'b1)
   end
   
   // Write Address
   assign s_axi_awid = 0;
   assign s_axi_awlen = 127;	// transfer the whole block
   assign s_axi_awsize = 'b010;	// 4 bytes at a time
   assign s_axi_awburst = 'b01;	// INCR
   assign s_axi_awlock = 0;
   assign s_axi_awcache = 0;
   assign s_axi_awprot = 0;
   assign s_axi_awqos = 0;
   assign s_axi_awaddr = { block_address[18:0], 9'o000 };

   // Write Data
   assign s_axi_wstrb = 4'b1111; // write all 4 bytes

   // Write Response
   assign s_axi_bready = 1;	// this should just accept any responses as they come, we don't
				// do anything with them.

   // Write State Machine
   reg		      writing = 0, start_write = 0, write_even = 0, write_finish = 0, write_delay = 0;
   reg [6:0] 	      write_count = 0;
   wire [6:0] 	      write_count_next;
   wire 	      write_last;
   assign { write_last, write_count_next } = write_count + 1;
   reg 		      write_done = 0;
   always @(posedge ramclk) begin
      write_data_enable <= 0;
      s_axi_awvalid <= 0;
      s_axi_wvalid <= 0;
      s_axi_wlast <= 0;

      case (1'b1)
	reset:
	  begin
	     saving <= 2;	// debug !!!
	     writing <= 0;
	     start_write <= 0;
	     write_even <= 0;
	     write_done <= 0;
	     write_finish <= 0;
	     write_delay <= 0;
	  end

	// wait until the write request clears before finishing up and clearing writing
	write_done:
	  if (!s_write_cmd) begin
	     writing <= 0;
	     write_done <= 0;
	  end
	
	// just toss in a one-cycle delay
	write_delay:
	  write_delay <= 0;

	start_write:
	  if (s_axi_awready) begin
	     start_write <= 0;
	     write_even <= 1;
	     write_count <= 0;
	     write_done <= 0;
	  end else
	    s_axi_awvalid <= 1;	// hold awvalid until arready is asserted

	write_finish:
	  if (s_axi_wready) begin
	     write_count <= write_count_next;
	     write_done <= write_last;
	     write_finish <= 0;
	  end else begin
	     s_axi_wvalid <= 1;
	     s_axi_wlast <= write_last;
	  end

	writing:
	  begin
	     write_even <= ~write_even;
	     
	     if (write_even) begin
		s_axi_wdata[15:0] <= write_data;
		write_data_enable <= 1;
		write_delay <= 1;
	     end else begin
		write_finish <= 1;
		s_axi_wdata[31:16] <= write_data;
		s_axi_wvalid <= 1;
		s_axi_wlast <= write_last;
		if (!write_last)
		  write_data_enable <= 1;

		// debug !!!
		if (saving) begin
		   save_data <= write_data[9:0];
		   saving <= saving - 1;
		end
	     end
	  end
	     
	default:
	  if (s_write_cmd) begin
	     start_write <= 1;
	     writing <= 1;
	     write_even <= 1;
	     write_count <= 0;
	     write_done <= 0;
 	     s_axi_awvalid <= 1;
	     write_data_enable <= 1; // clock out the first word in the write fifo
	  end
      endcase // case (1'b1)
   end
	     
   assign debug_output = save_data;

endmodule // ramdisk_sdram
