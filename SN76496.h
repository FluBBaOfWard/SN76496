//
//  SN76496.h
//  SN76496/SMS sound chip emulator for arm32.
//
//  Created by Fredrik Ahlström on 2009-08-25.
//  Copyright © 2009-2022 Fredrik Ahlström. All rights reserved.
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

	u16 ch0Volume;
	u16 ch1Volume;
	u16 ch2Volume;
	u16 ch3Volume;

	u32 ch0Reg;
	u32 ch1Reg;
	u32 ch2Reg;
	u32 ch3Reg;

	u8 snLastReg;
	u8 snPadding[3];

	u32 mixLength;
	u32 mixRate;
	u32 freqConv;
	u16 *freqTablePtr;
} SN76496;

void sn76496Init(SN76496 *chip, u16 *freqtableptr);

/**
 * Reset SN76496 chip.
 * @param  *chip: The SN76496 chip.
 * @param  chipType: selects version of chip, 0=SMS/GG VDP version, 1=SN76496, 2=NCR 8496.
 */
void sn76496Reset(SN76496 *chip, int chipType);

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

void sn76496SetMixrate(SN76496 *chip, int);
void sn76496SetFrequency(SN76496 *chip, int);

/**
 * Render len number of samples.
 * @param  *chip: The SN76496 chip.
 * @param  *dest: Pointer to buffer where sound is rendered.
 * @param  *len: Number of samples to render.
 */
void sn76496Mixer(SN76496 *chip, char *dest, int length);

/**
 * Write value to SN76496 chip
 * @param  *chip: The SN76496 chip.
 * @param  value: value to write.
 */
void sn76496W(SN76496 *chip, u8 value);

#ifdef __cplusplus
}
#endif

#endif // SN76496_HEADER
