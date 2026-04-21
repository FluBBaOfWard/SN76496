;@
;@  SN76496.i
;@  SN76496/SN76489 sound chip emulator for arm32.
;@
;@  Created by Fredrik Ahlström on 2005-07-11.
;@  Copyright © 2005-2026 Fredrik Ahlström. All rights reserved.
;@
#if !__ASSEMBLER__
	#error This header file is only for use in assembly files!
#endif

							;@ SN76496.s
	.struct 0
snStateStart:

ch0Frq:			.short 0
ch0Cnt:			.short 0
ch1Frq:			.short 0
ch1Cnt:			.short 0
ch2Frq:			.short 0
ch2Cnt:			.short 0
ch3Frq:			.short 0
ch3Cnt:			.short 0

rng:			.long 0
currentBits:	.long 0
noiseFB:		.long 0

snAttChg:		.byte 0
ch3Reg:			.byte 0
snPadding:		.skip 2

calculatedVolumes:	.space 16*2

ch0Volume:		.short 0
				.skip 1
ch0Att:			.byte 0
ch1Volume:		.short 0
				.skip 1
ch1Att:			.byte 0
ch2Volume:		.short 0
				.skip 1
ch2Att:			.byte 0
ch3Volume:		.short 0
				.skip 1
ch3Att:			.byte 0

snLastReg:		.long 0

snStateEnd:
noiseType:		.long 0

snSize:

;@----------------------------------------------------------------------------

