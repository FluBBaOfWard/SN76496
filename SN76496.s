;@
;@  SN76496.s
;@  SN76496/SMS/GG/MD/NGP sound chip emulator for arm32.
;@
;@  Created by Fredrik Ahlström on 2005-07-11.
;@  Copyright © 2005-2026 Fredrik Ahlström. All rights reserved.
;@
#ifdef __arm__

#include "SN76496.i"

	.global sn76496Reset
	.global sn76496SaveState
	.global sn76496LoadState
	.global sn76496GetStateSize
	.global sn76496Mixer
	.global sn76496W
	.global sn76496LW
	.global sn76496GGW
								;@ These values are for the SN76489/SN76496 sound chip.
	.equ PFEED_SN,	0x4000		;@ Periodic Noise Feedback
	.equ WFEED_SN,	0x6000		;@ White Noise Feedback

								;@ These values are for the SMS/GG/MD vdp/sound chip.
	.equ PFEED_SMS,	0x8000		;@ Periodic Noise Feedback
	.equ WFEED_SMS,	0x9000		;@ White Noise Feedback

								;@ These values are for the NCR 8496 sound chip.
	.equ PFEED_NCR,	0x4000		;@ Periodic Noise Feedback
	.equ WFEED_NCR,	0x4400		;@ White Noise Feedback

#define SN_ADDITION 0x00400000
#if !defined(SN_UPSHIFT)
	#define SN_UPSHIFT (2)
#endif

	.syntax unified
	.arm

#ifdef NDS
	.section .itcm, "ax", %progbits		;@ For the NDS ARM9
#elif GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
#else
	.section .text
#endif
	.align 2
;@----------------------------------------------------------------------------
;@ r0  = Mix length.
;@ r1  = Mixerbuffer.
;@ r2  = sn76496ptr.
;@ r3 -> r6 = pos+freq.
;@ r7  = Noise generator.
;@ r8  = currentBits + offset to calculated volumes.
;@ r9  = Noise feedback.
;@ r12 = Scrap.
;@ lr  = Mixer reg.
;@----------------------------------------------------------------------------
sn76496Mixer:				;@ In r0=len, r1=dest, r2=sn76496ptr
	.type   sn76496Mixer STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r9,lr}
	ldmia r2,{r3-r9,lr}			;@ Load freq/addr0-3, rng, currentBits, noisefb, attChg
	tst lr,#0xff
	blne calculateVolumes
;@----------------------------------------------------------------------------
mixLoop:
	mov lr,#0x80000000
innerMixLoop:
	adds r3,r3,#SN_ADDITION
	subcs r3,r3,r3,lsl#18
	eorcs r8,r8,#0x04

	adds r4,r4,#SN_ADDITION
	subcs r4,r4,r4,lsl#18
	eorcs r8,r8,#0x08

	adds r5,r5,#SN_ADDITION
	subcs r5,r5,r5,lsl#18
	eorcs r8,r8,#0x10

	adds r6,r6,#SN_ADDITION		;@ 0x00200000?
	subcs r6,r6,r6,lsl#18
	biccs r8,r8,#0x20
	movscs r7,r7,lsr#1
	eorcs r7,r7,r9
	orrcs r8,r8,#0x20

	ldr r12,[r2,r8]
	adds r0,r0,#0x100000000>>SN_UPSHIFT
	add lr,lr,r12
	bcc innerMixLoop
	eor lr,lr,#0x00008000
	subs r0,r0,#1
	strpl lr,[r1],#4
	bhi mixLoop

	stmia r2,{r3-r8}			;@ Writeback freq,addr,rng,currentBits
	ldmfd sp!,{r4-r9,lr}
	bx lr
;@----------------------------------------------------------------------------

	.section .text
	.align 2
;@----------------------------------------------------------------------------
sn76496Reset:				;@ In r0=chiptype SMS/SN76496, r1=sn76496ptr
	.type   sn76496Reset STT_FUNC
;@----------------------------------------------------------------------------
	cmp r0,#1
	ldr r3,=(WFEED_SN<<16)+PFEED_SN
	ldreq r3,=(WFEED_SMS<<16)+PFEED_SMS
	ldrhi r3,=(WFEED_NCR<<16)+PFEED_NCR

	mov r0,#0
	mov r2,#snStateEnd/4		;@ 60/4=15
rLoop:
	subs r2,r2,#1
	strpl r0,[r1,r2,lsl#2]
	bhi rLoop

	str r3,[r1,#noiseType]
	strh r3,[r1,#rng]
	mov r3,r3,lsr#16
	strh r3,[r1,#noiseFB]
	mov r2,#calculatedVolumes
	str r2,[r1,#currentBits]	;@ Add offset to calculatedVolumes
	str r0,[r1,r2]				;@ Clear volume 0
	mov r0,#0xFF
	strb r0,[r1,#ggStereo]

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
	stmfd sp!,{r0,lr}

	mov r2,#snStateEnd
	bl memcpy
	ldmfd sp!,{r0,lr}
	mov r1,#1
	strb r1,[r0,#snAttChg]
;@----------------------------------------------------------------------------
sn76496GetStateSize:		;@ Out r0=state size.
	.type   sn76496GetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#snStateEnd
	bx lr

#ifndef SN_NGP
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
	add r2,r1,r2,lsl#2
	ldrb r12,[r2,#ch0Att]
	and r0,r0,#0x0F
	eors r12,r12,r0
	strbne r0,[r2,#ch0Att]
	strbne r12,[r1,#snAttChg]
	bx lr

setFreq:
	cmp r2,#2					;@ Check channel 2/3
	bhi setNoiseFreq			;@ Noise channel
	add r2,r1,r2,lsl#2
	ldrbeq r1,[r1,#ch3Reg]		;@ Cache Ch3 reg
	tst r0,#0x80
	ldrbne r0,[r2,#ch0Frq+1]
	andeq r0,r0,#0x3F
	orr r0,r0,r12,lsl#3
	mov r0,r0,ror#24
	cmp r0,#0x0060				;@ We set any value under 6 to 1 to fix aliasing.
	movmi r0,#0x0010			;@ Value zero is same as 1 on SMS.
	strh r0,[r2,#ch0Frq]

	cmp r1,#3
	strheq r0,[r2,#ch0Frq+4]	;@ This means Ch3Frq
	bx lr

setNoiseFreq:
	and r2,r0,#3
	strb r2,[r1,#ch3Reg]
	ldr r12,[r1,#noiseType]
	tst r0,#4
	strh r12,[r1,#rng]
	movne r12,r12,lsr#16			;@ White noise
	strh r12,[r1,#noiseFB]
	cmp r2,#3
	ldrheq r0,[r1,#ch2Frq]
	movne r0,#0x0100			;@ These values sound ok
	movne r0,r0,lsl r2
	strh r0,[r1,#ch3Frq]
	bx lr

;@----------------------------------------------------------------------------
sn76496GGW:					;@ In r0=value, r1=sn76496ptr
	.type   sn76496GGW STT_FUNC
;@----------------------------------------------------------------------------
	ldrb r2,[r1,#ggStereo]
	eors r2,r2,r0
	strbne r0,[r1,#ggStereo]
	strbne r2,[r1,#snAttChg]
	bx lr

;@----------------------------------------------------------------------------
calculateVolumes:			;@ In r2=sn76496ptr
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,r1,r3-r6}

	add r1,r2,#snPadding0
	ldmia r1,{r3-r6}
	adr r1,attenuation1_4
	ldr r3,[r1,r3,lsr#22]
	ldr r4,[r1,r4,lsr#22]
	ldr r5,[r1,r5,lsr#22]
	ldr r6,[r1,r6,lsr#22]

	ldrb r0,[r2,#ggStereo]
	mov r1,#-1
	teq r0,r0,lsl#31
	bicpl r3,r3,r1,lsl#16
	biccc r4,r4,r1,lsl#16
	teq r0,r0,lsl#29
	bicpl r5,r5,r1,lsl#16
	biccc r6,r6,r1,lsl#16
	teq r0,r0,lsl#27
	bicpl r3,r3,r1,lsr#16
	biccc r4,r4,r1,lsr#16
	teq r0,r0,lsl#25
	bicpl r5,r5,r1,lsr#16
	biccc r6,r6,r1,lsr#16

	add r12,r2,#calculatedVolumes
	mov r1,#15
volLoop:
	movs r0,r1,lsl#31
	movmi r0,r3
	addcs r0,r0,r4
	teq r1,r1,lsl#29
	addmi r0,r0,r5
	addcs r0,r0,r6
	str r0,[r12,r1,lsl#2]
	subs r1,r1,#1
	bne volLoop

	strb r1,[r2,#snAttChg]
	ldmfd sp!,{r0,r1,r3-r6}
	bx lr
;@----------------------------------------------------------------------------
attenuation:						;@ each step * 0.79370053 (-1dB?)
	.long 0x3FFF3FFF,0x32CB32CB,0x28512851,0x20002000,0x19661966,0x14281428,0x10001000,0x0CB30CB3
	.long 0x0A140A14,0x08000800,0x06590659,0x050A050A,0x04000400,0x032C032C,0x02850285,0x00000000
attenuation1_4:						;@ each step * 0.79370053 (-1dB?)
	.long 0x0FFF0FFF,0x0CB30CB3,0x0A140A14,0x08000800,0x06590659,0x050A050A,0x04000400,0x032C032C
	.long 0x02850285,0x02000200,0x01960196,0x01430143,0x01000100,0x00CB00CB,0x00A100A1,0x00000000
;@----------------------------------------------------------------------------
#else
;@----------------------------------------------------------------------------
sn76496W:					;@ In r0=value, r1=sn76496ptr, right ch.
	.type   sn76496W STT_FUNC
;@----------------------------------------------------------------------------
	movs r12,r0,lsl#25
	ldrcc r12,[r1,#snLastReg]
	strcs r12,[r1,#snLastReg]
	movs r2,r12,lsr#30
	bcc setFreq
doVolume:
	add r2,r1,r2,lsl#2
	ldrb r12,[r2,#ch0Att]
	and r0,r0,#0x0F
	eors r12,r12,r0
	strbne r0,[r2,#ch0Att]
	strbne r12,[r1,#snAttChg]
	bx lr

setFreq:
	movs r12,r12,lsl#1
	bxcc lr
	bmi setNoiseFreq
	tst r0,#0x80
	ldrbne r0,[r1,#ch2Reg+1]
	andeq r0,r0,#0x3F
	orr r0,r0,r12,lsl#2
	mov r0,r0,ror#24
	cmp r0,#0x0060				;@ We set any value under 6 to 1 to fix aliasing.
	movmi r0,#0x0010			;@ Value zero is same as 1 on SMS.
	ldrb r12,[r1,#ch3Reg]
	strh r0,[r1,#ch2Reg]

	cmp r12,#3
	strheq r0,[r1,#ch3Frq]
	bx lr

setNoiseFreq:
	and r2,r0,#3
	strb r2,[r1,#ch3Reg]
	ldr r12,[r1,#noiseType]
	tst r0,#4
	strh r12,[r1,#rng]
	movne r12,r12,lsr#16			;@ White noise
	strh r12,[r1,#noiseFB]
	cmp r2,#3
	ldrheq r0,[r1,#ch2Reg]
	movne r0,#0x0100			;@ These values sound ok
	movne r0,r0,lsl r2
	strh r0,[r1,#ch3Frq]
	bx lr

;@----------------------------------------------------------------------------
sn76496LW:					;@ In r0 = value, r1 = sn76496ptr, left ch.
	.type   sn76496LW STT_FUNC
;@----------------------------------------------------------------------------
	movs r12,r0,lsl#25
	ldrcc r12,[r1,#snLastRegL]
	strcs r12,[r1,#snLastRegL]
	movs r2,r12,lsr#30
	add r2,r1,r2,lsl#2
	bcc setFreqL
doVolumeL:
	ldrb r12,[r2,#ch0AttL]
	and r0,r0,#0x0F
	eors r12,r12,r0
	strbne r0,[r2,#ch0AttL]
	strbne r12,[r1,#snAttChg]
	bx lr

setFreqL:
	cmn r12,#0x40000000			;@ Noise channel
	bxcs lr
	tst r0,#0x80
	ldrbne r0,[r2,#ch0Frq+1]
	andeq r0,r0,#0x3F
	orr r0,r0,r12,lsl#3
	mov r0,r0,ror#24
	cmp r0,#0x0060				;@ We set any value under 6 to 1 to fix aliasing.
	movmi r0,#0x0010			;@ Value zero is same as 1 on SMS.
	strh r0,[r2,#ch0Frq]

//	cmp r12,#2					;@ Ch2
//	ldrbeq r2,[r1,#ch3Reg]
//	cmpeq r2,#3
//	strheq r0,[r1,#ch3Frq]
	bx lr

;@----------------------------------------------------------------------------
calculateVolumes:			;@ In r2 = snptr
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,r1,r3-r6}

	add r1,r2,#snPadding0
	ldmia r1,{r4-r6,r12}
	adr r1,attenuation

	ldr r3,[r1,r4,lsr#22]
	mov r4,r4,lsl#8
	ldr r0,[r1,r4,lsr#22]
	orr r3,r3,r0,lsl#16

	ldr r4,[r1,r5,lsr#22]
	mov r5,r5,lsl#8
	ldr r0,[r1,r5,lsr#22]
	orr r4,r4,r0,lsl#16

	ldr r5,[r1,r6,lsr#22]
	mov r6,r6,lsl#8
	ldr r0,[r1,r6,lsr#22]
	orr r5,r5,r0,lsl#16

	ldr r6,[r1,r12,lsr#22]
	mov r12,r12,lsl#8
	ldr r0,[r1,r12,lsr#22]
	orr r6,r6,r0,lsl#16

	add r12,r2,#calculatedVolumes
	mov r1,#15
volLoop:
	movs r0,r1,lsl#31
	movmi r0,r3
	addcs r0,r0,r4
	teq r1,r1,lsl#29
	addmi r0,r0,r5
	addcs r0,r0,r6
	str r0,[r12,r1,lsl#2]
	subs r1,r1,#1
	bne volLoop

	strb r1,[r2,#snAttChg]
	ldmfd sp!,{r0,r1,r3-r6}
	bx lr
;@----------------------------------------------------------------------------
attenuation:						;@ each step * 0.79370053 (-1dB?)
	.long 0x3FFF>>SN_UPSHIFT,0x32CB>>SN_UPSHIFT,0x2851>>SN_UPSHIFT,0x2000>>SN_UPSHIFT
	.long 0x1966>>SN_UPSHIFT,0x1428>>SN_UPSHIFT,0x1000>>SN_UPSHIFT,0x0CB3>>SN_UPSHIFT
	.long 0x0A14>>SN_UPSHIFT,0x0800>>SN_UPSHIFT,0x0659>>SN_UPSHIFT,0x050A>>SN_UPSHIFT
	.long 0x0400>>SN_UPSHIFT,0x032C>>SN_UPSHIFT,0x0285>>SN_UPSHIFT,0x0000>>SN_UPSHIFT
;@----------------------------------------------------------------------------
#endif
	.end
#endif // #ifdef __arm__
