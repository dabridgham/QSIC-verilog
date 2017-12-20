;;; Microcode for the SD card interface in SPI mode
;;;
;;; Copyright 2017 Noel Chiappa and David Bridgham
	

start:	clr	hispd|hicap|vers2|rdy|csel|time
	sete	0x40
	nop			; do I need longer to let CS settle?
	nocard	.		; wait for a card to appear
	clr	time		; reset the timer
dally:	timer	clrcrd
	jmp	dally

clrcrd:	set	csel		; this is to clear out half-sent commands in the card
	byte	.
	byte	.
	clr	csel|time
dly2:	timer	gotcard
	jmp	dly2

	;; start the initialization sequence

	;; CMD0 - GO_IDLE_STATE
gotcard:	sync,reset,imm	0x40
	sync,crc7,imm	0
	sync,crc7,imm	0
	sync,crc7,imm	0
	sync,crc7,imm	0
	sync,crc7,tcrc7

	clr	time
r1:	byte	.
	timer	cmdtimeout
	cmp	0x80		; look for a response
	eq	r1
	cmp	0x04		; illegal command (0x04)
	eq	notmemory	; no memory card should fail CMD0
	cmp	0x08		; CRC error
	eq	initfail
	clr	csel		; release the SD card

	;; CMD8 - SEND_IF_COND
cmd8:	sync,reset,imm	0x48
	sync,crc7,imm	0
	sync,crc7,imm	0
	sync,crc7,imm	0x01	; 2.7 - 3.6V - we're fixed at 3.3V
	sync,crc7,imm	0
	sync,crc7,tcrc7

	clr	time
r2:	byte	.
	timer	cmdtimeout
	cmp	0x80		; look for a response
	eq	r2
	cmp	0x04		; illegal command (0x04)
	eq	v1		; v1 cards don't do CMD8
	cmp	0x08		; CRC error
	eq	crcer
	byte	.		; don't care
	byte	.		; don't care
	byte	.
	cmp	0x01		; 2.7 - 3.6V
	eq	vltgd
	jmp	initfail
vltgd:	byte	.		; don't care
	set	vers2		; it's a v2 card
v1:	clr	csel		; release the SD card

	;; CMD58 - READ_OCR	
	sync,reset,imm	0x7A
	sync,crc7,imm	0
	sync,crc7,imm	0
	sync,crc7,imm	0
	sync,crc7,imm	0
	sync,crc7,tcrc7

	clr	time
r3:	byte	.
	timer	cmdtimeout
	cmp	0x80		; look for a response
	eq	r3
	cmp	0x0C		; illegal command (0x04) or CRC error (0x08)
	eq	illcrc
	;; somewhere in here tells me the voltage range and I should check it again!!
	byte	.		; don't care
	byte	.		; don't care
	byte	.		; don't care
	byte	.		; don't care
	clr	csel		; release the SD card

	;; CMD55 - APP_CMD
initloop:	sync,reset,imm	0x77
	sync,crc7,imm	0
	sync,crc7,imm	0
	sync,crc7,imm	0
	sync,crc7,imm	0
	sync,crc7,tcrc7

	clr	time
r4:	byte	.
	timer	cmdtimeout
	cmp	0x80		; look for a response
	eq	r4
	cmp	0x0C		; illegal command (0x04) or CRC error (0x08)
	eq	illcrc
	clr	csel		; release the SD card
	
	;; ACMD41 - SD_SEND_OP_COND
	sync,reset,imm	0x69
	sync,crc7,imm	0x40	; HCS=1, I support high-capacity
	sync,crc7,imm	0
	sync,crc7,imm	0
	sync,crc7,imm	0
	sync,crc7,tcrc7

	clr	time
r5:	byte	.
	timer	cmdtimeout
	cmp	0x80		; look for a response
	eq	r5
	clr	csel		; release the SD card
	cmp	0x0C		; illegal command (0x04) or CRC error (0x08)
	eq	illcrc
	cmp	0x01		; in idle state
	eq	initloop	; keep sending ACMD41 until the card shows idle

	vers1	initdone	; for v1 cards, we're finished initialization
	
	;; CMD58 again to get CCS from v2 cards
	sync,reset,imm	0x7A	; CMD58 - READ_OCR
	sync,crc7,imm	0
	sync,crc7,imm	0
	sync,crc7,imm	0
	sync,crc7,imm	0
	sync,crc7,tcrc7

	clr	time
r6:	byte	.
	timer	cmdtimeout
	cmp	0x80		; look for a response
	eq	r6
	cmp	0x0C		; illegal command (0x04) or CRC error (0x08)
	eq	illcrc
	;; somewhere in here tells me the voltage range and I should check it again!!
	byte	.
	cmp	0x40		; Card Capacity Status CCS bit 30
	eq	sdhc
	jmp	lowcap
sdhc:	set	hicap
lowcap:	byte	.		; don't care
	byte	.		; don't care
	byte	.		; don't care
	clr	csel		; release the SD card

	;; the card is initialized, look for read or write commands or for the card to be
	;; removed
	
initdone:	set	rdy
	;; a bit of time to let Card Detect settle
	nop
	nop
idle:	nocard	start
	sete	0x61
	;; 	read	bread
	write	bwrite
	jmp	idle

	;; 
	;; Write out a block of data
	;; 
bwrite:	sync,reset,imm	0x58	; CMD24 WRITE_BLOCK	
	sync,crc7,addr3		; MSB of disk address
	sync,crc7,addr2
	sync,crc7,addr1
	sync,crc7,addr0		; LSB of disk address
	sync,crc7,tcrc7
	;; command response
	sete	0x62
	clr	time
r7:	byte	.
	timer	cmdtimeout
	cmp	0x80
	eq	r7
	cmp	0x7F
	eq	wrterr
	;; write data block
	sete	0x63
	byte	.
	byte	.		; give it one more byte time N_WR
	sync,reset,imm	0xFE	; Start Block token
tloop:	sync,crc16,tlow		; The PDP-11 is little-endian so that's how we write out the data
	sync,crc16,thigh
	crc16,block	tloop
	sync,crc16,tcrc16h
	sync,tcrc16l
	;; the data response immediately follows
	byte	.
	crcerr	crcer
	wrerr	wrterr
	clr	time
tbusy:	byte	.
	timer	wrtimeout
	cmp	0xFF		; loop while the card is busy writing data
	eq	wdone
	jmp	tbusy
wdone:	sete	0x64
	clr	csel
	jmp	idle

wrterr:	clr	csel
	sete	0x91
	jmp	initfail
wrtimeout:	clr csel
	sete	0x92
	jmp	initfail

	;;
	;; Read in a block of data
	;;
bread:	sync,reset,imm	0x51	; CMD17 READ_SINGLE_BLOCK
	sync,crc7,addr3		; MSB of disk address
	sync,crc7,addr2
	sync,crc7,addr1
	sync,crc7,addr0		; LSB of disk address
	sync,crc7,tcrc7
	;; command response
	clr	time
r8:	byte	.
	timer	cmdtimeout
	cmp	0x80
	eq	r8
	cmp	0x7F
	eq	rderr
	;; wait for Start Block token
rwait:	byte	.
	cmp	0x01
	eq	rwait
	;; read words into FIFO
rloop:	byte	.
	rlow			; Little endian for the data
	byte	.
	rhigh
	block	rloop
	clr	csel
	jmp	idle

rderr:	clr	csel
	sete	0x94
	jmp	initfail


	;; in any error, just wait for the card to be removed and reset
crcer:	jmp	initfail
notmemory:	jmp	initfail
cmdtimeout: jmp initfail
illcrc:	sete	0x84
	jmp	initfail
initfail:	clr	csel
waitcd:	nocard	start		; when the card goes away, go back to start
	jmp	waitcd
