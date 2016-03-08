//	-*- mode: Verilog; fill-column: 96 -*-
//
// The QBUS Interrupt Protocol
//
// Copyright 2016 Noel Chiappa and David Bridgham

`include "qsic.vh"

// Manages the QBUS Interrupt Protocol
module qint
   (
    input 	     clk, // 20MHz

    // Configuration
    input [1:0]      int_priority,
   
    // The QBUS
    input 	     RINIT, 
    input 	     RDIN,
    input [4:7]      RIRQ,
    input 	     RIAKI,
    output reg [4:7] TIRQ,
    output 	     TIAKO,

    // Control Lines
    input 	     interrupt_request, // the device wants to interrupt the processor
    output 	     assert_vector	// assert our interrupt vector
   );

   reg 		     irq_higher,     // someone at higher priority is requesting an interrupt
		     interrupt_mine; // I won the interrupt arbitration

   reg 		     irql = 0;	// latched interrupt_request
   always @(posedge interrupt_request, posedge RINIT, posedge assert_vector)
     if (RINIT || assert_vector)
       irql <= 0;
     else
       irql <= 1;

   // If the device is requesting an interrupt, assert the appropriate bus interrupt request
   // line(s).  Once we're asserting the interrupt vector, it's time to remove the request (this
   // may end up being more properly handled by clearing the interrupt condition in the device).
   always @(*) begin
      TIRQ <= 0;		// default off

      if (irql && !assert_vector) begin
	 // IRQ4 is always asserted for those devices that only work on a single interrupt level
	 TIRQ[4] <= 1;
	 
	 case (int_priority)
	   `INTP_4: TIRQ[4] <= 1;
	   `INTP_5: TIRQ[5] <= 1;
	   `INTP_6: TIRQ[6] <= 1;
	   `INTP_7: begin
	      TIRQ[6] <= 1;	// Level 7 devices also assert IRQ6
	      TIRQ[7] <= 1;
	   end
	 endcase // case (int_priority)
      end
   end // always @ (irq_assert)

   // figure out if anyone at a higher priority is requesting an interrupt
   always @(*) begin
      case (int_priority)
	// Since level 7 devices always assert IRQ6 as well, level 4 and 5 devices don't have to
	// check IRQ7.
	`INTP_4: irq_higher <= RIRQ[5] | RIRQ[6];
	`INTP_5: irq_higher <= RIRQ[6];
	`INTP_6: irq_higher <= RIRQ[7];
	`INTP_7: irq_higher <= 0;
      endcase
   end // always @ begin

   // each time RDIN gets asserted, check if we're requesting an interrupt and if no-one of
   // higher priority is requesting one
   always @(posedge RDIN, posedge RINIT) begin
      if (RINIT)
	interrupt_mine <= 0;
      else if (irql && !irq_higher)
	// if we're asking for an interrupt and no-one higher is asking, then we win the
	// interrupt arbitration.
	interrupt_mine <= 1;
      else
	interrupt_mine <= 0;
   end
   
   // pass on the interrupt ack if we don't take it
   assign TIAKO = RIAKI & ~interrupt_mine;

   // if we've won the arbitration and IAKI comes along, then it's time to assert RPLY and put
   // our interrupt vector on the bus
   assign assert_vector = RIAKI & interrupt_mine;
   
endmodule // qint

