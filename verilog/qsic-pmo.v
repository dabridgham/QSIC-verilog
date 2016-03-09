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

   // these LEDs on the debug board are on pins not being used for other things so they're open
   // for general use.  these need switches 5 and 6 turned on to enable the LEDs.
   output 	led_3_2, // D8
   output 	led_3_4, // D9
   output 	led_3_6, // D10
   output 	led_3_8, // D11
   output 	led_3_9, // C12
   output 	led_3_10, // D12
   output 	tp_b30, // testpoint B30 (FPGA pin A11)
   
   // The QBUS signals as seen by the FPGA
   output 	DALbe_L, // Enable transmitting on BDAL (active low)
   output 	DALtx, // set level-shifters to output and disable input from Am2908s
   output 	DALst, // latch the BDAL output
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


   // The direction of the bi-directional lines are controlled with DALtx
   // -- moved to below
   assign ZDAL = DALtx ? TDAL : 22'bZ;
   assign ZBS7 = DALtx ? 0 : 1'bZ;
   assign ZWTBT = DALtx ? rk_wtbt: 1'bZ;

   // all the QBUS signals that I'm not driving (yet)
//   assign DALbe_L = 1;
//   assign DALtx = 0;
//   assign DALst = 0;

//   assign TSYNC = 0;
//   assign TDIN = 0;
//   assign TDOUT = 0;
//   assign TRPLY = 0;
   assign TREF = 0;
//   assign TIRQ4 = 0;
//   assign TIRQ5 = 0;
//   assign TIRQ6 = 0;
//   assign TIRQ7 = 0;
//   assign TDMR = 0;
//   assign TSACK = 0;
//   assign TIAKO = 0;
//   assign TDMGO = 0;
   

   // Grab the addressing information when it comes by
   reg [21:0] 	addr_reg = 0;
   reg 		bs7_reg = 0;
   reg 		read_cycle = 0;
   always @(posedge RSYNC) begin
      addr_reg <= ZDAL;
      bs7_reg <= ZBS7;
      read_cycle <= ~ZWTBT;
   end
   

   // The internal microcontroller bus
   reg [15:0]  uADDR;
   wire [15:0] uDATA;
   reg 	       uWRITE;
   reg 	       uCLK;
   wire        uWAIT; // wired-OR !!!
   wire [7:0]  uINTERRUPT;


   //
   // Connect various devices
   //

   wire [15:0] RDL = ZDAL[15:0]; // Receive Data Lines
   reg [21:0]  TDAL;		 // Transmit Data/Address Lines

   reg 	       assert_vector = 0;

// `define SW_REG 1
`define RKV11 1

`ifdef SW_REG
   reg [17:0]  sr_addr = 18'o777570;
   wire        sr_match;
   wire [15:0] sr_tdl;

   switch_register
     switch_register(clk20, addr_reg, bs7_reg, RDL, sr_tdl,
		     sr_addr, sr_match, assert_vector, sRDOUTpulse);
`endif

`ifdef RKV11
   wire        rk_match, rk_dma_read, rk_dma_write, rk_assert_addr, rk_assert_data;
   wire        rk_bus_master, rk_dma_complete, rk_DALst, rk_DALbe, rk_nxm;
   wire        rk_wtbt, rk_irq, rk_assert_vector;
   wire [15:0] rk_tdl;
   wire [21:0] rk_tal;

   qmaster2908 
     rk_master(clk20, RSYNC, RRPLY, RDMR, RSACK, RINIT, RDMGI, RREF,
	       TSYNC, rk_wtbt, TDIN, TDOUT, TDMR, TSACK, TDMGO,
	       rk_dma_read, rk_dma_write, rk_assert_addr, rk_assert_data,
	       rk_bus_master, rk_dma_complete, rk_DALst, rk_DALbe, rk_nxm);

   qint rk_int(clk20, `INTP_4, RINIT, RDIN, 
 	       { RIRQ4, RIRQ5, RIRQ6, RIRQ7 }, RIAKI,
 	       { TIRQ4, TIRQ5, TIRQ6, TIRQ7 }, TIAKO,
	       rk_irq, rk_assert_vector);

   rkv11 rkv11(clk20, addr_reg, bs7_reg, rk_tal, RDL, rk_tdl, RINIT,
	       rk_match, rk_assert_vector, sRDOUTpulse, 
	       rk_dma_read, rk_dma_write, rk_bus_master, rk_dma_complete, rk_nxm, 
	       rk_irq, 
	       uADDR, uDATA, uWRITE, uCLK, uWAIT, uINTERRUPT);
`endif

   // mix the control signals from the DMA controller(s) and the register controller
   assign DALbe_L = ~rwDALbe & ~rk_DALbe;  // ~(rwDALbe | rk_DALbe);
   assign DALst = rwDALst | rk_DALst;
   assign DALtx = rwDALtx | rk_assert_addr | rk_assert_data;

   reg [15:0]  test_reg = 16'o177777;
   always @(posedge rwDALst) 
     if (rk_assert_vector)
       test_reg <= rk_tdl;

   // MUX for the data/address lines
   reg 	       addr_match;
   always @(*) begin
      addr_match = 0;
      assert_vector = 0;
      TDAL = 0;
      
      case (1'b1)
`ifdef RKV11
	rk_assert_data: TDAL = { 6'b0, rk_tdl };
	rk_assert_addr: TDAL = rk_tal;
`endif
	default:
	  // if RSYNC then we're doing a DATI or DATO cycle
	  if (RSYNC)
	    case (1'b1)
	      (bs7_reg & (addr_reg[12:0] == 13'o17720)):
			   { addr_match, TDAL } = { 1'b1, 6'b0, test_reg };
`ifdef SW_REG
	      sr_match: { addr_match, TDAL } = { 1'b1, 6'b0, sr_tdl };
`endif
`ifdef RKV11
	      rk_match: { addr_match, TDAL } = { 1'b1, 6'b0, rk_tdl };
`endif
	      default: 
		addr_match = 0;
	    endcase
	  // with no RSYNC, look for a interrupt vector read
	  else
	    case (1'b1)
`ifdef RKV11
	      rk_assert_vector: { assert_vector, TDAL } = { 1'b1, 6'b0, rk_tdl };
`endif
	      default: assert_vector = 0;
	    endcase
      endcase

   end


   //
   // Convert to synchronous to do register operations
   //
  
   // synchronize addr_match, extra bits here for sequencing the Am2908s
   reg [1:0]   addr_match_ra = 0;
   always @(posedge clk20) addr_match_ra <= { addr_match_ra[0], addr_match };
   wire        saddr_match = addr_match_ra[1];

   // synchronize assert_vector
   reg [3:0]   assert_vector_ra = 0;
   always @(posedge clk20) assert_vector_ra <= { assert_vector_ra[2:0], assert_vector };
   wire        sassert_vector = assert_vector_ra[1];

   // synchronize RDOUT
   reg [2:0]   RDOUTra = 0;
   always @(posedge clk20) RDOUTra <= { RDOUTra[1:0], RDOUT };
   wire        sRDOUT = RDOUTra[1];
   wire        sRDOUTpulse = RDOUTra[2:1] == 2'b01;
   
   // synchronize RDIN
   reg [3:0]   RDINra = 0;
   always @(posedge clk20) RDINra <= { RDINra[2:0], RDIN };
   wire        sRDIN = RDINra[1];
   wire        sRDINpulse = RDINra[2:1] == 2'b01;

   // implement reads or writes to registers
   reg 	       rwDALbe = 0;	// local control of these signals
   reg 	       rwDALst = 0;
   reg 	       rwDALtx = 0;
   always @(posedge clk20) begin
      // bus is idle by default
      TRPLY <= 0;
      rwDALst <= 0;
      rwDALbe <= 0;
      rwDALtx <= 0;
      
      if (saddr_match) begin	// if we're in a slave cycle for me
	 if (sRDIN) begin
	    rwDALtx <= 1;

	    // this is running off RDINra[3] to delay it by an extra clock cycle to let the
	    // signals in the ribbon cable settle down a bit.  when we get rid of the ribbon
	    // cable, I'm assuming we can drop back to RDINra[2].
	    if (RDINra[3]) begin
	       // This may look like it's asserting TRPLY too soon but the QBUS spec allows up
	       // to 125ns from asserting TRPLY until the data on the bus must be valid, so we
	       // could probably assert it even earlier
	       TRPLY <= 1;
	       rwDALbe <= 1;
	       rwDALst <= 1;
	    end
	 end else if (sRDOUT) begin
	    TRPLY <= 1;
	 end
      end else if (sassert_vector) begin // if we're reading an interrupt vector
	 rwDALtx <= 1;			 // start the data towards the Am2908s

	 // like above with RDIN, wait until assert_vector_ra[3] to give time for the signals in
	 // the ribbon cable to settle down
	 if (assert_vector_ra[3]) begin
	    TRPLY <= 1;		// should be able to assert TRPLY sooner than this !!!
	    rwDALbe <= 1;
	    rwDALst <= 1;
	 end
      end
   end // always @ (posedge clk20)

   //
   // Wire up LEDs for testing
   //

   assign tp_b30 = TSACK;
   assign led_3_4 = 0;
   assign led_3_6 = 0;
   assign led_3_8 = TSYNC;
   assign led_3_9 = TSACK;
   assign led_3_10 = TDMR;

   // blink some LEDs so we can see it's doing something

   // divide clock down to human visible speeds
   reg [23:0] 	count = 0;    
   always @(posedge clk20)
     count = count + 1;
        
   assign led_3_2 = count[21];

endmodule // pmo
