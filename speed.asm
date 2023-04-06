;
; Calculate CPU clock.
;

.include "devices.inc"

	.ORG 02000
START:
	MOV	$2000,SP

	MOV	$crlfs,R1
	JSR	PC,PUTS

	MOV	$intros,R1
	JSR	PC,PUTS

	CLR	R0
	CLRB	KW11LKS		; reset bit 7
1:	TSTB	KW11LKS		; wait until bit 7 set
	BPL	1b

	CLR	KW11LKS		; clear bit
1:	INC	R0
	TSTB	KW11LKS		; loop until bit 7 set
	BPL	1b

	; at this point, R0 is the number of times round the loop

	MOV	R0,BIGNUM	; lsb
	CLR	BIGNUM+2	; msb

	MOV	$msgs,R1
	JSR	PC,PUTS

	MOV	$BIGNUM,R0
	JSR	PC,PUTDEC32

	MOV	$hzs,R1
	JSR	PC,PUTS

	JMP	.

BIGNUM:
	.BLKW	2

intros:
	.asciz	"Speed Checker\r\n"
crlfs:
	.asciz	"\r\n"
msgs:
	.asciz	"CPU Speed is "
hzs:
	.asciz	" loops\r\n"

	.ALIGN	1
OUTHL:	ASR	R0		; OUT HEX LEFT BCD DIGIT
	ASR	R0
	ASR	R0
	ASR	R0
OUTHR:	BIC	$~17,R0		; OUT HEX RIGHT BCD DIGIT
	ADD	$'0',R0
	CMPB	R0,$'9'
	BLE	PUTC
	ADD	$7,R0
PUTC:	BITB	$TXRDY,*$DL11XCSR
	BEQ	PUTC
	MOVB	R0,*$DL11XBUF
	RTS	PC

1:	JSR	PC,PUTC
PUTS:	MOVB	(R1)+,R0
	BNE	1b
	RTS	PC

PUTHEX:	MOV	R0,-(SP)
	JSR	PC,OUTHL
	MOV	(SP)+,R0
	JMP	OUTHR

PUTHEX2:
	MOV	R0,-(SP)
	SWAB	R0
	JSR	PC,PUTHEX
	MOV	(SP)+,R0
	JMP	PUTHEX

;---
; print 32-bit number at (R0)
PUTDEC32:
	CLRB	-(SP)		; stack terminator
1:	MOV	$040,R2		; counter
	CLR	R1		; Remainder=0
2:	ADD	$-5,R1
	BCS	3f
	ADD	$5,R1
	CLC
3:	ROL	0(R0)
	ROL	2(R0)
	ROL	R1		; Shift bits of input into R1 (input mod 10)
	DEC	R2
	BNE	2b
	BISB	$'0',R1		; quotient in 0(R0):2(R0); remainder in R1
	MOVB	R1,-(SP)	; Push low digit 0-9 to print
	MOV	0(R0),R1
	BIS	2(R0),R1
	BNE	1b
	MOVB	(SP)+,R0	; Pop character left to right
4:	JSR	PC,PUTC		; Print it
	MOVB	(SP)+,R0
	BNE	4b
	RTS	PC

	.END
