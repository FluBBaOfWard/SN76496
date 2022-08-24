This is highly specialised for the GBA but can probably be tweaked
quite easily to support other platforms as well.

First call SN76496SetMixrate with 0 or 1 for low or high quality.
Then call SN76496SetFrequency with the actual clock rate of the chip.
Finally call SN76496Init to set it up.

