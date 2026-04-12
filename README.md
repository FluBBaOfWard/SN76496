# SN76496 V1.6.8

SN76496/SN76489, SMS sound chip plus GG stereo extension for ARM32.

## How to use

First alloc chip struct, call sn76496Reset with chip type & struct.
Call sn76496Mixer with length, destination and chip struct.
Produces signed 16bit interleaved stereo.

## Projects that use this code

* <https://github.com/FluBBaOfWard/S8DS>

## Credits

Fredrik Ahlström

<https://bsky.app/profile/therealflubba.bsky.social>

<https://www.github.com/FluBBaOfWard>

X/Twitter @TheRealFluBBa
