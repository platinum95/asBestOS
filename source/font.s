

.section .text

.globl generate_character_set
generate_character_set:


.globl draw_nullt_string
//r0 is x, r1 is y, r2 is pointer to null terminated string
draw_nullt_string:
	push	{r4-r7, lr}
	mov		r4, r0
	mov		r5, r1
	mov		r6, r2
	draw_nullt_while$:
		ldrb	r2, [r6], #1
		cmp		r2, #0
		popeq	{r4-r7, pc}
		mov		r0, r4
		mov		r1, r5
		bl		draw_char
		add		r4, #8
		ldr		r0, =framebuffer_physical_width
		ldr		r0, [r0]
		add		r1, r4, #8
		cmp		r1, r0
		movhs	r4, #1
		addhs	r5, #16
		b draw_nullt_while$
	

//r0 is x, r1 is y, r2 is ascii char
.globl draw_char
draw_char:
	push	{r4-r8, lr}
	cmp		r2, #127
	pophi	{r4-r8, pc}
	mov 	r2, r2, lsl #4	//16 bytes per character
	ldr		r3, =font_data
	add		r2, r3			//r2 is now character base addr, 16 bytes for character
	char_base_addr	.req	r2
	x		.req	r0
	y		.req	r1
	x1		.req	r3
	y1		.req	r4
	
	//r5-r8 are work registers
	mov		y1, #0
	draw_char_for_y0_15$:		//for y1 from 0 to 15
		mov		x1, #0
		ldrb	r5, [char_base_addr, y1]	//get current font byte
		current_byte		.req	r5	
		mov		r7, #1
		mov		r6, r7, lsl  #0	//set initial bit test
		bit_check	.req	r6
		
		draw_char_for_x0_7$: //for x1 from 0 to 7
			//assume 32 bit framebuffer for now
			tst		current_byte, bit_check		//check current bit, eq if background, ne if foreground
			colour	.req	r7
			ldreq	colour, =font_background
			ldrne	colour, =font_foreground
			ldr		colour, [colour]
			push	{r0-r6}	//prepare for function call
			add		x, x1
			add		y, y1
			mov		r2, colour
			bl		draw_point
			pop		{r0-r6}	//reset after call
			
			mov		bit_check, bit_check, lsl #1	//shift testing byte left
			add		x1, #1
			cmp		x1, #8
			blo		draw_char_for_x0_7$
		.unreq	bit_check
		.unreq	current_byte
		add		y1, #1
		cmp		y1, #16
		blo		draw_char_for_y0_15$	
		
	.unreq	x
	.unreq	y
	.unreq	x1
	.unreq	y1
	
	pop 	{r4-r8, pc}



.section .data

font_data:
	.incbin "font0.bin"
	
font_background:
	.word	0xff000000

font_foreground:
	.word	0xffffffff

