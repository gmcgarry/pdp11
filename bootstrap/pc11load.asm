; The high-speed paper tape reader and punch uses I/O
; addresses 177550-177557.
;
; The Model 33 Teletype uses paper trap reader uses
; I/O addresss 177560-177567.
;
; 0017744 is suitable for systems with 8K+ memory
; 0037744 is suitable for systems with 16K+ memory
; 0077744 is suitable for systems with 32K+ memory
;
; - will load 228B from the tape to 037400 ($3f00)
; - generally the absolute loader will be loaded
;   from the start of the tape which can be used
;   to load larger files (with checksums)
;

LOAD		= 037744

KL11RCSR	=	177560
PC11PRS		=	177550

	.ORG	LOAD

	MOV	DEVICE,R1	; load device base address
LOOP:	MOV	$352,R2	
	INC	*R1		; set LSB of control register
1:	TSTB	*R1		; wait for byte
	BPL	1b
	MOVB	2(R1),(LOOP+2-352)(R2)	; read byte and overwrite R2 load instruction
	INC	LOOP+2
	BR	LOOP
DEVICE:	.WORD	PC11PRS

	.END
