/*
Address	Size / Bytes	Name	Description	Read / Write
3f00B880	4	Read	Receiving mail.	R
3f00B890	4	Poll	Receive without retrieving.	R
3f00B894	4	Sender	Sender information.	R
3f00B898	4	Status	Information.	R
3f00B89C	4	Configuration	Settings.	RW
3f00B8A0	4	Write	Sending mail.	W



#define gfx_pm_read		0x0
#define gfx_pm_poll		0x10
#define gfx_pm_sender		0x14
#define gfx_pm_status		0x18
#define gfx_pm_config		0x1C
#define gfx_pm_write		0x20
*/
#include "postman.h"
.section .text

.globl gfx_MailboxWrite
/*r0 is value, r1 is channel */
gfx_MailboxWrite:
	/*validate inputs */
	tst		r0, #0b1111
	movne	pc, lr
	cmp		r1, #15
	movhi	pc, lr
	
	orr		r0, r1
	ldr		r1,	=Mailbox_Base
	
write_wait_for_status:
	ldr		r3,	=Mailbox_Status
	ldr 	r2, [r1, r3]
	tst		r2, #0x80000000
	bne		write_wait_for_status
	
	ldr		r3,	=Mailbox_Write
	str		r0,	[r1, r3]
	
	mov		pc, lr

.globl gfx_MailboxRead
/*r0 is Mailbox, r0 is return value */
gfx_MailboxRead:
	cmp		r0, #15
	movhi	pc, lr
	
	ldr		r1, =Mailbox_Base
	wait_for_channel:
		read_wait_for_status:
			ldr		r2, [r1, #0x18]
			tst		r2, #0x40000000
			bne		read_wait_for_status
		ldr		r2, [r1]
		and		r3, r2, #0b1111
		teq		r3, r0
		bne		wait_for_channel
		and 	r0, r2, #0xfffffff0
	
	mov		pc, lr

	
	
	
