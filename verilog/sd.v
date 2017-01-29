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
   input 	clk,
   input 	reset,
   output reg 	ready_cmd, // ready to accept a read or write command
   input 	read_cmd,
   input 	write_cmd,
   input [31:0] block_address,
   output reg 	data_ready, // host can read or write data
   input 	data_done, // host has read or written data
   inout [15:0] data,
   // the SD card itself
   output 	sd_clk,
   inout 	sd_cmd,
   inout [3:0] 	sd_dat,
   // Indicator Panel signals
   output reg 	ip_cd, // card detected
   output reg 	ip_v1, // Ver1.x
   output reg 	ip_v2, // Ver2.0 or higher
   output reg 	ip_SC, // Standard Capacity
   output reg 	ip_HC, // High Capacity or Extended Capacity
   output reg 	ip_err // saw an error
   );
   
   // For SPI mode, the signals get different meanings
   wire 	sd_cs;		// chip select
   wire 	sd_di;		// data in (to the SD card)
   wire 	sd_do;		// data out (from the SD card)
   wire 	sd_cd;		// card detect
   assign sd_do = sd_dat[0];
   assign sd_dat[3] = sd_cs ? 0 : 'bZ; // pull-down to select the card and let float to look for card detect
   assign sd_cd = sd_dat[3];	// for watching the card detect signal
   assign sd_cmd = sd_di;
   // sd_dat[1] and sd_dat[2] are reserved (unused by memory cards) in SPI mode and sd_clk is
   // still the clock

   // Generate the F_OD clock used in the Card Identification Mode by dividing clk by 64.
   // This clock should be between 100 and 400 kHz so the main clock (F_PP) can be in the range
   // 6.4 - 25 MHz.
   reg [5:0] 	clk_div = 0;
   always @(posedge clk) clk_div <= clk_div + 1;
 `ifdef SIM
   // in the sim, run the clock faster so it's a little easier to see what's going on
   wire 	clk400k = clk_div[0];
 `else
   wire 	clk400k = clk_div[5];
 `endif

   // control which clock goes to the SD card
   reg 		clear_fpp, set_fpp;
   reg 		fpp = 0;
   always @(posedge sd_clk)
     if (clear_fpp)
       fpp <= 0;
     else if (set_fpp)
       fpp <= 1;
   assign sd_clk = fpp ? clk : clk400k;

   // card detect - if sd_cd (aka sd_dat[3]) is low and we're not pulling it down (sd_cs), then
   // there must be a card there.  synchronize this signal since a card might get plugged in at
   // any time.
   wire 	card_detect_raw = sd_cd && !sd_cs;
   reg [1:0] 	cdra;
   always @(posedge clk) cdra[1:0] = { cdra[0], card_detect_raw };
   wire 	card_detect = cdra[1];

   // countdown timer - from clear to cd_timout is about 200ms with a 20MHz clock (when using
   // the slower clock F_OD).  could probably shorten that considerably.  Also clear the counter
   // on cmd_set as we use it to detect a command timeout
   reg [17:0] 	cd_timer;
   reg 		cd_timer_clear;
   always @(posedge sd_clk)
     cd_timer <= (cd_timer_clear || cmd_set) ? 0 : cd_timer+1;
`ifdef SIM
   // don't wait nearly so long when simulating
   wire 	cd_timeout = cd_timer[6];
`else
   wire 	cd_timeout = cd_timer[17];
`endif
   
   // keep track of whether the card is standard or high capacity
   reg 		high_capacity, set_high_capacity, clear_high_capacity;
   always @(negedge sd_clk)
     if (clear_high_capacity)
       high_capacity <= 0;
     else if (set_high_capacity)
       high_capacity <= 1;

   // data output shift register
   reg [46:0] 	cmd_output;	// the start bit is added here (should do the end bit too?)
   reg [47:0] 	output_sr;
   reg 		cmd_set, data_set;
   assign sd_di = output_sr[47];
   always @(negedge sd_clk)	// negedge for SPI mode 0
     if (cmd_set)
       output_sr <= { 1'b1, cmd_output };
     else
       output_sr <= { output_sr[46:0], 1'b1 };

   // data input shift register
   reg [31:0] 	input_sr;
   reg [7:0] 	r1;
   reg 		get_r1, get_busy, get_r2, get_r3, cmd_response;
   reg [1:0] 	response_type;
   reg [5:0] 	resp_arg_ctr;
   wire 	mod8 = (resp_arg_ctr[2:0] == 0);
   localparam
     R1 = 0,			// single byte
     R1b = 1,			// single byte but may be followed by busy
     R2 = 2,			// two bytes
     R3 = 3,			// R3 or R7, four bytes
     R7 = 3;
   wire 	in_idle_state = r1[0];
   wire 	card_ccs = input_sr[30]; // 0 = Standard Capacity, 1 = HC or XC
   assign sd_cs = ~cmd_response;	 // while we're running a command, assert CS
   always @(posedge sd_clk) 
     if (cmd_response == 0)
       input_sr <= { input_sr[30:0], sd_do };
   always @(posedge sd_clk) resp_arg_ctr <= get_r1 ? 0 : resp_arg_ctr + 1;
   always @(negedge sd_clk)
     if (reset) begin
	get_r1 <= 0;
	get_r2 <= 0;
	get_r3 <= 0;
	cmd_response <= 1;
     end else
       case (1'b1)
	 cmd_set: 		// when cmd_set, start looking
	   begin
	      get_r1 <= 1;
	      get_r2 <= 0;
	      get_r3 <= 0;
	      cmd_response <= 0;
	      r1 <= 0;
	   end
	 get_r1 && mod8:
	   if (input_sr[7] == 0) begin // look for the start bit
	      get_r1 <= 0;
	      r1 <= input_sr[7:0];
	      // if we're looking for an R1 response or we get a Command CRC error or Illegal
	      // Command error, then we're done
	      if ((response_type == R1) || input_sr[2] || input_sr[3])
		cmd_response <= 1;
	      else if (response_type == R1b)
		get_busy <= 1;
	      else if (response_type == R2)
		get_r2 <= 1;
	      else if (response_type == R3) // or R7
		get_r3 <= 1;
	   end
	 get_busy && mod8:
	   if (input_sr[7] == 1)	// the SD card will hold data low to indicate busy
	     cmd_response <= 0;
	 get_r2 && resp_arg_ctr[1]:
	   begin
	      get_r2 <= 0;
	      cmd_response <= 1;
	   end
	 get_r3 && resp_arg_ctr[5]:
	   begin
	      get_r3 <= 0;
	      cmd_response <= 1;
	   end
       endcase
   
   
   //
   // SD card state machine
   //
`ifdef SIM
   integer state_index;
   integer state_index_next;
`endif
   reg [INIT:LAST_STATE] state;
   reg [INIT:LAST_STATE] state_next;
   localparam
     INIT = 0,			// where we start and no card in sight
     DALLY = 1,			// a delay to let the card initialize
     SEND_RESET = 2,		// send the reset command to the SD card
     SEND_IF_COND = 3,		// tell the card what voltage we'll accept
     READ_OCR = 4,		// read back what voltage the card takes
     APP_CMD_1 = 5,		// extended command prefix
     SEND_OP_COND = 6,		// tell the card to initialize and specify if the host supports
				// High Capacity
     READ_CCS = 7,		// read back the card capacity status
     IDLE = 8,			// ready for host commands

     LAST_STATE = 12;		// highest numbered state

   task set_state;
      input integer s;
      begin
`ifdef SIM
	 state_index_next = s;
`endif
	 state_next[s] = 1'b1;
      end
   endtask

   // combinational part of the state machine
   always @(*) begin
      state_next = 0;
      cd_timer_clear = 0;
      cmd_output = 47'bX;
      set_fpp = 0;
      clear_high_capacity = 0;
      set_high_capacity = 0;
      cmd_set = 0;
      data_set = 0;
      response_type = 'bX;

      if (reset) begin
	 clear_fpp = 1;
	 set_state(INIT);
      end else
	case (1'b1)
	  state[INIT]:
	    begin
	       clear_fpp = 1;
	       // hang out here looking for a card to appear
	       if (card_detect) begin
		  cd_timer_clear = 1;
		  set_state(DALLY);
	       end else
		 set_state(INIT);
	    end
	  state[DALLY]:
	    // wait for the dally time
	    if (cd_timeout) begin
	       // CMD0 - GO_IDLE_STATE
	       cmd_output = { 7'd0, 32'h0, 8'h95 };
	       cmd_set = 1;
	       set_state(SEND_RESET);
	    end else
	      set_state(DALLY);
	  state[SEND_RESET]:
	    begin
	       response_type = R1;
	       if (!cmd_response)
		 set_state(SEND_RESET);
	       else begin
		  // CMD8 - SEND_IF_COND 2.7-3.6V
		  cmd_output = { 7'd8, 32'h00000100, 8'h01 }; // need to figure CRC !!!
		  cmd_set = 1;
		  set_state(SEND_IF_COND);
	       end
	    end
	  state[SEND_IF_COND]:
	    begin
	       response_type = R7;
	       if (!cmd_response)
		 set_state(SEND_IF_COND);
	       else begin
		  // set v1 if we got an illegal command error !!!
		  // check voltage range !!!

		  // CMD58 - READ_OCR
		  cmd_output = { 7'd58, 32'h00, 8'h01 }; // need to figure CRC !!!
		  cmd_set = 1;
		  set_state(READ_OCR);
	       end // else: !if(!cmd_response)
	    end
	  state[READ_OCR]:
	    begin
	       response_type = R3;
	       if (!cmd_response)
		 set_state(READ_OCR);
	       else begin
		  // illegal command = not a memory card !!!
		  // check voltage range (again?) !!!

		  // CMD55 - APP_CMD
		  cmd_output = { 7'd55, 32'h00, 8'h01 }; // need to figure CRC !!!
		  cmd_set = 1;
		  set_state(APP_CMD_1);
	       end // else: !if(!cmd_response)
	    end
	  state[APP_CMD_1]:
	    begin
	       response_type = R1;
	       if (!cmd_response)
		 set_state(APP_CMD_1);
	       else begin
		  // ACMD41 - SD_SEND_OP_COND - HCS = 0 (!!! set to 1 once I support HCS)
		  cmd_output = { 7'd41, 32'h00, 8'h01 }; // need to figure CRC !!!
		  cmd_set = 1;
		  set_state(SEND_OP_COND);
	       end
	    end
	  state[SEND_OP_COND]:
	    begin
	       response_type = R1;
	       if (!cmd_response)
		 set_state(SEND_OP_COND);
	       else begin
		  // loop, sending the ACMD41 repeatedly, until the card is no longer in idle state
		  if (in_idle_state) begin
		     // CMD55 - APP_CMD
		     cmd_output = { 7'd55, 32'h00, 8'h01 }; // need to figure CRC !!!
		     cmd_set = 1;
		     set_state(APP_CMD_1);
		  end else begin
		     // CMD58 - READ_OCR - looking for CCS (Card Capacity Status)
		     cmd_output = { 7'd58, 32'h00, 8'h01 }; // need to figure CRC !!!
		     cmd_set = 1;
		     set_state(READ_CCS);
		  end // else: !if(in_idle_state)
	       end // else: !if(!cmd_response)
	    end
	  state[READ_CCS]:
	    begin
	       response_type = R3;
	       if (!cmd_response)
		 set_state(READ_CCS);
	       else begin
		  if (card_ccs)
		    set_high_capacity = 1;
		  else
		    clear_high_capacity = 1;
		  set_fpp = 1;	// can kick up the clock speed now
		  set_state(IDLE);
	       end
	    end

	  // initialization is finished, just wait for read and write commands from the host and
	  // watch to see if the SD card is removed
	  state[IDLE]:
	    set_state(IDLE);
	  
	endcase // case (1'b1)
   end
   
   // synchronous part of the state machine
   always @(posedge sd_clk) begin
`ifdef SIM
      state_index <= state_index_next;
`endif
      state <= state_next;
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
   wire        sd_do = dat[0];
   wire        sd_cs = dat[3];

endmodule // SD_card


module SD_test();

   reg clk = 0;
   always @( * )
     #25 clk <= ~clk; // 20MHz clock (50ns cycle)

   // wire up the SD controller
   reg reset, read_cmd, write_cmd, data_done;
   wire ready_cmd, data_ready;
   reg [31:0] block_address;
   wire [15:0] data;
   wire sd_clk, sd_cs, sd_di, sd_do, sd_nc1, sd_nc2;
   wire ip_cd, ip_v1, ip_v2, ip_SC, ip_HC, ip_err;
   assign (weak1, weak0) sd_cs = 0; // host has a 270k pull-down
   assign (strong1, weak0) sd_do = 1;  // host has a 50k pull-up
   assign (strong1, weak0) sd_nc1 = 1; // "
   assign (strong1, weak0) sd_nc2 = 1; // "
   reg 	sd_cd = 0;
   assign (strong1, weak0) sd_cs = sd_cd; // 270k pull-down, card has a 50k pull-up
   
   SD_spi sd(clk, reset, ready_cmd, read_cmd, write_cmd, block_address, data_ready, data_done, data,
	     sd_clk, sd_di, { sd_cs, sd_nc2, sd_nc1, sd_do },
	     ip_cd, ip_v1, ip_v2, ip_SC, ip_HC, ip_err);
   
   // wire in the SD card
   SD_card card(clk, sd_di, { sd_cs, sd_nc2, sd_nc1, sd_do });


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
      

      #20000 $finish_and_return(0);
   end

endmodule // SD_test

`endif
