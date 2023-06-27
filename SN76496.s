;@
;@  SN76496.s
;@  SN76496/SMS sound chip emulator for arm32.
;@
;@  Created by Fredrik Ahlström on 2009-08-25.
;@  Copyright © 2009-2022 Fredrik Ahlström. All rights reserved.
;@
#ifdef __arm__

#include "SN76496.i"

	.global sn76496Init
	.global sn76496Reset
	.global sn76496SaveState
	.global sn76496LoadState
	.global sn76496GetStateSize
	.global sn76496SetMixrate
	.global sn76496SetFrequency
	.global sn76496Mixer
	.global sn76496W
								;@ These values are for the SMS/GG/MD vdp/sound chip.
.equ PFEED_SMS,	0x8000			;@ Periodic Noise Feedback
.equ WFEED_SMS,	0x9000			;@ White Noise Feedback

								;@ These values are for the SN76489/SN76496 sound chip.
.equ PFEED_SN,	0x4000			;@ Periodic Noise Feedback
.equ WFEED_SN,	0x6000			;@ White Noise Feedback

								;@ These values are for the NCR 8496 sound chip.
.equ PFEED_NCR,	0x4000			;@ Periodic Noise Feedback
.equ WFEED_NCR,	0x4400			;@ White Noise Feedback

	.syntax unified
	.arm

#ifdef GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
#else
	.section .text
#endif
	.align 2
;@----------------------------------------------------------------------------
;@ r0 = snptr.
;@ r1 = mixerbuffer.
;@ r2 = mix length.
;@ r3 -> r6 = pos+freq.
;@ r7 = noise generator.
;@ r8 = noise feedback.
;@ r9 = ch0/1 volumes.
;@ r10 = ch2/3 volumes.
;@ lr = mixer reg.
;@----------------------------------------------------------------------------
sn76496Mixer:				;@ r0=snptr, r1=dest, r2=len
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	ldmia snptr,{r3-r10}		;@ Load freq,addr,rng, noisefb,vol0, vol1
volF:
	mov r11,#0x80
;@----------------------------------------------------------------------------
mixLoop:
	adds r6,r6,r6,lsl#16
	movscs r7,r7,lsr#1
	eorcs r7,r7,r8
	ands lr,r7,#1
	movne lr,r10,lsr#16

	adds r3,r3,r3,lsl#16
	addpl lr,lr,r9

	adds r4,r4,r4,lsl#16
	addpl lr,lr,r9,lsr#16

	adds r5,r5,r5,lsl#16
	addpl lr,lr,r10

	add lr,r11,lr,lsr#8
	subs r2,r2,#1
	strbpl lr,[r1],#1
	bhi mixLoop

	stmia snptr,{r3-r7}			;@ Writeback freq,addr,rng
	ldmfd sp!,{r4-r11,lr}
	bx lr
;@----------------------------------------------------------------------------

	.section .text
	.align 2
;@----------------------------------------------------------------------------
sn76496Init:				;@ snptr=r0=pointer to struct, r1=FREQTABLE
;@----------------------------------------------------------------------------
	stmfd sp!,{snptr,lr}
	bl frequencyCalculate
	ldmfd sp!,{snptr,lr}
;@----------------------------------------------------------------------------
sn76496Reset:				;@ snptr=r0=pointer to struct, r1 = chiptype SMS/SN76496
;@----------------------------------------------------------------------------
	cmp r1,#1
	ldr r3,=(WFEED_SMS<<16)+PFEED_SMS
	ldreq r3,=(WFEED_SN<<16)+PFEED_SN
	ldrhi r3,=(WFEED_NCR<<16)+PFEED_NCR

	mov r1,#0
	mov r2,#(snSize-16)/4		;@ 52/4=13
rLoop:
	subs r2,r2,#1
	strpl r1,[snptr,r2,lsl#2]
	bhi rLoop
	strh r3,[snptr,#noiseFB]
	str r3,[snptr,#noiseType]

	bx lr

#define STATE_SIZE (0x34)
;@----------------------------------------------------------------------------
sn76496SaveState:			;@ In r0=destination, r1=snptr. Out r0=state size.
	.type   sn76496SaveState STT_FUNC
;@----------------------------------------------------------------------------
	mov r2,#STATE_SIZE
	stmfd sp!,{r2,lr}

	bl memcpy

	ldmfd sp!,{r0,lr}
	bx lr
;@----------------------------------------------------------------------------
sn76496LoadState:			;@ In r0=snptr, r1=source. Out r0=state size.
	.type   sn76496LoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	mov r2,#STATE_SIZE
	bl memcpy

	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
sn76496GetStateSize:		;@ Out r0=state size.
	.type   sn76496GetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#STATE_SIZE
	bx lr
;@----------------------------------------------------------------------------
sn76496SetMixrate:		;@ snptr=r0=pointer to struct, r1 in. 0 = low, 1 = high
;@----------------------------------------------------------------------------
	cmp r1,#0
	moveq r1,#924				;@ low,  18157Hz
	movne r1,#532				;@ high, 31536Hz
	str r1,[snptr,#mixRate]
	moveq r1,#304				;@ low
	movne r1,#528				;@ high
	str r1,[snptr,#mixLength]
	bx lr
;@----------------------------------------------------------------------------
sn76496SetFrequency:		;@ snptr=r0=pointer to struct, r1=frequency of chip.
;@----------------------------------------------------------------------------
	ldr r2,[snptr,#mixRate]
	mul r1,r2,r1
	mov r1,r1,lsr#12
	str r1,[snptr,#freqConv]	;@ Frequency conversion (SN76496freq*mixrate)/4096
	bx lr
;@----------------------------------------------------------------------------
frequencyCalculate:		;@ snptr=r0=pointer to struct, r1=FREQTABLE
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	str r1,[snptr,#freqTablePtr]
	mov r5,r1					;@ Destination
	ldr r6,[snptr,#freqConv]	;@ (sn76496/gba)*4096
	mov r4,#2048
frqLoop:
	mov r0,r6
	mov r1,r4
	swi 0x060000				;@ BIOS Div, r0/r1.
	cmp r4,#7*2
	movmi r0,#0					;@ To remove real high tones.
	subs r4,r4,#2
	strh r0,[r5,r4]
	bhi frqLoop

	ldmfd sp!,{r4-r6,lr}
	bx lr

;@----------------------------------------------------------------------------
	.section .ewram,"ax"
	.align 2
;@----------------------------------------------------------------------------
sn76496W:					;@ snptr = r0 = struct-pointer, r1 = value
;@----------------------------------------------------------------------------
	tst r1,#0x80
	andne r2,r1,#0x70
	strbne r2,[snptr,#snLastReg]
	ldrbeq r2,[snptr,#snLastReg]
	movs r2,r2,lsr#5
	bcc setFreq
doVolume:
	and r1,r1,#0x0F
	adr r3,attenuation			;@ This might be possible to optimise.
	add r3,r3,r1
	ldrh r1,[r3,r1]
	add r3,snptr,r2,lsl#1
	strh r1,[r3,#ch0Volume]
	bx lr

setFreq:
	cmp r2,#3					;@ Noise channel
	beq setNoiseF
	tst r1,#0x80
	add r3,snptr,r2,lsl#2
	andeq r1,r1,#0x3F
	movne r1,r1,lsl#4
	strbeq r1,[r3,#ch0Reg+1]
	strbne r1,[r3,#ch0Reg]
	ldrh r1,[r3,#ch0Reg]
	mov r1,r1,lsr#3

	ldr r12,[snptr,#freqTablePtr]
	ldrh r1,[r12,r1]
	strh r1,[r3,#ch0Frq]
	cmp r2,#2					;@ Ch2
	ldreq r3,[snptr,#ch3Reg]
	cmpeq r3,#3
	strheq r1,[snptr,#ch3Frq]
	bx lr

setNoiseF:
	and r2,r1,#3
	str r2,[snptr,#ch3Reg]
	tst r1,#4
	ldr r1,[snptr,#noiseType]	;@ Periodic noise
	strh r1,[snptr,#rng]
	movne r1,r1,lsr#16			;@ White noise
	strh r1,[snptr,#noiseFB]
	ldr r1,[snptr,#freqConv]
	mov r1,r1,lsr#5				;@ These values sound ok
	mov r1,r1,lsr r2
	cmp r2,#3
	ldrheq r1,[snptr,#ch2Frq]
	strh r1,[snptr,#ch3Frq]
	bx lr

attenuation:
	.hword 0x3FFF,0x32CB,0x2851,0x2000,0x1966,0x1428,0x1000,0x0CB3,0x0A14,0x0800,0x0659,0x050A,0x0400,0x032C,0x0285,0x0000
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
