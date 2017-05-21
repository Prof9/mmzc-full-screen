.nds
.open "temp\arm9.bin",0x02004000

.org 0x02004BA0 + 0x14
	.dw filesize("temp\arm9.bin") + 0x02004000

.close

.open "temp\y9.bin",0

.org 1 * 0x20 + 0x1C
	.dw filesize("temp\overlay\overlay_0001.bin") | (1 << 24)
.org 2 * 0x20 + 0x1C
	.dw filesize("temp\overlay\overlay_0002.bin") | (1 << 24)
.org 3 * 0x20 + 0x1C
	.dw filesize("temp\overlay\overlay_0003.bin") | (1 << 24)
.org 4 * 0x20 + 0x1C
	.dw filesize("temp\overlay\overlay_0004.bin") | (1 << 24)

.close