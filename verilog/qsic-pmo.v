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
   input 	clk48_in, // 48 MHz clock from the ZTEX module

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
   output 	ip_clk_pin,
   output 	ip_latch_pin,
   output 	ip_out_pin,

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
   // Clocking
   //

   wire 	pll_fb, clk200, clk400, uiclk, clk48, clk20;
   
   BUFG fxclk_buf (
		   .I(clk48_in),
 		   .O(clk48) 
		   );
   
   PLLE2_BASE #(.BANDWIDTH("LOW"),
		.CLKFBOUT_MULT(25), // f_VCO = 1200 MHz (valid: 800 .. 1600 MHz)
		.CLKFBOUT_PHASE(0.0),
		.CLKIN1_PERIOD(0.0),
		.CLKOUT0_DIVIDE(3),    // 400 MHz, memory clock
		.CLKOUT1_DIVIDE(6),    // 200 MHz, reference clock
		.CLKOUT2_DIVIDE(60),   // 20MHz, QBUS clock
		.CLKOUT3_DIVIDE(1),    // unused
		.CLKOUT4_DIVIDE(1),    // unused
		.CLKOUT5_DIVIDE(1),    // unused
		.CLKOUT0_DUTY_CYCLE(0.5),
		.CLKOUT1_DUTY_CYCLE(0.5),
		.CLKOUT2_DUTY_CYCLE(0.5),
		.CLKOUT3_DUTY_CYCLE(0.5),
		.CLKOUT4_DUTY_CYCLE(0.5),
		.CLKOUT5_DUTY_CYCLE(0.5),
		.CLKOUT0_PHASE(0.0),
		.CLKOUT1_PHASE(0.0),
		.CLKOUT2_PHASE(0.0),
		.CLKOUT3_PHASE(0.0),
		.CLKOUT4_PHASE(0.0),
		.CLKOUT5_PHASE(0.0),
		.DIVCLK_DIVIDE(1),
		.REF_JITTER1(0.0),
      		.STARTUP_WAIT("FALSE")
		)
   pmo_pll_inst (.CLKIN1(clk48),   // 48 MHz input clock
      		 .CLKOUT0(clk400), // 400 MHz memory clock
      		 .CLKOUT1(clk200), // 200 MHz reference clock
      		 .CLKOUT2(clk20),   
      		 .CLKOUT3(),   
      		 .CLKOUT4(),
      		 .CLKOUT5(),   
      		 .CLKFBOUT(pll_fb),
      		 .CLKFBIN(pll_fb),
      		 .PWRDWN(1'b0),
      		 .RST(1'b0),
		 .LOCKED()
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
   
   // The direction of the bi-directional lines are controlled with DALtx
   // -- moved to below
   assign ZDAL = DALtx ? TDAL : 22'bZ;
   assign ZBS7 = DALtx ? 0 : 1'bZ;
   assign ZWTBT = DALtx ? rk_wtbt : 1'bZ;

   // all the QBUS signals that I'm not driving (yet)
   assign TREF = 0;

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

   // include these devices
//`define SW_REG 1
`define RKV11 1
`define SD0 1
//`define SD1 1
`define RAM_DISK 1

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
   wire        rk_ip_clk;
   wire        rk_ip_latch;
   wire        rk_ip_out;

   // connection to the storage device
   wire [7:0]  rk0_loaded;	     // "disk" loaded and ready
   reg [7:0]   rk0_write_protect = 0; // the "disk" is write protected
   wire [2:0]  rk0_dev_sel;	     // "disk" drive select
   wire [12:0] rk0_lba;		     // linear block address
   wire        rk0_read;	     // initiate a block read
   wire        rk0_write;	     // initiate a block write
   wire        rk0_cmd_ready;	     // selected disk is ready for a command
   wire [15:0] rk0_write_data;
   wire        rk0_write_enable;    // enables writing data to the write FIFO
   wire        rk0_write_fifo_full; // write FIFO is full
   wire [15:0] rk0_read_data;
   wire        rk0_read_enable;	    // enables reading data from the read FIFO
   wire        rk0_read_fifo_empty; // no data in the read FIFO
   wire        rk0_fifo_rst;	    // reset command to the FIFOs
   
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
	       rk_irq, rk_ip_clk, rk_ip_latch, rk_ip_out,
	       rk0_loaded, rk0_write_protect, rk0_dev_sel, rk0_lba, rk0_read, rk0_write, 
	       rk0_cmd_ready,
	       rk0_write_data, rk0_write_enable, rk0_write_fifo_full,
	       rk0_read_data, rk0_read_enable, rk0_read_fifo_empty, rk0_fifo_rst);

   // The FIFOs between RK0 and the Storage Devices
   wire [15:0] sd_write_data;
   wire [15:0] sd_read_data;
   wire        rk0_write_data_enable;
   wire        rk0_read_data_enable;
   wire        rk0_fifo_clk;
   wire        rk0_read_fifo_full, rk0_write_fifo_empty; // ignore
   fifo_generator_1 rk0_read_fifo
     (.rst(RINIT|rk0_fifo_rst),
      .wr_clk(rk0_fifo_clk),
      .rd_clk(clk20),
      .din(sd_read_data),
      .wr_en(rk0_read_data_enable),
      .rd_en(rk0_read_enable),
      .dout(rk0_read_data),
      .full(rk0_read_fifo_full),
      .empty(rk0_read_fifo_empty));

   fifo_generator_1 rk0_write_fifo
     (.rst(RINIT|rk0_fifo_rst),
      .wr_clk(clk20),
      .rd_clk(rk0_fifo_clk),
      .din(rk0_write_data),
      .wr_en(rk0_write_enable),
      .rd_en(rk0_write_data_enable),
      .dout(sd_write_data),
      .full(rk0_write_fifo_full),
      .empty(rk0_write_fifo_empty));

`endif

`define CONFIG_REG 1
`ifdef CONFIG_REG
   wire        conf_match = (bs7_reg && (addr_reg[12:0] == 13'o17720));
   always @(posedge clk20)
     if (sRDOUTpulse && conf_match) begin
	ip_list[0] <= RDL[1:0];
	ip_list[1] <= RDL[4:3];
	ip_list[2] <= RDL[7:6];
	ip_list[3] <= RDL[10:9];
	ip_count <= RDL[13:12];
     end
`endif
   

   // mix the control signals from the DMA controller(s) and the register controller
   assign DALbe_L = ~rwDALbe & ~rk_DALbe;  // ~(rwDALbe | rk_DALbe);
   assign DALst = rwDALst | rk_DALst;
   assign DALtx = rwDALtx | rk_assert_addr | rk_assert_data;

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
`ifdef CONFIG_REG
	      conf_match: begin
		 addr_match = 1;
		 TDAL = { 6'b0, 2'b0, ip_count, 1'b0, ip_list[3], 1'b0, ip_list[2], 1'b0, ip_list[1], 1'b0, ip_list[0] };
	      end
`endif
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
   // Interface an SD Card
   //
   wire [31:0] LBA;		// Linear Block Address

`ifdef SD0
   wire        sd0_read, sd0_write;
   wire [31:0] sd0_lba = LBA;
   wire        sd0_write_data_enable;
   wire        sd0_dev_ready, sd0_cmd_ready, sd0_cd, sd0_v1, sd0_v2, sd0_SC, sd0_HC;
   wire [7:0]  sd0_err;
   wire [15:0] sd0_read_data;
   wire        sd0_read_data_enable;
   wire        sd0_fifo_clk;
   wire [7:0]  sd0_d8;
   SD_spi SD0(.clk(clk20), .reset(0), .device_ready(sd0_dev_ready), .cmd_ready(sd0_cmd_ready),
	      .read_cmd(sd0_read), .write_cmd(sd0_write),
	      .block_address(sd0_lba),
    	      .fifo_clk(sd0_fifo_clk),
	      .write_data(sd_write_data),
	      .write_data_enable(sd0_write_data_enable),
	      .read_data(sd0_read_data),
	      .read_data_enable(sd0_read_data_enable),
 	      .sd_clk(sd0_sdclk), .sd_cmd(sd0_sdcmd), .sd_dat(sd0_sddat),
 	      .ip_cd(sd0_cd), .ip_v1(sd0_v1), .ip_v2(sd0_v2), .ip_SC(sd0_SC),
    	      .ip_HC(sd0_HC), .ip_err(sd0_err),
	      .ip_d8(sd0_d8));
`else
   reg 	       sd0_dev_ready = 0;
   reg 	       sd0_cmd_ready = 0;
   reg 	       sd0_fifo_clk = 0;
   reg 	       sd0_write_data_enable = 0;
   reg 	       sd0_read_data_enable = 0;
   reg [15:0]  sd0_read_data = 0;
   wire        sd0_read, sd0_write;

   reg 	       sd0_cd = 0;	// for the indicator panel
   reg 	       sd0_v1 = 0;
   reg 	       sd0_v2 = 0;
   reg 	       sd0_SC = 0;
   reg 	       sd0_HC = 0;
   reg [7:0]   sd0_err = 0;
`endif   

   
   
   //
   // Interface a Block RAM RAMdisk
   //
`ifdef RAM_DISK
   reg 	       rd_dev_ready = 1;
   wire        rd_read, rd_write, rd_cmd_ready;
   wire [31:0] rd_lba = LBA;
   wire [15:0] rd_read_data;
   wire        rd_write_data_enable;
   wire        rd_read_data_enable;
   wire        rd_fifo_clk;
   wire [15:0] rd_debug;
   ramdisk_block #(.BLOCKS(2 * 12 * 32)) // 32 cylinders uses up most of the Block RAM I have
   RD (.clk(clk20), .reset(RINIT), .command_ready(rd_cmd_ready),
       .read_cmd(rd_read), .write_cmd(rd_write),
       .block_address(rd_lba),
       .fifo_clk(rd_fifo_clk),
       .write_data(sd_write_data),
       .write_data_enable(rd_write_data_enable),
       .read_data(rd_read_data),
       .read_data_enable(rd_read_data_enable));
`else // !`ifdef RAM_DISK
   reg 	       rd_dev_ready = 0;
   reg 	       rd_cmd_ready = 0;
   reg 	       rd_fifo_clk = 0;
   reg 	       rd_write_data_enable = 0;
   reg 	       rd_read_data_enable = 0;
   reg [15:0]  rd_read_data = 0;
   wire        rd_read, rd_write;
`endif
   
   // SD1 and USB devices aren't implemented yet so just stub out the signals
   reg 	       sd1_dev_ready = 0;
   reg 	       sd1_cmd_ready = 0;
   reg 	       sd1_fifo_clk = 0;
   reg 	       sd1_write_data_enable = 0;
   reg 	       sd1_read_data_enable = 0;
   reg [15:0]  sd1_read_data = 0;
   wire        sd1_read, sd1_write;

   reg 	       usb_dev_ready = 0;
   reg 	       usb_cmd_ready = 0;
   reg 	       usb_fifo_clk = 0;
   reg 	       usb_write_data_enable = 0;
   reg 	       usb_read_data_enable = 0;
   reg [15:0]  usb_read_data = 0;
   wire        usb_read, usb_write;
   


   //
   // Load Table - Just a start for now and needs to be configurable at runtime !!!
   //

   // The largest offset values (less the size of the disk pack) are:
   //  8GB: h0100_0000
   // 16GB: h0200_0000
   // 32GB: h0400_0000
   //
   // Disk Pack Sizes:
   // RK05: h0200 (rounded up)
`define pack_enable 1'b1
`define pack_disable 1'b0
`define pack_sd0 2'o0
`define pack_sd1 2'o1
`define pack_ramdisk 2'o2
`define pack_usb 2'o3
   // { Enable, Storage Device, LBA Offset }
   reg [34:0]  rk0_load_table [0:7] 
     = {
`ifdef SD0
	{ `pack_enable, `pack_sd0, 32'h0002_0000 },
 `ifdef RAM_DISK
	{ `pack_enable, `pack_ramdisk, 32'h0000_0000 },
 `else
	{ `pack_enable, `pack_sd0, 32'h0002_2000 },
 `endif
`else
	{ `pack_enable, `pack_ramdisk, 32'h0000_0000 },
	{ `pack_disable, `pack_sd0, 32'h0002_2000 },
`endif
	{ `pack_disable, `pack_sd0, 32'h0002_4000 },
	{ `pack_disable, `pack_sd0, 32'h0002_6000 },
	{ `pack_disable, `pack_sd0, 32'h0002_8000 },
	{ `pack_disable, `pack_sd0, 32'h0002_a000 },
	{ `pack_disable, `pack_sd0, 32'h0002_c000 },
	{ `pack_disable, `pack_sd0, 32'h0002_e000 }
	};
   wire        pack_enable = rk0_load_table[rk0_dev_sel][34];
   wire [1:0]  pack_sd_select = rk0_load_table[rk0_dev_sel][33:32];
   wire [31:0] pack_offset = rk0_load_table[rk0_dev_sel][31:0];
   
   assign LBA = rk0_lba + pack_offset; // offset into the selected disk pack

   // Build the Loaded table - if a pack is loaded and the associated device is ready
   wire [0:3]   sd_ready = { sd0_dev_ready, sd0_dev_ready, rd_dev_ready, usb_dev_ready };
   genvar      i;
   for (i=0; i<8; i=i+1)
     assign rk0_loaded[i] = rk0_load_table[i][34] & sd_ready[rk0_load_table[i][33:32]];


   //
   // Link the Disk Controller to the Storage Devices
   //

   sdmux rk0_sdmux(.command_ready(rk0_cmd_ready),
    		   .read_cmd(rk0_read),
		   .write_cmd(rk0_write),
		   .fifo_clk(rk0_fifo_clk), 
		   .write_data_enable(rk0_write_data_enable),
		   .read_data(sd_read_data),
		   .read_data_enable(rk0_read_data_enable),
		   .sd_select(pack_sd_select), // selects which Storage Device to use
		   // Storage Devices
    		   .sd_command_ready({ sd0_cmd_ready, sd1_cmd_ready, rd_cmd_ready, usb_cmd_ready }),
		   .sd_read_cmd({ sd0_read, sd1_read, rd_read, usb_read }),
		   .sd_write_cmd({ sd0_write, sd1_write, rd_write, usb_write }),
 		   .sd_fifo_clk({ sd0_fifo_clk, sd1_fifo_clk, rd_fifo_clk, usb_fifo_clk }),
		   .sd_write_data_enable({ sd0_write_data_enable, sd1_write_data_enable,
					   rd_write_data_enable, usb_write_data_enable }),
		   .sd_read_data_enable({ sd0_read_data_enable, sd1_read_data_enable,
					  rd_read_data_enable, usb_read_data_enable }),
		   // read data lines
		   .sd0_read_data(sd0_read_data),
		   .sd1_read_data(sd1_read_data),
		   .sd2_read_data(rd_read_data),
		   .sd3_read_data(usb_read_data));


   //
   // Indicator Panels
   //

   // QSIC/QBUS Indicator Panel
   wire qsic_latch, qsic_clk, qsic_out;
   indicator
     qsic_ip(qsic_clk, qsic_latch, qsic_out,
	     { DALtx, 1'b0, ZDAL, 3'b0,
	       sd0_cd, sd0_v1, sd0_v2, sd0_SC, sd0_HC, sd0_dev_ready, sd0_read, sd0_write, 1'b0 },
	     { read_cycle, bs7_reg, addr_reg, 3'b0, 6'b0, rk_dma_read, rk_dma_write, 1'b0 },
	     { ZWTBT, ZBS7, RSYNC, RDIN, RDOUT, RRPLY, RREF, 1'b0, RIAKI, RIRQ7, RIRQ6, RIRQ5, RIRQ4,
	       1'b0, RSACK, RDMGI, RDMR, 1'b0, RINIT, 1'b0, RDCOK, RPOK, 14'b0 },
	     { DALtx & ZWTBT, DALtx & ZBS7, TSYNC, TDIN, TDOUT, TRPLY, TREF, 1'b0,
	       TIAKO, TIRQ7, TIRQ6, TIRQ5, TIRQ4, 1'b0, TSACK, TDMGO, TDMR,
	       10'b0, sd0_err, 1'b0 });

   // Lamptest Indicator Panel - turn on all the lights
   wire lt_latch, lt_clk, lt_out;
   indicator
     lamptest(lt_clk, lt_latch, lt_out,
	      { 36'o777_777_777_777 },
	      { 36'o777_777_777_777 },
	      { 36'o777_777_777_777 },
	      { 36'o777_777_777_777 });


   // The configuration for what indicator panels to display
   reg [1:0] ip_count = 2;
   reg [1:0] ip_list [0:3] = { 2, 1, 0, 1 };
   wire [1:0] ip_step;
   wire ip_enable;		// this will get wired to an output pin once I make the move to
				// the v2 indicator panels !!!
   wire ip3_clk, ip3_latch, ip3_out; // unused
   wire ip_clk, ip_out, ip_latch;
   ip_mux #(.SEL_WIDTH(2), .COUNT_WIDTH(3))
   ip_mux (.clk_in(clk100k),
	   // connect to the external indicator panels
    	   .clk_out(ip_clk),
	   .data(ip_out),
	   .latch(ip_latch),
	   .enable(ip_enable), 
	   // connect to the config RAM
	   .ip_count(ip_count),
	   .ip_step(ip_step),
	   .ip_sel(ip_list[ip_step]),
	   // connections to the internal indicator panels
	   // 0 = lamptest
	   // 1 = QBUS
	   // 2 = RK12
	   // 3 = RP12 (once I implement it)
	   .ip_clk({ lt_clk, qsic_clk, rk_ip_clk, ip3_clk }),
	   .ip_latch({ lt_latch, qsic_latch, rk_ip_latch, ip3_latch }),
	   .ip_data({ lt_out, qsic_out, rk_ip_out, ip3_out }));

   // not entirely sure why these have to be inverted.  I must have wired the PMo wrong. !!!
   assign ip_clk_pin = ~ip_clk;
   assign ip_out_pin = ~ip_out;
   assign ip_latch_pin = ~ip_latch;

endmodule // pmo
