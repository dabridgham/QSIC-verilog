;; Microcode for the SD card interface in SPI mode

start:	clr	hispeed+hicapac+vers2+ready+csel
	sete	0
	nocard	.		; wait for a card to appear
	clr	timebit		; reset the timer
dally:	timer	gotcard
	jmp	dally

	;; start the initialization sequence

	;; CMD0 - GO_IDLE_STATE
gotcard:	byte	.	; synchronize to the byte boundary
	imm	0x40
	byte	.
	imm	0
	byte	.
	imm	0
	byte 	.
	imm	0
	byte 	.
	imm	0
	byte 	.
 	imm	0x95		; CRC

	clr	timebit
r1:	byte	.
	timer	cmdtimeout
	cmp	0x80		; look for a response
	eq	r1
	cmp	0x04		; illegal command (0x04)
	eq	notmemory	; no card should fail to suppose CMD0
	clr	csel		; release the SD card

	;; CMD8 - SEND_IF_COND
	byte	.		; synchronize to the byte boundary
	imm	0x48
	byte	.
	imm	0
	byte	.
	imm	0
	byte 	.
	imm	0x01		; 2.7 - 3.6V - we're fixed at 3.3V
	byte 	.
	imm	0
	byte 	.
	imm	0x01		; CRC

	clr	timebit
r2:	byte	.
	timer	cmdtimeout
	cmp	0x80		; look for a response
	eq	r2
	cmp	0x04		; illegal command (0x04)
	eq	v1		; v1 cards don't do CMD8
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
	byte	.		; synchronize to the byte boundary
	imm	0x7A
	byte	.
	imm	0
	byte	.
	imm	0
	byte 	.
	imm	0
	byte 	.
	imm	0
	byte 	.
	imm	0x01		; CRC

	clr	timebit
r3:	byte	.
	timer	cmdtimeout
	cmp	0x80		; look for a response
	eq	r3
	cmp	0x0C		; illegal command (0x04) or CRC error (0x08)
	eq	notmemory
	;; somewhere in here tells me the voltage range and I should check it again!!
	byte	.		; don't care
	byte	.		; don't care
	byte	.		; don't care
	byte	.		; don't care
	clr	csel		; release the SD card

	;; CMD55 - APP_CMD	
initloop:	byte	.		; synchronize to the byte boundary
	imm	0x77
	byte	.
	imm	0
	byte	.
	imm	0
	byte 	.
	imm	0
	byte 	.
	imm	0
	byte 	.
	imm	0x01		; CRC

	clr	timebit
r4:	byte	.
	timer	cmdtimeout
	cmp	0x80		; look for a response
	eq	r4
	cmp	0x0C		; illegal command (0x04) or CRC error (0x08)
	eq	notmemory
	clr	csel		; release the SD card
	
	;; ACMD41 - SD_SEND_OP_COND
	byte	.		; synchronize to the byte boundary
	imm	0x69
	byte	.
	imm	0x40		; HCS=1
	byte	.
	imm	0
	byte 	.
	imm	0
	byte 	.
	imm	0
	byte 	.
	imm	0x01		; CRC

	clr	timebit
r5:	byte	.
	timer	cmdtimeout
	cmp	0x80		; look for a response
	eq	r5
	cmp	0x0C		; illegal command (0x04) or CRC error (0x08)
	eq	notmemory
	cmp	0x01		; in idle state (!! don't read again)
	clr	csel		; release the SD card
	eq	initloop	; keep sending ACMD41 until the card shows idle

	vers1	initdone	; for v1 cards, we're finished initialization
	
	;; CMD58 again to get CCS from v2 cards
	byte	.		; synchronize to the byte boundary
	imm	0x7A		; CMD58 - READ_OCR
	byte	.
	imm	0
	byte	.
	imm	0
	byte 	.
	imm	0
	byte 	.
	imm	0
	byte 	.
	imm	0x01		; CRC

	clr	timebit
r6:	byte	.
	timer	cmdtimeout
	cmp	0x80		; look for a response
	eq	r6
	cmp	0x0C		; illegal command (0x04) or CRC error (0x08)
	eq	notmemory
	;; somewhere in here tells me the voltage range and I should check it again!!
	byte	.
	cmp	0x40		; Card Capacity Status CCS bit 30
	eq	hicap
	jmp	lowcap
hicap:	set	hicapac
lowcap:	byte	.		; don't care
	byte	.		; don't care
	byte	.		; don't care
	clr	csel		; release the SD card

	;; card is initialized, look for read or write commands or for the card to be
	;; removed
initdone:	set	hispeed+ready
	;; a bit of time to let Card Detect settle
	rxdest=rnone	0		; noop
	rxdest=rnone	0		; noop
idle:	nocard	start
	jmp	idle

	;; in any error, just wait for the card to be removed and reset
notmemory:	jmp	initfail
cmdtimeout:	jmp	initfail
initfail:	clr	csel
	;; double up this command to waste a little time so CSel can propagate through the
	;; synchronizer and won't obscure card detect
	sete	0xFF
	sete	0xFF
	rxdest=rnone	0		; noop
waitcd:	nocard	start		; when the card goes away, go back to start
	jmp	waitcd
	
