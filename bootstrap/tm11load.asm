; boot from TM11 magnetic tape (to address 0)

	.org	017764

	mov	$172526,R0
	mov	R0,-(R0)
	mov	$60003,-(R0)
	br	.

	.end
