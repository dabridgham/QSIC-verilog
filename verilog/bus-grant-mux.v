//	-*- mode: Verilog; fill-column: 96 -*-
//
// Bus Grant Multiplexer - Multiplexes a daisy-chained signal (bus-grant or interrupt
// acknowledge) between the different emulated boards
//
// Copyright 2015 Noel Chiappa and David Bridgham


module bg_mux
  (
   input 	    grant_in,	// from grant out from previous board
   output reg 	    grant_out,	// to grant in on next board

   input [2:0] 	    slot1, // each slot's device (0 means no device)
   input [2:0] 	    slot2,
   input [2:0] 	    slot3,
   input [2:0] 	    slot4,
   input [2:0] 	    slot5,

   output reg [1:7] go, // grant out to device's grant-in
   input [1:7] 	    gi // grant in from device's grant-out
   );

   integer     i;
   wire [2:0]  slot[1:7];
   reg 	       jump[0:5];
       
   assign 
     slot[1] = slot1,
     slot[2] = slot2,
     slot[3] = slot3,
     slot[4] = slot4,
     slot[5] = slot5;
   
   always @(*) begin
      // connect the jumper chain to the over-all in and out signals
      jump[0] <= grant_in;
      grant_out <= jump[5];

      // connect each slot to the specified device
      for (i = 1; i < 6; i = i + 1) begin
	 if (slot[i] == 0) begin
	    jump[i] <= jump[i-1]; // no device
	    go[slot[i]] <= 0;
	 end else begin
	    jump[i] <= gi[slot[i]];
	    go[slot[i]] <= jump[i-1];
	 end
      end
   end
   

endmodule // bg_mux
