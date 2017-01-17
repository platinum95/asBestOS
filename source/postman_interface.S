#include "postman_interface.h"

.section .text

.macro store_index value
	str		\value, [r8, r7]
	add		r7, #4
.endm

.macro check_tag	tag
	ldr		r4,	=\tag
	cmp		r0, r4
.endm

.globl Tag_Reset
Tag_Reset:
	//buffer size = 0
	ldr		r0, =Tag_Buffer_Size_Bytes
	mov		r1, #0
	str		r1, [r0]
	//buffer index = 2
	ldr		r0, =Tag_Buffer_Index
	mov		r1, #8
	str		r1, [r0]
	//buffer[0] = buffer[1] = 0
	ldr		r0, =Tag_Buffer
	mov		r1, #0
	str		r1, [r0]
	str		r1, [r0, #4]
	
	mov 	pc, lr

.globl Tag_ProcessTags
Tag_ProcessTags:
	push 	{lr}
	buffer	.req	r0
	index	.req	r1
	ldr		buffer, =Tag_Buffer
	ldr		index, =Tag_Buffer_Index
	ldr		index, [index]
	
	add		r2, index, #4
	str		r2, [buffer] 		//pt[PT_OSIZE] = ( pt_index + 1 ) << 2;
	mov		r2, #0
	str		r2, [buffer, #4] 	//pt[PT_OREQUEST_OR_RESPONSE] = 0;
	.unreq	index
	.unreq	buffer
	mov		r1, #8				//Mailbox channel 8
//	ldr		r0, [r0]			//r0 = &Tag_Buffer
	bl		gfx_MailboxWrite //RPI_Mailbox0Write( MB0_TAGS_ARM_TO_VC, (unsigned int)pt );

	mov		r0, #8
    bl		gfx_MailboxRead  //result = RPI_Mailbox0Read( MB0_TAGS_ARM_TO_VC );
	
	pop		{pc}
	
.globl Tag_addTag
// r0 = tag, r1-r3 = values
Tag_addTag:
	push	{lr}
	push	{r4 - r8}
	buffer	.req	r8
	index	.req	r7
	ldr		buffer, =Tag_Buffer
	ldr		index, =Tag_Buffer_Index
	ldr		index, [index]
	store_index r0
	
	check_tag		TAG_ALLOCATE_BUFFER
	beq				Tag_addTag_ALLOCATE_BUFFER
	
	check_tag		TAG_SET_PHYSICAL_SIZE
	beq				Tag_addTag_SetTest_Size_Offset
	check_tag		TAG_SET_VIRTUAL_SIZE
	beq				Tag_addTag_SetTest_Size_Offset
	check_tag		TAG_SET_VIRTUAL_OFFSET
	beq				Tag_addTag_SetTest_Size_Offset
	check_tag		TAG_TEST_PHYSICAL_SIZE
	beq				Tag_addTag_SetTest_Size_Offset
	check_tag		TAG_TEST_VIRTUAL_SIZE
	beq				Tag_addTag_SetTest_Size_Offset
	
	check_tag		TAG_GET_PHYSICAL_SIZE
	beq				Tag_addTag_Get_SizeOffset
	check_tag		TAG_GET_VIRTUAL_SIZE
	beq				Tag_addTag_Get_SizeOffset
	check_tag		TAG_GET_VIRTUAL_OFFSET
	beq				Tag_addTag_Get_SizeOffset
	
	check_tag		TAG_SET_DEPTH
	beq				Tag_addTag_Set_DepthPixelAlpha
    check_tag 	TAG_SET_PIXEL_ORDER
	beq				Tag_addTag_Set_DepthPixelAlpha
    check_tag 	TAG_SET_ALPHA_MODE 
	beq				Tag_addTag_Set_DepthPixelAlpha
	
	check_tag 	TAG_GET_ALPHA_MODE
	beq				Tag_addTag_Get_DepthPixelPitchAlpha
    check_tag 	TAG_GET_DEPTH
	beq				Tag_addTag_Get_DepthPixelPitchAlpha
    check_tag 	TAG_GET_PIXEL_ORDER
	beq				Tag_addTag_Get_DepthPixelPitchAlpha
    check_tag 	TAG_GET_PITCH
	beq				Tag_addTag_Get_DepthPixelPitchAlpha
	
	sub		index, #4
	b 		Tag_addTag_return
	
	
	//Allocate buffer sequence, r1 is alignment
Tag_addTag_ALLOCATE_BUFFER:
	alignment .req	r1
	mov		r2,	#8
	store_index	r2				//pt[pt_index++] = 8;
	mov		r2, #4
	store_index 	r2				//pt[pt_index++] = 0; /* Request */
	store_index	alignment 	//pt[pt_index++] = va_arg( vl, int );
	add		index, #4				//pt_index += 1;
	.unreq 	alignment
	b 		Tag_addTag_return
	
	//r1 = width, r2 = height
Tag_addTag_SetTest_Size_Offset:
	mov		r3,	#8
	store_index	r3				//pt[pt_index++] = 8;
    mov		r3, #8
	store_index 	r3				//pt[pt_index++] = 0; /* Request */
	store_index 	r1				//pt[pt_index++] = va_arg( vl, int ); /* Width */
    store_index 	r2 				//pt[pt_index++] = va_arg( vl, int ); /* Height */
	b 		Tag_addTag_return

Tag_addTag_Get_SizeOffset:
	mov		r1,	#8
	store_index	r1				//pt[pt_index++] = 8;
    mov		r1, #0
	store_index 	r1				//pt[pt_index++] = 0; /* Request */
	add		index, #8				//pt_index += 2;
	b 		Tag_addTag_return
	
Tag_addTag_Set_DepthPixelAlpha:
	mov		r2,	#4
	store_index	r2				//pt[pt_index++] = 4;
	mov		r2, #4
 	store_index	r2				//pt[pt_index++] = 0; /* Request */
	store_index 	r1				//pt[pt_index++] = va_arg( vl, int );
	b		Tag_addTag_return

Tag_addTag_Get_DepthPixelPitchAlpha:
	mov		r1,	#4
	store_index	r1				//pt[pt_index++] = 4;
	mov		r1, #0
 	store_index	r1				//pt[pt_index++] = 0; /* Request */
	add		index, #4
	
Tag_addTag_return:
	.unreq	buffer
	ldr		r8, =Tag_Buffer_Index
	str		index, [r8]
	.unreq	index
	pop		{r4 - r8}
	pop		{pc}
	

//r0 is tag input, r0 is output pointer to property
.globl Tag_GetResult
Tag_GetResult:
	push	{r4-r6}
	
	tag_buffer	.req	r1
	mov		tag_buffer, #0	//int* tag_buffer = NULL;
	
	property		.req	r2
	ldr		property, =Tag_Property
	str		r0, [property] 	//property.tag = tag;

	index			.req	r3
    mov		index, #8			//int index = 2;

	pt				.req	r5
	ldr		pt, =Tag_Buffer
	
	Tag_GetResult_while$:
		ldr		r4, [pt]			//while(index < pt size)
		cmp		index, r4
		bhi		Tag_GetResult_return
		
		ldr		r4, [pt, index]
		cmp		r4, r0				//if( pt[index] == tag )
		moveq	tag_buffer, pt	//tag_buffer = &pt[index];
		addeq	tag_buffer, index
		beq		Tag_GetResult_return	//break
		add		r6,	index, #4
		ldr		r6, [pt, r6]	//r6 = pt[index + 1]
		add		r6, #12
		add		index, r6		//index += ( pt[index + 1] >> 2 ) + 3;
		b		Tag_GetResult_while$
	

	Tag_GetResult_return:
		.unreq	index
		.unreq	pt
		/* Return NULL if the property tag cannot be found in the buffer */
		mov		r4, #0
		cmp		tag_buffer, r4	//if( tag_buffer == NULL )
		popeq	{r4-r6}				//return NULL;
		moveq	r0, #0
		moveq	pc, lr
		
		
		ldr		r3, [tag_buffer, #8]
		ldr		r4, =0xffff
		and		r3, r4			//r3 = tag_buffer[T_ORESPONSE] & 0xFFFF;
		str		r3, [property, #4]	//property.byte_length = r3
		
		mov		r3, tag_buffer
		add		r3, #12
		str		r3, [property, #8]	//property.data_pointer = &tag_buffer[T_OVALUE]
		
		.unreq	tag_buffer
		.unreq	property
		pop	{r4-r6}
		ldr		r0, =Tag_Property	//return &property;
		mov		pc, lr

.section .data
//Array for the buffer to send to mailbox
.align 4
Tag_Buffer:
	.space 	32768

Tag_Buffer_Size_Bytes:
	.int	0x0
	
Tag_Buffer_Index:
	.int 	0x0

Tag_Property:
	.int 	0x0	//tag					offset 0
    .int 	0x0	//byte_length;		offset 4
	.word	0x0	//data pointer		offset 8
	.word	0x0	//data				offset 12
	.word	0x0	//data
	.word	0x0	//data



	