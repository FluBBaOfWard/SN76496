# SN76496 V1.6.8

SN76496/SN76489, SMS/MD & NCR8496 sound chip emulator for ARM32.

This is highly specialised for the GBA but can probably be tweaked
quite easily to support other platforms as well.

## How to use

First alloc chip struct.
Then call sn76496SetMixrate with 0 or 1 for low or high quality.
Then call sn76496SetFrequency with the actual clock rate of the chip.
Finally call sn76496Init to set it up.

Call sn76496Mixer with chip struct, length and destination.
Produces 8bit signed mono.

## Projects that use this code

* <https://github.com/FluBBaOfWard/GreenBeretGBA>
* <https://github.com/FluBBaOfWard/YieArGBA>

## Credits

Fredrik Ahlström

<https://bsky.app/profile/therealflubba.bsky.social>

<https://www.github.com/FluBBaOfWard>

X/Twitter @TheRealFluBBa
