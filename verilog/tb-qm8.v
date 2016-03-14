//	-*- mode: Verilog; fill-column: 96 -*-
//
// Testbench for the QBUS Master w/ Am2908s
//
// Copyright 2016 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns


module tb_qm8();
   
   // QBUS signals
   reg RSYNC, RRPLY, RDMR, RSACK, RINIT, RDMGI, RREF;
   wire TSYNC, TWTBT, TDIN, TDOUT, TDMR, TSACK,  TDMGO;
   

   // internal controls
   reg 	dma_read, dma_write;
   wire assert_addr, assert_data, bus_master, dma_complete, DALst, DALbe, nxm;

   reg 	       qclk = 1;
   always @(*)
     #25 qclk <= ~qclk;		// 20 MHz clock (50ns cycle time)

   // simulate a bus arbiter
   always @(TDMR) begin
      if (TDMR)
	#75 RDMGI <= 1;		// after DMA latency, give up the bus
      else
	#75 RDMGI <= 0;		// and release the bus
   end

   // simulate memory, just generates RRPLY
   always @(TDIN, TDOUT) begin
      if (TDIN || TDOUT)
	#75 RRPLY <= 1;
      else
	#75 RRPLY <= 0;
   end
   
   // simulate a bus master device
   reg write_request = 0, read_request = 0;
   always @(posedge qclk) begin
      if (RINIT) begin
	 dma_read <= 0;
	 dma_write <= 0;
      end else begin
	 if (write_request)
	   dma_write <= 1;
	 else if (assert_data)
	   dma_write <= 0;

	 if (read_request)
	   dma_read <= 1;
	 else if (dma_complete)
	   dma_read <= 0;
      end
   end

   // synchronize RDMGI
   reg [0:1] RDMGIsr;
   always @(posedge qclk) RDMGIsr <= { RDMGIsr[1], RDMGI };
   wire      sRDMGI = RDMGIsr[0];


   qmaster2908 qm
     (qclk, RSYNC, RRPLY, RDMR, RSACK, RINIT, RDMGI, sRDMGI, RREF,
      TSYNC, TWTBT, TDIN, TDOUT, TDMR, TSACK, TDMGO,
      dma_read, dma_write, assert_addr, assert_data,
      bus_master, dma_complete, DALst, DALbe, nxm);   

   initial begin
      $dumpfile("tb-qm8.lxt");
      $dumpvars(0, tb_qm8);

      // bus idle, no requests
      #0 { RSYNC, RRPLY, RDMR, RSACK, RINIT, RDMGI, RREF} = 0;

      #100 RINIT <= 1;
      #100 RINIT <= 0;
      
      #100 write_request <= 1;
      #100 write_request <= 0;

      while (!TSYNC)
	#1 write_request <= 0;
      while (TSYNC)
	#1 write_request <= 0;

      #100 read_request <= 1;
      #100 read_request <= 0;
      while (!TSYNC)
	#1 read_request <= 0;
      while (TSYNC)
	#1 read_request <= 0;

      #1200 $finish_and_return(0);
   end

endmodule // tb_qm8


  
