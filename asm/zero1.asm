.nds
.open "temp\overlay\overlay_0001.bin",0x02064000

//----------------------------------
// Camera push-back at edge of map.
//----------------------------------
Z1_CameraPushBack:
.thumb
.org 0x02065564
.area 0xC8	// holy geez this is a tight fit...
@@main:
	push	r0-r1,r4-r7,r14

	mov	r2,9*4
	add	r6,=@@values

	bl	@@checkRoom
	add	r7,r3,1h		// r7 = base room

	ldmia	[r0]!,r0,r5		// r0 = x, r5 = y
	mov	r1,120
	lsl	r1,r1,8h
	blx	2023ED4h
	mov	r4,r1			// r4 = x % 120.0
	mov	r0,r5			// r0 = y
	mov	r1,80
	lsl	r1,r1,8h
	blx	2023ED4h
	mov	r2,r1			// r2 = y %  80.0
	pop	r0-r1

	mov	r3,2-1
@@main_loop:
	mov	r5,0h
	bl	@@direction
	bl	@@direction
	stmia	[r1]!,r5
	mov	r4,r2
	sub	r3,1h
	bpl	@@main_loop

	pop	r4-r7,r15

.align 4
@@values:
	// push camera right
	.db	-120 >> 3,    0 >> 3			// room to   left
	.db	 256 >> 3,    0 >> 3			// room to  right
	.db	-128 >> 3,    0 >> 3			// room to   left
	.db	 120 >> 3,    8 >> 3,    8 >> 3		// LHS
	// push camera left
	.db	 120 >> 3,    0 >> 3			// room to  right
	.db	-256 >> 3,    0 >> 3			// room to   left
	.db	 128 >> 3,    0 >> 3			// room to  right
	.db	   0 >> 3,   -8 >> 3,  112 >> 3		// LHS
	// push camera down
	.db	   0 >> 3,  -80 >> 3			// room to    top
	.db	   0 >> 3,  192 >> 3			// room to bottom
	.db	   0 >> 3,  -96 >> 3			// room to    top
	.db	  80 >> 3,   16 >> 3,   16 >> 3		// LHS
	// push camera up
	.db	   0 >> 3,   80 >> 3			// room to bottom
	.db	   0 >> 3, -192 >> 3			// room to    top
	.db	   0 >> 3,   96 >> 3			// room to bottom
	.db	   0 >> 3,  -16 >> 3,   64 >> 3		// LHS
	// get base room
	.db	   0 >> 0,    0 >> 3			// current room

@@direction:
	// in:
	//	r0 = ptr to camera base position
	//	r4 = RHS
	//	r5 = camera position modifier
	//	r6 = values ptr
	//	r7 = base room
	// out:
	//	r5 = camera position modifier
	//	r6 = incremented offsets
	push	r2-r3,r14

@@direction_standard:
	mov	r2,0h
	bl	@@checkRoom
	beq	@@direction_extra
	mov	r2,6h
	ldsb	r2,[r6,r2]
	lsl	r2,r2,3+8
	sub	r2,r2,r4
	add	r5,r5,r2

@@direction_extra:
	mov	r2,2h
	bl	@@checkRoom
	bne	@@direction_end
@@direction_full:
	// r2 = 0 when CheckRoom returns false
	bl	@@checkRoom
	beq	@@direction_partial
	mov	r2,7h
	ldsb	r2,[r6,r2]
	lsl	r2,r2,3+8
	add	r5,r5,r2
	b	@@direction_end
@@direction_partial:
	mov	r2,4h
	bl	@@checkRoom
	beq	@@direction_end
	mov	r2,8h
	ldsb	r2,[r6,r2]
	lsl	r2,r2,3+8
	sub	r2,r2,r4
	add	r5,r5,r2

@@direction_end:
	add	r6,9h
	pop	r2-r3,r15

@@checkRoom:
	// in:
	//	r0 = ptr to camera base position
	//	r2 = values offset
	//	r6 = values base ptr
	//	r7 = base room
	// out:
	//	z  = same room as base room
	//	r2 = 0 if not same room as base room
	//	r3 = room number
	push	r0-r1,r14
	ldmia	[r0]!,r0,r1		// r0 = base x, r1 = base y
	add	r3,r2,1h
	ldsb	r2,[r6,r2]
	ldsb	r3,[r6,r3]
	lsl	r2,r2,3+8		// r2 = x offset
	lsl	r3,r3,3+8		// r3 = y offset
	add	r0,r0,r2
	add	r1,r1,r3
	bl	2065A2Ch
	mov	r3,r0
	sub	r0,r7,r0
	bmi	@@checkRoom_end
	cmp	r0,2h
	bgt	@@checkRoom_end
	mov	r2,0h
@@checkRoom_end:
	pop	r0-r1,r15
.endarea	// ...but we made it work somehow

// Some world block/room number changes to fix some camera scrolling issues.
// Resistance Base, empty block above Rank A+ hallway
.org 0x020DC600 +     8*128 + 46
	.db	0x19		// World block
.org 0x020E8F80 + 4 + 2* 16 +  8
	.db	0x08		// Room number
// Resistance Base, elevator left to room with door leading to Trans Server
.org 0x020E8F80 + 4 + 3* 16 +  5
	.db	0x01		// Room number
// Disposal Center boss gate (might also be able to fix in the level blocks)
//.org 0x020DC600 +   + 4*96 + 70
//	.db	0x21		// World block
//.org 0x020E0CD4 + 4 + 1*64 + 37
//	.db	0x01		// Room number
//.org 0x020E0CD4 + 4 + 1*64 + 38
//	.db	0x02		// Room number
//.org 0x020E0CD4 + 4 + 2*64 + 37
//	.db	0x00		// Room number
//.org 0x020E0CD4 + 4 + 2*64 + 38
//	.db	0x02		// Room number
//.org 0x020E0A4C + 4 + 2*64 + 37
//	.db	0x03		// Room number
//.org 0x020E0B90 + 4 + 1*64 + 38
//	.db	0x02		// Room number
//.org 0x020E0B90 + 4 + 2*64 + 37
//	.db	0x00		// Room number



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



//----------------------------------------
// Move Zero's HP bar up and to the left.
//----------------------------------------
.thumb
.org 0x020C864C
Z1_ZeroHpBar:
.area 0x294
	push	r4-r7,r14

	ldr	r1,[r0]			// r1 = tmap
	ldr	r0,[r0,4h]		// r0 = data
	add	r0,9Ch			// r0 = data+9Ch
	cmp	r0,0h
	beq	@@end

	ldr	r2,=2035918h+4h
	ldr	r2,[r2]
	ldrb	r3,[r2,1h]
	mov	r4,1h
	orr	r3,r4
	strb	r3,[r2,1h]

	mov	r2,9			// r2 = y-origin of HP bar (default 10)
	lsl	r2,r2,6h		// r2 = tmap origin offset
	add	r1,r1,r2		// r1 = tmap ptr
	mov	r2,r1			// r2 = tmap ptr

@@zeroEmblem:
	ldr	r3,=0x120B|(0x120C<<16)
	str	r3,[r2]
	ldr	r3,=0x122B|(0x122C<<16)
	str	r3,[r2,40h]
	add	r2,80h

@@weapons:
	mov	r3,0FFh
	add	r3,r0,r3
	ldrb	r3,[r3,(1A9h-9Ch-0FFh)]	// r3 = elem
	lsl	r4,r3,1Fh
	lsr	r5,r4,1Ch		// r5 = (elem & 1) * 0x8
	lsr	r3,r3,2h		// c = (elem & 2) ? 1 : 0
	bcc	@@weapons_check
	add	r5,30h			// r5 = (elem&1)*0x8+(elem&2)*0x30
@@weapons_check:
	mov	r3,(196h-9Ch)
	add	r3,r0,r3
	ldrb	r4,[r3,1h]		// r4 =  subWpn
	ldrb	r3,[r3]			// r3 = mainWpn
	lsl	r3,r3,1h		// r3 = mainWpn'
	lsl	r4,r4,1h		// r4 = mainWpn'
	add	r3,r3,r5		// r3 + mainWpn' + elem'
	add	r4,r4,r5		// r4 =  subWpn' + elem'

	// Top half of main weapon
	ldr	r5,=12011200h
	add	r5,0Dh
	add	r3,r3,r5		// r3 = 120Dh + mainWpn' + elem'
	add	r4,r4,r5		// r4 = 120Dh +  subWpn' + elem'
	strh	r3,[r2]
	add	r5,r3,1h
	strh	r5,[r2,2h]
	add	r2,40h

	cmp	r3,r4			// still works despite the additions
	bne	@@weapons_two
@@weapons_one:
	// Bottom half of main weapon
	add	r3,20h
	strh	r3,[r2]
	add	r3,1h
	strh	r3,[r2,2h]
	b	@@hp

@@weapons_two:
	// Bottom half of main weapon
	add	r3,40h
	strh	r3,[r2]
	add	r5,r3,1h
	strh	r5,[r2,2h]
	add	r2,40h

	// Top half of sub weapon
	strh	r4,[r2]
	add	r5,r4,1h
	strh	r5,[r2,2h]
	add	r2,40h

	// Bottom half of sub weapon
	add	r4,20h
	strh	r4,[r2]
	add	r5,r4,1h
	strh	r5,[r2,2h]

@@hp:
	ldrb	r2,[r0]			// r2 = curHp
	mov	r3,(18Fh-9Ch)
	ldrb	r3,[r0,r3]		// r3 = barHp
	ldr	r4,=12011200h		// r4 = first HP bar base tile
	cmp	r2,r3
	ble	@@hp_start
@@hp_second:
	add	r4,2h			// r4 = second HP bar base tile
	sub	r2,r2,r3		// r2 = curHp - barHp
@@hp_start:
	mov	r5,0h			// r5 = i
	lsl	r6,r2,1Eh
	lsr	r6,r6,19h		// r6 = partial HP tile offset
@@hp_loop:
	sub	r1,40h			// go to previous row
	add	r7,r5,4h		// r7 = i + 4
	cmp	r7,r2			// compare i+4 to curHp(-barHp)
	bgt	@@hp_notfull
@@hp_full:
	mov	r7,20h
	b	@@hp_next
@@hp_notfull:
	mov	r7,0A0h
	cmp	r5,r2
	bgt	@@hp_next
@@hp_partial:
	sub	r7,r7,r6
@@hp_next:
	add	r7,r4,r7		// add base tile
	strh	r7,[r1]			// store HP tiles
	add	r7,1h
	strh	r7,[r1,2h]

	add	r5,4h			// i += 4
	cmp	r5,r3
	blt	@@hp_loop

@@hp_top:
	sub	r1,40h
	ldr	r2,=12011200h
	str	r2,[r1]
@@rank:
	add	r2,2Ah
	strh	r2,[r1,4h]
	add	r1,40h
	mov	r3,(184h-9Ch)
	ldrb	r3,[r0,r3]
	sub	r3,26h
	add	r3,r3,r2
	strh	r3,[r1,4h]
	add	r1,40h
	add	r2,20h
	strh	r2,[r1,4h]

@@end:
	pop	r4-r7,r15

	.pool
.endarea

.org 0x020CF60C
	// Move HP bars up a bit.
//	.dw	(-11) & 0xFFFF		// from -16



.close