;Version of ODT to be blown into a 2716 PROM for use as console ODT on a T-11
;system. This code started life as the DECUS offering ODT11X. It now has many
;more features resembling those of RT-11's ODT.

;Possible additions:
;	XON - XOFF recognition
;	Aborting printout after ;W & ;E
;	<address>;<count>A	Ascii string print/change

RAM		=	30000-400	; 12KB

ROMBASE		=       0140000	; 0xC000 (48KB)
;ROMBASE	=       0170000	; 0xF000 (60KB)
;ROMBASE	=       037000  ; 0x3E000 (20KB)
;ROMBASE	=       050000  ; 0x5000 (20KB)

bkp	=	16	;Number of breakpoints-1 mult. by 2
tvec	=	14	;BREAK vector location
stm	=	340	;Priority mask - status register
tbt	=	20	;T-bit mask - status register

rcsr	=	177560	;r c/sr		Console input port addresses
rdb	=	177562	;r data buffer
tcsr	=	177564	;t c/sr		Console output port addresses
tdb	=	177566	;t data buffer
st	=	177776		;Not LSI - address of status register

cr	=	15	;Carrage return
lf	=	12	;Line feed

	.ORG	ROMBASE

; Initialise ODT

odt:	clr	csr1		;Clear 'saved' terminal status regs.
	mov	$reloc,sp	;Set up stack pointers to init. tables
	mov	sp,r0
	clr	r1		;& setup some other vectors
1:	clr	-(sp)		;Clear out registers
	mov	$-1,(r0)+	;Remove relocation constants
	mov	$Lbreak,(r1)+	;Set up a load of vectors as BPT's
	mov	$stm,(r1)+
	cmp	sp,$ur0		;All registers set up yet ?
	bhi	1b		;Loop if not
	mov	$1000,usp	;Give the user a possible stack
	movb	-(r0),p		;Disallow proceed
	clr	s.t		;Disable single instruction & T flags
	mov	$7,pri		;Set default ODT priority
	mov	$1,format	; XXXX
	jmp	rall		;Clear breakpoint tables

; Output the top RAD50 char from r4. The RAD50 character set used is:
;	" ABCDEFGHIJKLMNOPQRSTUVWXYZ$./0123456789"
;Note that in this encoding, '$' is 33, the ASCII code for escape.
;There's probably a nice trick in there somewhere, if I could see it :-)

chr50o:	clr	r0		;Extract a RAD50 char from r4
1:	inc	r0		;r0 := r4/1600.   r4 := r4%1600.
	sub	$0t1600,r4	; By repeated subtraction
	bhis	1b
	add	$0t1600,r4	;Correct for the extra subtract
	mov	$' [',-(sp)	;Convert single RAD50 char to ASCII
	dec	r0		;RAD50 0 is space, is on the stack
	beq	3f
2:	swab	(sp)		;Not space, add '@' to convert letters
	sub	$0t27,r0		;Is it really a letter ?
	blo	3f
	mov	$'$H',(sp)	;No, must be $./ or digit
	tst	r0		;Is it $ ?
	bne	2b		;No, add '-'+27='H' for ./01234567
3:	add	(sp)+,r0	;Convert the character
	jsr	r5,ftyp		;Print it out
	clr	r0		;Multiply r4 by octal 50 to do the next char.

;Routine used by RAD50 conversions, and octal numeric input.
;After calling MUL50:	r4 := r4 * 50 + r0,  r0 := r4 * 8 + r0,  r2 := r2 + 1
;After calling MULIN:	r4 := r4 * 4 + r0,   r2 := r2 + 1

mul50:	asl	r4
	asl	r4
	asl	r4
	add	r4,r0
mulin:	asl	r4
	asl	r4
	add	r0,r4
	inc	r2		;Count this char
	rts	pc

;Accept a RAD50 char & pack into r4

chr50i:	jsr	r5,get		;Get a char
	mov	$40,r1		;Put constant 40 in R1
	cmp	r0,r1		;Is char a space ?
	beq	3f		;Branch if space
	blo	clgl1		;Lower than space - exit
	cmp	r0,$'A'		;Possible letter ?
	bhis	1f
	mov	$11,r1		;Not letter, change constant
	cmp	r0,$'$'		;$=44
	beq	3f		;Is '$' - return 44-11=33
	cmp	r0,$'.'		;Not '$', range .-9 ? (.=56)
	blo	clgl1		;No - exit
	cmp	r0,$'9'		;Is it ?
	br	2f

1: ;	BIC	R1,R0		;Fold lower case to upper
	cmp	r0,$'Z'		;Alphabetic ?
2:	bhi	clgl1		;Not RAD50 char - exit
	sub	r1,r0
3:	sub	r1,r0
	br	mul50		;Add new char to word in R4

;Search for the char in R0 in the list at R1. If not there, see if octal digit
;Returns carry=0 -> not digit, char at -1(r1)
;	 carry=1 -> digit, value in r0
;No return if not found & not digit

chklst:	cmpb	r0,(r1)+	;This character ?
	beq	1f		;Yes, return
	tstb	(r1)		;No, more to check ?
	bne	chklst		;Loop if so
	sub	$'8',r0		;Char not in table. Octal digit ?
	add	$10,r0
	bcc	err0		;Not digit, give error message
1:	rts	pc


; Process R and ! - relocation commands

rel:	mov	cad,r0		;'R' command - possible data to relocate
	tstb	semic		;Are we setting or relocating ?
	beq	rel1		;Branch if relocating
	mov	$reloc,r0	;Get a pointer to the relocation regs
	dec	r3		;Setting or removing ?
	bpl	1f		;Branch if setting
	mov	r3,r5		;Removing - force value of -1
	tst	r2		;Reg number given ?
	beq	2f		;No - remove all
1:	dec	r2		;Legal relocation reg ?
	bgt	err		;No - multi digit number !
	asl	r4		;Ok - make word offset
	mov	r5,reloc(r4)	;Set value in table
	br	dcd

2:	mov	r5,(r0)+	;Remove all relocation constants
	cmp	r0,$reloc+20
	blo	2b
	br	dcd

reladr:	mov	$cad,r0		;'!' command - get address to relocate
rel1:	cmp	bw,$2		;Ensure a word is open
	bne	err0
	mov	r5,-(sp)	;Fake return address part of a JSR R5,
	mov	$dcd2,r5	; which will return to DCD2
	asl	r4		;Make address of wanted relocation
	add	$reloc,r4
	mov	(r0),-(sp)	;Yes - fake first part of CADA
	jsr	r5,eqtype	;Type an '='
	dec	r2		;Was specific register requested ?
	bpl	2f
	jmp	cada1		;No - let CADA choose one, returns to dcd2

2:	bne	err0		;Yes - check only 1 digit
	mov	r4,r0
	jmp	cadain		;Output relocated address, return to dcd2

clgl1:	tst	(sp)+
	br	clgl

; Process X - RAD50

rad50:	jsr	r5,tstwrd	;Check word mode, put address in r2
	jsr	r5,eqtype	;Is word mode. Type the '='
	mov	(r2),r4		;Get the contents of that location
	mov	$4,r3		;Set up the character counter
1:	jsr	pc,chr50o	;Print a RAD50 character
	dec	r3
	bne	1b		;4 of 'em. The 4th will be a space
	clr	r2		;Reset r2 to count input characters
2:	jsr	pc,chr50i	;Get a char, & convert to RAD50
	cmp	r2,$3		;Loop 'till 3 characters packed
	blo	2b		;Leave r2 with number exists indicator
	jsr	r5,type		;Got all 3, delimit with a space
	.asciz	" "
	br	scan

; Special name handler
;  Depends upon the explicit order of the two tables TL and UR0

regt:	jsr	r5,get		;Special name, get one more character
	mov	$tl,r1		;Table start address
	jsr	pc,chklst	;See if it's a known character
	mov	r0,r4		;Move digit value (if there)
	bcs	1f		;Branch if octal digit
	sub	$tl-7,r1	;Letter - make small integer
	mov	r1,r4		;In R4
1:	inc	r2		;Indicate char found
	asl	r4		;Make into word offset
	add	$ur0,r4		;Form address of wanted item
	cmp	r4,$reloc	;Is it a breakpoint reg ?
	blos	2f
	mov	$adr1,r4	;Yes - correct address
2:	jsr	r5,type		;Give 'open' character
	.asciz	"/"
	br	wrd		;Then go & open it


tcls:	jsr	pc,clse		;Close current cell
tstwrd:	cmp	$2,bw		;Only word mode allowed
	bne	err0		;Branch if error
	mov	cad,r2		;Current address in R2
	rts	r5

err0:	br	err		;Show the error


; Process S - single instruction mode

sngl:	movb	r2,s		;Set the flag as requested
	br	dcd


; @ Handler - open absolute location

orab:	jsr	r5,tcls		;Test word mode and close
	mov	(r2),r2		;Get absolute address
	br	pcs

; > Handler - follow relative branch (NOT SOB !)

orrb:	jsr	r5,tcls		;Test and close
	movb	(r2),r1		;Compute new address
	inc	r1
	asl	r1		;R2=2(@R2+1)
	add	r1,r2		;   +PC
	br	pcs

; _ Handler - open indexed on the PC

orpc:	jsr	r5,tcls		;Test word mode and close
	add	(r2)+,r2	;Compute
pcs:	mov	cad,dot		;Save current position
	mov	r2,cad		;Update CAD
	br	op2		;Go finish up

;  All registers may be used (R0-R5),

err:	jsr	r5,type		; ? to be typed
	.asciz	"?"
dcd:	clr	bw		;Close all
	jsr	r5,crtype	;Type  <CR><LF>*
	.asciz	"*"
dcd2:	clr	semic		;Clear semi-colon flag & SEQ
	clr	r3		;R3 is a save register for R2
	clr	r5		;R5 is a save register for R4
dcd1:	clr	offset		;Clear out relocation offset
dcdr:	clrb	negate		;No '-' sign received yet
	clr	r4		; R4 contains the converted octal
	clr	r2		; R2 is the digit count/number found flag
scan:	mov	$ur0,sp		;Reset stack to be safe
	jsr	r5,get		;Get a char, return in R0
clgl:	cmpb	r0,$'-'		;Check for negative number
	bne	1f		;Not - check normal things
	tst	r2		;'-' must preceed all digits
	bne	err		;It doesn't... so complain
	incb	negate		;Negative - flag it
	br	scan		;Then get the next char
1:	mov	$lgch,r1	;Point at command char table
	jsr	pc,chklst	;Lookup char in list
	bcc	2f		;Letter or octal digit ?
	asl	r4		;Digit - build number
	jsr	pc,mulin
	br	scan		;Loop for next char
2:	asrb	negate		;Letter. Was there a '-' sign ?
	bcc	3f		;Skip this if not
	neg	r4		;'-' - negate value
3:	add	offset,r4	;Add in relocation offset
	asl	r1
	jmp	*(lgdr-2-2*lgch)(r1)	;Go to proper routine

; Registers on dispatch:
;  R0 - Character code of command	R3 - Digits in arg before ';'
;  R1 - Offset into dispatch table	R4 - Value of arg after ';'
;  R2 - Digits in arg after ';'		R5 - Value of arg before ';'

; Comma processor
comma:	dec	r2
	bne	err		;Error if not single digit relocation reg
	sub	offset,r4	;In case twit relocated it
	asl	r4		;Make into word offset
	mov	reloc(r4),r2	;Extract relocation constant
	mov	r2,offset	;Store it
	inc	r2		;Was it legal ?
	beq	dcd1		;No - zap it
	br	dcdr		;Yes - keep it

; Semi-colon processor
semi:	mov	r2,r3		;A semi-colon has been received
	mov	r4,r5		;Numeric flag to R3, contents to R5
	incb	semic		;Set semi-colon flag
	br	dcd1		;Go back for more
; Process C - constant reg.

const:	tst	r3		;Setting or using ?
	beq	1f
	mov	r5,creg		;Setting
	jsr	r5,eqtype	;Say "=nnnnnn" to show the value
	mov	$2,bw		;Say this is word mode
	mov	r5,r0		;Get the word to print
	jsr	r5,cadv		;Print the word in r0
	br	dcd

1:	mov	creg,r4		;Using - get value
	bisb	(pc),r2		;Say more than 1 digit there
	br	scan

; Process / and \ - open word or byte

wrd:	mov	$2,bw		;Open word
	br	wb1
byt1:	rol	r4		;Get the address back
byt:	mov	$1,bw		;Open byte
wb1:	tst	r2		;Get value if R2 is non-zero
	beq	wrd1		;Skip otherwise
	mov	r4,cad		;Put value in CAD
wrd1:	mov	cad,r4		;Get current address
	cmp	$1,bw		;Check byte mode
	beq	2f		;Jump if byte
	asr	r4		;Move one bit to carry
	bcs	byt1		;Jump if odd address
	mov	*cad,r0		;Get contents of word
	br	3f
2:	movb	(r4),r0		;Get contents of byte
3:	jsr	r5,cadv		;Go get and type out @CAD
	br	dcd2		;Go back to decoder

; Process carriage return

cret:	jsr	pc,clse		;Close location
dcda:	br	dcd		;Return to decoder

; Process <LF>, open next word

old:	incb	seq		;Set need DOT to CAD move
op1:	mov	bw,r0		;<LF> received
err2:	beq	err		;Error if nothing is open
	jsr	pc,clse		;Close present cell
	tstb	seq		;See if < command
	beq	1f		;Branch if not
	mov	dot,cad		;Go to the former stream
1:	add	r0,cad		;Generate new address
op2:	jsr	r5,crlf		;<CR><LF>
	mov	bw,-(sp)	;Save bw
	mov	$2,bw		;Set to type full word address
	mov	cad,r0		;Number to type
	jsr	r5,cada		;Type out address
	mov	(sp),bw		;Restore bw
	mov	$'\\/',r0	;Things to type
	dec	(sp)+		;Is it byte mode?
	beq	1f		;Jump if yes
	swab	r0		;Type a /
1:	jsr	r5,ftyp		;Or a \
	br	wrd1		;Go process it

; Process ^, open previous word

back:	mov	bw,r0		; ^ received
	beq	err2		;Error if nothing open
	jsr	pc,clse
	sub	r0,cad		;Generate new address
	br	op2		;Go do the rest

; B Handler - set and remove breakpoints

bkpt:	mov	$breakc,r0
	asl	r4		;Multiply number by two
	tst	r3
	beq	remb		;If R3 is zero go remove breakpoint
	asr	r5		;Get one bit to carry
	bcs	err1		;Badness if odd address
	asl	r5		;Restore one bit
	add	$adr1,r4
	dec	r2
	beq	set1		;Jump if specific cell
	bpl	err1		;Too many digits
set:	cmp	r0,(r4)		;Is this cell free?
	beq	set1		;Jump if yes
	cmp	r4,$bkp+adr1	;Are we at the end of our rope
	bhis	err1		;Yes, there is nothing free
	tst	(r4)+		;Increment by two
	br	set
set1:	mov	r5,(r4)		;Set breakpoint
	br	dcda		;Return
remb:	dec	r2		;How many reg # digits ?
	bmi	rall		;None - remove all
	bne	err1		;More than 1 - error
	mov	r0,adr1(r4)	;Clear breakpoint
	clr	ct(r4)		;Clear count also
	br	dcda
rall:	clr	r4
1:	mov	$breakc,adr1(r4) ;Reset bkpt
	mov	$Lbreak,uin(r4)	;Reset contents of table
	clr	ct(r4)		;Clear count
	tst	(r4)+		;Increment by two
	cmp	r4,$bkp+2	;All done?
	blos	1b		;Loop if not
dcdb:	br	dcda

; Process O, compute offset

ofst:	cmp	$2,bw		;Check word mode
	bne	err1		;Error if not correct mode
	jsr	r5,type		;Type one blank as a separator
	.asciz	" "
	tst	r3		;Was semi-colon typed?
	beq	err1		;No, call it an error
	sub	cad,r5		;Compute
	dec	r5
	dec	r5		; 16 bit offset
	mov	r5,r0
	jsr	r5,cadv		;Number in R0 - word mode
	mov	r5,r0
	asr	r0		;Divide by two
	bcs	1f		;Error if odd
	cmp	$-200,r0	;Compare with -200
	bgt	1f		;Do not type if out of range
	cmp	$177,r0		;Compare with +177
	blt	1f		;Do not type if out of range
	dec	bw		;Set temporary byte mode
	jsr	r5,cadv		;Number in R0 - byte mode
	inc	bw		;Restore word mode
1:	jmp	dcd2		;All done

; Common routine for ;F and ;I, word and byte area fill

fill:	mov	$msk+2,r0	;Address of parameters
	mov	(r0)+,r1	;Start of block to fill
	mov	(r0)+,r2	;End address
	mov	(r0),r0		;Value to fill with
fillit:	cmp	r1,r2		;Any more to fill ?
	bhi	dcdb		;No, all done
	jmp	(r5)		;Yes, move the correct data size

; Searches - 	$MSK   has the mask
;		$MSK+2 has the FWA
;		$MSK+4 has the LWA
;Registers:
; R0 -	Contents of location	R3 - Effective address referenced
; R1 -	Word/addr mode flag	R4 - Search mask
; R2 -	Address of location	R5 - Object to search for

eff:	inc	r1		;Set effective search
	br	wds

wsch:	clr	r1		;Set word search
wds:	tst	r3		;Check for object found
	beq	err1		;Error if no object
	mov	$2,bw		;Set word mode
	mov	msk+2,r2	;Set origin
	mov	msk,r4		;Set mask
	com	r4
wds2:	cmp	r2,msk+4	;Is the search all done?
	bhi	dcdb		; yes
	tstb	*$rcsr		;User hitting the keyboard ?
	bmi	dcdb		;Yes, stop search
	mov	$'/@',-(sp)	;Possible address/contents seperators
	mov	(r2),r0		;Get object
	tst	r1		;Which search mode ?
	bne	eff1		;Branch if effective search
	bic	r4,r0		;Apply mask to data
	bic	r4,r5		; and test word
	cmp	r0,r5		;Now compare the two
wds3:	bne	wds4		;Re-loop if no match
	mov	r4,-(sp)	;Registers R2,R4, and R5 are safe
	jsr	r5,crlf
	mov	r2,r0		;Get ready to type
	jsr	r5,cada		;  type address
	mov	2(sp),r0	;Get seperator
	jsr	r5,ftyp		; type it
	mov	(r2),r0		;Get contents
	jsr	r5,cadv		;Type contents
	mov	(sp)+,r4	; restore R4
wds4:	cmp	(r2)+,(sp)+	;Increment to next cell, drop seperator
	br	wds2		;  and return

err1:	jmp	err		;Intermediate help

; Process ;I, byte area fill

bfill:	jsr	r5,fill		;Do all the common stuff
	movb	r0,(r1)+	;Fill in another byte
	br	fillit		;The rest is common too

;	.ORG	ROMBASE + 02004
power:	jmp	odt
Lreset:	br	Lbreak

; Process ;F, word area fill

wfill:	jsr	r5,fill		;Do all the common stuff
	mov	r0,(r1)+	;Fill in another word
	br	fillit		;The rest is common too

; More of the search commands... effective address search part

eff1:	swab	(sp)		;Set '@' as seperator
	cmp	r0,r5		; Is (X)=K?
	beq	wds3		;Type if equal
	mov	$'_>',(sp)	;Change seperators
	mov	r0,r3		;(X) to R3
	inc	r3
	inc	r3		;(X)+2
	add	r2,r3		;(X)+X+2
	cmp	r3,r5		;Is (X)+X+2=K?
	beq	wds3		;Branch if equal
	swab	(sp)		;Make '>' seperator
	movb	r0,r0		;Sign extend the offset
	inc	r0
	asl	r0		;Multiply by two
	add	r2,r0		;Add PC
	cmp	r0,r5		;Is the result a proper rel. branch?
	br	wds3

; Process G - go

go:	tst	r3		;Was K; typed?
	beq	err1		;Type ?<CR,LF> if not
	movb	$bkp+3,p	;Clear proceed
	asr	r5		;Check low order bit
	bcs	err1		;Error if odd number
	asl	r5		;Restore word
	mov	r5,upc		;Set up new PC
	jsr	r5,rstt		;Set high priority & restore teletype
tbit:	clrb	t		;Clear T-flag
	tstb	s		;See if we need a T bit
	bne	go2		;If so go now
	mov	$bkp,r4		;Restore all breakpoints (0-7)
1:	mov	*adr1(r4),uin(r4) ;Save contents
	clr	*adr1(r4)		;Replace with 'HALT' trap
	dec	r4
	dec	r4
	bge	1b		;Loop until done
go2:	mov	(sp)+,r0	;Restore registers R0-R6
	mov	(sp)+,r1
	mov	(sp)+,r2
	mov	(sp)+,r3
	mov	(sp)+,r4
	mov	(sp)+,r5
	mov	(sp),sp		;Restore user stack
	mov	ust,-(sp)	; and status

	bic	$tbt,(sp)	;Clear the T bit
	movb    (sp),*$st	;Enable user priority interrupts
	tst	s.t		;Either S or T flags set ?
	beq	1f		;No, carry on
	bis	$tbt,(sp)	;Yes, set the T bit
;Even on a T-11 we must grab the BPT trap vector when the T bit is set
	mov	$Lbreak,*$tvec	;Force correct break vector PC
	mov	$stm,*$tvec+2	;Status word to break vector+2

1:	mov	upc,-(sp)	;Restore users PC
	rtt			;Then do some of the users prog.

; Process P - proceed;  Only allowed after a breakpoint

proc:	movb	p,r0		;Check legality of proceed
	blt	err1		;Not legal
	tst	r2		;Check for illegal count
	bne	err1		;Jump if illegal
	tst	r3		;Was count specified?
	beq	pr1		;No
	mov	r5,ct(r0)	;Yes, put away count
pr1:	jsr	r5,rstt		;Force high priority & restore tty
c1:	cmpb	p,$bkp		;See if a real breakpoint or a fake
	bhi	tbit		;Branch if fake
	tstb	s		;See if single instruction mode
	bne	tbit		;If so exit now
	incb	t		;Set T-bit flag
	br	go2

; Breakpoint handler

Lbreak:	mov	(sp)+,upc	;Priority is 7 upon entry
	mov	(sp)+,ust	;Save status and PC
	movb	$bkp+3,p	;Tell ;P that we can continue

; Save registers R0-R6;  internal stack

	mov	sp,usp		;Save user stack address
	mov	$usp,sp		;Set to internal stack
	mov	r5,-(sp)	;Save registers
	mov	r4,-(sp)	;0
	mov	r3,-(sp)	;
	mov	r2,-(sp)	; thru
	mov	r1,-(sp)	;
	mov	r0,-(sp)	;	5

	movb	t,r4		;Check for T-bit set
	beq	Lb1		;Jump if not set
	decb	r4		;Check prog. didn't mangle it
	beq	tbit		;OK - good T bit trap
	jsr	r5,crtype	;Tell user all is corrupt
	.asciz	"#"

; Remove breakpoints 0-7,  in the opposite order of setting

Lb1:	tstb	s		;See if single instruction is going
	bne	Lb3		;Skip if so
	clr	r4		;Remove all breakpoints
Lb2:	mov	uin(r4),*adr1(r4)	;Clear breakpoint
	tst	(r4)+
	cmp	r4,$bkp
	blos	Lb2		;Re-loop until done
Lb3:	mov	upc,r5		;Get PC, it points to the BREAK
	tstb	s		;See if it was single instruction fun
	bne	Lb5		;If so handle there
	tst	-(r5)
	mov	r5,upc
	mov	$bkp,r4		;Get a counter
Lb4:	cmp	r5,adr1(r4)	;Compare with list
	beq	Lb6		;Jump if found
	dec	r4
	dec	r4
	bge	Lb4		;Re-loop until found
	jsr	r5,svttyp	;Lower priority & save teletype status
	.asciz	"BE "		;Output "BE " for bad entry
	mov	r5,r0
	add	$2,upc		;Pop over the adjustment above
	br	Lb7		; or continue
Lb5:	movb	$bkp+2,r4	;Set break point high + 1
	mov	r5,adr1(r4)	;Store next PC value for type out
Lb6:	movb	r4,p		;Allow proceed
	dec	ct(r4)
	bgt	c1		;Jump if repeat
	mov	$1,ct(r4)	;Reset count to 1
	jsr	r5,svttyp	;Lower priority & save tty status; R4 is safe
	.asciz	"B"		;Type "B"
	movb	p,r0		;Convert breakpoint number to ascii
	asr	r0
	add	$'0;',R0	;Type number;
	jsr	r5,typ2
	movb	p,r4
	mov	adr1(r4),r0	;Get address of break
Lb7:	mov	$2,bw		;Set word mode
	jsr	r5,cada		;Type address
	jmp	dcd		;Go to decoder

; Type out address in r0, relocating as required.

cada:	tst	format		;Is relocation allowed ?
	bne	cadv		;Skip this if not
	mov	r0,-(sp)	;Save address to be output
cada1:	mov	$reloc,r4	;Point at relocation regs
	mov	$zero,r0	;Start assuming no relocation
1:	cmp	(sp),(r4)	;This relocation possible ?
	blo	2f		;Skip if too big
	cmp	(r4),(r0)	;Possible - better than current ?
	blos	2f		;Skip if not
	mov	r4,r0		;Better - save it
2:	tst	(r4)+		;Advance to next value
	cmp	r4,$reloc+10	;If there is one
	blo	1b		;Loop 'till all values tried
cadain:	sub	(r0),(sp)	;Now relocate address
	sub	$reloc,r0	;Which relocation reg ?
	blo	1f		;None - don't print one
	asr	r0		;Convert it to digit
	add	$'0,',r0
	jsr	r5,typ2		;Type it & a comma
1:	mov	(sp)+,r0	;Get offset, fall through & type

; Type out contents of word or byte with one trailing space. Word is in R0

cadv:	mov	$6,r3		;# of digits
	mov	$-2,r4		;# of bits first-3
	cmp	$1,bw		;See if word mode
	bne	spc		;Branch if so
	movb	r0,-(sp)	;Save byte for character output
	asr	r3		;Only do 3 digits
	inc	r4		;Do 2 bits first
	swab	r0		;And turn R0 around
	jsr	r5,spc		;Output in octal
	jsr	r5,eqtype	;Then as =<char code>
	bic	$177600,(sp)	;Strip parity bit
	cmpb	(sp),$40	;Control char ?
	bhis	1f		;Branch if not
	mov	$'?',(sp)	;Yes - unprintable
1:	mov	$20000,r0	;Get a trailing space
	bis	(sp)+,r0	;And char
	br	typ2		;Type it & return

spc:	mov	r0,-(sp)	;Save R0
1:	add	$3,r4		;Compute the number of bits to do
	clr	r0
2:	rol	(sp)		;Get a bit
	rol	r0		;Store it away
	dec	r4
	bne	2b		;Loop once for each bit
	add	$'0 ',r0	;Convert to ascii, put space in high byte
	jsr	r5,ftyp		;Type digit
	dec	r3
	bne	1b		;Loop if more digits
	tst	(sp)+		;Get rid of junk
styp:	swab	r0		;Setup trailing space & fall thru FTYP

; Type only one character (contained in R0)

ftyp:	tstb	*$tcsr
	bpl	ftyp
	movb	r0,*$tdb
typ1:	rts	r5

crlf:	mov	$5015,r0	;<CR,LF>
	jsr	r5,typ2
	clr	r0		;Fill with 2 nulls

typ2:	jsr	r5,ftyp
	br	styp

eqtype:	mov	$'=',r0		;Type an '=' sign
	br	ftyp

; General character input routine -- ODT11S
; Character input goes to R0

ttget:	tstb	*$rcsr
	bpl	ttget
	movb	*$rdb,r0
	rts	pc

get:	jsr	pc,ttget	;Get character
	inc	r0		;Make <rubout> give an illegal code
	bic	$177600,r0	;Strip off parity from character
	dec	r0		;Restore all chars except <rubout>
	beq	get		;Ignore nulls
	cmpb	r0,$lf		;See if a <LF>
	beq	3f		;If so save the paper
	cmpb	r0,$140		;See if upper case
	blos	2f		;OK if so
	sub	$40,r0		;Fold lower case to upper
2:	jsr	r5,ftyp		;Echo character
	cmpb	$40,r0		;Check for spaces
	beq	get		;Ignore spaces
3:	rts	r5

; Lower priority, save teletype status & print a message

svttyp:	movb	pri,r0		;Check if priority
	bpl	1f		; is as same as user pgm
	movb	ust,r0		;Pick up user ust if so
	br	2f
1:	asrb	r0		;Shift low order bits of actual priority
	rorb	r0		;  into
	rorb	r0		;    high order
	rorb	r0		;      position
2:	bic	$tbt,r0		;Clear "T" bit
	movb    r0,*$st	;Put the status away where it belongs
;
	movb	*$rcsr,csr1	;Save r c/sr
	movb	*$tcsr,csr2	;Save t c/sr
	clrb	*$rcsr		;Clear enable and maintenance
	clrb	*$tcsr		;  bits in both c/sr

; General string/character output routine

crtype:	jsr	r5,crlf		;Preceed with <CR><LF>
type:	movb	(r5)+,r0	;Get a char
	beq	typ1		;Exit when done
	jsr	r5,ftyp		;Type one character
	br	type		;Loop until done

; Set high priority & restore teletype status

rstt:	movb    $stm,*$st	;Set high priority
	jsr	r5,crlf		;Take a new line
	tstb	*$tcsr		;Wait ready
	bpl	.-4		;  on printer
	bit	$4000,*$rcsr	;Check busy flag
	beq	1f		;Skip ready loop if not busy
	tstb	*$rcsr		;Wait ready
	bpl	.-4		;  on reader
1:	movb	csr1,*$rcsr	;Restore
	movb	csr2,*$tcsr	;  the status registers
	rts	r5

; Close word or byte and exit,
; Upon entering, R2 has numeric flag, R4 has contents

clse:	tst	r2		;If no number was typed there is
	beq	2f		;No change to the open cell
	cmp	$1,bw
	beq	1f		;Jump if byte mode
	bhi	2f		;Jump if already closed
	mov	r4,*cad		;Store word
	br	2f
1:	movb	r4,*cad		;Store byte
2:	rts	pc

;Process L - load a program from tape

;Input format:

;Frame
;  1	001
;  2	000
;  3	Low order byte count	(Includes all except checksum,
;  4	High order byte count		even the 001 000.)
;  5	Low order load address
;  6	High order load address
;  7..	Data bytes
;  XXX	Checksum	(Includes all the block - even the 001)
;
;The checksum is calculated such that when all the bytes have
;been added up, the low byte of the sum will be zero.
;
;If the byte count is 6, the load address specified will be
;taken to be the start address of the program. If the address
;is even the program will be started, otherwise ODT will be
;re-entered.  If (count > 6), the data block will be loaded.
;
;This is the format used by DEC for paper tapes, and can be
;produced using the RT-11 LINK/LDA command.

;Register use:
; R0 - contents of byte		R3 - checksum
; R1 - load address		R4 - Word from L.GWRD; start address
; R2 - byte count		R5 - read subr pointer

load:	jsr	pc,ttget	;Wait for dummy char before starting
	mov	r3,-(sp)	;See if any relocation wanted
	beq	1f		;Branch if not
	mov	r5,(sp)		;Wanted - get relocation address
	bne	1f		;If given
	mov	l.addr,(sp)	;None given - place after last tape
1:	mov	$l.read,r5	;Setup read routine address
	clr	r1		;Clear out load address

;Look for a block start

l.ld2:	clr	r3		;Initialise ckecksum
	jsr	pc,(r5)		;Read a frame
	dec	r0
	bne	l.ld2		;Loop 'till byte=1 (block start)
	jsr	pc,(r5)		;Found '1' - skip next byte

;Get byte count & address, relocate address, if end goto L.JMP

	jsr	pc,l.gwrd	;Get byte count word
	mov	r4,r2		;Save it
	sub	$4,r2		;Correct it after reading 001,000,count
	jsr	pc,l.gwrd	;Get load address
	add	(sp),r4		;Plus relocation factor
	tst	r2		;Is it an end block ?
	beq	l.jmp		;Branch if so
	mov	r4,r1		;Keep as load address

;Read in the remainder of the data block

l.ld3:	jsr	pc,(r5)		;Read a frame
	bge	l.ld4		;Branch if more data there
	tstb	r3		;Look at checksum
	beq	l.ld2		;Good sum - find next block
l.bad:	.word	0			;Checksum error
	br	l.ld2

l.ld4:	movb	r0,(r1)+	;Put byte in memory
	br	l.ld3

;Input a frame, decrement byte count, accumulate checksum

l.read:	bis	$1,*$rcsr	;Set cassette & reader run
	jsr	pc,ttget	;Then wait for char
	bic	$177400,r0	;Strip off silly bits
	add	r0,r3		;Accumulate checksum
	dec	r2		;Update byte count
	rts	pc

;Assemble a full word of data

l.gwrd:	jsr	pc,(r5)		;Get low byte
	mov	r0,r4		;Save it
	jsr	pc,(r5)		;Then high byte
	swab	r0		; in high bits
	bis	r0,r4		;Assemble full word
	rts	pc

l.jmp:	inc	r2		;;Get the constant 1
	inc	r1		;;Round up load address
;;	cmpb	(r1)+,(r2)+	;r2=1, increment r1
	bic	r2,r1
	mov	r1,l.addr	;Save next free memory address
	jsr	pc,(r5)		;Read the checksum
	tstb	r3		;Good checksum ?
	bne	l.bad		;Branch if error
	bic	r2,r4		;Round down to word boundry
	mov	r4,upc		;Save start as users PC
	movb	$bkp+3,p	;Allow proceed from here

dcdc:	jmp	dcd

; Process D - dump memory out to tape in a format compatible with
; the L command above.

;Register use:
;R0 - Word / byte to punch	R3 - Address of D.PW routine
;R1 - Checksum			R4 - 1st address beyond block to punch
;R2 - Spare			R5 - Address of data to punch

dump:	jsr	pc,ttget	;Wait for dummy char
	mov	$d.pw,r3	;Load address of word read routine
	clr	r1		;Clear out checksum word
	clr	r0		;Form header word of '1'
	inc	r0
	jsr	r5,(r3)		;Then punch it
	mov	r4,r0		;Move to o/p reg
	add	$6,r0		;Account for header words
	sub	r5,r0		;Make # bytes to punch
	jsr	r5,(r3)		;Output block size
	mov	r5,r0		;Then block address
	jsr	r5,(r3)
2:	cmp	r5,r4		;Any bytes to o/p ?
	bhis	3f		;Go for checksum if not
	movb	(r5)+,r0	;Yes - get byte
	jsr	r5,d.pb		;And punch it
	br	2b
3:	movb	r1,r0		;Get checksum
	jsr	r5,(r3)		;Punch it, 3 bytes of rubbish & return
	jsr	r5,(r3)
	br	dcdc

d.pw:	jsr	r5,d.pb		;Punch low byte
	swab	r0		;Get high one, fall thru & punch

d.pb:	sub	r0,r1		;Accumulate checksum
	jmp	ftyp		;Output byte & return

lgdr:	.word	op1	; <LF>	modify, close, open next
	.word	cret	; <CR>	close
	.word	reladr	; !  relocate address
	.word	regt	; $  register ops
	.word	comma	; ,  relocate data
	.word	wrd	; /  open word
	.word	semi	; ;  introduce second argument
	.word	old	; <  return to old sequence and open
	.word	orrb	; >  open related, rel. branch
	.word	orab	; @  open related, absolute
	.word	bkpt	; B  breakpoints
	.word	const	; C  constant reg access
	.word	dump	; D  dump to tape
	.word	eff	; E  search effective address
	.word	wfill	; F  fill a block of words
	.word	go	; G  go to address k
	.word	bfill	; I  fill a block of bytes
	.word	load	; L  load tape
	.word	ofst	; O  offset
	.word	proc	; P  proceed
	.word	rel	; R  set relocation constant
	.word	sngl	; S  single instruction mode
	.word	wsch	; W  search word
	.word	rad50	; X  radix 50
	.word	byt	; \  open byte
	.word	back	; ^  open previous
	.word	orpc	; _  open related, index - PC

tl:	.byte	'S'	;Do	1	; User status reg.
	.byte	'P'	;not	2	; Priority for ODT
	.byte	'M'	;	3	; Search mask
	.byte	'L'	;change	4	; Lower limit
	.byte	'U'	;	5	; Upper limit
	.byte	'C'	;the	6	; Constant reg.
	.byte	'A'	;	7	; Load address
	.byte	'F'	;order	8	; Format reg.
	.byte	'R'	;	9	; Relocation regs.
	.byte	'B'	;here	10	; Breakpoints
	.byte	0	;List terminator

lgch:	.byte	lf, cr, '!', '$', ',', '/', ';', '<', '>'
	.byte	'@', 'B', 'C', 'D', 'E', 'F', 'G', 'I', 'L'
	.byte	'O', 'P', 'R', 'S', 'W', 'X', '\\', '^', '_'
zero:	.word	0
breakc:	.word	0		;Trace trap prototype. HALTs get used as ZERO

		.section  dseg
		.ORG	RAM

;The order of the following entries is critical

ur0:	.blkw	6	;User R0-R5
usp:	.blkw	1	;User SP
upc:	.blkw	1	;User PC
ust:	.blkw	1	;User ST
pri:	.blkw	1	;ODT priority (7)
msk:	.blkw	1	;Mask
	.blkw	1	;Low limit
	.blkw	1	;High limit
creg:	.blkw	1	;Constant reg
l.addr:	.blkw	1	;Next free load address
format:	.blkw	1	;Format reg
reloc:	.blkw	10	;Relocation regs

; Break point lists, adr1 = address of breakpoint, ct = count,
;   uin = contents

adr1:	.blkb	bkp+4
ct:	.blkb	bkp+4
uin:	.blkb	bkp+4


offset:	.blkw	1	;Relocation offset
bw:	.blkw	1	; =0 - all closed,
			; =1 - byte open,
			; =2 - word open
cad:	.blkw	1	; Current address
dot:	.blkw	1	; Origin address
semic:	.blkb	1	;Semi-colon flag
seq:	.blkb	1	;Flag for < command
s.t:	.blkw	1	;s & t together as a single 16 bit word
	s = s.t		;Single instruction flag, non 0 if active, 0 if not.
			;No breakpoints may be set in single instruction mode.
	t = s.t + 1	;T-bit flag, doing the instruction under a breakpoint
p:	.blkb	1	;Proceed flag = -2 if manual entry
			;		-1 if no proceed allowed
			;		0-7 if proceed allowed
negate:	.blkb	1	;Negate pending flag for numeric input
;NB. csr1 and csr2 get cleared together by a word clear - do not split.
csr1:	.blkb	1	;Save cell - r c/sr
csr2:	.blkb	1	;Save cell - t c/sr

.end
