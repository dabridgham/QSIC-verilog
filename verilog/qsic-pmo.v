//	-*- mode: Verilog; fill-column: 96 -*-
//
// The top-level module for the QSIC on the wire-wrapped prototype board with a ZTEX FPGA
// module.  The prototype board uses Am2908s for bus transceiver for all the Data/Address lines
// so there's a level of buffering there that needs to be considered.
//
// Copyright 2016-2020 Noel Chiappa and David Bridgham

`timescale 1 ns / 1 ns

`include "qsic.vh"

`define FPGA_MAJOR 8'd0		// Major Version number for the FPGA load
`define FPGA_MINOR 8'd0		// Minor Version number for the FPGA load
`define FPGA_DEV 1'b1		// set to 1 if this is development code, 0 for release
`define SOFT_DEV 1'b1		// set to 1 if this is development code, 0 for release (set by the Soft-11 !!!)

module pmo
  (
   input 	 clk48_in, // 48 MHz clock from the ZTEX module

   // these LEDs on the debug board are on pins not being used for other things so they're open
   // for general use.  these need switches 5 and 6 turned on to enable the LEDs.
   output 	 led_3_2, // D8
   output 	 led_3_4, // D9
//   output 	led_3_6, // D10
//   output 	led_3_8, // D11
   output 	 led_3_9, // C12
//   output 	led_3_10, // D12
   output 	 tp_b30, // testpoint B30 (FPGA pin A11)
   
   // Interface to indicator panels
   output 	 ip_clk_pin,
   output 	 ip_latch_pin,
   output 	 ip_out_pin,

   // The QBUS signals as seen by the FPGA
   output 	 DALbe_L, // Enable transmitting on BDAL (active low)
   output 	 DALtx, // set level-shifters to output and disable input from Am2908s
   output 	 DALst, // latch the BDAL output
   inout [21:0]  ZDAL,
   inout 	 ZBS7,
   inout 	 ZWTBT,

   input 	 RSYNC,
   input 	 RDIN,
   input 	 RDOUT,
   input 	 RRPLY,
   input 	 RREF, // option for DMA block-mode when acting as memory
   input 	 RIRQ4,
   input 	 RIRQ5,
   input 	 RIRQ6,
   input 	 RIRQ7,
   input 	 RDMR,
   input 	 RSACK,
   input 	 RINIT,
   input 	 RIAKI,
   input 	 RDMGI,
   input 	 RDCOK,
   input 	 RPOK,

   output 	 TSYNC,
   output 	 TDIN,
   output 	 TDOUT,
   output 	 TRPLY,
   output 	 TREF,
   output 	 TIRQ4,
   output 	 TIRQ5,
   output 	 TIRQ6,
   output 	 TIRQ7,
   output 	 TDMR,
   output 	 TSACK,
   output 	 TIAKO,
   output 	 TDMGO,

   output 	 sd0_sdclk,
   output 	 sd0_sdcmd,
   inout [3:0] 	 sd0_sddat,

   // Memory interface ports
   output [13:0] ddr3_addr,
   output [2:0]  ddr3_ba,
   output 	 ddr3_cas_n,
   output [0:0]  ddr3_ck_n,
   output [0:0]  ddr3_ck_p,
   output [0:0]  ddr3_cke,
   output 	 ddr3_ras_n,
   output 	 ddr3_reset_n,
   output 	 ddr3_we_n,
   inout [15:0]  ddr3_dq,
   inout [1:0] 	 ddr3_dqs_n,
   inout [1:0] 	 ddr3_dqs_p,
   output [1:0]  ddr3_dm,
   output [0:0]  ddr3_odt
   );


   // all the QBUS signals that I'm not driving (yet)
   assign TREF = 0;		// will drive when we implement memory !!!


   //
   // Clocking
   //

   wire 	pll_fb, clk200, clk400, clk48, clk20;
   
   BUFG fxclk_buf (.I(clk48_in),
 		   .O(clk48));
   
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
   assign led_3_4 = count[22];
   
//   assign led_3_6 = 0;
//   assign led_3_8 = TSYNC;
   assign led_3_9 = count[21]; // sRDIN;
//   assign led_3_10 = TDMR;

   assign tp_b30 = ip_latch;

   //  get an approx 100kHz clock for the indicator panels
   wire 	clk100k = count[7];


   // The main RESET signal
   wire 	reset = RINIT || !RDCOK;
   
   // Need to be declared early
   wire [21:0] 	reg_addr;	// bus address
   wire 	reg_bs7;	// I/O page
   wire [15:0] 	reg_wdata;	// write data to bus registers
   wire 	reg_write;	// write strobe for writing data to bus registers
   wire 	conf_write;	// write strobe for writing data to conf registers

   // Wire in an RP11-D
   wire [15:0] 	rp0_caddr, rp0_crdata, rp0_rdata;
   wire 	rp0_caddr_match;
   wire 	rp0_ip_clk, rp0_ip_latch, rp0_ip_out;
   wire 	rp0_irq;
   wire [1:0] 	rp0_int_pri;
 	
   rp11d #(.ENABLED(1), .Q22(1), .CONF_ADDR(20), .UNIT(0), 
	   .ADDR_BASE('o17_700), .INT_PRI(`INTP_5), .INT_VEC('o254))
   rp0 (.clk(clk20), .reset(reset),
	// Config Bus
	.c_addr(rp0_caddr), .c_wdata(reg_wdata), .c_rdata(rp0_crdata), .c_addr_match(rp0_caddr_match), 
	.c_write(conf_write), .c_int_pri(rp0_int_pri),
	// the Bus
	.b_addr(reg_addr[12:0]), .b_iopag(reg_bs7), .b_wdata(reg_wdata), .b_rdata(rp0_rdata),
	
	// control lines
	.addr_match(addr_match), .assert_vector(assert_vector), .write_pulse(write_pulse), .dma_read_pulse(dma_read_pulse),
	.dma_read_req(dma_read_req), .dma_write_req(dma_write_req), .dma_bus_master(dma_bus_master),
	.dma_complete(dma_complete), .dma_nxm(dma_nxm), .interrupt_request(rp0_irq), 

	// indicator panel
	.ip_clk(rp0_ip_clk), .ip_latch(rp0_ip_latch), .ip_out(rp0_ip_out), 

	// connection to the storage device
	// All this is slated to change !!!
	.sd_loaded(sd_loaded), .sd_write_protect(sd_write_protect), .sd_dev_sel(sd_dev_sel), .sd_lba(sd_lba), .sd_read(sd_read),
	.sd_write(sd_write), .sd_ready_u(sd_ready_u), .sd_write_data(sd_write_data), .sd_write_enable(sd_write_enable),
	.sd_write_full(sd_write_full), .sd_read_data(sd_read_data), .sd_read_enable(sd_read_enable), .sd_read_empty(sd_read_empty),
	.sd_fifo_rst(sd_fifo_rst));


   // The Configuration Registers Controler
   wire 	reg_read_cycle;
   wire [15:0] 	cr_rdata, conf_addr;
   reg 		tl_match, ip_caddr_match;
   reg [15:0] 	tl_rdata, ip_crdata;
   conf #(.ADDR_BASE(`CONF_REG_ADDR_BASE))
   conf (.clk(clk20),
	 // to the register controller
	 .reg_addr(reg_addr[12:0]), .reg_bs7(reg_bs7), .reg_addr_match(cr_match),
	 .reg_rdata(cr_rdata), .reg_wdata(reg_wdata), .reg_write(reg_write),
	 // to the configuration bus
	 .conf_addr(conf_addr), .conf_write(conf_write),
	 // to configuration sources
	 .tl_match(tl_match), .tl_rdata(tl_rdata),
	 .dev0_match(ip_caddr_match), .dev0_rdata(ip_crdata), // Indicator Panel config
	 .dev1_match(rp0_caddr_match), .dev1_rdata(rp0_crdata),	// RP0 config
	 .dev2_match(0), .dev2_rdata(0), // add more devices here !!!
	 .dev3_match(0), .dev3_rdata(0));
   
   // The Bus Register Controller
   wire 	reg_addr_match;
   wire [15:0] 	reg_rdata;
   rctrl rctrl(.reg_addr_match(reg_addr_match), .reg_rdata(reg_rdata),
	       .c_match(cr_match), .c_rdata(cr_rdata), // configuration bus control registers
	       .dev0_match(rp0_addr_match), .dev0_rdata(rp0_brdata), // RP0
	       .dev1_match(0), .dev1_rdata(0), // add more devices here !!!
	       .dev2_match(0), .dev2_rdata(0),
	       .dev3_match(0), .dev3_rdata(0));

   // The QBUS Controller
   qctl_2908 qctl(.clk(clk20), .reset(reset),
		  .DALbe_L(DALbe_L), .DALtx(DALtx), .DALst(DALst), .ZDAL(ZDAL), .ZBS7(ZBS7), .ZWTBT(ZWTBT),
		  .RSYNC(RSYNC), .RDIN(RDIN), .RDOUT(RDOUT), .TRPLY(TRPLY),
 		  .dma_assert_dal(dma_assert_dal), .dma_dal(dma_dal), .dma_dalbe(dma_dalbe), 
		  .dma_daltx(dma_daltx), .dma_dalst(dma_dalst), .int_assert_vector(int_assert_vector),
		  .reg_addr(reg_addr), .reg_bs7(reg_bs7), .reg_read_cycle(reg_read_cycle), 
		  .reg_addr_match(reg_addr_match), .reg_rdata(reg_rdata), .reg_wdata(reg_wdata), .reg_write(reg_write) );




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

   // Which devices to include
//`define SW_REG 1
`define RP0 1			// doesn't do anything yet!!!
//`define RKV11 1
//`define SD0 1
//`define SD1 1
`define RAM_DISK 1
`define SDRAM 1

`ifdef SW_REG
   reg [17:0]  sr_addr = 18'o777570;
   wire        sr_match;
   wire [15:0] sr_tdl;

   switch_register
     switch_register(clk20, addr_reg[12:0], bs7_reg, RDL, sr_tdl,
		     sr_addr, sr_match, assert_vector, sRDOUTpulse);
`endif


   // These are declared here just to stub them out for now !!!
   reg	       sd0_cd = 0;
   reg	       sd0_v2 = 0;
   reg	       sd0_HC = 0;
   reg [5:0]   sd0_size = 0;
   wire	       sd0_rdy, sd0_rd, sd0_wr;
   wire [3:0]  sd0_err;
   


   //
   // Indicator Panels
   //

   // IP Config
   reg [3:0] ip_count;			  // How many indicator panels are active
   reg [3:0] ip1, ip2, ip3, ip4, ip5, ip6, ip7; // the type of each indicator panel

   // Read the IP Config registers
   localparam IP_CONF_ADDR = 11'd18;
   always @(*) begin
      ip_caddr_match = 1;
      ip_crdata = 16'bx;
      case (conf_addr)
	IP_CONF_ADDR: ip_crdata = { ip_count, ip1, ip2, ip3 };
	IP_CONF_ADDR+1: ip_crdata = { ip4, ip5, ip6, ip7 };
	default: ip_caddr_match = 0;
      endcase // case (conf_addr)
   end

   // Write the IP Config registers
   always @(posedge clk20)
     if (ip_caddr_match && conf_write)
       case (conf_addr)
	 IP_CONF_ADDR: { ip_count, ip1, ip2, ip3 } <= reg_wdata;
	 IP_CONF_ADDR+1: { ip4, ip5, ip6, ip7 } <= reg_wdata;
       endcase // case (conf_addr)

   // QSIC/QBUS Indicator Panel
   wire qsic_latch, qsic_clk, qsic_out;
   indicator
     qsic_ip(qsic_clk, qsic_latch, qsic_out,
	     { DALtx, 1'b0, ZDAL, 3'b0,
	       sd0_cd, sd0_v1, sd0_v2, sd0_SC, sd0_HC, sd0_rdy, sd0_rd, sd0_wr, 1'b0 },
	     { read_cycle, bs7_reg, addr_reg, 3'b0, 6'b0, rk_dma_read, rk_dma_write, 1'b0 },
	     { ZWTBT, ZBS7, RSYNC, RDIN, RDOUT, RRPLY, RREF, 1'b0, RIAKI, RIRQ7, RIRQ6, RIRQ5, RIRQ4,
	       1'b0, RSACK, RDMGI, RDMR, 1'b0, RINIT, 1'b0, RDCOK, RPOK, 14'b0 },
	     { DALtx & ZWTBT, DALtx & ZBS7, TSYNC, TDIN, TDOUT, TRPLY, TREF, 1'b0,
	       TIAKO, TIRQ7, TIRQ6, TIRQ5, TIRQ4, 1'b0, TSACK, TDMGO, TDMR,
	       rd_debug, sd0_err, 1'b0 });

   // Lamptest Indicator Panel - turn on all the lights
   wire lt_latch, lt_clk, lt_out;
   indicator
     lamptest(lt_clk, lt_latch, lt_out,
	      { 36'o777_777_777_777 },
	      { 36'o777_777_777_777 },
	      { 36'o777_777_777_777 },
	      { 36'o777_777_777_777 });


   // Debugging Indicator Panel - gets changed as I feel like it for debugging
   wire db_latch, db_clk, db_out;
   indicator
     debug_ip(db_clk, db_latch, db_out,
	      { 36'o623_623_623_623 },
	      { 36'o623_623_623_623 },
	      { 36'o623_623_623_623 },
	      { 36'o623_623_623_623 });

   // eventually these will be initilized by the soft-11 rather than statically !!!
   initial begin
      ip_count = 2;
      ip1 = 4;
      ip2 = 1;
      ip3 = 0;
      ip4 = 1;
      ip5 = 0;
      ip6 = 0;
      ip7 = 0;
   end
   reg [3:0] ip_sel;		// width here is SEL_WIDTH-1 for ip_mux()
   wire [3:0] ip_step;
   // ip_sel selects which indicator panel we're viewing
   always @(*) begin
      case (ip_step)
	0: ip_sel = ip1;
	1: ip_sel = ip2;
	2: ip_sel = ip3;
	3: ip_sel = ip4;
	4: ip_sel = ip5;
	5: ip_sel = ip6;
	6: ip_sel = ip7;
	default: ip_sel = 0;	// lamptest is as good as any
      endcase // case (ip_step)
   end // always @ (*)
   
   wire ip_enable;		// this will get wired to an output pin once I make the move to
				// the v2 indicator panels !!!
   wire ip_clk, ip_out, ip_latch;
   ip_mux #(.SEL_WIDTH(4), .COUNT_WIDTH(3))
   ip_mux (.clk_in(clk100k),
	   // connect to the external indicator panels
    	   .clk_out(ip_clk),
	   .data(ip_out),
	   .latch(ip_latch),
	   .enable(ip_enable), 
	   // connect to the config registers
	   .ip_count(ip_count),
	   .ip_step(ip_step),
	   .ip_sel(ip_sel),
	   // connections to the internal indicator panels
	   // 0 = lamptest
	   // 1 = QBUS monitor
	   // 2 = RK11 #0
	   // 3 = RK11 #1
	   // 4 = RP11 #0
	   // 5 = RP11 #1
	   // 6 = Enable+
	   // 7 = Interlan 1010
	   // 15 = debugging
	   .ip_clk({ lt_clk, qsic_clk, lt_clk, lt_clk, rp0_ip_clk, lt_clk, lt_clk, lt_clk,
		     lt_clk, lt_clk, lt_clk, lt_clk, lt_clk, lt_clk, lt_clk, db_clk }),
	   .ip_latch({ lt_latch, qsic_latch, lt_latch, lt_latch, rp0_ip_latch, lt_latch, lt_latch, lt_latch,
		       lt_latch, lt_latch, lt_latch, lt_latch, lt_latch, lt_latch, lt_latch, db_latch }),
	   .ip_data({ lt_out, qsic_out, lt_out, lt_out, rp0_ip_out, lt_out, lt_out, lt_out,
		      lt_out, lt_out, lt_out, lt_out, lt_out, lt_out, lt_out, db_out }));

   // not entirely sure why these have to be inverted.  I must have wired the PMo wrong. !!!
   assign ip_clk_pin = ~ip_clk;
   assign ip_out_pin = ~ip_out;
   assign ip_latch_pin = ~ip_latch;


   //
   // Top-Level Configuration Table
   //

   // Read Mux
   // The Soft-11 version number and the `SOFT_DEV bit want to be set by the Soft-11 itself. !!!
   always @(*) begin
      tl_match = 1;
      tl_rdata = 16'bx;
      case (conf_addr)
	0: tl_rdata = { `TYPE_QSIC, `FPGA_DEV, `SOFT_DEV, 8'b0, `CONF_VERSION };
	1: tl_rdata = { `FPGA_MAJOR, `FPGA_MINOR }; // FPGA Version
	2: tl_rdata = { 8'd0, 8'd0 };		    // Soft-11 Software Version
	3: tl_rdata = { 8'd2, 8'd2 };		    // Controller Count ,, Storage Device Count
	// Controller Table
	4: tl_rdata = { `CTR_IP, IP_CONF_ADDR };
	5: tl_rdata = { `CTR_RP, 11'd20 };
	// Storage Device Table
	6: tl_rdata = { `SD_SD, 11'd10 };
	7: tl_rdata = { `SD_RAM, 11'd11 };
	// Storage Devices
	10: tl_rdata = { sd0_cd, sd0_v2, sd0_HC, sd0_rdy, sd0_rd, sd0_wr, sd0_err, sd0_size }; // SD0 -- need size!!!
	11: tl_rdata = 19;	// RAM Disk -- 256MB = 2^28 bytes = 2^19 blocks

	default: tl_match = 0;
      endcase // case (conf_addr)
   end // always @ (*)
   
   // Writing Configuration -- Nothing is writable yet in the top-level configuration.  The only
   // thing that's going to be writable is the SAVE bit in location 0 that kicks the soft-11 to
   // save the current configuration in flash. !!!
   reg conf_save = 0;
   always @(posedge clk20)
     if ((conf_addr == 0) && conf_write)
       conf_save <= reg_wdata[11];


endmodule // pmo
