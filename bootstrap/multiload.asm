; multiloader for mt tape
; will present boot prompt to specify device
; from which device to boot

MTS             =       0172520
MTC             =       0172522
MTBRC           =       0172524
MTCMA           =       0172526
MTD             =       0172530
MTRD            =       0172532

KL11RCSR        =       0177560
KL11RBUF        =       0177562
KL11XCSR        =       0177564
KL11XBUF        =       0177566

PDRI            =       0177600
PDRD            =       0177620
PARI            =       0177640
PARD            =       0177660

LOADSTART	=	137000
CMDBUFFER	=	(LOADSTART - 40)
CMDLEN		=	43

	.ORG	LOADSTART

START:
	mov	$START,sp
	mov	sp,r1
	cmp	pc,r1
	bcc	MAIN
	clr	r0
	cmp	(r0),$407	; check for PDP-11 executable header
	bne	1f
	mov	$20,r0		; skip PDP-11 executable header
1:
	mov	(r0)+,(r1)+	; relocate
	cmp	r1,$(START+1000)
	bcs	1b		; 137026
	jmp	(sp)		; jump to

MAIN:
	mov	$JUMPTABLE,r5
	mov	$CMDBUFFER,r4
	jsr	pc,MTRESET
	mov	$'=',r0
	jsr	pc,(r5)		; PUTCHAR

; get command
1:
	mov	r4,r1		; POINT TO START OF CMDBUFFER
2:
	jsr	pc,GETCHAR
	cmp	r0,$12		; LF?
	beq	3f		; 137126
	cmp	r0,$100
	beq	1b		; 137062
	movb	r0,(r1)+	; STORE IN CMDBUFFER
	cmp	r0,$CMDLEN	; 43
	bne	2b		; 137064
	sub	$2,r1		; POINT BACK TWO
	cmp	r1,r4		; EMPTY
	bcs	1b		; 137062
	br	2b		; 137064

; process the command
3:
	clrb	(r1)		; ZERO TERMINATE CMDBUFFER
	cmp	r1,r4		; EMPTY COMMAND?
	blos	START		; RESTART
	mov	$1,NUMSECTS	; READ ONE SECTOR
	mov	$164000,ENDADDR
	jsr	pc,READSECTS	; READ FIRST SECTOR
	clr	r1
1:
	mov	r1,r2
	mov	r4,r0
2:							; COMPARE CMDBUFFER WITH STRING IN FIRST SECTOR
	cmpb	(r0)+,(r1)	; r0=POINTER INTO CMDBUFFER, r1=0
	bne	3f		; 137174
	tstb	(r1)+
	bne	2b
	br	4f		; 137216
3:
	mov	r2,r1		; RESET r1=0
	add	$100,r1		; SKIP 64B
	cmp	r1,$30000	; TOO BIG?
	bcs	1b		; SCAN FOR NEXT BOOT LOADER
	jsr	pc,MTRESET	; RESET MT
	br	START		; AND REQUEST NEXT LOADER NAME

4:
LOAD:				; FOUND SECTOR WITH BOOT LOADER
	mov	54(r2),NUMSECTS	; READ DETAILS FROM RECORD
	mov	46(r2),r0	; GET LENGTH
	inc	r0
	clc
	ror	r0
	neg	r0
	mov	r0,ENDADDR
	clr	r0
1:
	clr	(r0)+
	cmp	r0,sp
	bcs	1b		; 137246
	jsr	pc,READSECTS	; 137462
	jsr	pc,MTRESET
	br	BOOT

NUMSECTS: 	.WORD	0
ENDADDR:	.WORD	0
STARTADDR:	.WORD	0

GETCHAR:
	tstb	*$KL11RCSR	; 177560
	bge	1b		; 137274
	mov	KL11RBUF,r0	; 177562
	bic	$177600,r0	; mask off bits
	cmp	r0,$101
	bcs	2f		; 137332
	cmp	r0,$132
	bhi	2f		; 137332
	add	$40,r0		; conver to lowercase
2:
	cmp	r0,$15		; CR?
	bne	PUTCHAR		; 137344
	mov	$12,r0		; replace CR with LF

PUTCHAR:
	cmp	r0,$12		; is LF?
	bne	4f		; 137364
	mov	$15,r0		; CR
	jsr	pc,(r5)		; PUTCHAR
	mov	$12,r0		; LF
4:
	tstb	KL11XCSR
	bpl	4b		; 137364
	mov	r0,KL11XBUF	; 177566
	rts	pc

PUTS:	; pc is on  the top of stack, r5 points to the jump table
1:
	movb	*0(sp),r0
	beq	2f		; 137414
	jsr	pc,(r5)		; PUTCHAR
	inc	(sp)
	br	1b		; 137400
2:
	add	$2,(sp)		; return address
	bic	$1,(sp)		; align to word
	rts	pc

BOOT:
	clr	r0
	cmp	(r0),$407	; CHECK FOR HEADER
	bne	2f
1:
	mov	20(r0),(r0)+	; RELOCATE BACK
	cmp	r0,sp
1:
	bcs	1b		; 137436
	mov	$START,-(sp)
	clr	pc		; jump to 0

; jump table
JUMPTABLE:
	br	PUTCHAR
	br	GETCHAR
	br	PUTS


READSECTS:
1:
	mov	STARTADDR,ADDRESS	; 137652
	cmp	SECTCNT,NUMSECTS
	beq	3f		; 137516
	bhi	2f		; 137510
	jsr	pc,MTREAD	; 137536
	br	1b		; 137462
2:
	jsr	pc,MTRESET
	br	1b		; 137462
3:
	mov	ENDADDR,r1
4:
	jsr	pc,MTREAD	; 137536
	add	$400,r1
	bmi	4b		; 137522
	rts	pc

MTREAD:
1:
	mov	$MTS,r0
	bit	$2,(r0)+	; TEST STATUS
	bne	1b		; 137536
	tstb	(r0)+		; TEST STATUS
	bpl	1b		; 137536
	inc	r0		; POINT TO MTBRC
	mov	$177000,(r0)+	;
	mov	ADDRESS,(r0)	; ADDRESS TO MTCMA
	mov	$MTC,r0		; POINT TO COMMAND
	mov	$60003,(r0)	; SET COMMAND
2:
	tstb	(r0)		; READ COMMAND
	bpl	2b		; 137576
	tst	(r0)+
	bpl	3f		; 137620
	mov	$177777,(r0)	; WRITE COMMAND
	mov	$60013,-(r0)	; WRITE COMMAND
	br	2b		; 137536
3:
	add	$1000,ADDRESS
	inc	SECTCNT		; 137650
	rts	pc

MTRESET:
	mov	$60017,*$MTC
	clr	SECTCNT		; 137650
	rts	pc

SECTCNT:	.WORD	0
ADDRESS:	.WORD	0

	.END
