.nds
.open "temp\overlay\overlay_0003.bin",0x02064000

//--------------------------
// Full screen intro logos.
//--------------------------
.thumb

.org 0x020C68A6
	bl	ZC_ClearBG3



//---------------------------
// Full screen title screen.
//---------------------------
.thumb

.org 0x020C6FF6
	bl	ZC_ClearBG1



.close