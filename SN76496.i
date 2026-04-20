;@
;@  SN76496.i
;@  SN76496/SMS/GG/MD/NGP sound chip emulator for arm32.
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
noiseFB:		.long 0

snAttChg:		.byte 0
ggStereo:		.byte 0
snPadding:		.skip 2

ch0Reg:			.short 0
ch0AttL:		.byte 0
ch0Att:			.byte 0
ch1Reg:			.short 0
ch1AttL:		.byte 0
ch1Att:			.byte 0
ch2Reg:			.short 0
ch2AttL:		.byte 0
ch2Att:			.byte 0
ch3Reg:			.short 0
ch3AttL:		.byte 0
ch3Att:			.byte 0
#ifdef SN_NGP
ch0RegL:		.short 0
snPadding0L:	.skip 2
ch1RegL:		.short 0
snPadding1L:	.skip 2
ch2RegL:		.short 0
snPadding2L:	.skip 2
ch3RegL:		.short 0
snPadding3L:	.skip 2

snLastRegL:		.long 0
#endif
snLastReg:		.long 0

snStateEnd:
noiseType:		.long 0
mixRate:		.long 0
freqConv:		.long 0
freqTablePtr:	.long 0

calculatedVolumes:	.space 16*2*2

snSize:

;@----------------------------------------------------------------------------

