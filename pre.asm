.nds
.create "temp\arm9.dec",0

.import "temp\arm9.bin",0,readu32("temp\header.bin",0x2C)

.close