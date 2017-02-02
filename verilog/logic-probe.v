//	-*- mode: Verilog; fill-column: 96 -*-
//
// A module that's sort of like an old-time logic probe on a signal.  This is for driving an LED
// to observe signals.  It detects if the signal is pulsing and generates a blinking output.
// Otherwise the output is like the input.
//
// Copyright 2016 Noel Chiappa and David Bridgham

module logic_probe
  #(parameter
    PAUSE = 1024)
   (
    input  input_signal,
    input  clk,
    output reg output_signal
   );

   localparam cnt_size = $clog2(PAUSE);

   reg [cnt_size:0] counter = 0;
   reg 		    flip = 0;

   always @(posedge clk) begin
      if (counter == 0) begin
	 if (flip) begin
	    flip <= 0;
	    output_signal <= ~output_signal;
	    counter <= PAUSE;
	 end else begin
	    output_signal <= input_signal;
	    if (output_signal != input_signal)
	      counter <= PAUSE;
	 end
      end else begin
	 if (output_signal != input_signal)
	   flip <= 1;
	 counter <= counter - 1;
      end
   end

endmodule // logic_probe

// another approach
module lp2 
  (
   input      input_signal,
   input      fast_clk, // a clock fast enough to see all changes to input_signal
   input      slow_clk, // a clock at twice the fastest you want the output to blink
   output reg output_signal
   );

   reg 	      saw0 = 0;
   reg 	      saw1 = 0;

   // set saw0 or saw1 if it sees that value between clear signals
   always @(posedge fast_clk) begin
      if (clear) begin
	 saw0 <= 0;
	 saw1 <= 0;
      end else if (input_signal)
	saw1 <= 1;
      else
	saw0 <= 1;
   end

   // look for the rising edge of slow_clk and generate a pulse of one period of fast_clk to
   // clear the saw? flags
   reg [2:0] sc_ra = 0;
   always @(posedge fast_clk) sc_ra = { sc_ra[1:0], slow_clk };
   wire      clear = sc_ra == 2'b011;

   // toggle the output at the blink speed if it saw the other value during the previous blink period
   always @(posedge slow_clk) begin
      if (output_signal && saw0)
	output_signal <= 0;
      else if (!output_signal && saw1)
	output_signal <= 1;
   end

endmodule // lp2
