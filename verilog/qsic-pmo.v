//	-*- mode: Verilog; fill-column: 96 -*-
//
// The top-level module for the QSIC on the wire-wrapped prototype board with a ZTEX FPGA
// module.  The prototype board uses Am2908s for bus transceiver for all the Data/Address lines
// so there's a level of buffering there that needs to be considered.
//
// Copyright 2016-2018 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

`include "qsic.vh"

module pmo
  (
   input 	clk48, // 48 MHz clock from the ZTEX module

   // these LEDs on the debug board are on pins not being used for other things so they're open
   // for general use.  these need switches 5 and 6 turned on to enable the LEDs.
   output 	led_3_2, // D8
   output 	led_3_4, // D9
//   output 	led_3_6, // D10
//   output 	led_3_8, // D11
   output 	led_3_9, // C12
//   output 	led_3_10, // D12
   output 	tp_b30, // testpoint B30 (FPGA pin A11)
   
   // Interface to indicator panels
   output 	ip_clk,
   output 	ip_latch,
   output 	ip_out,

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
   output 	TDMGO,

   output 	sd0_sdclk,
   output 	sd0_sdcmd,
   inout [3:0] 	sd0_sddat
   );

   //
   // Wire up LEDs for testing
   //

   // blink some LEDs so we can see it's doing something

   // divide clock down to human visible speeds
   reg [23:0] 	count = 0;    
   always @(posedge clk20)
     count = count + 1;
        
   assign led_3_2 = count[21];
   assign led_3_4 = rk_match;
//   assign led_3_6 = 0;
//   assign led_3_8 = TSYNC;
   assign led_3_9 = sRDIN;
//   assign led_3_10 = TDMR;

   assign tp_b30 = ip_latch;

   //  get an approx 100kHz clock for the indicator panels
   wire 	clk100k = count[7];
   


   // Turn the 48MHz clock into a 20MHz clock that will be used as the general QBUS clock
   // throughout the QSIC
   wire 	clk20, reset, locked;
   assign reset = 0;
   clk_wiz_0 clk(clk20, reset, locked, clk48);

   // The direction of the bi-directional lines are controlled with DALtx
   // -- moved to below
   assign ZDAL = DALtx ? TDAL : 22'bZ;
   assign ZBS7 = DALtx ? 0 : 1'bZ;
   assign ZWTBT = DALtx ? rk_wtbt : 1'bZ;

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
   // Connect various devices
   //

   // synchronize RDMGI for the bus-grant chain
   reg [0:1] RDMGIsr;
   always @(posedge clk20) RDMGIsr <= { RDMGIsr[1], RDMGI };
   wire      sRDMGI = RDMGIsr[0];


   wire [15:0] RDL = ZDAL[15:0]; // Receive Data Lines
   reg [21:0]  TDAL;		 // Transmit Data/Address Lines

   reg 	       assert_vector = 0;

//`define SW_REG 1
`define RKV11 1
`define SD_CARD 1		// commenting this out switches over to a RAM Disk

`ifdef SW_REG
   reg [17:0]  sr_addr = 18'o777570;
   wire        sr_match;
   wire [15:0] sr_tdl;

   switch_register
     switch_register(clk20, addr_reg[12:0], bs7_reg, RDL, sr_tdl,
		     sr_addr, sr_match, assert_vector, sRDOUTpulse);
`endif

`ifdef RKV11
   wire        rk_match, rk_dma_read, rk_dma_write, rk_assert_addr, rk_assert_data, rk_read_pulse;
   wire        rk_bus_master, rk_dma_complete, rk_DALst, rk_DALbe, rk_nxm;
   wire        rk_wtbt, rk_irq, rk_assert_vector;
   wire [15:0] rk_tdl;
   wire [21:0] rk_tal;
   wire        rk_ip_latch;
   wire        rk_ip_out;

   // connection to the storage device
   reg [7:0]   sd_loaded = 8'h03; // "disk" loaded and ready
   reg [7:0]   sd_write_protect = 0; // the "disk" is write protected
   wire [2:0]  sd_dev_sel;	     // "disk" drive select
   wire [12:0] sd_lba;		     // linear block address
   wire        sd_read;		     // initiate a block read
   wire        sd_write;	     // initiate a block write
   wire        sd_cmd_ready;	     // selected disk is ready for a command
   wire [15:0] sd_write_data;
   wire        sd_write_enable;	  // enables writing data to the write FIFO
   wire        sd_write_full;	  // write FIFO is full
   wire [15:0] sd_read_data;
   wire        sd_read_enable;	  // enables reading data from the read FIFO
   wire        sd_read_empty;	  // no data in the read FIFO
   
   qmaster2908 
     rk_master(clk20, RSYNC, RRPLY, RDMR, RSACK, RINIT, RDMGI, sRDMGI, RREF,
	       TSYNC, rk_wtbt, TDIN, TDOUT, TDMR, TSACK, TDMGO,
	       rk_dma_read, rk_dma_write, rk_assert_addr, rk_assert_data, rk_read_pulse,
	       rk_bus_master, rk_dma_complete, rk_DALst, rk_DALbe, rk_nxm);

   qint rk_int(`INTP_4, RINIT, RDIN, 
 	       { RIRQ4, RIRQ5, RIRQ6, RIRQ7 }, RIAKI,
 	       { TIRQ4, TIRQ5, TIRQ6, TIRQ7 }, TIAKO,
	       rk_irq, rk_assert_vector);

   rkv11 rkv11(clk20, addr_reg[12:0], bs7_reg, rk_tal, RDL, rk_tdl, RINIT,
	       rk_match, rk_assert_vector, sRDOUTpulse, rk_read_pulse,
	       rk_dma_read, rk_dma_write, rk_bus_master, rk_dma_complete, rk_nxm, 
	       rk_irq, clk100k, rk_ip_latch, rk_ip_out,
	       sd_loaded, sd_write_protect, sd_dev_sel, sd_lba, sd_read, sd_write, 
	       sd_cmd_ready,
	       sd_write_data, sd_write_enable, sd_write_full,
	       sd_read_data, sd_read_enable, sd_read_empty);
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


`ifdef SD_CARD
   //
   // Interface an SD Card
   //

   wire sd0_read, sd0_write;
   wire [31:0] sd0_lba;
   wire [15:0] sd0_write_data;
   wire        sd0_write_data_enable;
   wire        sd0_dev_ready, sd0_cmd_ready, sd0_cd, sd0_v1, sd0_v2, sd0_SC, sd0_HC;
   wire [7:0]  sd0_err;
   wire [15:0] sd0_read_data;
   wire        sd0_read_data_enable;
   wire        sd0_fifo_clk;
   wire [35:0] sd0_debug;
   wire [7:0]  sd0_d8;
   SD_spi SD0(.clk(clk20), .reset(0), .device_ready(sd0_dev_ready), .cmd_ready(sd0_cmd_ready),
	      .read_cmd(sd0_read), .write_cmd(sd0_write),
	      .block_address(sd0_lba),
    	      .fifo_clk(sd0_fifo_clk),
	      .write_data(sd0_write_data),
	      .write_data_enable(sd0_write_data_enable),
	      .read_data(sd0_read_data),
	      .read_data_enable(sd0_read_data_enable),
 	      .sd_clk(sd0_sdclk), .sd_cmd(sd0_sdcmd), .sd_dat(sd0_sddat),
 	      .ip_cd(sd0_cd), .ip_v1(sd0_v1), .ip_v2(sd0_v2), .ip_SC(sd0_SC),
    	      .ip_HC(sd0_HC), .ip_err(sd0_err),
	      .ip_d8(sd0_d8), .ip_debug(sd0_debug));
   
   // Connections beween RK11 and SD card

   // This is where the drive number and block address from the RK11 is mapped to the SD card.
   // Eventually this mapping will be controlled by the pack load configuration. !!!
   //
   // The high 16 bits just offset the 8 RK05 disks into the SD card.  Largest values are:
   //  8GB: h00ff
   // 16GB: h01ff
   // 32GB: h03ff
   assign sd0_lba = { 16'h0002, sd_dev_sel, sd_lba };
//   assign sd_dev_ready = sd0_dev_ready;  // sd0_dev_ready needs to change sd_loaded[]
   assign sd_cmd_ready = sd0_cmd_ready;
   assign sd0_read = sd_read;
   assign sd0_write = sd_write;

   wire        sd0_read_full, sd0_read_rst_write_busy, sd0_read_rst_read_busy; // the SD card ignores these
   fifo_generator_0 sd_read_fifo
     (.rst(RINIT),
      .wr_clk(sd0_fifo_clk),
      .rd_clk(clk20),
      .din(sd0_read_data),
      .wr_en(sd0_read_data_enable),
      .rd_en(sd_read_enable),
      .dout(sd_read_data),
      .full(sd0_read_full),
      .empty(sd_read_empty),
      .wr_rst_busy(sd0_read_rst_write_busy),
      .rd_rst_busy(sd0_read_rst_read_busy));

   wire sd0_write_empty, sd0_write_rst_write_busy, sd0_write_rst_read_busy; // the SD card ignores these
   fifo_generator_0 sd_write_fifo
     (.rst(RINIT),
      .wr_clk(clk20),
      .rd_clk(sd0_fifo_clk),
      .din(sd_write_data),
      .wr_en(sd_write_enable),
      .rd_en(sd0_write_data_enable),
      .dout(sd0_write_data),
      .full(sd_write_full),
      .empty(sd0_write_empty),
      .wr_rst_busy(sd0_write_rst_write_busy),
      .rd_rst_busy(sd0_write_rst_read_busy));
   
`else  // RAM Disk
   //
   // Interface a Block RAM RAMdisk
   //
   wire        rd_read, rd_write, rd_cmd_ready;
   wire [31:0] rd_lba;
   wire [15:0] rd_write_data;
   wire        rd_write_data_enable;
   wire [15:0] rd_read_data;
   wire        rd_write_fifo_empty;
   wire        rd_read_data_enable;
   wire        rd_fifo_clk;
   wire [15:0] rd_debug;
   ramdisk_block #(.BLOCKS(2 * 12 * 32)) // 32 cylinders uses up most of the Block RAM I have
   RD (.clk(clk20), .reset(RINIT), .command_ready(rd_cmd_ready),
       .read_cmd(rd_read), .write_cmd(rd_write),
       .block_address(rd_lba),
       .fifo_clk(rd_fifo_clk),
       .write_data(rd_write_data),
       .write_data_enable(rd_write_data_enable),
       .write_fifo_empty(rd_write_fifo_empty),
       .read_data(rd_read_data),
       .read_data_enable(rd_read_data_enable),
       .debug(rd_debug));

   // Connect the RK11 to the RAM Disk

   assign rd_lba = { 19'b0, sd_lba };
   assign sd_cmd_ready = rd_cmd_ready;
   assign rd_read = sd_read;
   assign rd_write = sd_write;
   
   wire        rd_full;	// the RAM Disk ignores this
   fifo_generator_1 rd_read_fifo
     (.rst(RINIT),
      .wr_clk(rd_fifo_clk),
      .rd_clk(clk20),
      .din(rd_read_data),
      .wr_en(rd_read_data_enable),
      .rd_en(sd_read_enable),
      .dout(sd_read_data),
      .full(rd_full),
      .empty(sd_read_empty));

   fifo_generator_1 rd_write_fifo
     (.rst(RINIT),
      .wr_clk(clk20),
      .rd_clk(rd_fifo_clk),
      .din(sd_write_data),
      .wr_en(sd_write_enable),
      .rd_en(rd_write_data_enable),
      .dout(rd_write_data),
      .full(sd_write_full),
      .empty(rd_write_fifo_empty));

`endif // !`ifdef SD_CARD
   

   //
   // Indicator Panels
   //

   // panel driver (Are these inverted because I wired the PMo wrong? !!!)
   assign ip_latch = ~ip_done;
   assign ip_clk = ~clk100k;
   wire 	panel_out;
`define RKIP
`ifdef RKIP
   assign ip_out = ~rk_ip_out;
`else
   assign ip_out = ~panel_out;
`endif
   assign rk_ip_latch = ip_done;
   
   reg [7:0] 	ip_count = 0;
   reg 		ip_done = 0;
   always @(posedge clk100k) begin
      if (RINIT || ip_done) begin
	 ip_count <= -143;
	 ip_done <= 0;
      end else
	{ ip_done, ip_count } <= ip_count + 1;
   end
   
//`define LAMPTEST 1
   indicator
     qsic_ip(clk100k, ip_done, panel_out,
`ifdef LAMPTEST
	     { 36'o777_777_777_777 },
	     { 36'o777_777_777_777 },
	     { 36'o777_777_777_777 },
	     { 36'o777_777_777_777 }
`else
 `ifdef SD_CARD
	     { DALtx, 1'b0, ZDAL, 3'b0,
	       sd0_cd, sd0_v1, sd0_v2, sd0_SC, sd0_HC, sd0_dev_ready, sd0_read, sd0_write, 1'b0 },
	     { read_cycle, bs7_reg, addr_reg, 3'b0, 6'b0, rk_dma_read, rk_dma_write, 1'b0 },
 `else  // RAM Disk
	     { DALtx, 1'b0, ZDAL, rd_debug[11:0] },
	     { read_cycle, bs7_reg, addr_reg, 3'b0, 9'b0 },
 `endif
 `ifdef SD_CARD
	     { ZWTBT, ZBS7, RSYNC, RDIN, RDOUT, RRPLY, RREF, 1'b0, RIAKI, RIRQ7, RIRQ6, RIRQ5, RIRQ4,
	       1'b0, RSACK, RDMGI, RDMR, 1'b0, RINIT, 1'b0, RDCOK, RPOK, 14'b0 },
	     { DALtx & ZWTBT, DALtx & ZBS7, TSYNC, TDIN, TDOUT, TRPLY, TREF, 1'b0,
	       TIAKO, TIRQ7, TIRQ6, TIRQ5, TIRQ4, 1'b0, TSACK, TDMGO, TDMR,
	       10'b0, sd0_err, 1'b0 }
`else
	     { ZWTBT, ZBS7, RSYNC, RDIN, RDOUT, RRPLY, RREF, 1'b0, RIAKI, RIRQ7, RIRQ6, RIRQ5, RIRQ4,
	       1'b0, RSACK, RDMGI, RDMR, 1'b0, RINIT, 1'b0, RDCOK, RPOK, rd_debug[13:0] },
	     { DALtx & ZWTBT, DALtx & ZBS7, TSYNC, TDIN, TDOUT, TRPLY, TREF, 1'b0,
	       TIAKO, TIRQ7, TIRQ6, TIRQ5, TIRQ4, 1'b0, TSACK, TDMGO, TDMR, 1'b0, 
	       2'b0, rd_write_data }
`endif
`endif
	     );

endmodule // pmo
