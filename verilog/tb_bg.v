//	-*- mode: Verilog; fill-column: 96 -*-
//
// Testbench for the bus grant multiplexer
//
// Copyright 2015 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

// a device that's not requesting the bus so it passes grant
module pass (input grant_in,
	     output grant_out);
   assign grant_out = grant_in;
endmodule // pass

// a device that is requesting the bus so it blocks the grant signal
module block (input grant_in,
	      output grant_out);
   assign grant_out = 0;
endmodule // block


module tb_bg();
   
   reg grant_in;
   wire grant_out;
   wire [1:7] go;
   wire [1:7] gi;
   reg [2:0]  slot[1:5];

   // an assortment of devices
   pass p1(gi[1], go[1]);
   pass p2(gi[2], go[2]);
   pass p3(gi[3], go[3]);
   pass p4(gi[4], go[4]);
   pass p5(gi[5], go[5]);
   block b1(gi[6], go[6]);
   block b2(gi[7], go[7]);

   bg_mux bg_mux(grant_in, grant_out, slot[1], slot[2], slot[3], slot[4], slot[5], gi, go);

   initial begin
      $dumpfile("tb_bg.lxt");
      $dumpvars(0, tb_bg);

      // wire up no devices
      #0 grant_in <= 0;
      slot[1] <= 0;
      slot[2] <= 0;
      slot[3] <= 0;
      slot[4] <= 0;
      slot[5] <= 0;
      
      // see that the grant flies straight through
      #10 grant_in <= 1;
      #10 if (grant_out != 1)
	$display("Error (1)");
      #10 grant_in <= 0;
      #10 if (grant_out != 0)
	$display("Error (2)");

      // now fill the bus with devices that are passing the grant
      slot[1] <= 1;
      slot[2] <= 2;
      slot[3] <= 3;
      slot[4] <= 4;
      slot[5] <= 5;
      
      // see that the grant flies straight through
      #10 grant_in <= 1;
      #10 if (grant_out != 1)
	$display("Error (3)");
      #10 grant_in <= 0;
      #10 if (grant_out != 0)
	$display("Error (4)");

      // put the devices on the bus in reverse order
      slot[1] <= 5;
      slot[2] <= 4;
      slot[3] <= 3;
      slot[4] <= 2;
      slot[5] <= 1;
      
      // see that the grant flies straight through
      #10 grant_in <= 1;
      #10 if (grant_out != 1)
	$display("Error (5)");
      #10 grant_in <= 0;
      #10 if (grant_out != 0)
	$display("Error (6)");

      // block the grant
      slot[1] <= 6;
      slot[2] <= 0;
      slot[3] <= 0;
      slot[4] <= 0;
      slot[5] <= 0;
      
      // see that the grant is stopped
      #10 grant_in <= 1;
      #10 if (grant_out != 0)
	$display("Error (7)");
      #10 grant_in <= 0;
      #10 if (grant_out != 0)
	$display("Error (8)");

      // block the grant in the middle
      slot[1] <= 0;
      slot[2] <= 0;
      slot[3] <= 6;
      slot[4] <= 0;
      slot[5] <= 0;
      
      // see that the grant is stopped
      #10 grant_in <= 1;
      #10 if (grant_out != 0)
	$display("Error (9)");
      #10 grant_in <= 0;
      #10 if (grant_out != 0)
	$display("Error (10)");
      
      // block the grant at the end
      slot[1] <= 0;
      slot[2] <= 0;
      slot[3] <= 0;
      slot[4] <= 0;
      slot[5] <= 6;
      
      // see that the grant is stopped
      #10 grant_in <= 1;
      #10 if (grant_out != 0)
	$display("Error (11)");
      #10 grant_in <= 0;
      #10 if (grant_out != 0)
	$display("Error (12)");
      
      // two blockers
      slot[1] <= 0;
      slot[2] <= 7;
      slot[3] <= 0;
      slot[4] <= 6;
      slot[5] <= 0;
      
      // see that the grant is stopped
      #10 grant_in <= 1;
      #10 if (grant_out != 0)
	$display("Error (13)");
      if (gi[7] != 1)
	$display("Error (14)");	// grant should get to device 7
      if (go[7] != 0)
	$display("Error (15)");	// grant should not come out of device 7
      if (gi[6] != 0)
	$display("Error (16)");	// grant shouldn't get to device 6

      #10 grant_in <= 0;
      #10 if (grant_out != 0)
	$display("Error (17)");
      

      $finish(0);

   end

endmodule // tb_bg


  
