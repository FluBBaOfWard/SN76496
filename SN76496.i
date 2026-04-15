;@
;@  SN76496.i
;@  SN76496/SMS sound chip emulator for arm32.
;@
;@  Created by Fredrik Ahlström on 2009-08-25.
;@  Copyright © 2009-2026 Fredrik Ahlström. All rights reserved.
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
ggStereo:		.byte 0
snPadding:		.skip 1

snPadding0:		.skip 3
ch0Att:			.byte 0
snPadding1:		.skip 3
ch1Att:			.byte 0
snPadding2:		.skip 3
ch2Att:			.byte 0
snPadding3:		.skip 3
ch3Att:			.byte 0

snLastReg:		.long 0

snStateEnd:
noiseType:		.long 0
snPadding4:		.skip 2*4
calculatedVolumes:	.space 16*2*2

snSize:

;@----------------------------------------------------------------------------

