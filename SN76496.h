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
	u32 noiseFB;

	u8 attChg;
	u8 ggStereo;
	u8 padding[2];

	u32 ch0Reg;
	u32 ch1Reg;
	u32 ch2Reg;
	u32 ch3Reg;
#ifdef SN_NGP
	u32 ch0RegL;
	u32 ch1RegL;
	u32 ch2RegL;
	u32 ch3RegL;

	u32 snLastRegL;
#endif
	u32 snLastReg;

	u32 noiseType;
	u32 mixRate;
	u32 freqConv;
	u16 *freqTablePtr;
	u16 calculatedVolumes[16*2];
} SN76496;

void sn76496SetMixrate(SN76496 *chip, int rate);
void sn76496SetFrequency(SN76496 *chip, int freq);

void sn76496Init(SN76496 *chip, u16 *freqtableptr);

/**
 * Reset SN76496 chip.
 * @param  chipType: selects version of chip, 0=SN76496, 1=SMS/GG VDP version, 2=NCR 8496.
 * @param  *chip: The SN76496 chip.
 */
void sn76496Reset(int chipType, SN76496 *chip);

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
 * Render length number of samples.
 * @param  *dest: Pointer to buffer where sound is rendered.
 * @param  *len: Number of samples to render.
 * @param  *chip: The SN76496 chip.
 */
void sn76496Mixer(char *dest, int length, SN76496 *chip);

/**
 * Write value to SN76496 chip
 * @param  value: value to write.
 * @param  *chip: The SN76496 chip.
 */
void sn76496W(u8 value, SN76496 *chip);

/**
 * Write value to SN76496 chip, left side
 * @param  value: value to write.
 * @param  *chip: The SN76496 chip.
 */
void sn76496LW(u8 value, SN76496 *chip);

/**
 * Write stereo separation value to SN76496 chip in the GameGear
 * @param  value: value to write.
 * @param  *chip: The SN76496 chip.
 */
void sn76496GGW(u8 value, SN76496 *chip);

#ifdef __cplusplus
}
#endif

#endif // SN76496_HEADER
