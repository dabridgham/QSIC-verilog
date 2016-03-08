//	-*- mode: Verilog; fill-column: 96 -*-
//
// QBus Master logic for when there are Am2908s between us and the QBUS - This is the logic that
// handles bus acquisition, managing the data transfers, and handing the bus back.  The actual
// data paths are elsewhere.
//
// Copyright 2016 Noel Chiappa and David Bridgham


module qmaster2908
  (
   input      clk, // 20MHz clock to get right timing for QBUS

   // QBUS
   input      RSYNC,
   input      RRPLY,
   input      RDMR,
   input      RSACK,
   input      RINIT,
   input      RDMGI,
   input      RREF, 
   output reg TSYNC,
   output reg TWTBT, 
   output reg TDIN,
   output reg TDOUT,
   output reg TDMR,
   output reg TSACK, 
   output reg TDMGO,

   // internal controls
   input      dma_read,
   input      dma_write,
   output reg assert_addr,
   output reg assert_data,
   output reg bus_master,
   output reg dma_complete, // only asserted for one clock cycle each dma cycle
   output reg DALst,
   output reg DALbe,
   output reg nxm
   );

   // states of bus master (one-hot)
`ifdef SIM
   integer state_index;
`endif
   reg [0:12] state;
   localparam
     IDLE = 0,			// idle
     BUS_REQUEST = 1,		// requesting the bus
     ADDR_SETUP = 2,		// acquired the bus, send address
     ADDR_HOLD = 3,		// hold the address, then start read or write

     WRITE_SETUP = 4,		// put the data on the bus
     WRITE = 5,			// begin write cycle
     WRITE_WAIT = 6,		// wait for reply
     WRITE_HOLD = 7,		// hold the write data
     WRITE_FINISH = 8,		// finish up the write cycle and release the bus
     
     READ = 9,			// start a read cycle
     READ_WAIT = 10,		// wait for reply
     READ_FINISH = 11,		// hold time on read data
     READ_RPLY_CLEAR = 12;	// wait for reply to clear, then release the bus
   
   task set_state;
      input integer s;
      begin
`ifdef SIM
	 state_index <= s;
`endif
	 state[s] <= 1'b1;
      end
   endtask
   
   
   // a counter used for doing timeouts.  the longest timeout is 10us for NXM which is a
   // count of 200 at 20MHz.
   reg [7:0] 	timeout_count;
   wire 	timeout = timeout_count == 0;

   // pass bus-grant so long as we're not trying to get it and we're not already passing
   // it.  because this is not sensitive to state[IDLE], if we leave IDLE we don't stop
   // passing bus-grant.
   always @(RDMGI, RINIT)	// not sensitive to state[IDLE]
     if (RINIT)
       TDMGO <= 0;
     else if (RDMGI && state[IDLE])
       TDMGO <= 1;
     else
       TDMGO <= 0;
   
   // synchronize various asynchronous signals
   reg [0:1] 	RSYNCsr, RRPLYsr, TDMGOsr;
   reg [0:2] 	RDMGIsr;	// one extra clock cycle delay for DMGI to close a window
				// where grant-in has been asserted but hasn't propagated
				// to grant-out yet but it's going to. with this delay, we
				// won't glitch grant out
   
   initial begin
      set_state(IDLE);
      TDMR <= 0;
      TSACK <= 0;
      TSYNC <= 0;
      TWTBT <= 0;
      TDIN <= 0;
      TDOUT <= 0;
      DALst <= 0;
      DALbe <= 0;
      assert_addr <= 0;
      assert_data <= 0;
      bus_master <= 0;
      dma_complete <= 0;
      nxm <= 0;
   end      

   always @(posedge clk) begin
      if (RINIT) begin
	 RSYNCsr <= 0;
	 RRPLYsr <= 0; 
	 RDMGIsr <= 0; 
	 TDMGOsr <= 0;
      end else begin
	 RSYNCsr <= { RSYNCsr[1], RSYNC };
	 RRPLYsr <= { RRPLYsr[1], RRPLY };
	 TDMGOsr <= { TDMGOsr[1], TDMGO };
	 RDMGIsr <= { RDMGIsr[1:2], RDMGI };
      end
   end
   wire sRSYNC = RSYNCsr[0],
	sRRPLY = RRPLYsr[0],
	sTDMGO = TDMGOsr[0],
	sRDMGI = RDMGIsr[0];
   

   // bus master state machine
   always @(posedge clk) begin
      timeout_count <= timeout_count - 1;
      state <= 0;
      if (RINIT) begin
	 set_state(IDLE);
	 TDMR <= 0;		// these are all latched
	 TSACK <= 0;
	 TSYNC <= 0;
	 TWTBT <= 0;
	 TDIN <= 0;
	 TDOUT <= 0;
	 DALst <= 0;
	 DALbe <= 0;
	 assert_addr <= 0;
	 assert_data <= 0;
	 bus_master <= 0;
	 dma_complete <= 0;
	 nxm <= 0;
      end else begin
	 case (1'b1)
	   state[IDLE]:
	     begin
		nxm <= 0;
		bus_master <= 0;
		if (dma_read || dma_write) begin
		   TDMR <= 1;	// request the bus
		   set_state(BUS_REQUEST);
		end else
		  set_state(IDLE);
	     end

	   state[BUS_REQUEST]:
	     // when we get grant-in, we're not passing grant-out, and sync and rply
	     // clear, then we own the bus so start sending the addressing information
	     if (sRDMGI && !sTDMGO && !sRSYNC && !sRRPLY) begin
		TDMR <= 0;	    // stop requesting the bus
		TSACK <= 1;	    // acknowledge we have the bus
		bus_master <= 1;    // let the device know we're bus master
		assert_addr <= 1;   // send the addressing info
		TWTBT <= dma_write; // if it's going to be a write cycle
		timeout_count <= 1; // !!! because we're using the FPGA module over ribbon
				    // cables, give it an extra cycle for the signals to settle
		set_state(ADDR_SETUP);
	     end else
	       set_state(BUS_REQUEST);

	   state[ADDR_SETUP]:
	     if (timeout) begin
		DALst <= 1;	    // strobe the address into the AM2908s
		DALbe <= 1;	    // and put it on the bus
		timeout_count <= 2; // wait 150ns before asserting SYNC.  with waiting for RSYNC
				    // and RRPLY to be synchronized plus the setup time for
				    // clocking the Am2908s, this is ample to make for the 250ns
				    // minimum before asserting SYNC.
		set_state(ADDR_HOLD);
	     end else
	       set_state(ADDR_SETUP);
		
	   state[ADDR_HOLD]:
	     if (timeout) begin
		DALst <= 0;
		assert_addr <= 0; // this is just the addressing to the Am2908s, the address is
				  // still on the bus
		TWTBT <= 0;	  // if we set it, clear now
		TSYNC <= 1;
		timeout_count <= 2; // wait 100ns more before removing address from bus
		if (dma_write) begin
		   assert_data <= 1; // start the data towards the Am2908s
		   set_state(WRITE_SETUP);
		end else begin
		   set_state(READ);
		end
	     end else	
	       set_state(ADDR_HOLD);


	   state[WRITE_SETUP]:
	     if (timeout) begin
		DALst <= 1;	    // strobe the data into the Am2908s
		DALbe <= 1;	    // keep sending, data now
		timeout_count <= 2; // 100ns from data to TDOUT
		set_state(WRITE);
	     end else
	       set_state(WRITE_SETUP);
		
	   state[WRITE]:
	     if (timeout) begin
		assert_data <= 0; // data is kept in the Am2908s now
		DALst <= 0;
		TDOUT <= 1;
		timeout_count <= 200; // ~10us NXM timeout
		set_state(WRITE_WAIT);
	     end else
	       set_state(WRITE);

	   state[WRITE_WAIT]:
	     if (sRRPLY) begin	    // wait for RPLY
		dma_complete <= 1;  // let the requester know that write succeeded
		set_state(WRITE_HOLD);
	     end else if (timeout) begin // or wait for NXM
		nxm <= 1;
		set_state(WRITE_HOLD);
	     end else
	       set_state(WRITE_WAIT);

	   state[WRITE_HOLD]:
	     begin
		dma_complete <= 0;
		TDOUT <= 0;
		nxm <= 0;	    // in case it was set
		timeout_count <= 1; // 100ns before removing data from bus
		set_state(WRITE_FINISH);
	     end

	   state[WRITE_FINISH]:
	     if (timeout) begin
		DALbe <= 0;	// remove data from bus
		TSYNC <= 0;	// we're done with the write cycle
		TSACK <= 0;	// we're done with the bus (this could happen up to 300ns
				// earlier)
		bus_master <= 0;
		set_state(IDLE);
	     end else
	       set_state(WRITE_FINISH);
	   
	   
	   state[READ]:
	     if (timeout) begin
		DALbe <= 0;	      // remove address from bus
		TDIN <= 1;	      // signal we're ready to read
		timeout_count <= 200; // ~10us NXM timeout
		set_state(READ_WAIT);
	     end else
	       set_state(READ);
	   
	   state[READ_WAIT]:
	     if (sRRPLY) begin		 // wait for RPLY
		set_state(READ_FINISH);	 // 100ns from RPLY because of synchronizer
		dma_complete <= 1;	 // won't be acted upon until the next clock so it's 150ns
	     end else if (timeout) begin // or wait for NXM
		nxm <= 1;
		set_state(READ_FINISH);
	     end else
	       set_state(READ_WAIT);

	   state[READ_FINISH]:
	     begin
		TDIN <= 0;	// 200ns from RPLY
		nxm <= 0;	// if it was set
		dma_complete <= 0;
		set_state(READ_RPLY_CLEAR);
	     end

	   state[READ_RPLY_CLEAR]:
	     if (!sRRPLY) begin	// wait for RPLY to be negated
		TSYNC <= 0;	// we're done with the read cycle
		TSACK <= 0;	// we're done with the bus
		bus_master <= 0;
		set_state(IDLE);
	     end else
	       set_state(READ_RPLY_CLEAR);
		
	 endcase
      end
   end
   

endmodule // qmaster2908
