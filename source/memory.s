

.section .text
// r0 is dest, r1 is src, r2 is number of bytes
.globl memcpy
memcpy:
	push	{r4, r5, r6, r7, r8, r9, r10, lr}
	
memcpy_while$:
	mov		r3, #32			//if(# bytes >= 32)
	cmp		r2, r3
	bhs		memcpy_32B	//Copy 32 bytes
	
memcpy_low32B:			//else
	mov		r3, #4			//if(# bytes >=4)
	cmp		r2, r3		
	bhs		memcpy_4B		// copy word
	mov		r4, #0
memcpy_low32B_while$:	//else
	ldrb	r3, [r1], #1	//load byte
	strb	r3,	[r0], #1	//store byte
	sub		r2, #1			//dec byte counter
	cmp		r2, r4			//if more to write, loop
	bne		memcpy_low32B_while$	//else exit
	pop		{r4, r5, r6, r7, r8, r9, r10, pc}
	
memcpy_4B:
	ldr		r3, [r1], #4	//load 4 bytes
	str		r3, [r0], #4	//store 4 bytes
	sub		r2, #4			//dec byte counter by 4
	
memcpy_check_return_low32B:
	mov		r3, #0			//check if exit
	cmp		r2, r3
	bne		memcpy_low32B
	pop		{r4, r5, r6, r7, r8, r9, r10, pc}
	
memcpy_32B:
	ldmia	r1!, {r3, r4, r5, r6, r7, r8, r9, r10}	//load 32 bytes
	stmia	r0!, {r3, r4, r5, r6, r7, r8, r9, r10}	//store 32  bytes
	sub		r2, #32									//dec counter by 32
memcpy_check_return_32B:
	mov		r3, #0				//check for return condition
	cmp		r2, r3
	bne		memcpy_while$
	pop		{r4, r5, r6, r7, r8, r9, r10, pc}
	
	
	
	
// r0 is dest, r1 is value, r2 is number of bytes
.globl memfill
memfill:
	push	{r4, r5, r6, r7, r8, r9, r10, lr}
	mov		r3, #0
memfill_while$:
	cmp		r2, r3
	popeq	{r4, r5, r6, r7, r8, r9, r10, pc}
	strb	r1, [r0], #1 
	add		r3, #1
	b 		memfill_while$
