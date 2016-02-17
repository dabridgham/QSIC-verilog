//	-*- mode: Verilog; fill-column: 96 -*-
//
// The QBUS interface to device registers and interrupt control.
//
// Copyright 2015 Noel Chiappa and David Bridgham

`include "qsic.vh"

// Mediates between the asynchronous QBUS and the FPGA internal, synchronous operation of
// various I/O devices.  Handles data reads and writes from/to device registers.  Also runs the
// interrupt request protocol.
module qreg
  #(parameter
    RA_BITS = 3)		// how many bits are needed to address the device's registers
   (
    // Configuration
    input [12:0] 	     io_addr_base,
    input [1:0] 	     int_priority,

    input 		     clk, // 20MHz
   
    // The QBUS
    output 		     DALbe_L, // enable BDAL output onto the bus (active low)
    output 		     DALtx, // enable BDAL output through level-shifter
    output reg 		     DALst, // strobe data output to BDAL
    inout [21:0] 	     ZDAL,
    inout 		     ZBS7,
    inout 		     ZWTBT,
    input 		     RSYNC,
    input 		     RDIN,
    input 		     RDOUT,
    output 		     TRPLY,

    input [4:7] 	     RIRQ,
    input 		     RIAKI,
    output reg [4:7] 	     TIRQ,
    output 		     TIAKO,

    // to device registers
    output reg [RA_BITS-1:0] reg_addr, // the register address within the block
    output reg 		     addr_mine, // the address matches
    output reg 		     write_cycle,     // a strobe for writing
    output reg 		     read_cycle,      // a strobe for reading
    output reg 		     interrupt_cycle, // a strobe for interrupts
    output 		     assert_register, // assert the register value
    output 		     assert_vector    // assert our interrupt vector
   );


   //
   // Device Registers
   //

   reg write_flag;		// remember RWTBT during address phase
   assign assert_register = RSYNC & addr_mine & ~write_flag;

   // Asynchronously latch the addressing information whenever it comes along
   always @(posedge RSYNC) begin
      reg_addr <= ZDAL[RA_BITS:0];
      write_cycle <= ZWTBT;
      if (ZBS7 &&					      // I/O page
	  !ZDAL[0] &&					      // not an odd address
	  (ZDAL[12:RA_BITS+1] == io_addr_base[12:RA_BITS+1])) // address matches
	addr_mine <= 1;
      else
	addr_mine <= 0;
   end

   assign DALbe_L = ~((addr_mine & RDIN) | assert_vector);
   assign DALtx = assert_register | assert_vector;
   assign TRPLY = (addr_mine & (RDIN | RDOUT)) | assert_vector;

   // Synchronize RDIN and RDOUT to internal clock
   reg [1:0] DINra, DOUTra;
   always @(posedge clk) DINra <= { DINra[0], RDIN };
   always @(posedge clk) DOUTra <= { DOUTra[0], RDOUT };
   wire      sDIN = DINra[1];	// a synchronized version of RDIN
   wire      sDOUT = DOUTra[1];	// a synchronized version of RDOUT

   // Synchronously strobe the register data (which should be already sitting on ZDAL) into the
   // latch in the Am2908.  Since sDIN is synchronized with clk, it is delayed from RDIN by 1 to
   // 2 clock cycles (50 to 100 ns).  However, the QBUS spec says we have up to 125ns to put our
   // data on the bus after asserting RPLY so we don't have to delay RPLY any.
   always @(posedge clk) begin
      DALst <= 0;

      if (sDIN && addr_mine)
	DALst <= 1;
   end

   // Create the read strobe.  Reading is generally done a little more asynchronosly in that the
   // data is simply asserted on DAL from assert_register.  However, if something needs to react
   // to the read operation, it's easier to have a synchronized strobe signal.  This is also
   // used along with assert_vector to clear interrupt conditions.
   reg read_state = 0;
   always @(posedge clk) begin
      read_cycle <= 0;
      if (sDIN) begin
	 if (read_state == 0)
	   read_cycle <= 1;
	 read_state <= 1;
      end else
	read_state <= 0;
   end

   // Synchronously strobe the bus data into the device register.  The dance with write_state is
   // so write_cycle is only asserted for one clock cycle each time sDOUT cycles.  We assert
   // RPLY immediately on seeing RDOUT but since we have 175ns minimum from asserting RPLY until
   // R DATA goes away and sDOUT will percolate through in 1 or 2 clock cycles (50 to 100ns),
   // we're good.
   reg 	write_state = 0;
   always @(posedge clk) begin
      write_cycle <= 0;
      if (sDOUT) begin
	 if (write_state == 0)
	   write_cycle <= 1;
	 write_state <= 1;
      end else
	write_state <= 0;
   end

   
   //
   // Interrupt Arbitration
   //

   wire irq_assert; 		// requesting an interrupt
   reg 	irq_higher,		// someone at higher priority is requesting an interrupt
	interrupt_mine;		// I won the interrupt arbitration

   always @(*) begin
      TIRQ <= 0;
      if (irq_assert && !assert_vector) begin
	 // IRQ4 is always asserted for those devices that only work on a single interrupt level
	 TIRQ[4] <= 1;
	 
	 case (int_priority)
	   `INTP_4: TIRQ[4] <= 1;
	   `INTP_5: TIRQ[5] <= 1;
	   `INTP_6: TIRQ[6] <= 1;
	   `INTP_7: begin
	      TIRQ[6] <= 1;
	      TIRQ[7] <= 1;
	   end
	 endcase // case (int_priority)
      end
   end // always @ (irq_assert)

   always @(*) begin
      case (int_priority)
	// Since level 7 devices always assert IRQ6 as well, level 4 and 5 devices don't have to
	// check IRQ7.  But it's easy enough to do here so I do, just in case.
	`INTP_4: irq_higher <= RIRQ[5] | RIRQ[6] | RIRQ[7];
	`INTP_5: irq_higher <= RIRQ[6] | RIRQ[7];
	`INTP_6: irq_higher <= RIRQ[7];
	`INTP_7: irq_higher <= 0;
      endcase
   end // always @ begin

   // Oddly, to me, this only looks at RDIN.  That is, it does not consider RSYNC as well.  So
   // any DATI cycle will also set interrupt_mine if we're requesting an interrupt.  This ought
   // to work anyway but it would seem to decide the arbitration earlier than necessary or
   // desirable.
   wire interrupt_clear = RINIT | (~RDIN & ~RIAKI);
   always @(posedge RDIN, interrupt_clear) begin
      if (interrupt_clear)
	interrupt_mine <= 0;
      else if (irq_assert && !irq_higher)
	// if we're asking for an interrupt and no-one higher is asking, then we win the
	// interrupt arbitration.
	interrupt_mine <= 1;
   end
   
   // pass on the interrupt ack if we don't take it
   assign TIAKO = RIAKI & ~interrupt_mine;

   // if we've won the arbitration and IAKI comes along, then it's time to assert RPLY and put
   // our interrupt vector on the bus
   assign assert_vector = RIAKI & interrupt_mine;
   
   // Synchronize assert_vector to internal clock to generate interrupt_cycle
   reg [1:0] av_ra;
   always @(posedge clk) av_ra <= { av_ra[0], assert_vector };
   wire      sav = av_ra[1];	// a synchronized version of assert_vector

   reg 	int_state = 0;
   always @(posedge clk) begin
      interrupt_cycle <= 0;
      if (sDOUT) begin
	 if (int_state == 0)
	   interrupt_cycle <= 1;
	 int_state <= 1;
      end else
	int_state <= 0;
   end



endmodule // qsync
