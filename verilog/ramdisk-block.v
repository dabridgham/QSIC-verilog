//	-*- mode: Verilog; fill-column: 96 -*-
//
// A RAM Disk from the FPGA's Block RAM
//
// Copyright 2018 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

module ramdisk_block
  #(parameter BLOCKS = 2 * 12 * 5) // surfaces * sectors * cylinders (for RK05 but limited to
				    // ~32 cylinders because of the amount of Block RAM)
   (
    input 	      clk, // 20MHz
    input 	      reset, 

   // connection to the storage device
    output reg 	      device_ready, // ready to accept a read or write command
    input 	      read_cmd,
    input 	      write_cmd,
    input [31:0]      block_address,
    output 	      fifo_clk, 
    input [15:0]      write_data,
    output reg 	      write_data_enable,
    input 	      write_fifo_empty,
    output reg [15:0] read_data,
    output reg 	      read_data_enable,
    output reg [15:0] debug
   );

   assign fifo_clk = clk;	// just pass the clock through to the FIFO

   // The RAM for the RAM Disk
   localparam BLOCK_SIZE = 256;	// in words
   localparam WORDS = BLOCKS * BLOCK_SIZE;
   reg [15:0] 	      RAM[0:WORDS-1];
   reg [17:0] 	      memory_address; // the size here is specific to the XC7A75T which has up
				// to about 400kB (or 200kW) of Block RAM

   // State controls
   reg 		      first_word = 0,
		      reading = 0, 
		      writing = 0,
		      block_done = 0;
   reg [7:0] 	      word_counter = 0;
   wire 	      last_word;
   wire [7:0] 	      next_counter;
   assign { last_word, next_counter } = word_counter + 1;

   // The state machine, such as it is
   always @(posedge clk) begin
      read_data_enable <= 0;
      write_data_enable <= 0;
      block_done <= 0;
      first_word <= 0;
      reading <= 0;
      writing <= 0;
      device_ready <= 0;
      
      // the ordering of the cases here most definitely matters
      case (1'b1)
	// reset overides anything
	reset:
	  begin
	     reading <= 0;	// if any reading or writing going on, stop it
	     writing <= 0;
	  end
	// if we're in the middle of reading or writing a block, continue with that
	reading:
	  if (block_done) begin
	     read_data_enable <= 1; // write the last word to the FIFO
	  end else begin
	     if (!first_word)
	       // only write to the FIFO after the first read from the RAM has happened
	       read_data_enable <= 1;
	     read_data <= RAM[memory_address];
	     memory_address <= memory_address + 1;
	     { block_done, word_counter } <= { last_word, next_counter };
	     reading <= 1;
	  end
	writing:
	  if (!block_done) begin
	     if (!last_word)
	       write_data_enable <= 1;
	     RAM[memory_address] <= write_data;
	     debug <= write_data;
	     memory_address <= memory_address + 1;
	     { block_done, word_counter } <= { last_word, next_counter };
	     writing <= 1;
	  end
	// if not otherwise busy, look for a command
	read_cmd:
	  begin
	     memory_address <= { block_address[9:0], 8'h00 };
	     word_counter <= 0;
	     block_done <= 0;
	     reading <= 1;
	     first_word <= 1;
	  end
	write_cmd:
	  begin
	     memory_address <= { block_address[9:0], 8'h00 };
	     word_counter <= 0;
	     block_done <= 0;
	     writing <= 1;
	     first_word <= 1;
	     write_data_enable <= 1; // read the first word out of the FIFO
	  end
	default:
	  device_ready <= 1;	// if we're not doing anything else, then we're ready for a command
      endcase
      
   end // always @ (posedge clk)
   

endmodule // ramdisk_block
