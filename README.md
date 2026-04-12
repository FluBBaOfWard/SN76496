# SN76496 V1.6.8

SN76496/SN76489, NCR8496 & SMS/GG/MD sound chip emulator for ARM32.

First alloc chip struct, call sn76496Reset with chip type & struct.
Call sn76496Mixer with length, destination and chip struct.
Produces signed 16bit mono.

You define SN_UPSHIFT to a number, this is how many times the internal
sampling is doubled. You can add "-DSN_UPSHIFT=2" to the "make" file to
make the internal clock speed 4 times higher.

## Projects that use this code

* <https://github.com/FluBBaOfWard/K80DS>
* <https://github.com/wavemotion-dave/ColecoDS>
* <https://github.com/wavemotion-dave/DS994a>

## Credits

Fredrik Ahlström

<https://bsky.app/profile/therealflubba.bsky.social>

<https://www.github.com/FluBBaOfWard>

X/Twitter @TheRealFluBBa
