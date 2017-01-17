/* Assembly source for timers */

/* Halt processor for r0 Microseconds, 4 byte resolution */
.globl Timer_WaitMicros
/*r0 is wait time in micro seconds */
Timer_WaitMicros:
	wait_time		.req	r0
	/* r1 is timer register addr*/
	ldr		r1, =Timer_RegisterBase
	ldr		r1, [r1]
	add		r1, #4
	timer_addr	.req	r1
	/*r2 is current time*/
	curr_time		.req	r2
	ldr 	r2, [r1]
	/*r3 is start time*/
	mov 	r3, r2
	start_time	.req	r3
Timer_WaitLoop:
	ldr 	curr_time, [timer_addr]
	sub		curr_time, curr_time, start_time	/*diff = curr - start */
	cmp		curr_time, wait_time
	bls		Timer_WaitLoop
	
	mov 	pc, lr	

.section	.data
Timer_RegisterBase:
	.word 	0x3F003000
	