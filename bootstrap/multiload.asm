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

	ORG	LOADSTART

START:
137000: 012706 137000       	mov	$START,sp		
137004: 010601              	mov	sp,r1			
137006: 020701              	cmp	pc,r1			
137010: 103013              	bcc	MAIN
137012: 005000              	clr	r0			
137014: 021027 000407       	cmp	(r0),$407	; check for PDP-11 executable header
137020: 001002              	bne	1f
137022: 012700 000020       	mov	$20,r0		; skip PDP-11 executable header
1:
137026: 012021              	mov	(r0)+,(r1)+	; relocate
137030: 020127 140000       	cmp	r1,$(START+1000)
137034: 103774              	bcs	1b		; 137026			
137036: 000116              	jmp	(sp)		; jump to 

MAIN:
137040: 012705 137454       	mov	$JUMPTABLE,r5
137044: 012704 136740       	mov	$CMDBUFFER,r4
137050: 004767 000560       	bsr	MTRESET
137054: 012700 000075       	mov	$'=',r0
137060: 004715              	bsr	(r5)		; PUTCHAR

; get command
1:
137062: 010401              	mov	r4,r1		; POINT TO START OF CMDBUFFER
2:
137064: 004767 000204       	bsr	GETCHAR
137070: 020027 000012       	cmp	r0,$12		; LF?
137074: 001414              	beq	3f		; 137126
137076: 020027 000100       	cmp	r0,$100
137102: 001767              	beq	1b		; 137062	
137104: 110021              	movb	r0,(r1)+	; STORE IN CMDBUFFER
137106: 020027 000043       	cmp	r0,$CMDLEN	; 43
137112: 001364              	bne	2b		; 137064
137114: 162701 000002       	sub	$2,r1		; POINT BACK TWO
137120: 020104              	cmp	r1,r4		; EMPTY
137122: 103757              	bcs	1b		; 137062
137124: 000757              	br	2b		; 137064

; process the command
3:
137126: 105011              	clrb	(r1)		; ZERO TERMINATE CMDBUFFER
137130: 020104              	cmp	r1,r4		; EMPTY COMMAND?
137132: 101722              	blos	START		; RESTART
137134: 012767 000001 000124	mov	$1,NUMSECTS	; READ ONE SECTOR
137142: 012767 164000 000120	mov	$164000,ENDADDR
137150: 004767 000306       	bsr	READSECTS	; READ FIRST SECTOR
137154: 005001              	clr	r1
1:
137156: 010102              	mov	r1,r2
137160: 010400              	mov	r4,r0
2:							; COMPARE CMDBUFFER WITH STRING IN FIRST SECTOR
137162: 122011              	cmpb	(r0)+,(r1)	; r0=POINTER INTO CMDBUFFER, r1=0
137164: 001003              	bne	3f		; 137174
137166: 105721              	tstb	(r1)+			
137170: 001374              	bne	2b
137172: 000411              	br	4f		; 137216			
3:
137174: 010201              	mov	r2,r1		; RESET r1=0
137176: 062701 000100       	add	$100,r1		; SKIP 64B
137202: 020127 030000       	cmp	r1,$30000	; TOO BIG?
137206: 103763              	bcs	1b		; SCAN FOR NEXT BOOT LOADER
137210: 004767 000420       	bsr	MTRESET		; RESET MT
137214: 000671              	br	START		; AND REQUEST NEXT LOADER NAME

4:
LOAD:	; FOUND SECTOR WITH BOOT LOADER
137216: 016267 000054 000042	mov	54(r2),NUMSECTS	; READ DETAILS FROM RECORD
137224: 016200 000046       	mov	46(r2),r0	; GET LENGTH
137230: 005200              	inc	r0			
137232: 000241              	clc				
137234: 006000              	ror	r0			
137236: 005400              	neg	r0			
137240: 010067 000024       	mov	r0,ENDADDR		
137244: 005000              	clr	r0
1:
137246: 005020              	clr	(r0)+			
137250: 020006              	cmp	r0,sp			
137252: 103775              	bcs	1b		; 137246			
137254: 004767 000202       	bsr	READSECTS	; 137462			
137260: 004767 000350       	bsr	MTRESET			
137264: 000460              	br	BOOT

NUMSECTS: 	.WORD	0
ENDADDR:	.WORD	0
STARTADDR:	.WORD	0

GETCHAR:
137274: 105737 177560       	tstb	*$KL11RCSR	; 177560 
137300: 002375              	bge	1b		; 137274			
137302: 016700 040254       	mov	KL11RBUF,r0	; 177562
137306: 042700 177600       	bic	$177600,r0	; mask off bits
137312: 020027 000101       	cmp	r0,$101			
137316: 103405              	bcs	2f		; 137332
137320: 020027 000132       	cmp	r0,$132			
137324: 101002              	bhi	2f		; 137332
137326: 062700 000040       	add	$40,r0		; conver to lowercase
2:
137332: 020027 000015       	cmp	r0,$15		; CR?
137336: 001002              	bne	PUTCHAR		; 137344			
137340: 012700 000012       	mov	$12,r0		; replace CR with LF

PUTCHAR:
137344: 020027 000012       	cmp	r0,$12		; is LF?
137350: 001005              	bne	4f		; 137364	
137352: 012700 000015       	mov	$15,r0		; CR
137356: 004715              	bsr	(r5)		; PUTCHAR
137360: 012700 000012       	mov	$12,r0		; LF
4:
137364: 105767 040174       	tstb	KL11XCSR
137370: 100375              	bpl	4b		; 137364			
137372: 010067 040170       	mov	r0,KL11XBUF	; 177566		
137376: 000207              	rts	pc

PUTS:	; pc is on  the top of stack, r5 points to the jump table
1:
137400: 117600 000000       	movb	*0(sp),r0
137404: 001403              	beq	2f		; 137414			
137406: 004715              	bsr	(r5)		; PUTCHAR
137410: 005216              	inc	(sp)
137412: 000772              	br	1b		; 137400			
2:
137414: 062716 000002       	add	$2,(sp)		; return address
137420: 042716 000001       	bic	$1,(sp)		; align to word
137424: 000207              	rts	pc

BOOT:
137426: 005000              	clr	r0
137430: 021027 000407       	cmp	(r0),$407	; CHECK FOR HEADER
137434: 001004              	bne	2f
1:
137436: 016020 000020       	mov	20(r0),(r0)+	; RELOCATE BACK
137442: 020006              	cmp	r0,sp
1:
137444: 103774              	bcs	1b		; 137436
137446: 012746 137000       	mov	$START,-(sp)
137452: 005007              	clr	pc		; jump to 0

; jump table
JUMPTABLE:
137454: 000733              	br	PUTCHAR
137456: 000706              	br	GETCHAR
137460: 000747              	br	PUTS


READSECTS:
1:
137462: 016767 177604 000162	mov	STARTADDR,ADDRESS	; 137652		
137470: 026767 000154 177570	cmp	SECTCNT,NUMSECTS		
137476: 001407              	beq	3f		; 137516
137500: 101003              	bhi	2f		; 137510
137502: 004767 000030       	bsr	MTREAD		; 137536
137506: 000765              	br	1b		; 137462			
2:
137510: 004767 000120       	bsr	MTRESET			
137514: 000762              	br	1b		; 137462			
3:
137516: 016701 177546       	mov	ENDADDR,r1		
4:
137522: 004767 000010       	bsr	MTREAD		; 137536
137526: 062701 000400       	add	$400,r1			
137532: 100773              	bmi	4b		; 137522	
137534: 000207              	rts	pc

MTREAD:
1:
137536: 012700 172520       	mov	$MTS,r0		
137542: 032720 000002       	bit	$2,(r0)+	: TEST STATUS
137546: 001373              	bne	1b		; 137536			
137550: 105720              	tstb	(r0)+		; TEST STATUS
137552: 100371              	bpl	1b		; 137536			
137554: 005200              	inc	r0		; POINT TO MTBRC
137556: 012720 177000       	mov	$177000,(r0)+	; 
137562: 016710 000064       	mov	ADDRESS,(r0)	; ADDRESS TO MTCMA 
137566: 012700 172522       	mov	$MTC,r0		; POINT TO COMMAND
137572: 012710 060003       	mov	$60003,(r0)	; SET COMMAND
2:
137576: 105710              	tstb	(r0)		; READ COMMAND
137600: 100376              	bpl	2b		; 137576
137602: 005720              	tst	(r0)+
137604: 100005              	bpl	3f		; 137620
137606: 012710 177777       	mov	$177777,(r0)	; WRITE COMMAND
137612: 012740 060013       	mov	$60013,-(r0)	; WRITE COMMAND
137616: 000747              	br	2b		; 137536
3:
137620: 062767 001000 000024	add	$1000,ADDRESS
137626: 005267 000016       	inc	SECTCNT		; 137650			
137632: 000207              	rts	pc

MTRESET:
	012737 060017 172522	mov	$60017,*$MTC
137642: 005067 000002       	clr	SECTCNT		; 137650			
137646: 000207              	rts	pc

SECTCNT:	.WORD	0
ADDRESS:	.WORD	0
