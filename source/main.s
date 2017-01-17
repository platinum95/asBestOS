.section .init


.section .text
.globl main
main:
	mov		r0, #47
	mov		r1, #0
	bl		GPIO_SetPinFunction
	bl		FrameBuffer_Initialise_Tag
	
	render$:
	fbAddr .req r3
	ldr fbAddr,=framebuffer_addr
	ldr	fbAddr, [fbAddr]
	
	mov	r0, r3
	mov	r1, #0
	ldr	r2, =framebuffer_size
	ldr	r2, [r2]
	bl	memfill
	mov		r0, #0
	mov		r1, #0
	ldr		r2, =0xff0000ff
	push	{r0, r1, r2, r3}
	mov		r0, #500
	mov		r1, #240
	ldr		r2, =test_string
	bl		draw_nullt_string
	pop		{r0, r1, r2, r3}
		
	ldr		r0, =1000000
	bl		Timer_WaitMicros
	b render$
	colour .req r0
	y .req r1
	ldr y,=framebuffer_physical_height
	ldr	y, [y]
	drawRow$:
		x .req r2
		ldr x,=framebuffer_physical_width
		ldr	x, [x]
		drawPixel$:
			strh colour,[fbAddr]
			add fbAddr,#2
			sub x,#1
			teq x,#0
			bne drawPixel$

		sub y,#1
		add colour,#1
		teq y,#0
		bne drawRow$

	b render$

	.unreq fbAddr
	
.globl Flash_Binary
/* r0 is input value */
Flash_Binary:
	push 	{lr}
	mov 	r3, #0
	mov 	r2, r0
while$:
	and		r1, r2, #0b1
	mov		r0, #47
	push	{r2, r3}
	bl		GPIO_SetPinValue
	ldr		r0, =1000000
	bl		Timer_WaitMicros
	pop		{r2, r3}
	lsr		r2, #1
	add		r3, #1
	cmp		r3, #31
	bls		while$
	
	pop {pc}
	
.globl FAILED
FAILED:
	push	{lr}
	ldr		r0, =0b010101010101
	bl		Flash_Binary
	pop		{pc}
	
.section .data
	fb_infoPointer:
		.word	0x00000000
	
	fb_addr:
		.word	0x00000000
		
	test_string:
		.asciz	"Dia Dhuit, a domhain"
	
/*
loop$:
	mov		r1, #0
	mov		r0, #47
	bl		GPIO_SetPinValue
	
	ldr		r0,	=100000
	bl		Timer_WaitMicros

	mov		r1, #1
	mov		r0, #47
	bl		GPIO_SetPinValue
	
	ldr		r0,	=100000
	bl		Timer_WaitMicros

	b loop$
*/
