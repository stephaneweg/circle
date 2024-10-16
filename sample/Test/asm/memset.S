	.global __memset_arm32
	.align	6
	
__memset_arm32:


	mov	x3, x0
	cbz	x2, 10f


1:
	str		x1, [x3]
	add		x3,x3,#4
	sub		x2,x2,#1
	cbz		x2, 10f
	bne	1b

10:
	ret