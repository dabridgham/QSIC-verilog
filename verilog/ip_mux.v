//	-*- mode: Verilog; fill-column: 96 -*-
//
// A commutator to combine the signals from several indicator panels
// into a single datastream
//
// Copyright 2018 Noel Chiappa and David Bridgham

`timescale 1ns/1ns

module ip_mux
  #(parameter
    SEL_WIDTH = 2,		// width of panel selector
    COUNT_WIDTH = 3,		// width of number of different panels supported
    PANELS = (1 << SEL_WIDTH),	// number of panels in use
    COUNT = (1 << COUNT_WIDTH))	// number of different panels 
   (input 		    clk_in,  // Indicator Panel Clock, ~100kHz
    output 		       clk_out, // Clk out to Indicator Panels
    output 		       data, // output signals to the indicator panels
    output 		       latch,
    output 		       enable, 

    // connection to the config RAM
    input [SEL_WIDTH-1:0]      ip_count, // how many panels are in use
    output reg [SEL_WIDTH-1:0] ip_step, // which entry in the conf RAM
    input [SEL_WIDTH-1:0]      ip_sel, // which panel to use

    // connection to the internal indicator panels
    output [0:PANELS-1]        ip_clk,
    output [0:PANELS-1]        ip_latch,
    input [0:PANELS-1] 	       ip_data);

   reg [7:0] 		    counter = 0;
   reg 			    done = 0;
   reg 			    enable_out = 0;
   assign enable = enable_out;
   wire 		    last_panel = (ip_step == 0);

   always @(posedge clk_in)
     if (done) begin
	counter <= -144;
	done <= 0;
     end else
       {done, counter} <= counter + 1;

   always @(posedge clk_in)
     if (done)
       if (last_panel) begin
	  ip_step <= ip_count - 1;
	  enable_out <= 1;
       end else
	 ip_step <= ip_step - 1;
   
   // clk_out is masked off for one clock cycle at the end of each indicator panel
   reg clk_mask = 0;
   always @(negedge clk_in)
     if (done)
       clk_mask <= 1;
     else
       clk_mask <= 0;
   assign clk_out = clk_in & ~clk_mask;

   genvar 		ig;
   // for now, just send the clock and latch to everyone.  sometime in
   // the future it might be a nice improvement to only clock the
   // panel that is currently being used
   for (ig=0; ig<PANELS; ig=ig+1) begin
      assign ip_clk[ig] = clk_in;
      assign ip_latch[ig] = clk_mask;
   end

   assign latch = clk_mask & last_panel; // latch the actual indicator panels just at the end
   assign data = ip_data[ip_sel];  // send the right data out

endmodule // ip_mux
