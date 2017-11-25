//	-*- mode: Verilog; fill-column: 96 -*-
//
// Interfacing to an SD card
//
// Copyright 2016-2017 Noel Chiappa and David Bridgham


//   Start Up sequence for SD mode [not using this one]
//   --------------------------------------------------
// - card detect
// - wait at least 1ms and 74 clock cycles
// - in Card Identification Mode
// - CMD0 GO_IDLE - check voltage
// - CMD8 SEND_IF_COND - verify voltage and indicate host can do 2.0, if no response
//                       then v1.0 and skip ACMD41
// - ACMD41 SD_SEND_OP_COND - reject cards that don't match voltage range, get OCR
//                            set HCS and read CCS (Host/Card Capacity Status)
//   - loop on busy for at least 1 second
// - CMD2 ALL_SEND_CID - retrieve Card Identification Number
// - CMD3 SEND_RELATIVE_ADDR - retrieve the card's proposed relative address
// - now in Data Transfer Mode so can change clock speed
// - CMD9 SEND_CSD - retrieve Card Specific Data
// - CMD4 SET_DSR - set bus length, frequency (optional)
// - CMD7 SELECT_CARD - to go to Transfer State (tran)
// - ACMD6 SET_BUS_WIDTH - set bus width
// - ACMD13 SD_STATUS - Get SD Status (512 bits of info)
//
// [somewhere I need to read CID (Card ID), CSD (Card Specific Data, memory size), and SCR (SD
// Conf Reg, allowed bus widths]
// - CMD10 SEND_CID
// - CMD9 SEND_CSD
// - ACMD51 SEND_SCR
//
// - ACMD42 SET_CLR_CARD_DETECT - disable pullup on DAT3
//
//   on-going ...
// - CMD17 READ_SINGLE_BLOCK
// - CMD24 WRITE_BLOCK
// - detect card removal

//   Start Up sequence for SPI mode
//   ------------------------------
// - card detect
// - wait a bit (same as above? 1ms and 74 clock cycles?)
// - CMD0 RESET w/ CS asserted - to put card in SPI mode (0x40, 00, 00, 00, 00, 0x95)
// - CMD8 SEND_IF_COND - set host voltage (this needs to have a valid CRC too?)
//   if illegal command, might be Ver 1.x SD memory card
// - CMD59 CRC_ON_OFF - optional, if want to enable CRC checks
// - CMD58 READ_OCR - optional but recommended, check voltage range
// - ACMD41 SD_SEND_OP_COND - start initialization, set HCS (High Capacity Support)
//   loop on busy
// - if Ver2.00 or greater CMD58 READ_OCR - get card capacity information
//   (CCS=1 HC or XC and CCS=0 SC)
// - when can I switch to the full-speed clock?


// Addresses:
//  777200 for RQ
//  770450-56 for QSIC
//  777720-26 Noel suggests this for the QSIC

`timescale 1 ns / 1 ns

// top-level SD card module for SPI mode
module SD_spi
  (
   input 	     clk, // F_PP between 6.4 and 25 MHz
   input 	     reset,
   output reg 	     device_ready, // ready to accept a read or write command
   input 	     read_cmd,
   input 	     write_cmd,
   input [31:0]      block_address,
   input [15:0]      write_data,
   output reg [15:0] read_data,
   // the SD card itself
   output 	     sd_clk,
   inout 	     sd_cmd,
   inout [3:0] 	     sd_dat,
   // Indicator Panel signals
   output 	     ip_cd, // card detected
   output 	     ip_v1, // Ver1.x
   output 	     ip_v2, // Ver2.0 or higher
   output 	     ip_SC, // Standard Capacity
   output 	     ip_HC, // High Capacity or Extended Capacity
   output reg [7:0]  ip_err // saw an error
   );
   
   // For SPI mode, the signals get different meanings
   reg 		sd_cs;		// chip select
   wire 	sd_di;		// data in (to the SD card)
   wire 	sd_do;		// data out (from the SD card)
   wire 	sd_cd;		// card detect
   assign sd_do = sd_dat[0];
   assign sd_dat[3] = sd_cs ? 0 : 'bZ; // pull-down to select the card and let float to look for card detect
   assign sd_cd = sd_dat[3];	// for watching the card detect signal
   assign sd_cmd = sd_di;
   // sd_dat[1] and sd_dat[2] are reserved (unused by memory cards) in SPI mode and sd_clk is
   // still the clock

   // The micro-instruction and breakout
   reg [24:0] 	uinst;
   wire 	byte_sync = uinst[24];	  // sync instruction to byte clock
   wire 	crc_reset = uinst[23];	  // reset both crc chains
   wire 	crc7_enable = uinst[22];  // enable the crc7 calc
   wire 	crc16_enable = uinst[21]; // enable the crc16 calc
   wire 	set_bits = uinst[20];	  // set bits from literal
   wire 	clr_bits = uinst[19];	  // clear bits from literal
   wire 	set_error = uinst[18];	  // set the error code from literal
   wire [3:0]	condition = uinst[17:14]; // jump conditions
   localparam
     JMP_NEXT = 0,
     JMP_ALWAYS = 1,
     JMP_NO_CARD = 2,
     JMP_TIMEOUT = 3,
     JMP_EQ = 4,
     JMP_NEQ = 5,
     JMP_BYTE = 6,
     JMP_READ = 7,
     JMP_WRITE = 8,
     JMP_V1 = 9;
   wire [1:0] 	rx_dest = uinst[13:12]; // move from Rx SR to dest
   localparam
     RX_NONE = 0,
     RX_CMP = 1,
     RX_DATA_LOW = 2,
     RX_DATA_HIGH = 3;
   wire [3:0] 	tx_src = uinst[11:8]; // move from src to Tx SR
   localparam
     TX_NONE = 0,
     TX_IMM = 1,
     TX_DATA_LOW = 2,
     TX_DATA_HIGH = 3,
     TX_CRC7 = 4,
     TX_CRC16_LOW = 5,
     TX_CRC16_HIGH = 6,
     TX_ADDR_0 = 7,
     TX_ADDR_1 = 8,
     TX_ADDR_2 = 9,
     TX_ADDR_3 = 10;
   wire [7:0] 	literal = uinst[7:0]; // immediate constant
   wire 	literal_high_speed = literal[7];
   wire 	literal_high_capacity = literal[6];
   wire 	literal_version_2 = literal[5];
   wire 	literal_timeout = literal[4];
   wire 	literal_ready = literal[3];
   wire 	literal_cs = literal[2];


   
   // Generate the F_OD clock used in Card Identification Mode by dividing clk by 64.  This
   // clock should be between 100 and 400 kHz so the main clock (F_PP) can be in the range 6.4 -
   // 25 MHz.
   reg [5:0] 	clk_div = 0;
   always @(posedge clk) clk_div <= clk_div + 1;
 `ifdef SIM
   // in the sim, run the clock faster so it's a little easier to see what's going on
   wire 	clk400k = clk_div[0];
 `else
   wire 	clk400k = clk_div[5];
 `endif

   // control which clock goes to the SD card
   reg 		fpp = 0;
   always @(negedge clk)
     if (clr_bits & literal_high_speed)
       fpp <= 0;
     else if (set_bits & literal_high_speed)
       fpp <= 1;
   assign sd_clk = fpp ? clk : clk400k;

   // generate a byte strobe from the sd_clk
   reg [2:0] 	byte_clk_ra = 0;
   wire 	byte_clk = (byte_clk_ra == 0);
   always @(negedge sd_clk) byte_clk_ra <= byte_clk_ra + 1;

   // card detect - if sd_cd (aka sd_dat[3]) is low and we're not pulling it down (sd_cs), then
   // there must be a card there.  synchronize this signal since a card might get plugged in at
   // any time.
   wire 	card_detect_raw = sd_cd || sd_cs;
   reg [1:0] 	cdra;
   always @(negedge sd_clk) cdra[1:0] = { cdra[0], card_detect_raw };
   wire 	card_detect = cdra[1];
   assign ip_cd = card_detect;	// send the card detect to the indicator panel

   // countdown timer - from clear to cd_timout is about 200ms with a 20MHz clock (when using
   // the slower clock F_OD).  could probably shorten that considerably.
   reg [17:0] 	cd_timer;
   always @(negedge sd_clk)
     cd_timer <= (clr_bits & literal_timeout) ? 0 : cd_timer+1;
`ifdef SIM
   wire 	cd_timeout = cd_timer[6];   // shorten timeout when simulating
`else
   wire 	cd_timeout = cd_timer[17];
`endif
   
   // keep track of whether the card is standard or high capacity
   reg 		high_capacity = 0;
   assign ip_SC = ~high_capacity;
   assign ip_HC = high_capacity;
   always @(negedge sd_clk)
     if (clr_bits & literal_high_capacity) begin
`ifdef SIM
	$display("Clear: High Cap");
`endif
	high_capacity <= 0;
     end else if (set_bits & literal_high_capacity) begin
`ifdef SIM
	$display("Set: High Cap");
`endif
	high_capacity <= 1;
     end

   // keep track of whether the card is version 1 or 2
   reg 		version_2 = 0;
   assign ip_v1 = ~version_2;
   assign ip_v2 = version_2;
   always @(negedge sd_clk)
     if (clr_bits & literal_version_2) begin
`ifdef SIM
	$display("Clear: V2");
`endif
	version_2 <= 0;
     end else if (set_bits & literal_version_2) begin
`ifdef SIM
	$display("Set: V2");
`endif
	version_2 <= 1;
	end

   // run the device ready line back to the disk controller
   always @(negedge sd_clk)
     if (clr_bits & literal_ready) begin
`ifdef SIM
	$display("Clear: Card Ready");
`endif
	device_ready <= 0;
     end else if (set_bits & literal_ready) begin
`ifdef SIM
	$display("Set: Card Ready");
`endif
	device_ready <= 1;
     end

   // Set an error code
   always @(negedge sd_clk)
     if (set_error) begin
`ifdef SIM
	$display("Error: 0x%02x", literal);
`endif
	ip_err <= literal;
     end

   wire 	crc7_reset = crc_reset;
   wire 	crc16_reset = crc_reset;
   wire 	crc7_di = sd_di;
   wire 	crc16_di = sd_di;
   wire [6:0] 	crc7_do;
   wire [15:0] 	crc16_do;
   crc7 sd_crc7(sd_clk, crc7_reset, crc7_enable, crc7_di, crc7_do);
   crc16 sd_crc16(sd_clk, crc16_reset, crc16_enable, crc16_di, crc16_do);

   // Older SD cards used byte addressing which limited the size to 2GB (why wasn't it 4GB?).
   // In HC and XC cards they went to block addressing, pushing that limit up to 2TB.  The disk
   // controllers generate block addresses so convert here if using an SD card.
   wire [31:0] 	disk_address = high_capacity ? block_address : block_address << 9;

   // data output shift register
   reg [7:0] 	tx_sr;
   assign sd_di = tx_sr[7];
   always @(negedge sd_clk)	// change on negedge for SPI mode 0
     if (byte_clk)
       case (tx_src)
	 TX_IMM: tx_sr <= literal;
	 TX_DATA_LOW: tx_sr <= write_data[7:0];
	 TX_DATA_HIGH: tx_sr <= write_data[15:8];
	 TX_CRC7: tx_sr <= { crc7_do, 1'b1 };
	 TX_CRC16_LOW: tx_sr <= crc16_do[7:0];
	 TX_CRC16_HIGH: tx_sr <= crc16_do[15:8];
	 TX_ADDR_0: tx_sr <= disk_address[7:0];
	 TX_ADDR_1: tx_sr <= disk_address[15:8];
	 TX_ADDR_2: tx_sr <= disk_address[23:16];
	 TX_ADDR_3: tx_sr <= disk_address[31:24];
	 TX_NONE: tx_sr <= { tx_sr[6:0], 1'b1 };
	 default: tx_sr <= { tx_sr[6:0], 1'b1 };
       endcase // case (tx_src)
     else
       tx_sr <= { tx_sr[6:0], 1'b1 };

   // the Card Select is asserted when data is sent to the TxSR
   always @(negedge sd_clk)
     if (clr_bits && literal_cs)
       sd_cs <= 0;
     else if ((set_bits & literal_cs) || 
	      ((tx_src != TX_NONE) && byte_clk))
       sd_cs <= 1;


   // data input shift register
   reg [7:0] 	rx_sr;
   always @(posedge sd_clk)	// read on posedge for SPI mode 0
     rx_sr <= { rx_sr[6:0], sd_do };

   // on the byte strobe delayed by one cycle, transfer the RxSR to a receive register where it
   // will remain stable until the next byte is done.  this is what's used for comaprison
   reg [7:0] 	rx_reg, literal_reg;
   reg 		delayed_byte;
   always @(negedge sd_clk) delayed_byte <= byte_clk;
   always @(negedge sd_clk)
     if (byte_clk)
       rx_reg <= rx_sr;

   // move Rx data to where it's going
   always @(negedge sd_clk)
     case (rx_dest)
       RX_NONE: ;
       RX_CMP:
	 // this one is a little strange.  rx_sr is already being copied to rx_reg on the byte
	 // strobe.  To do a compare, we save the literal here for branching later.
	 literal_reg <= literal;
       RX_DATA_LOW: read_data[7:0] <= rx_reg;
       RX_DATA_HIGH: read_data[15:8] <= rx_reg;
     endcase // case (rx_dest)

   // compare rx_reg with literal_reg
   wire 	cmp_eq = ((rx_reg & literal_reg) != 8'b0); // if any masked bit set
   wire 	cmp_neq = ((~rx_reg & literal_reg) == 8'b0); // if all masked bits set

   // synchronize read and write commands from the disk controller
   reg [1:0] 	read_ra, write_ra;
   always @(negedge sd_clk) read_ra <= { read_ra[0], read_cmd };
   always @(negedge sd_clk) write_ra <= { write_ra[0], write_cmd };
   wire 	s_read_cmd = read_ra[1];
   wire 	s_write_cmd = write_ra[1];

   // Jump Condition
   reg 		jump = 0;
   always @(*)
     case (condition)
       JMP_NEXT: jump = 0;
       JMP_ALWAYS: jump = 1;
       JMP_NO_CARD: jump = !card_detect;
       JMP_TIMEOUT: jump = cd_timeout;
       JMP_EQ: jump = cmp_eq;
       JMP_NEQ: jump = cmp_neq;
       JMP_BYTE: jump = !byte_clk;
       JMP_READ: jump = s_read_cmd;
       JMP_WRITE: jump = s_write_cmd;
       JMP_V1: jump = !version_2;
       default: jump = 0;
     endcase
     

   // the microcode itself and sequencing

   reg [7:0] 	uPC = 0;
   reg [7:0] 	uPC_next = 0;
   reg [24:0] 	uROM [0:255];

   initial $readmemh("sd.hex", uROM);
   
   always @(*)
     if (reset)
       uPC_next = 0;
     else if (byte_sync && !byte_clk)
       uPC_next = uPC;
     else if (jump)
       uPC_next = literal;
     else
       uPC_next = uPC + 1;
     
   always @(negedge sd_clk)
     begin
	uPC <= uPC_next;
	uinst <= uROM[uPC_next];
     end
   
endmodule // SD_spi

`ifdef SIM

//
// A testbench for this SD Card interface
//

// A simple SD card emulator.  SPI mode only and just enough to test the initialization sequence.
module SD_card
  (
   input clk,
   inout cmd,
   inout [3:0] dat
   );

   wire        sd_di = cmd;
   wire        sd_cs = dat[3];
   wire        sd_do;
   assign dat[0] = sd_do;

   reg [47:0]  input_sr;
   integer     bit_count, byte_count, init_count;
   wire        byte_mark = (bit_count % 8) == 0;
   always @(posedge clk) input_sr <= sd_cs ? {48{1'b1}} : { input_sr[46:0], sd_di };
   always @(posedge clk) bit_count <= sd_cs ? 0 : bit_count + 1;

   reg 	       cs_n;		// CS delayed to view on negedge clk
   always @(posedge clk) cs_n <= sd_cs;

   reg [47:0]  output_sr;
   assign sd_do = output_sr[47];

   localparam
     IDLE = 0,
     READ_CMD = 1,
     SEND_RESP = 2;
   reg [0:3]  state = 0;
   
   always @(negedge clk)
     begin
	// this may be overridden below
	output_sr <= { output_sr[46:0], 1'b1 };
	state <= 0;

	if (cs_n == 1) begin	// cs is active low
	   output_sr <= {48{1'b1}};
	   state[IDLE] <= 1;
        end else if (byte_mark == 1)
	  case (1'b1)
	    state[IDLE]:
	      state[READ_CMD] <= 1;

	    state[READ_CMD]:
	      if (input_sr[47] == 1) // if no start bit
		state[READ_CMD] <= 1;
	      else		// we have a command
		begin
		   $display("Command: %d", input_sr[45:40]);
		   state[SEND_RESP] <= 1;
		   byte_count <= 0;
		   case (input_sr[45:40])
		     0:   // reset
		       begin
			  init_count <= 4;
			  output_sr <= 48'h00_ff_ff_ff_ff_ff; // command good
		       end
		     8:   // SEND_IF_COND
		       output_sr <= 48'h00_00_00_01_00_ff; // command good, 3.3V
		     58:   // READ_OCR
		       output_sr <= 48'h00_00_00_01_00_ff; // command good, should be voltage ranges here
		     55:   // APP_CMD
		       output_sr <= 48'h00_ff_ff_ff_ff_ff; // command good
		     41:   // SD_SEND_OP_COND
		       begin
			  init_count <= init_count - 1;
			  if (init_count == 0)
			    output_sr <= 48'h00_ff_ff_ff_ff_ff; // command good
			  else
			    output_sr <= 48'h01_ff_ff_ff_ff_ff; // in idle state
		       end
		     default:
		       output_sr <= 48'h04_ff_ff_ff_ff_ff; // illegal command
		   endcase // case (input_sr[45:40])
		end // else: !if(input_sr[47] == 1)

	    state[SEND_RESP]:
	      begin
		 if (byte_count > 5)
		   state[IDLE] <= 1;
		 else
		   state <= state;
		 byte_count <= byte_count + 1;
	      end
	  endcase // case (1'b1)
	else
	  state <= state;
     end // always @ (negedge clk)

endmodule // SD_card


module SD_test();

   reg clk = 0;
   always @( * )
     #25 clk <= ~clk; // 20MHz clock (50ns cycle)

   // wire up the SD controller
   reg reset, read_cmd, write_cmd, data_done;
   wire ready_cmd, data_ready;
   reg [31:0]  block_address;
   wire [15:0] read_data;
   reg [15:0] write_data;
   wire sd_clk, sd_cs, sd_di, sd_do, sd_nc1, sd_nc2;
   wire ip_cd, ip_v1, ip_v2, ip_SC, ip_HC;
   wire [7:0] ip_err;
   assign (weak1, weak0) sd_cs = 0;  // host has a 270k pull-down
   assign (pull1, weak0) sd_do = 1;  // host has a 50k pull-up
   assign (pull1, weak0) sd_nc1 = 1; // "
   assign (pull1, weak0) sd_nc2 = 1; // "
   reg 	sd_cd = 0;
   assign (pull1, weak0) sd_cs = sd_cd; // 270k pull-down, card has a 50k pull-up
   
   SD_spi sd(clk, reset, ready_cmd, read_cmd, write_cmd, block_address, 
	     write_data, read_data,
	     sd_clk, sd_di, { sd_cs, sd_nc2, sd_nc1, sd_do },
	     ip_cd, ip_v1, ip_v2, ip_SC, ip_HC, ip_err);
   
   // wire in the SD card
   SD_card card(sd_clk, sd_di, { sd_cs, sd_nc2, sd_nc1, sd_do });


   initial begin
      $dumpfile("sd.lxt");
      $dumpvars(0, SD_test);

      reset <= 0;
      read_cmd <= 0;
      write_cmd <= 0;
      data_done <= 0;
      block_address <= 0;

      #100 reset <= 1;
      #600 reset <= 0;
      
      #1000 sd_cd <= 1;		// plug in the card
      

      #130000 $finish_and_return(0);
   end

endmodule // SD_test

`endif
