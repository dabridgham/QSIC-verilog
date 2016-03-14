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
   input      sRDMGI, // a synchronized (and delayed) RDMGI
   input      RREF, 
   output reg TSYNC,
   output reg TWTBT, 
   output reg TDIN,
   output reg TDOUT,
   output     TDMR,
   output reg TSACK, 
   output     TDMGO,

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

   //
   // handle the bus arbitration.  this looks much like the interrupt ack processing.  perhaps
   // the biggest difference is that the interrupt processing latches the interrupt request
   // while here we expect the device to keep requesting dma so long as it has more data to
   // transfer.
   //

   assign TDMR = dma_read | dma_write;
   

   // each time RDMGI gets asserted, latch if we're requesting the bus
   reg 	      won_arbitration = 0;
   reg 	      clear_win = 0;
   always @(posedge RDMGI, posedge RINIT, posedge clear_win) begin
      if (RINIT || clear_win)
	won_arbitration <= 0;
      else
	won_arbitration <= TDMR;
   end
   
   // pass on the bus grant if we don't take it.  the magic here is that we chain out the
   // delayed version of RDMGI.  that delay gives time for the won_arbitration signal to settle
   // and hopefully any meta-stable state to stabilize.  if we have multiple devices, they can
   // all look at the same RDGMI and then the chain starts from the synchronizer and each device
   // only adds the single AND gate.
   assign TDMGO = sRDMGI & ~won_arbitration;


   //
   // The state machine handles the sequencing for the master side of executing slave cycles
   //

   // states of bus master (one-hot)
`ifdef SIM
   integer state_index;
   integer state_index_next;
`endif
   reg [0:11] state;
   reg [0:11] state_next;
   localparam
     IDLE = 0,			// idle
     ADDR_SETUP = 1,		// acquired the bus, send address
     ADDR_HOLD = 2,		// hold the address, then start read or write

     WRITE_SETUP = 3,		// put the data on the bus
     WRITE = 4,			// begin write cycle
     WRITE_WAIT = 5,		// wait for reply
     WRITE_HOLD = 6,		// hold the write data
     WRITE_FINISH = 7,		// finish up the write cycle and release the bus
     
     READ = 8,			// start a read cycle
     READ_WAIT = 9,		// wait for reply
     READ_FINISH = 10,		// hold time on read data
     READ_RPLY_CLEAR = 11;	// wait for reply to clear, then release the bus
   
   task set_state;
      input integer s;
      begin
`ifdef SIM
	 state_index_next = s;
`endif
	 state_next[s] = 1'b1;
      end
   endtask
   
   
   // a counter used for doing timeouts.  the longest timeout is 10us for NXM which is a count
   // of 200 at 20MHz.  all the timeouts set below may look like one less than the comment
   // suggests but it takes one clock cycle to get to the next state.
   reg [7:0] 	timeout_count;
   reg [7:0] 	timeout_next;
   wire 	timeout = (timeout_count == 0);

   // synchronize various asynchronous signals
   reg [0:1] 	RSYNCsr, RRPLYsr;
   always @(posedge clk) begin
      if (RINIT) begin
	 RSYNCsr <= 0;
	 RRPLYsr <= 0; 
      end else begin
	 RSYNCsr <= { RSYNCsr[1], RSYNC };
	 RRPLYsr <= { RRPLYsr[1], RRPLY };
      end
   end
   wire sRSYNC = RSYNCsr[0],
	sRRPLY = RRPLYsr[0];
   
   // combinational part of the state machine
   reg TSACK_set, TSACK_clear, TSYNC_set, TSYNC_clear, TWTBT_set, TWTBT_clear;
   reg TDIN_set, TDIN_clear, TDOUT_set, TDOUT_clear;
   reg DALbe_set, DALbe_clear, DALst_set, DALst_clear;
   reg assert_addr_set, assert_addr_clear, assert_data_set, assert_data_clear;
   reg bus_master_set, bus_master_clear;

   always @(*) begin
      state_next = 0;		// every path through had better set exactly one state bit
      timeout_next = timeout_count - 1; // most of the time we just decrement the timeout counter
      dma_complete = 0;
      nxm = 0;
      clear_win = 0;
      
      // control lines to set or clear signals I mustn't glitch
      TSACK_set = 0;
      TSACK_clear = 0;
      TSYNC_set = 0;
      TSYNC_clear = 0;
      TWTBT_set = 0;
      TWTBT_clear = 0;
      TDIN_set = 0;
      TDIN_clear = 0;
      TDOUT_set = 0;
      TDOUT_clear = 0;
      DALbe_set = 0;
      DALbe_clear = 0;
      DALst_set = 0;
      DALst_clear = 0;
      assert_addr_set = 0;
      assert_addr_clear = 0;
      assert_data_set = 0;
      assert_data_clear = 0;
      bus_master_set = 0;
      bus_master_clear = 0;

      if (RINIT) begin
	 set_state(IDLE);
      end else
	case (1'b1)
	  state[IDLE]:
	    begin
	       if (sRDMGI && won_arbitration && !sRSYNC && !sRRPLY) begin
		  TSACK_set = 1;	// acknowledge we have the bus
		  bus_master_set = 1; // let the device know we're bus master
		  assert_addr_set = 1; // send the addressing info towards the Am2908s
		  TWTBT_set = dma_write; // if it's going to be a write cycle
		  timeout_next = 1;  // !!! give 1 extra cycle of delay to let the signals on
				     // the ribbon cable settle
		  set_state(ADDR_SETUP);
	       end else
		 set_state(IDLE);
	    end

	   state[ADDR_SETUP]:
	     if (timeout) begin
		DALst_set = 1;	    // strobe the address into the AM2908s
		DALbe_set = 1;	    // and put it on the bus
		timeout_next = 2;   // wait 150ns before asserting SYNC.  with waiting for RSYNC
				    // and RRPLY to be synchronized plus the setup time for
				    // clocking the Am2908s, this is ample to make for the 250ns
				    // minimum before asserting SYNC.
		set_state(ADDR_HOLD);
	     end else
	       set_state(ADDR_SETUP);
		
	   state[ADDR_HOLD]:
	     if (timeout) begin
		DALst_clear = 1;
		assert_addr_clear = 1; // this is just the addressing to the Am2908s, the address is
				// still on the bus
		TWTBT_clear = 1;  // if we set it, clear now
		TSYNC_set = 1;	// our address has been on the bus for 150ns and it's at least
				// 250ns since RSYNC and RRPLY were cleared
		timeout_next = 1; // wait 100ns more before removing address from bus 
		if (dma_write) begin
		   timeout_next = 1;	// !!! extra time for the ribbon cable
		   assert_data_set = 1; // start the data towards the Am2908s
		   set_state(WRITE_SETUP);
		end else begin
		   set_state(READ);
		end
	     end else	
	       set_state(ADDR_HOLD);

	   state[WRITE_SETUP]:
	     if (timeout) begin
		DALst_set = 1;	    // strobe the data into the Am2908s
		DALbe_set = 1;	    // keep sending on the bus, but data now
		timeout_next = 1;  // 100ns from data to TDOUT
		set_state(WRITE);
	     end else
	       set_state(WRITE_SETUP);
		
	   state[WRITE]:
	     if (timeout) begin
		DALst_clear = 1;
		assert_data_clear = 1; // data is kept in the Am2908s now
		TDOUT_set = 1;
		timeout_next = 200; // ~10us NXM timeout
		set_state(WRITE_WAIT);
	     end else
	       set_state(WRITE);

	   state[WRITE_WAIT]:
	     if (sRRPLY) begin	  // wait for RPLY
		dma_complete = 1; // let the requester know that write succeeded 
		timeout_next = 1; // 150ns before clearing TDOUT (but already waited some for the sync)
		set_state(WRITE_HOLD);
	     end else if (timeout) begin // or wait for NXM
		nxm = 1;
		timeout_next = 1; // don't really have to wait, it's a NXM after all
		set_state(WRITE_HOLD);
	     end else
	       set_state(WRITE_WAIT);

	   state[WRITE_HOLD]:
	     if (timeout) begin
		TDOUT_clear = 1;
		timeout_next = 3; // 100ns min before removing data from bus and 175ns min
				  // before clearing TSYNC
		set_state(WRITE_FINISH);
	     end else
	       set_state(WRITE_HOLD);

	   state[WRITE_FINISH]:
	     if (timeout) begin
		DALbe_clear = 1; // remove data from bus
		if (!sRRPLY) begin
		   TSYNC_clear = 1;	// once RRPLY clears, we can clear TSYNC and be done
		   TSACK_clear = 1;	// we're done with the bus
		   bus_master_clear = 1;
		   clear_win = 1;	// clear the won_arbitration flag
		   set_state(IDLE);
		end else begin
		   timeout_next = 0;
		   set_state(WRITE_FINISH);
		end
	     end else
	       set_state(WRITE_FINISH);
	   
	   state[READ]:
	     if (timeout) begin
		DALbe_clear = 1;    // remove address from bus
		TDIN_set = 1;	    // signal we're ready to read
		timeout_next = 200;   // ~10us NXM timeout
		set_state(READ_WAIT);
	     end else
	       set_state(READ);
	   
	   state[READ_WAIT]:
	     if (sRRPLY) begin		 // wait for RPLY
		timeout_next = 0;	 // don't read the data too early
		set_state(READ_FINISH);	 // 100ns from RPLY because of synchronizer
	     end else if (timeout) begin // or wait for NXM
		timeout_next = 0;
		nxm = 1;
		set_state(READ_FINISH);
	     end else
	       set_state(READ_WAIT);

	   state[READ_FINISH]:
	     if (timeout) begin
		dma_complete = 1; // won't be acted upon until the next clock so it's 150ns
		TDIN_clear = 1;
		set_state(READ_RPLY_CLEAR);
	     end else
	       set_state(READ_FINISH);

	   state[READ_RPLY_CLEAR]:
	     if (!sRRPLY) begin	// wait for RPLY to be negated
		TSYNC_clear = 1; // we're done with the read cycle
		TSACK_clear = 1;	// we're done with the bus
		bus_master_clear = 1;
		clear_win = 1;	// clear the won_arbitration flag
		set_state(IDLE);
	     end else
	       set_state(READ_RPLY_CLEAR);

`ifdef SIM
	  default:
	    begin
	       $display("No state set!!!");
//	       set_state(IDLE);
	    end
`endif
	endcase // case (1'b1)
   end

   // synchronous part of the state machine
   always @(posedge clk) begin
`ifdef SIM
      state_index <= state_index_next;
`endif
      state <= state_next;
      timeout_count <= timeout_next;

      if (RINIT || TSACK_clear)
	TSACK <= 0;
      else if (TSACK_set)
	TSACK <= 1;
      
      if (RINIT || TSYNC_clear)
	TSYNC <= 0;
      else if (TSYNC_set)
	TSYNC <= 1;
      
      if (RINIT || TWTBT_clear)
	TWTBT <= 0;
      else if (TWTBT_set)
	TWTBT <= 1;
      
      if (RINIT || TDIN_clear)
	TDIN <= 0;
      else if (TDIN_set)
	TDIN <= 1;
      
      if (RINIT || TDOUT_clear)
	TDOUT <= 0;
      else if (TDOUT_set)
	TDOUT <= 1;
      
      if (RINIT || DALbe_clear)
	DALbe <= 0;
      else if (DALbe_set)
	DALbe <= 1;
      
      if (RINIT || DALst_clear)
	DALst <= 0;
      else if (DALst_set)
	DALst <= 1;
      
      if (RINIT || assert_addr_clear)
	assert_addr <= 0;
      else if (assert_addr_set)
	assert_addr <= 1;
      
      if (RINIT || assert_data_clear)
	assert_data <= 0;
      else if (assert_data_set)
	assert_data <= 1;
      
      if (RINIT || bus_master_clear)
	bus_master <= 0;
      else if (bus_master_set)
	bus_master <= 1;
      
      end

endmodule // qmaster2908
