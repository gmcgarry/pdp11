; RF11 boot
	.ORG 0773700
	mov $177472,r0
	mov $3,-(r0)
	mov $140000,-(r0)
	mov $54000,-(r0)
	mov $-2000,-(r0)
	mov $5,-(r0)
1:	tstb (r0)
	bge 1b
	jmp *$54000
