; TC11 boot rom
	.ORG 0773700
	mov $177350,r0
	clr -(r0)
	mov r0,-(r0)
	mov $3,-(r0)
1:	tstb (r0)
	bge 1b
	tst *$177350
	bne .
	movb $5,(r0)
1:	tstb (r0)
	bge 1b
	clr pc

	.END
