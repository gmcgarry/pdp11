; https://www.ak6dn.com/PDP-11/M9312/
; https://gunkies.org/wiki/M9312_ROM

; This boot PROM is not a real boot PROM, but a pseudo-boot device that
; runs the internal M9312 full diagnostics continuously, incl memory test.
;
; This PROM is intimately tied to the standard 23-248F1 console/diag PROM,
; and will NOT work in boards other than a real M9312 with a '248F1.
;
; Standard devices are 82S131, Am27S13, 74S571 or other compatible bipolar
; PROMs with a 512x4 TriState 16pin DIP architecture. This code resides in
; the low half of the device; the top half is blank and unused.
;
; Alternatively, 82S129 compatible 256x4 TriState 16pin DIP devices can be
; used, as the uppermost address line (hardwired low) is an active low chip
; select (and will be correctly asserted low).

diags	= 165564				; ph2 diags, ret to 2(R4), temp R2,R3,R5,SP
prtoct	= 165430				; print octal in R0, ret to 2(R1), temp R2,R3
prteol	= 165500				; print EOL, ret to 2(R1), temp R2,R3
txchar	= 165540				; print char in R2, ret to 2(R3)

	.org	 173000

	; --------------------------------------------------
start:	.ascii	"ZZ"			; device code (reversed)

	.word	last-.			; offset to next boot header

zz0n:	sec				; boot std csr, unit zero, no diags
zz0d:	mov	$0,r0			; boot std csr, unit zero, with diags [NOTUSED]
zzNr:	mov	$0,r1			; boot std csr, unit <R0> [NOTUSED]
zzNb:	mov	pc,r4			; boot csr <R1>, unit <R0>
	bcc	diag			; br if diags requested
	br	go			; return to (R4)+2 from diags
					; then skip over pseudo reboot vector

	; --------------------------------------------------

	.word	start			; prom start addess @ 24
	.word	340			; and priority level @ 26

	; --------------------------------------------------

go:	mov	pc,r1			; setup return address
	br	crlf			; call EOL print

2:	clr	r3			; R3=000000 C=0
	inc	r3			; R3=000001 C=0
	com	r3			; R3=177776 C=1
	asr	r3			; R3=177777 C=0
	asl	r3			; R3=177776 C=1
	ror	r3			; R3=177777 C=0
	tst	r3			; R3=177777 C=0
	neg	r3			; R3=000001 C=1
	dec	r3			; R3=000000 C=1
	sbc	r3			; R3=177777 C=1
	rol	r3			; R3=177777 C=1
	adc	r3			; R3=000000 C=1
	swab	r3			; R3=000000 C=0
	bne	.			; br . if FAIL

	mov	pc,r4			; setup return address
	br	diag			; call ph2 diagnostics

	inc	r0			; bump pass count
	mov	r0,r1			;
	mov	r1,r2			; check some registers
	mov	r2,r3			;
	mov	r3,r4			;
	mov	r4,r5			; save pass count

	mov	pc,r1			; where we are
	add	$endp-.,r1		; offset to string
4:	movb	(r1)+,r2		; get next char
	beq	5f			; br if done
	mov	pc,r3			; setup return address
	br	tx			; print char in R2
	br	4b			; loop

5:	mov	pc,r1			; setup return address
	br	putoct			; call octal print of R0

	mov	pc,r1			; setup return address
	br	crlf			; call EOL print

	mov	r5,r0			; restore pass count
	br	2b			; and loop forever

	; --------------------------------------------------

endp:	.asciz	"End Pass "		; a message

tx:	jmp	*$txchar		; jump to char print
putoct:	jmp	*$prtoct		; jump to octal print
crlf:	jmp	*$prteol		; jump to EOL print
diag:	jmp	*$diags			; jump to console diags

	; --------------------------------------------------

	.org	173176
crc16:	.word	152737			; CRC-16 will go here

last:	; next boot prom starts here

	.end
