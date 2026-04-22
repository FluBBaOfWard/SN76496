;@
;@  SN76496.s
;@  SN76496/SMS sound chip emulator for arm32.
;@
;@  Created by Fredrik Ahlström on 2005-07-11.
;@  Copyright © 2005-2026 Fredrik Ahlström. All rights reserved.
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
								;@ These values are for the SN76489/SN76496 sound chip.
.equ PFEED_SN,	0x4000			;@ Periodic Noise Feedback
.equ WFEED_SN,	0x6000			;@ White Noise Feedback

								;@ These values are for the SMS/GG/MD vdp/sound chip.
.equ PFEED_SMS,	0x8000			;@ Periodic Noise Feedback
.equ WFEED_SMS,	0x9000			;@ White Noise Feedback

								;@ These values are for the NCR 8496 sound chip.
.equ PFEED_NCR,	0x4000			;@ Periodic Noise Feedback
.equ WFEED_NCR,	0x4400			;@ White Noise Feedback

	.syntax unified
	.arm

#ifdef NDS
	.section .itcm, "ax", %progbits		;@ For the NDS ARM9
#elif GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
#else
	.section .text						;@ For everything else
#endif
	.align 2
;@----------------------------------------------------------------------------
;@ r0 = sn76496ptr.
;@ r1 = Mixerbuffer.
;@ r2 = Mix length.
;@ r3 -> r6 = pos+freq.
;@ r7 = Noise generator.
;@ r8 = Noise feedback.
;@ r9 = Ch0/1 volumes.
;@ r10 = Ch2/3 volumes.
;@ lr = Mixer reg.
;@----------------------------------------------------------------------------
sn76496Mixer:				;@ In r0=sn76496ptr, r1=dest, r2=len
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	ldmia snptr,{r3-r10}		;@ Load freq,addr,rng, noisefb,vol0, vol1
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
sn76496Init:				;@ In r0=sn76496ptr, r1=FREQTABLE
;@----------------------------------------------------------------------------
	stmfd sp!,{snptr,lr}
	bl frequencyCalculate
	ldmfd sp!,{snptr,lr}
;@----------------------------------------------------------------------------
sn76496Reset:				;@ In r0=sn76496ptr, r1=chiptype SN76496/SMS
;@----------------------------------------------------------------------------
	cmp r1,#1
	ldr r3,=(WFEED_SN<<16)+PFEED_SN
	ldreq r3,=(WFEED_SMS<<16)+PFEED_SMS
	ldrhi r3,=(WFEED_NCR<<16)+PFEED_NCR

	mov r1,#0
	mov r2,#snStateEnd/4		;@ 52/4=13
rLoop:
	subs r2,r2,#1
	strpl r1,[snptr,r2,lsl#2]
	bhi rLoop

	str r3,[snptr,#noiseType]
	strh r3,[snptr,#rng]
	mov r3,r3,lsr#16
	strh r3,[snptr,#noiseFB]

	bx lr

;@----------------------------------------------------------------------------
sn76496SaveState:			;@ In r0=dest, r1=sn76496ptr. Out r0=state size.
	.type   sn76496SaveState STT_FUNC
;@----------------------------------------------------------------------------
	mov r2,#snStateEnd
	stmfd sp!,{r2,lr}

	bl memcpy

	ldmfd sp!,{r0,lr}
	bx lr
;@----------------------------------------------------------------------------
sn76496LoadState:			;@ In r0=sn76496ptr, r1=source. Out r0=state size.
	.type   sn76496LoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	mov r2,#snStateEnd
	bl memcpy

	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
sn76496GetStateSize:		;@ Out r0=state size.
	.type   sn76496GetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#snStateEnd
	bx lr
;@----------------------------------------------------------------------------
sn76496SetMixrate:			;@ In r0=sn76496ptr, r1 in 0 = low, 1 = high
;@----------------------------------------------------------------------------
	cmp r1,#0
	moveq r1,#924				;@ low,  18157Hz
	movne r1,#532				;@ high, 31536Hz
	str r1,[snptr,#mixRate]
	bx lr
;@----------------------------------------------------------------------------
sn76496SetFrequency:		;@ In r0=sn76496ptr, r1=frequency of chip.
;@----------------------------------------------------------------------------
	ldr r2,[snptr,#mixRate]
	mul r1,r2,r1
	mov r1,r1,lsr#12
	str r1,[snptr,#freqConv]	;@ Frequency conversion (SN76496freq*mixrate)/4096
	bx lr
;@----------------------------------------------------------------------------
frequencyCalculate:			;@ In r0=sn76496ptr, r1=FREQTABLE
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
	.section .ewram, "ax", %progbits
	.align 2
;@----------------------------------------------------------------------------
sn76496W:					;@ In r0=value, r1=sn76496ptr
	.type   sn76496W STT_FUNC
;@----------------------------------------------------------------------------
	movs r12,r0,lsl#25
	ldrcc r12,[r1,#snLastReg]
	strcs r12,[r1,#snLastReg]
	movs r2,r12,lsr#30
	bcc setFreq
doVolume:
	and r0,r0,#0x0F
	adr r12,attenuation			;@ This might be possible to optimise.
	add r12,r12,r0
	ldrh r0,[r12,r0]
	add r2,r1,r2,lsl#1
	strh r0,[r2,#ch0Volume]
	bx lr

setFreq:
	cmp r2,#2					;@ Check channel 2/3
	bhi setNoiseFreq			;@ Noise channel
	add r2,r1,r2,lsl#2
	tst r0,#0x80				;@ Should not change carry.
	ldrbne r0,[r2,#ch0Reg+1]
	andeq r0,r0,#0x3F
	orr r0,r0,r12,lsl#3
	mov r0,r0,ror#24
	ldrbcs r12,[r1,#ch3Reg]
	strh r0,[r2,#ch0Reg]
	mov r0,r0,lsr#3

	cmp r12,#3
	ldr r12,[r1,#freqTablePtr]
	ldrh r0,[r12,r0]
	strh r0,[r2,#ch0Frq]

	strheq r0,[r1,#ch3Frq]
	bx lr

setNoiseFreq:
	and r2,r0,#3
	strb r2,[r1,#ch3Reg]
	ldr r12,[r1,#noiseType]
	tst r0,#4
	strh r12,[r1,#rng]
	movne r12,r12,lsr#16		;@ White noise
	strh r12,[r1,#noiseFB]
	cmp r2,#3
	ldrne r0,[r1,#freqConv]
	ldrheq r0,[r1,#ch2Frq]
	movne r0,r0,lsr#5			;@ These values sound ok
	movne r0,r0,lsr r2
	strh r0,[r1,#ch3Frq]
	bx lr

attenuation:				;@ each step * 0.79370053 (-1dB?)
	.hword 0x3FFF,0x32CB,0x2851,0x2000,0x1966,0x1428,0x1000,0x0CB3,0x0A14,0x0800,0x0659,0x050A,0x0400,0x032C,0x0285,0x0000
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
