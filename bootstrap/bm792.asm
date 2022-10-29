; BM792-YB bootrom
	.ORG 0773100	; 64 words
	mov 177570,r1	; read switches
begin:	reset
	mov r1,r2
	mov $-256,(r0)	; set WC
	cmp r0,$177344	; dectape?
	bne start	; no
	mov $4002,-(r0)	; yes, rewind tape
1:	tst (r0)	; wait for error
	bpl 1b
	tst -(r0)	; endzone?
	bpl begin	; try again
	cmp (r0)+,(r0)+
start:	mov $5,-(r0)	; start
1:	tstb (r0)	; wait for done
	bpl 1b
	tst (r0)	; error?
	bmi begin	; try again
	clrb (r0)	; stop dectape
	jmp $0

	.END
