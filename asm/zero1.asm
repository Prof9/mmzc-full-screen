.nds
.open "temp\overlay\overlay_0001.bin",0x02064000

//----------------------------------
// Camera push-back at edge of map.
//----------------------------------
.thumb
.org 0x02065564



//--------------------------
// Full screen intro logos.
//--------------------------
.thumb
.org 0x020C9816
	bl	ZC_ClearBG3



//---------------------------
// Full screen title screen.
//---------------------------
.thumb
// Full width buffer tiles.
.org 0x020CA2FA
	cmp	r2,20h

// Full width bottom (empty) tiles.
.org 0x020CA32A
	cmp	r2,20h

// Extend lines-in effect by 16 frames.
// Alternative: C0 -> B0 for CA4EA, CA4EE
.org 0x020CA3DA
	cmp	r0,0B0h
.org 0x020CA3E4
	mov	r0,0AFh
.org 0x020CA414
	bl	Z1_TitleExtendLineIn1
.org 0x020CA4F2
	bl	Z1_TitleExtendLineIn3

// Reduce Z-in effect by 16 frames.
.org 0x020CA6A2
	b	20CA6ACh
.org 0x020CA706
	cmp	r0,10h
.org 0x020CA70A
	sub	r0,10h
.org 0x020CA754
	cmp	r0,30h

// Full height scanlines for lines-in.
.org 0x020CA4C8
	add	r2,10h
	cmp	r2,0C0h
	ble	.+4
	mov	r2,0C0h
	mov	r0,0h
	cmp	r2,0h
	ble	20CA4E8h
	mov	r1,r7
	mov	r3,8h
//	ldsh	r4,[r6,r3]
//	sub	r4,r4,r0
	bl	Z1_TitleExtendLineIn2
	strh	r4,[r1]
.org 0x020CA4EA
	cmp	r2,0C0h
.org 0x020CA4EE
	mov	r2,0C0h
.org 0x020CA50C
	nop
	strh	r5,[r1]
.org 0x020CA51A
	cmp	r2,0C0h
.org 0x020CA51E
	mov	r1,0C0h
.org 0x020CA538
	nop
	strh	r1,[r5]
.org 0x020CA548
	cmp	r0,0C0h
.org 0x020CA554
	nop
	strh	r1,[r4]
.org 0x020CA55C
	cmp	r0,0C0h

// Full height scanlines for Z-in.
.org 0x020CA5C2
	mov	r0,34h
.org 0x020CA5C6
	strh	r1,[r2]
.org 0x020CA5CC
	cmp	r3,0C0h
.org 0x020CA62C
	cmp	r0,16h
.org 0x020CA6BC
	mov	r1,44h
	add	r0,88h
.org 0x020CA6C0
	asr	r5,r3,8h
	bpl	.+4h
	mov	r5,0h
	sub	r5,r5,r1
	strh	r5,[r0]
	sub	r3,r3,r2
	sub	r0,r0,2h
	sub	r1,r1,1h
	bpl	.-10h
	mov	r3,0Dh
	mov	r0,r4
	lsl	r3,r3,0Ah
	mov	r1,44h
	add	r0,88h
	lsr	r5,r3,8h
	sub	r5,r5,r1
	strh	r5,[r0]
.org 0x020CA6E8
	cmp	r1,0C0h
	blt	.-0Eh



.close