# SN76496
SN76496/SN76489, NCR8496 & SMS/GG/MD sound chip emulator for ARM32.

First alloc chip struct, call init with chip type.
Call SN76496Mixer with chip struct, length and destination.
Produces 16bit signed mono.
