//	-*- mode: Verilog; fill-column: 96 -*-
//
// Bus Master logic - this is the logic that handles bus acquisition, managing the data
// transfers, and handing the bus back.  the actual data paths are elsewhere.
//
// Copyright 2015 Noel Chiappa and David Bridgham


module master
  (
   input      clk, // 20MHz clock to get right timing for QBUS

   // QBUS
   input      RSYNC,
   input      RRPLY,
   input      RDMR,
   input      RSACK,
   input      RINIT,
   input      RDMGI,
   output reg TSYNC,
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
   output reg latch_read_data,
   output reg nxm
   );

   // states of bus master (one-hot)
`ifdef SIM
   integer state_index;
`endif
   reg [0:12] state;
   localparam
     IDLE = 0,			// idle
     REQ = 1,			// requesting the bus
     ACQ = 2,			// acquired the bus, send address
     BEGIN = 3,			// addressing done, begin read or write
     READ = 4,			// starting a read cycle
     READ_DATA = 5,		// clock the read data in
     READ_DONE = 6,		// DIN off
     RPLY_CLEAR = 7,		// wait for RPLY to negate
     WRITE = 10,		// starting a write cycle

     RELEASE = 12;		// release the bus back to the processor
   
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
   
   always @(RINIT, posedge clk) begin
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
   always @(RINIT, posedge clk) begin
      timeout_count <= timeout_count - 1;
      state <= 0;
      if (RINIT) begin
	 set_state(IDLE);
	 TDMR <= 0;		// these are all latched
	 TSACK <= 0;
	 TSYNC <= 0;
	 TDIN <= 0;
	 TDOUT <= 0;
	 assert_addr <= 0;
	 assert_data <= 0;
	 latch_read_data <= 0;
	 nxm <= 0;
      end else begin
	 case (1'b1)
	   state[IDLE]:
	     begin
		nxm <= 0;
		if (dma_read || dma_write) begin
		   TDMR <= 1;
		   set_state(REQ);
		end else
		  set_state(IDLE);
	     end

	   state[REQ]:
	     // when we get grant-in, we're not passing grant-out, and sync and rply
	     // clear, then we own the bus
	     if (sRDMGI && !sTDMGO && !sRSYNC && !sRRPLY) begin
		TDMR <= 0;
		TSACK <= 1;
		assert_addr <= 1;
		timeout_count <= 2; // because RSYNC and RRPLY are synchronized, we've
				    // already waited at least two clock cycles to get
				    // here so only three more are needed for the 250ns
				    // minimum wait before asserting SYNC
		set_state(ACQ);
	     end else
	       set_state(REQ);

	   state[ACQ]:
	     if (timeout) begin
		TSYNC <= 1;
		timeout_count <= 1; // wait 100ns before removing addr
		set_state(BEGIN);
	     end else
	       set_state(ACQ);

	   state[BEGIN]:
	     if (timeout) begin
		assert_addr <= 0;
		if (dma_write) begin
		   assert_data <= 1;
		   set_state(WRITE);
		end else begin	// assume dma_read
		   TDIN <= 1;
		   timeout_count <= 200; // NXM timeout ~10us
		   set_state(READ);
		end
	     end else // if (timeout)
	       set_state(BEGIN);

	   state[READ]:
	     if (sRRPLY) begin	// wait for RPLY
		set_state(READ_DATA);	 // 100ns from RPLY because of synchronizer
	     end else if (timeout) begin // or wait for NXM
		TDIN <= 0;
		nxm <= 1;
		set_state(RELEASE);
	     end else
	       set_state(READ);

	   state[READ_DATA]:
	     begin
		latch_read_data <= 1; // 150ns from RPLY, won't be acted upon until next clock
		set_state(READ_DONE);
	     end

	   state[READ_DONE]:
	     begin
		TDIN <= 0;	// 200ns from RPLY
		latch_read_data <= 0;
		set_state(RPLY_CLEAR);
	     end

	   state[RPLY_CLEAR]:
	     if (!sRRPLY) begin	// wait for RPLY to be negated
		TSYNC <= 0;
		TSACK <= 0;
		set_state(IDLE); // we're done
	     end else
	       set_state(RPLY_CLEAR);
		
	 endcase
      end
   end
   

endmodule // master
