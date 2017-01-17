
.section .init

.equ    CPSR_MODE_USER,         0x10
.equ    CPSR_MODE_FIQ,          0x11
.equ    CPSR_MODE_IRQ,          0x12
.equ    CPSR_MODE_SVR,          0x13
.equ    CPSR_MODE_ABORT,        0x17
.equ    CPSR_MODE_UNDEFINED,    0x1B
.equ    CPSR_MODE_SYSTEM,       0x1F

// See ARM section A2.5 (Program status registers)
.equ    CPSR_IRQ_INHIBIT,       0x80
.equ    CPSR_FIQ_INHIBIT,       0x40
.equ    CPSR_THUMB,             0x20


.globl _start
_start:
	ldr		pc,	= _reset_w
	ldr		pc,	= _inst_undef_w
	ldr		pc,	= _soft_int_w
	ldr		pc,	= _pref_abrt_w
	ldr		pc,	= _data_abrt_w
	ldr		pc,	= _unused_hand_w
	ldr		pc,	= _irq_w
	ldr		pc,	= _fiq_w

_reset_w:			.word		_reset_
_inst_undef_w:	.word		_inst_undef_
_soft_int_w:		.word		_soft_int_
_pref_abrt_w:	.word		_pref_abrt_
_data_abrt_w:	.word		_data_abrt_
_unused_hand_w:	.word		_reset_
_irq_w:			.word		_irq_
_fiq_w:			.word		_fiq_

_reset_:
	ldr		r0, =0x0
	ldr		r1, =_start
	ldmia	r1!, {r2, r3, r4, r5, r6, r7, r8, r9}
	stmia	r0!, {r2, r3, r4, r5, r6, r7, r8, r9}
	ldmia	r1!, {r2, r3, r4, r5, r6, r7, r8, r9}
	stmia	r0!, {r2, r3, r4, r5, r6, r7, r8, r9}
	
	msr cpsr_c, #(CPSR_MODE_IRQ | CPSR_IRQ_INHIBIT | CPSR_FIQ_INHIBIT )
	mov	sp,	#0x7000
	
	msr cpsr_c, #(CPSR_MODE_SVR | CPSR_IRQ_INHIBIT | CPSR_FIQ_INHIBIT )
	mov	sp,	#0x8000
	
	bl		kernel_begin

_inst_undef_:
_soft_int_:
_pref_abrt_:
_data_abrt_:
_irq_:
_fiq_:



kernel_begin:
	ldr		r0, =__bss_start__
	ldr		r1, =__bss_end__
	sub		r2, r1, r0
	mov		r1, #0
	bl		memfill
	b		main
	




