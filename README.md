# SN76496 V1.6.8

SN76496/SN76489, SMS/MD sound chip plus GG & NGP stereo extension for ARM32.

## How to use

First alloc chip struct, call sn76496Reset with chip type & struct.
Call sn76496Mixer with length, destination and chip struct.
Produces signed 16bit interleaved stereo.

You can define SN_UPSHIFT to a number, this is how many times the internal
sampling is doubled. You can add "-DSN_UPSHIFT=2" to the "make" file to
make the internal clock speed 4 times higher (this is the default).
You can also define SN_NGP to emulate the sound chip of the NeoGeo Pocket. 

## Projects that use this code

* <https://github.com/FluBBaOfWard/NGPDS>
* <https://github.com/FluBBaOfWard/S8DS>

## Credits

Fredrik Ahlström

<https://bsky.app/profile/therealflubba.bsky.social>

<https://www.github.com/FluBBaOfWard>

X/Twitter @TheRealFluBBa
