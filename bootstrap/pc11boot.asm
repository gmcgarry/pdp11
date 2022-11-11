; ABSOLUTE BOOT LOADER

; The high-speed paper tape reader and punch uses
; I/O addresses 177550-177557.

; self-modifying code!

	.ORG	037744
	MOV	reg,R1
loop:	MOV	$352,R2
	INC	*R1
1:	TSTB	*R1
	BPL	1b
	MOVB	2(R1),(loop+2-352)(R2)
	INC	loop+2
	BR	loop
reg:	.WORD 177550
	.END
