;@ SN76496 sound chip emulator.
#ifdef __arm__

#include "SN76496.i"

	.global sn76496Reset
	.global sn76496SaveState
	.global sn76496LoadState
	.global sn76496GetStateSize
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

#ifdef NDS
	.section .itcm						;@ For the NDS
#elif GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
#else
	.section .text
#endif
	.align 2
;@----------------------------------------------------------------------------
;@ r0  = Mix length.
;@ r1  = Mixerbuffer.
;@ r2 -> r5 = pos+freq.
;@ r6  = currentBits + offset to calculated volumes.
;@ r7  = Noise generator.
;@ r8  = Noise feedback.
;@ lr  = Mixer reg.
;@ r12 = snptr.
;@----------------------------------------------------------------------------
sn76496Mixer:				;@ r0=len, r1=dest, r12=snptr
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r8,lr}
	ldmia snptr,{r2-r8,lr}		;@ Load freq/addr0-3, currentBits, rng, noisefb, attChg
	tst lr,#0xff
	blne calculateVolumes
;@----------------------------------------------------------------------------
mixLoop:
	adds r2,r2,#0x00400000
	subcs r2,r2,r2,lsl#16
	eorcs r6,r6,#0x02

	adds r3,r3,#0x00400000
	subcs r3,r3,r3,lsl#16
	eorcs r6,r6,#0x04

	adds r4,r4,#0x00400000
	subcs r4,r4,r4,lsl#16
	eorcs r6,r6,#0x08

	adds r5,r5,#0x00400000		;@ 0x00200000?
	subcs r5,r5,r5,lsl#16
	biccs r6,r6,#0x10
	movscs r7,r7,lsr#1
	eorcs r7,r7,r8
	orrcs r6,r6,#0x10

	ldrh lr,[snptr,r6]
	subs r0,r0,#1
	strhpl lr,[r1],#2
	bhi mixLoop

	stmia snptr,{r2-r7}			;@ Writeback freq,addr,currentBits,rng
	ldmfd sp!,{r4-r8,lr}
	bx lr
;@----------------------------------------------------------------------------

	.section .text
	.align 2
;@----------------------------------------------------------------------------
sn76496Reset:				;@ r0 = chiptype SMS/SN76496, snptr=r12=pointer to struct
;@----------------------------------------------------------------------------

	cmp r0,#1
	ldr r3,=(WFEED_SMS<<16)+PFEED_SMS
	ldreq r3,=(WFEED_SN<<16)+PFEED_SN
	ldrhi r3,=(WFEED_NCR<<16)+PFEED_NCR

	mov r0,#0
	mov r2,#snSize/4			;@ 60/4=15
rLoop:
	subs r2,r2,#1
	strpl r0,[snptr,r2,lsl#2]
	bhi rLoop
	strh r3,[snptr,#noiseFB]
	str r3,[snptr,#noiseType]
	mov r2,#calculatedVolumes
	str r2,[snptr,#currentBits]
	mov r1,#0x8000
	strh r1,[snptr,r2]

	bx lr

;@----------------------------------------------------------------------------
sn76496SaveState:		;@ In r0=destination, r1=snptr. Out r0=state size.
	.type   sn76496SaveState STT_FUNC
;@----------------------------------------------------------------------------
	mov r2,#snSize
	stmfd sp!,{r2,lr}

	bl memcpy

	ldmfd sp!,{r0,lr}
	bx lr
;@----------------------------------------------------------------------------
sn76496LoadState:		;@ In r0=snptr, r1=source. Out r0=state size.
	.type   sn76496LoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	mov r2,#snSize
	bl memcpy

	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
sn76496GetStateSize:	;@ Out r0=state size.
	.type   sn76496GetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#snSize
	bx lr

;@----------------------------------------------------------------------------
sn76496W:					;@ r0 = value, snptr = r12 = struct-pointer
;@----------------------------------------------------------------------------
	tst r0,#0x80
	andne r2,r0,#0x70
	strbne r2,[snptr,#snLastReg]
	ldrbeq r2,[snptr,#snLastReg]
	movs r2,r2,lsr#5
	add r1,snptr,r2,lsl#2
	bcc setFreq
doVolume:
	ldrb r2,[r1,#ch0Att]
	and r0,r0,#0x0F
	eors r2,r2,r0
	strbne r0,[r1,#ch0Att]
	strbne r2,[snptr,#snAttChg]
	bx lr

setFreq:
	cmp r2,#3					;@ Noise channel
	beq setNoiseFreq
	tst r0,#0x80
	andeq r0,r0,#0x3F
	movne r0,r0,lsl#4
	strbeq r0,[r1,#ch0Reg+1]
	strbne r0,[r1,#ch0Reg]
	ldrh r0,[r1,#ch0Reg]
	movs r0,r0,lsl#2			;@ 0x000 is 0x400 on SN76496, 0x001 on SMS VDP.
//	moveq r0,#0x0040			;@ This is for SMS
	strh r0,[r1,#ch0Frq]

	cmp r2,#2					;@ Ch2
	ldrbeq r1,[snptr,#ch3Reg]
	cmpeq r1,#3
	strheq r0,[snptr,#ch3Frq]
	bx lr

setNoiseFreq:
	and r1,r0,#3
	strb r1,[snptr,#ch3Reg]
	tst r0,#4
	ldr r0,[r1,noiseType]
	strh r0,[r1,#rng]
	movne r0,r0,lsr#16			;@ White noise
	strh r0,[snptr,#noiseFB]
	cmp r1,#3
	ldrheq r0,[snptr,#ch2Frq]
	movne r0,#0x0400			;@ These values sound ok
	movne r0,r0,lsl r1
	strh r0,[snptr,#ch3Frq]
	bx lr

;@----------------------------------------------------------------------------
calculateVolumes:
;@----------------------------------------------------------------------------
	stmfd sp!,{r0-r6,lr}

	ldrb r3,[snptr,#ch0Att]
	ldrb r4,[snptr,#ch1Att]
	ldrb r5,[snptr,#ch2Att]
	ldrb r6,[snptr,#ch3Att]
	adr r1,attenuation
	ldr r3,[r1,r3,lsl#2]
	ldr r4,[r1,r4,lsl#2]
	ldr r5,[r1,r5,lsl#2]
	ldr r6,[r1,r6,lsl#2]

	mov lr,#0x8000
	add r2,snptr,#calculatedVolumes
	mov r1,#0x1E
volLoop:
	ands r0,r1,#0x02
	movne r0,r3
	tst r1,#0x04
	addne r0,r0,r4
	tst r1,#0x08
	addne r0,r0,r5
	tst r1,#0x10
	addne r0,r0,r6
	eor r0,lr,r0,lsr#2
	strh r0,[r2,r1]
	subs r1,r1,#2
	bne volLoop
	strb r1,[snptr,#snAttChg]
	ldmfd sp!,{r0-r6,pc}

;@----------------------------------------------------------------------------
attenuation:						;@ each step * 0.79370053 (-2dB?)
	.long 0xFFFF,0xCB30,0xA145,0x8000,0x6598,0x50A3,0x4000,0x32CC
	.long 0x2851,0x2000,0x1966,0x1428,0x1000,0x0CB3,0x0A14,0x0000
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
