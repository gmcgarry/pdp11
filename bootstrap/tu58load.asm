;
; This source code is taken from M9312 boot PROM for the TU58 version 23-765B9.
;
; This boot PROM is for the TU58 DECtapeII serial tape controller.
;
; Multiple units and/or CSR addresses are supported via different entry points.
;
; Revision history:
; March 2017: Joerg Hoppe
;	 Made relocatable, adaption for tu58fs.
;
; 2009?:   Don North / AK6DN ?
;      The original code in 23-765A9 is REALLY BROKEN when it comes to
;      supporting a non-std CSR other than 776500 in R1 on entry
;      All the hard references to:  ddrbuf, ddxcsr, ddxbuf
;      have been changed to:	2(R1),	4(R1),	6(R1)
;      The one reference where 'ddrcsr' might have been used is '(R1)' instead
;      which is actually correct (but totally inconsistent with other usage).
;
; 1978?:  DEC
;      Original ROM 23-765B9 for M9312.
;

ddcsr	=	176500 			; std TU58 csrbase

ddrcsr	=	0			; receive control
ddrbuf	=	2			; receive data
ddxcsr	=	4			; transmit control
ddxbuf	=	6			; transmit data

	.org	2000 			; arbitrary position

; --------------------------------------------------

start:

dd0n:	sec				; boot std csr, unit zero, no diags
dd0d:	mov	$0,r0			; boot std csr, unit zero, with diags
ddNr:	mov	$ddcsr,r1		; boot std csr, unit <R0>

go:	mov	$2000,sp		; setup a stack
	clr	r4			; zap old return address
	inc	ddxcsr(r1)		; set break bit
	clr	r3			; data 000,000
	jsr	pc,xmtch8		; transmit 8 zero chars
	clr	ddxcsr(r1)		; clear break bit
	tst	ddrbuf(r1)		; read/flush any stale rx char
	mov	$(010*400)+004,r3	; data 010,004
	jsr	pc,xmtch2		; transmit 004 (init) and 010 (boot)
	mov	r0,r3			; get unit number
	jsr	pc,xmtch		; transmit unit number

	clr	r3			; clear rx buffer ptr
2:	tstb	(r1)			; wait for rcv'd char available
	bpl	2b			; br if not yet
	movb	ddrbuf(r1),(r3)+	; store the char in buffer, bump ptr
	cmp	$1000,r3		; hit end of buffer (512. bytes)?
	bhi	2b			; br if not yet
	clr	pc			; jump to bootstrap at zero

xmtch8: 				; transmit 4x the two chars in r3
	jsr	pc,(pc) 		; recursive call for char replication
xmtch4:
	jsr	pc,(pc) 		; recursive call for char replication
xmtch2:					; transmit 2 chars in lower r3, upper r3
	jsr	pc,(pc) 		; recursive call for char replication
xmtch:					; xmt char in lower r3, then swap r3
	tstb	ddxcsr(r1)		; wait for xmit buffer available
	bpl	xmtch			; br if not yet
	movb	r3,ddxbuf(r1)		; send the char
	swab	r3			; swap to other char
	rts	pc			; now recurse or return

	.end
