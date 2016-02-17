//	-*- mode: Verilog; fill-column: 96 -*-
//
// The top-level module for the QSIC on the wire-wrapped prototype board with a ZTEX FPGA
// module.  The prototype board uses Am2908s for bus transceiver for all the Data/Address lines
// so there's a level of buffering there that needs to be considered.
//
// Copyright 2016 Noel Chiappa and David Bridgham

`include "qsic.vh"

module pmo
  (
   input 	clk48, // 48 MHz clock from the ZTEX module

   // these LEDs on the debug board are not on pins being used for other things so they're open
   // for general use.  these need switches 5 and 6 turned on to enable the LEDs.
   output 	led_3_2, // d8
   output 	led_3_4, // d9
   output 	led_3_6, // d10
   output 	led_3_8, // d11
   output 	led_3_9, // c12
   output 	led_3_10, // d12
   output 	tp_b30, // testpoint B30 (FPGA pin A11)
   
   // The QBUS signals as seen by the FPGA
   output reg 	DALbe_L, // Enable transmitting on BDAL (active low)
   output reg 	DALtx, // set level-shifters to output and disable input from Am2908s
   output reg 	DALst, // latch the BDAL output
   inout [21:0] ZDAL,
   inout 	ZBS7,
   inout 	ZWTBT,

   input 	RSYNC,
   input 	RDIN,
   input 	RDOUT,
   input 	RRPLY,
   input 	RREF, // option for DMA block-mode when acting as memory
   input 	RIRQ4,
   input 	RIRQ5,
   input 	RIRQ6,
   input 	RIRQ7,
   input 	RDMR,
   input 	RSACK,
   input 	RINIT,
   input 	RIAKI,
   input 	RDMGI,
   input 	RDCOK,
   input 	RPOK,

   output 	TSYNC,
   output 	TDIN,
   output 	TDOUT,
   output reg 	TRPLY,
   output 	TREF,
   output 	TIRQ4,
   output 	TIRQ5,
   output 	TIRQ6,
   output 	TIRQ7,
   output 	TDMR,
   output 	TSACK,
   output 	TIAKO,
   output 	TDMGO
   );

   // Turn the 48MHz clock into a 20MHz clock that will be used as the general QBUS clock
   // throughout the QSIC
   wire 	clk20, reset, locked;
   assign reset = 0;
   clk_wiz_0 clk(clk48, clk20, reset, locked);

   // blink some LEDs so we can see it's doing something

   // divide clock down to human visible speeds
   reg [23:0] 	count = 0;    
   always @(posedge clk20)
     count = count + 1;
        
   assign led_3_2 = count[23];
   assign led_3_4 = count[22];
   assign led_3_6 = count[21];


   // The direction of the bi-directional lines are controlled with DALtx
   reg [21:0] 	DALreg;		// holds data to be written out the DAL lines
   assign ZDAL = DALtx ? DALreg : 22'bZ;
   assign ZBS7 = DALtx ? 0 : 1'bZ;
   assign ZWTBT = DALtx ? 0: 1'bZ;

   // all the QBUS signals that I'm not driving (yet)
//   assign DALbe_L = 1;
//   assign DALtx = 0;
//   assign DALst = 0;

   assign TSYNC = 0;
   assign TDIN = 0;
   assign TDOUT = 0;
//   assign TRPLY = 0;
   assign TREF = 0;
   assign TIRQ4 = 0;
   assign TIRQ5 = 0;
   assign TIRQ6 = 0;
   assign TIRQ7 = 0;
   assign TDMR = 0;
   assign TSACK = 0;
   assign TIAKO = 0;
   assign TDMGO = 0;
   

   localparam SR_ADDR = 18'o777570; // address of switch register
   reg [15:0] 	switch_register = 16'o0;


   // Grab the addressing information when it comes by
   reg [21:0] 	addr_reg = 0;
   reg 		bs7_reg = 0;
   reg 		read_cycle = 0;
   always @(posedge RSYNC) begin
      addr_reg <= ZDAL;
      bs7_reg <= ZBS7;
      read_cycle <= ~ZWTBT;
   end
   
   // see if it's my address and synchronize the signal
   wire addr_match = RSYNC & bs7_reg & (addr_reg[12:0] == SR_ADDR[12:0]);
   reg [1:0] addr_match_ra = 0;
   always @(posedge clk20) addr_match_ra <= { addr_match_ra[0], addr_match };
   wire      saddr_match = addr_match_ra[1];

   // synchronize RDOUT
   reg [2:0] 	RDOUTra = 0;
   always @(posedge clk20) RDOUTra <= { RDOUTra[1:0], RDOUT };
   wire 	sRDOUT = RDOUTra[1];
   wire 	sRDOUTpulse = RDOUTra[2:1] == 2'b01;
   
   // synchronize RDIN
   reg [3:0] 	RDINra = 0;
   always @(posedge clk20) RDINra <= { RDINra[2:0], RDIN };
   wire 	sRDIN = RDINra[1];
   wire 	sRDINpulse = RDINra[2:1] == 2'b01;

	 
   // implement reads or writes to the switch register
   always @(posedge clk20) begin
      // bus is idle by default
      TRPLY <= 0;
      DALst <= 0;
      DALbe_L <= 1;
      DALtx <= 0;
      DALreg <= 0;
      
      if (saddr_match) begin	// if we're in a slave cycle for me
	 if (sRDIN) begin
	    DALreg <= { 4'b0000, switch_register };
	    DALtx <= 1;

	    // this is running off RDINra[3] to delay it by an extra clock cycle to let the
	    // signals in the ribbon cable settle down a bit.  when we get rid of the ribbon
	    // cable, I'm assuming we can drop back to RDINra[2].
	    if (RDINra[3]) begin
	       // This may look like it's asserting TRPLY too soon but the QBUS spec allows up to
	       // 125ns from asserting TRPLY until the data on the bus must be valid
	       TRPLY <= 1;
	       DALbe_L <= 0;
	       DALst <= 1;
	    end
	 end else if (sRDOUT) begin
	    if (sRDOUTpulse)
	      switch_register <= ZDAL[15:0];
	    TRPLY <= 1;
	 end
      end
   end // always @ (posedge clk20)

   assign tp_b30 = addr_match;
   assign led_3_8 = addr_reg[3];
   assign led_3_9 = addr_reg[4];
   assign led_3_10 = addr_reg[5];

endmodule // pmo
