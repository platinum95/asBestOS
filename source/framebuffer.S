#include "postman_interface.h"


.section .text

.macro FrameBuffer_Add_Tag tag 
	ldr		r0,	=\tag
	bl		Tag_addTag
.endm

.macro FrameBuffer_Add_Tag1 tag val1 
	ldr		r0,	=\tag
	ldr		r1, =\val1
	bl		Tag_addTag
.endm

.macro FrameBuffer_Add_Tag2 tag val1 val2
	ldr		r0,	=\tag
	ldr		r1, =\val1
	ldr		r2, =\val2
	bl		Tag_addTag
.endm

.macro FrameBuffer_Add_Tag_Reg_2 tag val1 val2
	ldr		r0,	=\tag
	mov		r1, \val1
	mov		r2, \val2
	bl		Tag_addTag
.endm

.macro	Load_From_Memory	reg, addr
	ldr		\reg, =\addr
	ldr		\reg, [\reg]
.endm
	
.globl FrameBuffer_Initialise_Tag
FrameBuffer_Initialise_Tag:
	push	{lr}
	
	bl		Tag_Reset
	FrameBuffer_Add_Tag 	TAG_GET_PHYSICAL_SIZE
    bl		Tag_ProcessTags
	ldr		r0, =TAG_GET_PHYSICAL_SIZE
	bl		Tag_GetResult
	mov		r1, #0
	cmp		r0, r1
	bleq	FAILED
	ldr 	r1, [r0, #8]
	ldr		r2, [r1]
	ldr		r3, = framebuffer_physical_width
	str		r2, [r3]
	ldr		r2, [r1, #4]
	ldr		r3, = framebuffer_physical_height
	str		r2, [r3]
	bl		Tag_Reset
	
	Load_From_Memory	r1, framebuffer_physical_width
	Load_From_Memory	r2, framebuffer_physical_height
	FrameBuffer_Add_Tag_Reg_2	TAG_SET_PHYSICAL_SIZE, 	r1, r2
	Load_From_Memory	r1, framebuffer_physical_width
	Load_From_Memory	r2, framebuffer_physical_height
	add		r2, r2
	FrameBuffer_Add_Tag_Reg_2	TAG_SET_VIRTUAL_SIZE, 	r1, r2
	FrameBuffer_Add_Tag1 	TAG_SET_DEPTH 				32
	FrameBuffer_Add_Tag1 	TAG_ALLOCATE_BUFFER 		16
	FrameBuffer_Add_Tag	TAG_GET_PITCH
	FrameBuffer_Add_Tag	TAG_GET_PHYSICAL_SIZE
	FrameBuffer_Add_Tag	TAG_GET_DEPTH
    bl		Tag_ProcessTags

	ldr		r0, =TAG_GET_PITCH
	bl		Tag_GetResult
	mov		r1, #0
	cmp		r0, r1
	bleq	FAILED		//if( ( mp = RPI_PropertyGet( TAG_GET_PITCH ) ) )
	//first get pointer to data
	ldr 	r1, [r0, #8]	//r1 = tag_property[data_offset] 
	//pitch should be first word at pointer
	ldr		r1, [r1]		//r1 = mp->data.buffer_32[0];
	ldr		r0, =framebuffer_pitch
	str		r1, [r0]		//pitch = r1
	
	ldr		r0, =TAG_ALLOCATE_BUFFER
	bl		Tag_GetResult
	mov		r1, #0
	cmp		r0, r1
	bleq	FAILED		//if( ( mp = RPI_PropertyGet( TAG_ALLOCATE_BUFFER ) ) )
	//first get pointer to data
	ldr 	r1, [r0, #8]	//r1 = tag_property[data_offset] 
	//fb addr should be first word at pointer
	ldr		r2, [r1]		//r1 = mp->data.buffer_32[0];
	ldr		r0, =framebuffer_addr
	str		r2, [r0]		//pitch = r1
	//fb size should be second word at pointer
	ldr		r2, [r1, #4]		//r1 = mp->data.buffer_32[1];
	ldr		r0, =framebuffer_size
	str		r2, [r0]		//pitch = r1
	
	ldr		r0, =TAG_GET_DEPTH
	bl		Tag_GetResult
	mov		r1, #0
	cmp		r0, r1
	bleq	FAILED		//if( ( mp = RPI_PropertyGet( TAG_ALLOCATE_BUFFER ) ) )
	//first get pointer to data
	ldr 	r1, [r0, #8]	//r1 = tag_property[data_offset] 
	//depth should be first word at pointer
	ldr		r1, [r1]		//r1 = mp->data.buffer_32[0];
//	add		r1, #0x80000000
	ldr		r0, =framebuffer_depth
	str		r1, [r0]		//pitch = r1
	
	ldr		r3, =draw_point_xw
	cmp		r1, #8			//if bpp == 8, draw point with 8 bit func
	ldreq	r0, =draw_point_8
	streq	r0, [r3]
	cmp		r1, #16			//if bpp == 16, draw point with 16 bit func
	ldreq	r0, =draw_point_16
	streq	r0, [r3]
	cmp		r1, #24			//if bpp == 24, draw point with 24 bit func
	ldreq	r0, =draw_point_24
	streq	r0, [r3]
	cmp		r1, #32			//if bpp == 32, draw point with 32 bit func
	ldreq	r0, =draw_point_32
	streq	r0, [r3]
	
	ldr		r0, =TAG_GET_PHYSICAL_SIZE
	bl		Tag_GetResult
	mov		r1, #0
	cmp		r0, r1
	bleq	FAILED
	ldr 	r1, [r0, #8]
	ldr		r2, [r1]
	ldr		r3, = framebuffer_physical_width
	str		r2, [r3]
	ldr		r2, [r1, #4]
	ldr		r3, = framebuffer_physical_height
	str		r2, [r3]
	
	pop		{pc}
	

// r0 is x, r1 is y, r2 is val
.globl draw_point
draw_point:
	push	{r4, r5, r6, r7, lr}
	
	ldr		r3, =framebuffer_pitch
	ldmia	r3!, {r4-r7}
	pitch		.req r4
	depth		.req r5
	f_addr	.req r6
	f_size	.req r7
	mul		r1, pitch		// y * pitch
	ldr		r3, =draw_point_xw
	ldr		r3, [r3]
	bx		r3
	
draw_point_8:
	mov		r0, r0, lsl #3		// x * 8 = x << 3
	add		r0, r1		//index = y * pitch + x * bpp
	index	.req	r0
	cmp		index, f_size
	pophi	{r4, r5, r6, r7, lr}
	strb	r2, [f_addr, index]	
	pop		{r4, r5, r6, r7, lr}
	
draw_point_16:
	mov		r0, r0, lsl #4		// x * 16 = x << 4
	add		r0, r1		//index = y * pitch + x * bpp
	index	.req	r0
	cmp		index, f_size
	pophi	{r4, r5, r6, r7, lr}
	strh	r2, [f_addr, index]	
	pop		{r4, r5, r6, r7, lr}
	
draw_point_24:
	mov		r0, r0, lsl #3		// x * 8 = x << 3
	mov		r3, r0, lsl #1		// x * 24 = x * 8 + x * 16 = x<<3 + x<<4 = x<<3 + (x<<3)<<1
	add		r0, r3
	add		r0, r1		//index = y * pitch + x * bpp
	index	.req	r0
	cmp		index, f_size
	pophi	{r4, r5, r6, r7, lr}
	str		r2, [f_addr, index]	
	pop		{r4, r5, r6, r7, lr}
	
draw_point_32:
	mov		r0, r0, lsl #2		// x * 4 = x << 2
	add		r0, r1		//index = y * pitch + x * bpp
	index	.req	r0
	cmp		index, f_size
	pophi	{r4, r5, r6, r7, lr}
	str		r2, [f_addr, index]	
	pop		{r4, r5, r6, r7, lr}

.unreq	index
.unreq	pitch
.unreq	depth	
.unreq	f_addr
.unreq	f_size

.section .bss
draw_point_xw:
	.word	=0x0
	
.section .data


draw_point_8w:
	.word	=draw_point_8
draw_point_16w:
	.word	=draw_point_16
draw_point_24w:
	.word	=draw_point_24
draw_point_32w:
	.word	=draw_point_32

.section .bss
.global framebuffer_physical_width
framebuffer_physical_width:
	.int 0x0

.global framebuffer_physical_height
framebuffer_physical_height:
	.int 0x0
.global framebuffer_pitch
framebuffer_pitch:
	.int	0x0
	
framebuffer_depth:
	.int	0x0

.globl framebuffer_addr
framebuffer_addr:
	.word	0x0
.globl framebuffer_size
framebuffer_size:
	.word	0x0
