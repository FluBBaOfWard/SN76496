;@
;@  SN76496.i
;@  SN76496/SMS sound chip emulator for arm32.
;@
;@  Created by Fredrik Ahlström on 2009-08-25.
;@  Copyright © 2009-2022 Fredrik Ahlström. All rights reserved.
;@
;@ ASM header for the SN76496 emulator
;@

	snptr			.req r0

							;@ SN76496.s
	.struct 0
	ch0Frq:			.short 0
	ch0Cnt:			.short 0
	ch1Frq:			.short 0
	ch1Cnt:			.short 0
	ch2Frq:			.short 0
	ch2Cnt:			.short 0
	ch3Frq:			.short 0
	ch3Cnt:			.short 0

	rng:			.long 0
	noiseFB:		.long 0

	ch0Volume:		.short 0
	ch1Volume:		.short 0
	ch2Volume:		.short 0
	ch3Volume:		.short 0

	ch0Reg:			.long 0
	ch1Reg:			.long 0
	ch2Reg:			.long 0
	ch3Reg:			.long 0
	snLastReg:		.byte 0
	snPadding:		.space 3

	mixLength:		.long 0
	mixRate:		.long 0
	freqConv:		.long 0
	freqTablePtr:	.long 0

	noiseType:		.long 0
	snSize:

;@----------------------------------------------------------------------------

