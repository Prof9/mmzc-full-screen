.nds
.open "temp\overlay\overlay_0001.bin",0x02064000

//----------------------------------
// Camera push-back at edge of map.
//----------------------------------
.thumb
.org 0x02065564
.area 0xC8	// holy geez this is a tight fit
	push	r0-r1,r4-r7,r14

	add	r6,=@@offsets

	ldmia	[r0]!,r0,r5		// r0 = x, r5 = y
	ldrh	r1,[r6,@@vals - @@offsets + 0]
	blx	2023ED4h
	mov	r4,r1			// r4 = x % 120.0
	mov	r0,r5			// r0 = y
	ldrh	r1,[r6,@@vals - @@offsets + 2]
	blx	2023ED4h
	mov	r5,r1			// r5 = x %  80.0
	pop	r0-r1

	bl	@@checkRoom		// get base room
	add	r7,r2,1h		// r7 = base room

@@checkH:
	mov	r3,0h			// init camera x offset
@@checkLeft:
	bl	@@checkRoom		// 2nd call
	beq	@@checkRight
	ldrh	r2,[r6,@@vals - @@offsets + 0 - 2*2]
	sub	r3,r2,r4		// r3 += 120.0 - x % 120
@@checkRight:
	bl	@@checkRoom		// 3rd call
	beq	@@checkV
	sub	r3,r3,r4		// r3 -= x % 120.0

@@checkV:
	mov	r4,0h			// init camera y offset
@@checkUp:
	bl	@@checkRoom		// 4th call
	beq	@@checkDown
	ldrh	r2,[r6,@@vals - @@offsets + 2 - 2*4]
	sub	r4,r2,r5		// r4 += 80 - y % 80
@@checkDown:
	bl	@@checkRoom		// 5th call
	beq	@@checkExtra
	sub	r4,r4,r5		// r4 -= y % 80
@@checkExtra:
	bl	@@checkRoom		// 6th call
	bne	@@end
@@checkExtra1:
	bl	@@checkRoom		// 7th call
	beq	@@checkExtra2
	
	mov	r2,16
	lsl	r2,r2,8h
	sub	r4,r4,r2		// r4 -= 16
	b	@@end
@@checkExtra2:
	bl	@@checkRoom		// 8th call
	beq	@@end
	mov	r2,64
	lsl	r2,r2,8h
	sub	r2,r5,r2
	sub	r4,r4,r2		// r4 -= y % 80 - 64

@@end:
	stmia	[r1]!,r3,r4
	pop	r4-r7,r15

@@checkRoom:
	// in:
	//	r0 = zeroPos
	//	r6 = offsets
	//	r7 = base room
	// out:
	//	
	//	r2 = room number
	//	r6 = offsets
	push	r0-r1,r3-r5,r7,r14
	ldmia	[r0]!,r0,r1		// r0 = player.x, r1 = player.y
	mov	r2,0h
	ldsb	r2,[r6,r2]
	mov	r3,1h
	ldsb	r3,[r6,r3]
	add	r6,2h			// increment offsets
	lsl	r2,r2,3+8		// r2 = x offset
	lsl	r3,r3,3+8		// r3 = y offset
	add	r0,r0,r2
	add	r1,r1,r3
	bl	2065A2Ch
	mov	r2,r0
	sub	r0,r7,r0
	bmi	@@checkRoom_end
	cmp	r0,2h
	bgt	@@checkRoom_end
	mov	r0,0h
@@checkRoom_end:
	pop	r0-r1,r3-r5,r7,r15

.align 4
@@offsets:
	.db	   0 >> 3,    0 >> 3	// 1st call
	.db	-120 >> 3,    0 >> 3	// 2nd call
	.db	 120 >> 3,    0 >> 3	// 3rd call
	.db	   0 >> 3,  -80 >> 3	// 4th call
	.db	   0 >> 3,   80 >> 3	// 5th call
	.db	   0 >> 3, -192 >> 3	// 6th call
	.db	   0 >> 3,   80 >> 3	// 7th call
	.db	   0 >> 3,   96 >> 3	// 8th call
@@vals:
	.dh	 120 << 8,   80 << 8
.endarea



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