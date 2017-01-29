//	-*- mode: Verilog; fill-column: 96 -*-
//
// Testbench for the QBUS Interrupt Controller
//
// Copyright 2016 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

`include "qsic.vh"

module tb_qint();
   
   // QBUS signals
   reg RINIT, RDIN, RIAKI;
   reg [4:7] RIRQ;
   wire      TIAKO;
   wire [4:7] TIRQ;

   // internal controls
   reg 	      interrupt_request;
   wire       assert_vector;

   
   reg 	       qclk = 1;
   always @(*)
     #25 qclk <= ~qclk;		// 20 MHz clock (50ns cycle time)

   // simulate an interrupt handler
   always @(*) begin
      if (TIRQ) begin
	 #75 RDIN <= 1;		// after latency, send DIN
	 #150 RIAKI <= 1;	// then ACK
      end else begin
	 #75 RDIN <= 0;		// and release the bus
	 #25 RIAKI <= 0;
      end
   end

   
   qint qint
     (qclk, `INTP_4, RINIT, RDIN, RIRQ, RIAKI, TIRQ, TIAKO,
      interrupt_request, assert_vector);

   initial begin
      $dumpfile("tb-qint.lxt");
      $dumpvars(0, tb_qint);

      // bus idle, no requests
      #0 { RINIT, RDIN, RIAKI } <= 0;
      RIRQ <= 0;
      interrupt_request <= 0;
      
      #100 RINIT <= 1;
      #100 RINIT <= 0;
      
      #100 interrupt_request <= 1;
      #20 interrupt_request <= 0;
      

      #1000 $finish_and_return(0);
   end

endmodule // tb_qm8


  
