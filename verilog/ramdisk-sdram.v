//	-*- mode: Verilog; fill-column: 96 -*-
//
// A RAM Disk using external SDRAM.
//
// Copyright 2019 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

module ramdisk_sdram
  (
   // AXI4 connection to the SDRAM
   // user interface signals
   input 	     ui_clk,
   input 	     ui_clk_sync_rst,
     // Slave Interface Write Address Ports
   output [3:0]      s_axi_awid,
   output reg [27:0] s_axi_awaddr,
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
   output reg [27:0] s_axi_araddr,
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
   output reg 	     read_data_enable
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

   // Read State Machine
   reg 		      reading = 0, start_read = 0, read_even = 0;
   reg [6:0] 	      read_count = 0;
   reg [15:0] 	      odd_save;
   reg 		      read_done;
   always @(posedge ramclk) begin
      case (1'b1)
	reset:
	  begin
	     read_data_enable <= 0;
	     reading <= 0;
	     start_read <= 0;
	     read_even <= 0;
	     s_axi_arvalid <= 0;
	     s_axi_rready <= 0;
	  end

	start_read:
	  if (s_axi_arready) begin
	     s_axi_arvalid <= 0;
	     start_read <= 0;
	     read_count <= 0;
	     read_done <= 0;
	     read_even <= 1;
	     s_axi_rready <= 1;
	  end

	reading:
	  if (s_axi_rvalid) begin
	     s_axi_rready <= 0;
	     read_data_enable <= 1;
	     if (read_even) begin
		{ odd_save, read_data } <= s_axi_rdata;
		{ read_done, read_count } <= read_count + 1;
	     end else begin
		read_data <= odd_save;
		if (read_done)
		  reading <= 0;
		else
		  s_axi_rready <= 1;
	     end
	     read_even <= ~read_even;
	  end else
	    read_data_enable <= 0;

	default:
	  if (s_read_cmd) begin
	     reading <= 1;
	     start_read <= 1;
	     s_axi_araddr <= { block_address[18:0], 9'o000 };
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

   // Write Data
   assign s_axi_wstrb = 4'b1111; // write all 4 bytes

   // Write Response
   assign s_axi_bready = 1;	// this should just accept any responses as they come, we don't
				// do anything with them.

   // Write State Machine
   reg		      writing = 0, start_write = 0, write_even = 0;
   reg [6:0] 	      write_count = 0;
   reg 		      write_done;
   always @(posedge ramclk) begin
      case (1'b1)
	reset:
	  begin
	     write_data_enable <= 0;
	     writing <= 0;
	     start_write <= 0;
	     write_even <= 0;
 	     s_axi_awvalid <= 0;
	     s_axi_wvalid <= 0;
	     s_axi_wlast <= 0;
	  end

	start_write:
	  begin
	     write_data_enable <= 1;
	     if (write_even) begin
		s_axi_wdata[15:0] <= write_data;
	     end else begin
		s_axi_wdata[31:16] <= write_data;
		s_axi_wvalid <= 1;
		s_axi_wlast <= write_done;
		start_write <= 0;
	     end
	     write_even <= ~write_even;
	  end

	writing:
	  begin
	     write_data_enable <= 0;
	     if (s_axi_wready) begin
		s_axi_wvalid <= 0;
		if (write_done)
		  writing <= 0;
		else
		  start_write <= 1;
		{ write_done, write_count } <= write_count + 1;
	     end
	  end

	default:
	  if (s_write_cmd) begin
	     writing <= 1;
	     write_even <= 1;
	     write_count <= 1;
	     write_done <= 0;
	     start_write <= 1;
	     s_axi_awaddr <= { block_address[18:0], 9'o000 };
	     s_axi_wlast <= 0;
 	     s_axi_awvalid <= 1;
	  end
      endcase // case (1'b1)
   end
	     
endmodule // ramdisk_sdram
