/*	Assembly source for basic GPIO manipulation


r0 input pin
r0 output reg addr | r1 output offset
r0 = r1 = 0 if failed
*/
GPIO_GetFunctionLocation:
	/*Check input value*/
	cmp 	r0, #53
	movhi 	r0, #0
	movhi 	r1, #0
	movhi	pc, lr
	
	/*Reduce down to get offset (r2)*/
	mov r2, #0
reduce_to_Range:
	cmp 	r0, #9
	addhi	r2, #4
	subhi	r0, #10
	bhi		reduce_to_Range

	/* pin * 3 gets register offset*/
	lsl		r0, #1
	add		r0, r0
	/*Move registers output state*/
	ldr 	r3, = GPIO_BaseLocation
	ldr 	r0, [r3]
	mov 	r1, r0
	add 	r0, r2

	mov 	pc, lr
	

.globl GPIO_SetPinFunction
/*r0 is pin, r1 is function*/
GPIO_SetPinFunction:
	/*Check input values, return 1 or 2 if error*/
	cmp 	r0, #53
	movhi	r0, #1
	cmpls	r1, #7
	movhi	r0, #2
	movhi	pc, lr
	
	push	{lr}
	push	{r1}
	bl GPIO_GetFunctionLocation
	pop		{r2}
	/*At this point, r0 = register address, r1 = pin offset, and r2 = function value*/
	ldr 	r3, [r0]
	lsl		r2, r1
	orr 	r3, r2
	str		r3,	[r0]
	
	pop {pc}

.globl GPIO_GetPinFunction
/*r0 is pin*/
GPIO_GetPinFunction:
	/*Check input value, return 8 if error */
	cmp 	r0, #53
	movhi	r0, #8
	movhi	pc, lr
	
	push	{lr}
	bl GPIO_GetFunctionLocation
	/*At this point, r0 = register address, r1 = pin offset */
	ldr 	r2, [r0]
	lsr		r2, r1
	mov		r3, #7
	and 	r2, r3
	mov		r0,	r3

	pop {pc}

	
.globl GPIO_SetPin
/*r0 is pin */
GPIO_SetPin:
	/*Check input value, return 0 if error*/
	cmp 	r0, #53
	movhi	r0, #0
	movhi	pc, lr
	
	/*Get register location */
	ldr 	r3, = GPIO_BaseLocation
	ldr 	r1, [r3]
	add		r1, #28
	cmp		r0, #31
	addhi	r1, #4
	subhi	r0, #32
	
	/*Get bit location */
	mov 	r2, #1
	lsl		r2, r0
	
	/*Load existing register, orr it, store it */
	ldr		r0, [r1]
	orr		r0, r2
	str		r0, [r1]

	mov		pc, lr
	
.globl GPIO_ClearPin
/*r0 is pin*/
GPIO_ClearPin:
	/*Check input value, return 0 if error */
	cmp 	r0, #53
	movhi	r0, #0
	movhi	pc, lr
	
	/*Get register location*/
	ldr 	r3, = GPIO_BaseLocation
	ldr 	r1, [r3]
	add		r1, #40
	cmp		r0, #31
	addhi	r1, #4
	subhi	r0, #32
	/*Get bit location*/
	mov 	r2, #1
	lsl		r2, r0
	/*Load existing register, orr it, store it*/
	ldr		r0, [r1]
	orr		r0, r2
	str		r0, [r1]
	
	mov		pc, lr
	
.globl GPIO_SetPinValue
/*r0 is pin, r1 is value */
GPIO_SetPinValue:
	push	{lr}
	cmp 	r1, #0
	beq		clear
	bl		GPIO_SetPin
	pop		{pc}

clear:
	bl		GPIO_ClearPin
	pop		{pc}
		
	
.section 	.data
GPIO_BaseLocation:
	.word	0x3f200000
	
	
	