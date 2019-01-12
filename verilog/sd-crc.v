//	-*- mode: Verilog; fill-column: 96 -*-
//
// The CRC modules for SD cards
//
// Copyright 2016 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

// CRC7 = x^7 + x^3 + 1
module crc7
  (
   input 	clk,
   input 	reset,
   input 	enable, 
   input 	data,
   output [6:0] crc
   );

   assign crc = sr;

   reg [6:0] 	sr;
   always @(posedge clk) begin
      if (reset)
	sr <= 7'b0;
      else if (enable) begin
	 sr[6] <= sr[5];
	 sr[5] <= sr[4];
	 sr[4] <= sr[3];
	 sr[3] <= sr[2] ^ sr[6] ^ data;
	 sr[2] <= sr[1];
	 sr[1] <= sr[0];
	 sr[0] <= sr[6] ^ data;
      end
   end
   
endmodule // crc7

// CRC16 = x^16 + x^12 + x^5 + 1
module crc16
  (
   input 	clk,
   input 	reset,
   input 	enable, 
   input 	data,
   output [15:0] crc
   );

   assign crc = sr;

   reg [15:0] 	 sr;
   always @(posedge clk) begin
      if (reset)
	sr <= 16'b0;
      else if (enable) begin
	 sr[15] <= sr[14];
	 sr[14] <= sr[13];
	 sr[13] <= sr[12];
	 sr[12] <= sr[11] ^ sr[15] ^ data;
	 sr[11] <= sr[10];
	 sr[10] <= sr[9];
	 sr[9] <= sr[8];
	 sr[8] <= sr[7];
	 sr[7] <= sr[6];
	 sr[6] <= sr[5];
	 sr[5] <= sr[4] ^ sr[15] ^ data;
	 sr[4] <= sr[3];
	 sr[3] <= sr[2];
	 sr[2] <= sr[1];
	 sr[1] <= sr[0];
	 sr[0] <= sr[15] ^ data;
      end
   end

endmodule // crc16



`ifdef TB_CRC

module tb();

   reg clk = 0, reset, enable;
   wire data;
   wire [6:0] crc;
   wire [15:0] crcl;
   reg 	       data16 = 1;
   
   crc7 crc7(clk, reset, enable, data, crc);

   crc16 crc16(clk, reset, enable, data16, crcl);
   

   //
   // test cases
   //

   // 01 000000 00000000000000000000000000000000 "1001010" 1
   // 01 010001 00000000000000000000000000000000 "0101010" 1
   // 00 010001 00000000000000000000100100000000 "0110011" 1

   reg [39:0] command;
   assign data = command[39];
   integer    i;

   initial begin
      $dumpfile("tb-sd.lxt");
      $dumpvars(0, tb);

      enable <= 0;
      reset <= 0;

      // 01 000000 00000000000000000000000000000000 "1001010" 1
      #50 reset <= 1;
      #25 clk <= 0;
      #25 clk <= 1;
      #25 clk <= 0;
      #25 reset <= 0;
      #25 enable <= 1;
      command <= 40'b01_000000_00000000000000000000000000000000;
      for (i = 0; i < 40; i = i + 1) begin
	 #25 clk <= 1;
	 #25 clk <= 0;
	 command <= { command[38:0], 1'b0 };
      end
      if (crc != 7'b1001010)
	$display("Test 1 error: got %b", crc);
      
      // 01 010001 00000000000000000000000000000000 "0101010" 1
      #50 reset <= 1;
      #25 clk <= 0;
      #25 clk <= 1;
      #25 clk <= 0;
      #25 reset <= 0;
      #25 enable <= 1;
      command <= 40'b01_010001_00000000000000000000000000000000;
      for (i = 0; i < 40; i = i + 1) begin
	 #25 clk <= 1;
	 #25 clk <= 0;
	 command <= { command[38:0], 1'b0 };
      end
      if (crc != 7'b0101010)
	$display("Test 2 error: got %b", crc);
      
      // 00 010001 00000000000000000000100100000000 "0110011" 1
      #50 reset <= 1;
      #25 clk <= 0;
      #25 clk <= 1;
      #25 clk <= 0;
      #25 reset <= 0;
      #25 enable <= 1;
      command <= 40'b00_010001_00000000000000000000100100000000;
      for (i = 0; i < 40; i = i + 1) begin
	 #25 clk <= 1;
	 #25 clk <= 0;
	 command <= { command[38:0], 1'b0 };
      end
      if (crc != 7'b0110011)
	$display("Test 3 error: got %b", crc);
      
      // 512 bytes of 0xFF should give a CRC16 of 0x7FA1
      #50 reset <= 1;
      #25 clk <= 0;
      #25 clk <= 1;
      #25 clk <= 0;
      #25 reset <= 0;
      #25 enable <= 1;
      data16 <= 1;
      for (i = 0; i < 512*8; i = i + 1) begin
	 #25 clk <= 1;
	 #25 clk <= 0;
      end
      if (crcl != 16'h7FA1)
	$display("Test 4 error: got %x", crcl);
      

      #100 $finish_and_return(0);
   end

endmodule // tb

`endif
