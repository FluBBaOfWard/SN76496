# SN76496 V1.6.1
SN76496/SN76489, SMS sound chip plus GG stereo extension for ARM32.

First alloc chip struct, call sn76496Reset with chip type & struct.
Call SN76496Mixer with length, destination and chip struct.
Produces signed 16bit interleaved stereo.
