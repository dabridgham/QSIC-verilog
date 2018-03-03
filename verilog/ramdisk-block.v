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

   // connection to the disk controller
    output reg 	      command_ready, // ready to accept a read or write command
    input 	      read_cmd,
    input 	      write_cmd,
    input [31:0]      block_address,
    output 	      fifo_clk, 
    input [15:0]      write_data,
    output reg 	      write_data_enable,
    output reg [15:0] read_data,
    output reg 	      read_data_enable
   );

   wire 	      ramclk = clk;
   assign fifo_clk = ramclk;	// just pass the clock through to the FIFO

   // The RAM for the RAM Disk
   localparam BLOCK_SIZE = 256;	// in words
   localparam WORDS = BLOCKS * BLOCK_SIZE;
   reg [15:0] 	      RAM[0:WORDS-1];
   reg [17:0] 	      memory_address; // the size here is specific to the XC7A75T which has up
				// to about 400kB (or 200kW) of Block RAM
   reg mem_write = 0,
       mem_read = 0;
   always @(posedge ramclk)
     if (mem_write)
       RAM[memory_address] <= write_data;
     else if (mem_read)
       read_data <= RAM[memory_address];

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
   always @(posedge ramclk) begin
      read_data_enable <= 0;
      write_data_enable <= 0;
      block_done <= 0;
      first_word <= 0;
      reading <= 0;
      writing <= 0;
      mem_read <= 0;
      mem_write <= 0;
      command_ready <= 0;
      
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
	     if (first_word)
	       memory_address <= { block_address[9:0], 8'h00 };
	     else begin
		memory_address <= memory_address + 1;
		// only write to the FIFO after the first read from the RAM has happened
		read_data_enable <= 1;
	     end
	     { block_done, word_counter } <= { last_word, next_counter };
	     mem_read <= 1;
	     reading <= 1;
	  end
	writing:
	  if (!block_done) begin
	     if (!last_word)
	       write_data_enable <= 1;
	     if (first_word)
	       memory_address <= { block_address[9:0], 8'h00 };
	     else
	       memory_address <= memory_address + 1;
	     { block_done, word_counter } <= { last_word, next_counter };
	     mem_write <= 1;
	     writing <= 1;
	  end
	// if not otherwise busy, look for a command
	read_cmd:
	  begin
	     word_counter <= 0;
	     block_done <= 0;
	     first_word <= 1;
	     reading <= 1;
	  end
	write_cmd:
	  begin
	     word_counter <= 0;
	     block_done <= 0;
	     first_word <= 1;
	     writing <= 1;
	     write_data_enable <= 1; // read the first word out of the FIFO
	  end
	default:
	  command_ready <= 1;	// if we're not doing anything else, then we're ready for a command
      endcase // case (1'b1)
      
   end // always @ (posedge ramclk)

endmodule // ramdisk_block


`ifdef SIM

//
// A Testbench for this RAM Disk
//

module RD_test();

   reg clk = 0;
   always @(*)
     #25 clk <= ~clk; // 20MHz clock (50ns cycle)
   
   reg reset, read_cmd, write_cmd;
   wire command_ready, fifo_clk, write_data_enable, read_data_enable;
   reg [31:0] block_address = 0;
   reg [15:0] write_data = 16'o177000;
   wire [15:0] read_data;

   ramdisk_block #(.BLOCKS(2 * 12 * 5))	// surfaces * sectors * cylinders (for RK05 but limited to
				// ~32 cylinders because of the amount of Block RAM)
   RD0 (.clk(clk),
	.reset(reset),
 	.command_ready(command_ready),
	.read_cmd(read_cmd),
	.write_cmd(write_cmd),
	.block_address(block_address),
	.fifo_clk(fifo_clk), 
	.write_data(write_data),
	.write_data_enable(write_data_enable),
	.read_data(read_data),
	.read_data_enable(read_data_enable)
   );

   // A simple write FIFO, pre-filled with data
   reg [15:0]  wFIFO [0:511];
   reg [8:0]   wFptr = 0;
   reg [8:0]   rFptr = 0;

   integer     i;

   always @(posedge fifo_clk)
     if (write_data_enable) begin
	write_data <= wFIFO[rFptr];
	rFptr <= rFptr + 1;
     end

   // Print out data that comes back from the reads
   integer col = 0;
   integer row = 0;
   always @(posedge fifo_clk) begin
      if (read_cmd) begin
	 row <= 0;
	 col <= 0;
      end

      if (read_data_enable) begin
	 if ((row == 0) && (col == 0))
	   $display("Read Block %o", block_address);
	 
	 if (col == 0)
	   $write("%6o |", row);

	 $write(" %6o", read_data);
	 if (col == 7) begin
	    col <= 0;
	    row <= row + 16;
	    $write("\n");
	 end else
	   col <= col + 1;
      end
   end

   // Run the test
   initial begin
      $dumpfile("ramdisk-block.lxt");
      $dumpvars(0, RD_test);

      reset <= 0;
      read_cmd <= 0;
      write_cmd <= 0;

      // fill the FIFO
      for (i = 0; i < 512; i=i+1)
	wFIFO[i] <= 16'o04000 + i;

      #100 reset <= 1;
      #600 reset <= 0;

      // Write block 0
      block_address <= 0;
      #1000 write_cmd <= 1;
      while (command_ready)
	#50;
      #50 write_cmd <= 0;
      while (!command_ready)
	#100;

      // Read block 0
      block_address <= 0;
      #100 read_cmd <= 1;
      while (command_ready)
	#50;
      #50 read_cmd <= 0;
      while (!command_ready)
	#100;

      // Write block 1
      block_address <= 1;
      #1000 write_cmd <= 1;
      while (command_ready)
	#50;
      #50 write_cmd <= 0;
      while (!command_ready)
	#100;

      // Write block 2
      block_address <= 2;
      #1000 write_cmd <= 1;
      while (command_ready)
	#50;
      #50 write_cmd <= 0;
      while (!command_ready)
	#100;

      // Read block 1
      block_address <= 1;
      #100 read_cmd <= 1;
      while (command_ready)
	#50;
      #50 read_cmd <= 0;
      while (!command_ready)
	#100;

      // Read block 2
      block_address <= 2;
      #100 read_cmd <= 1;
      while (command_ready)
	#50;
      #50 read_cmd <= 0;
      while (!command_ready)
	#100;

      #100 $finish_and_return(0);
   end
      

endmodule

`endif
