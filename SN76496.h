//
//  SN76496.h
//  SN76496/SMS/GG/MD/NGP sound chip emulator for arm32.
//
//  Created by Fredrik Ahlström on 2005-07-11.
//  Copyright © 2005-2026 Fredrik Ahlström. All rights reserved.
//
#ifndef SN76496_HEADER
#define SN76496_HEADER

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
	u16 ch0Frq;
	u16 ch0Cnt;
	u16 ch1Frq;
	u16 ch1Cnt;
	u16 ch2Frq;
	u16 ch2Cnt;
	u16 ch3Frq;
	u16 ch3Cnt;

	u32 rng;
	u32 currentBits;
	u32 noiseFB;

	u8 attChg;
	u8 ch3Reg;
	u8 ggStereo;
	u8 padding[1];

	u8 padding0[2];
	u8 ch0AttL;
	u8 ch0Att;
	u8 padding1[2];
	u8 ch1AttL;
	u8 ch1Att;
	u16 ch2Reg;
	u8 ch2AttL;
	u8 ch2Att;
	u8 padding3[2];
	u8 ch3AttL;
	u8 ch3Att;

	u32 lastReg;
	u32 lastRegL;

	u32 noiseType;
	u32 padding4[1];
	s16 calculatedVolumes[16*2];
} SN76496;

/**
 * Reset/initialize SN76496 chip.
 * @param  chipType: selects version of chip, 0=SN76496, 1=SMS/GG VDP version, 2=NCR 8496.
 * @param  *chip: The SN76496 chip.
 */
void sn76496Reset(int chiptype, SN76496 *chip);

/**
 * Saves the state of the SN76496 chip to the destination.
 * @param  *destination: Where to save the state.
 * @param  *chip: The SN76496 chip to save.
 * @return The size of the state.
 */
int sn76496SaveState(void *destination, const SN76496 *chip);

/**
 * Loads the state of the SN76496 chip from the source.
 * @param  *chip: The SN76496 chip to load a state into.
 * @param  *source: Where to load the state from.
 * @return The size of the state.
 */
int sn76496LoadState(SN76496 *chip, const void *source);

/**
 * Gets the state size of a SN76496.
 * @return The size of the state.
 */
int sn76496GetStateSize(void);

/**
 * Runs the sound chip for count number of cycles shifted by "SN_UPSHIFT",
 * the default is 2, so if actual chip would output 218kHz this mixer would render at ~55kHz.
 * @param  count: Number of samples to generate.
 * @param  *dest: Pointer to buffer where sound is rendered.
 * @param  *chip: The SN76496 chip.
 */
void sn76496Mixer(int count, s16 *dest, SN76496 *chip);

/**
 * Write value to SN76496 chip (NGP port#0).
 * @param  value: value to write.
 * @param  *chip: The SN76496 chip.
 */
void sn76496W(u8 value, SN76496 *chip);

/**
 * Write value to NGP/SN76496 chip port#1.
 * @param  value: value to write.
 * @param  *chip: The SN76496 chip.
 */
void sn76496LW(u8 value, SN76496 *chip);

/**
 * Write stereo separation value to SN76496 chip in the GameGear
 * @param  *chip: The SN76496 chip.
 * @param  value: value to write.
 */
void sn76496GGW(u8 value, SN76496 *chip);


#ifdef __cplusplus
}
#endif

#endif // SN76496_HEADER
