.nds
.open "temp\arm9.dec",0x02004000

//----------------------------------------------------------------------
// Replace screen border functions with some functions that blank VRAM.
// Zero 1 title screen stuff in leftover space.
//----------------------------------------------------------------------
.thumb
.org 0x0202DFB4
	.dw	0x0200E906|1
	.dw	0x0200E906|1
	.dw	0x0200E906|1
	.dw	0x0200E906|1
.org 0x0200E90C
.area 0x158
ZC_ClearBG1:
	ldr	r1,=600C000h
	b	ZC_ClearBG
ZC_ClearBG2:
	ldr	r1,=6002000h
	b	ZC_ClearBG
ZC_ClearBG3:
	ldr	r1,=6001000h
ZC_ClearBG:
	push	r14
	add	r0,=@@vramFill
	ldr	r2,=(800h/2) | (1<<24)
	swi	0Bh

	pop	r15
	.pool

@@vramFill:
	// Blue tiles for Inti Creates intro screen.
	.dh	0x2000,0x2000

Z1_TitleExtendLineIn1:
	mov	r5,0h
	asr	r0,r0,3h
	cmp	r0,14h
	blt	.+4h
	mov	r0,13h
	bx	r14

Z1_TitleExtendLineIn2:
	ldsh	r4,[r6,r3]
	cmp	r4,0A0h
	blt	.+4h
	mov	r4,9Fh
	sub	r4,r4,r0
	bx	r14

Z1_TitleExtendLineIn3:
	ldsh	r3,[r6,r1]
	cmp	r3,0A0h
	blt	.+4h
	mov	r3,9Fh
	mov	r1,7h
	bx	r14
.endarea



//----------------------------------------------------------------
// Expand BG scrolling stride, draw default BG for out-of-bounds.
//----------------------------------------------------------------
.thumb
.org 0x0200C040
.area 0x41C
ZC_ScrollBG:
	push	r4-r7,r14
	add	sp,-30h
	str	r0,[sp]		// store bg data ptr
	str	r1,[sp,4h]	// store cam ptr
	str	r2,[sp,8h]	// store vram ptr

	mov	r7,3h		// scrolledX = true, scrolledY = true
	ldr	r3,[r1,4h]	// r3 = cam.y
	ldr	r1,[r1]		// r1 = cam.x

@@checkX:
	ldr	r6,[r0]		// r6 = data.camX
	lsl	r4,r1,1Bh
	lsr	r4,r4,1Fh	// r4 = cam.x & 0x10
	lsl	r5,r6,1Bh
	lsr	r5,r5,1Fh	// r5 = data.camX & 0x10
	cmp	r4,r5		// if cam.x & 10 != data.camX & 10
	beq	@@checkY
	mov	r4,r1		// r4 = cam.x
	mov	r5,r3		// r5 = cam.y
	sub	r7,1h		// scrolledX = false
	cmp	r1,r6		// if cam.x > data.camX
	ble	@@checkX_left
@@checkX_right:
	add	r4,240
	add	r4,16+32+32	// r4 = cam.x + 256 + 32 (+ 32 subtracted next)
@@checkX_left:
	sub	r4,32		// r4 = cam.x - 32
@@checkX_end:
	sub	r5,16		// r5 = cam.y - 16
	str	r4,[sp,10h]	// store hx
	str	r5,[sp,14h]	// store hy

@@checkY:
	ldr	r6,[r0,4h]	// r6 = data.camY
	lsl	r4,r3,1Bh
	lsr	r4,r4,1Fh	// r4 = cam.y & 0x10
	lsl	r5,r6,1Bh
	lsr	r5,r5,1Fh	// r5 = data.camY & 0x10
	cmp	r4,r5		// if cam.y & 10 != data.camY & 10
	beq	@@updateCam
	mov	r4,r1		// r4 = cam.x
	mov	r5,r3		// r5 = cam.y
	sub	r7,2h		// scrolledY = false
	cmp	r3,r6		// if cam.y > data.camY
	ble	@@checkY_up
@@checkY_down:
	add	r5,192+16+16	// r5 = cam.y + 192 + 16 (+ 16 subtracted next)
@@checkY_up:
	sub	r5,16		// r5 = cam.y - 16
@@checkY_end:
	sub	r4,32		// r4 = cam.x - 32
	str	r4,[sp,18h]	// store vx
	str	r5,[sp,1Ch]	// store vy

@@updateCam:
	str	r1,[r0]		// data.camX = cam.x
	str	r3,[r0,4h]	// data.camY = cam.y
	lsl	r1,r1,17h
	lsr	r1,r1,17h
	lsl	r3,r3,17h
	lsr	r3,r3,17h
	strh	r1,[r0,8h]	// store cam.x & 0x1FF
	strh	r3,[r0,0Ah]	// store cam.y & 0x1FF

	ldr	r4,[r0,14h]
	ldrb	r1,[r4,1h]	// r1 = default screen
	str	r1,[sp,24h]
	ldrb	r5,[r4,3h]	// r5 = data.screensHeight
	mov	r1,160
	mul	r1,r5		// r1 = max camera y
	str	r1,[sp,2Ch]
	ldrb	r5,[r4]		// r5 = data.screensWidth
	mov	r1,240
	mul	r1,r5		// r1 = max camera x
	str	r1,[sp,28h]
	add	r4,4h		// r4 = data.screens

@@scrollH:
	str	r7,[sp,0Ch]	// store scrolledX, scrolledY
	lsr	r7,r7,1h	// shift scrolledX into carry
	bcs	@@scrollV
	// r0 = data ptr here
	// r4 = data.bgData.bgs here
	// r5 = data.bgData.width here

	mov	r1,15		// 160->192 so 13->15
	str	r1,[sp,20h]	// store i

	// calc hx / 240, (hx % 240) / 16
	ldr	r0,[sp,10h]
	mov	r1,240
	blx	2023ED4h	// hx / 240
	asr	r6,r1,4h	// r6 = (hx % 240) / 16 = tx
	add	r4,r4,r0	// r4 += hx / 240

	// calc hy / 160, (hy % 160) / 16
	ldr	r0,[sp,14h]
	mov	r1,160
	blx	2023ED4h	// hy / 160
	asr	r7,r1,4h	// r7 = (hy % 160) / 16 = ty
	mul	r0,r5		// r0 = data.screensWidth * (hy / 160)
	add	r4,r4,r0	// r4 += data.screensWidth * (hy / 160)

@@scrollH_screen:
	// check if hx < 0
	ldr	r0,[sp,10h]
	cmp	r0,0h
	blt	@@scrollH_outOfBounds
	// check if hx > max_hx
	ldr	r1,[sp,28h]
	cmp	r0,r1
	bge	@@scrollH_outOfBounds
	// check if hy < 0
	ldr	r0,[sp,14h]
	cmp	r0,0h
	blt	@@scrollH_outOfBounds
	// check if hy > max_hy
	ldr	r1,[sp,2Ch]
	cmp	r0,r1
	bge	@@scrollH_outOfBounds

	ldrb	r0,[r4]		// r0 = screen
	b	@@scrollH_addScreen

@@scrollH_outOfBounds:
	ldr	r0,[sp,24h]	// r0 = default screen

@@scrollH_addScreen:
	mov	r1,150		// r1 = 150
	mul	r0,r1		// r0 = screen * 150
	mov	r1,15		// r1 = 15
	mov	r2,r7
	bpl	@@scrollH_addTY
@@scrollH_offsetTY:
	add	r2,10
//	bmi	@@scrollH_offsetTY
@@scrollH_addTY:
	mul	r2,r1		// r2 = ty * 15
	add	r0,r0,r2	// r0 = screen' + hy'
	mov	r2,r6
	bpl	@@scrollH_addTX
@@scrollH_offsetTX:
	add	r2,15
//	bmi	@@scrollH_offsetTX
@@scrollH_addTX:
	add	r0,r0,r2	// r0 = screen' + hy' + hx'
	lsl	r0,r0,1h
	ldr	r1,[sp]		// r1 = data
	ldr	r1,[r1,10h]	// r1 = block array ptr
	add	r5,r1,r0	// r5 = block ptr

@@scrollH_block:
	// load tile pointer
	ldrh	r0,[r5]		// r0 = block
	lsl	r0,r0,3h	// r0 = block * 8
	ldr	r1,[sp]		// r1 = data
	ldr	r1,[r1,0Ch]	// r1 = tile array ptr
	add	r1,r0,r1	// r1 = tile ptr
	ldr	r2,[r1]		// load tileAB
	ldr	r3,[r1,4h]	// load tileCD

@@scrollH_writeTile:
	// calc vram ptr
	ldr	r0,[sp,10h]	// r0 = hx
	lsl	r1,r0,17h
	lsr	r1,r1,1Fh
	lsl	r1,r1,0Bh	// r1 = ((hx & 0x100) >> 8) * 0x800
	lsr	r0,r0,4h
	lsl	r0,r0,1Ch
	lsr	r0,r0,1Ah	// r0 = ((hx & 0xFF) / 16) * 0x4
	add	r0,r0,r1	// r0 = hx'
	ldr	r1,[sp,14h]	// r1 = hy
	lsr	r1,r1,4h
	lsl	r1,r1,1Ch
	lsr	r1,r1,15h	// r1 = ((hy & 0xFF) / 16) * 0x80
	add	r0,r0,r1	// r0 = hx' + hy'
	ldr	r1,[sp,8h]
	add	r0,r0,r1	// r0 = vram ptr
	str	r2,[r0]		// store tileAB
	str	r3,[r0,40h]	// store tileCD

	// decrement i
	ldr	r0,[sp,20h]
	sub	r0,1h
	str	r0,[sp,20h]
	bmi	@@scrollV

	// increment block ptr
	add	r5,15*2		// move to block on next row

	// increment hy
	ldr	r0,[sp,14h]
	add	r0,16		// hy += 16
	str	r0,[sp,14h]

	// increment ty
	add	r7,1h
	beq	@@scrollH_screen
	cmp	r7,10
	blt	@@scrollH_block

@@scrollH_nextScreen:
	// move to next screen
	mov	r7,0h		// reset ty to 0
	ldr	r0,[sp]
	ldr	r0,[r0,14h]
	ldrb	r0,[r0]		// r0 = bg width
	add	r4,r4,r0	// move to screen on next row
	b	@@scrollH_screen

@@scrollV:
	ldr	r7,[sp,0Ch]	// load scrolledX, scrolledY
	lsr	r7,r7,2h	// shift scrolledY into carry
	bcs	@@end

	ldr	r0,[sp]
	ldr	r4,[r0,14h]
	ldrb	r5,[r4]
	add	r4,4h

	mov	r1,21		// 240->256 so 20->21
	str	r1,[sp,20h]	// store i

	// calc vx / 240, (vx % 240) / 16
	ldr	r0,[sp,18h]
	mov	r1,240
	blx	2023ED4h	// vx / 240
	asr	r6,r1,4h	// r6 = (vx % 240) / 16 = tx
	add	r4,r4,r0	// r4 += vx / 240

	// calc vy / 160, (vy % 160) / 16
	ldr	r0,[sp,1Ch]
	mov	r1,160
	blx	2023ED4h	// vy / 160
	asr	r7,r1,4h	// r7 = (vy % 160) / 16 = ty
	mul	r0,r5		// r0 = data.screensWidth * (vy / 160)
	add	r4,r4,r0	// r4 += data.screensWidth * (vy / 160)

@@scrollV_screen:
	// check if vx < 0
	ldr	r0,[sp,18h]
	cmp	r0,0h
	blt	@@scrollV_outOfBounds
	// check if vx > max_vx
	ldr	r1,[sp,28h]
	cmp	r0,r1
	bge	@@scrollV_outOfBounds
	// check if vy < 0
	ldr	r0,[sp,1Ch]
	cmp	r0,0h
	blt	@@scrollV_outOfBounds
	// check if vy > max_vy
	ldr	r1,[sp,2Ch]
	cmp	r0,r1
	bge	@@scrollV_outOfBounds

	ldrb	r0,[r4]		// r0 = screen
	b	@@scrollV_addScreen

@@scrollV_outOfBounds:
	ldr	r0,[sp,24h]	// r0 = default screen

@@scrollV_addScreen:
	mov	r1,150		// r1 = 150
	mul	r0,r1		// r0 = screen * 150
	mov	r1,15		// r1 = 15
	mov	r2,r7
	bpl	@@scrollV_addTY
@@scrollV_offsetTY:
	add	r2,10
//	bmi	@@scrollV_offsetTY
@@scrollV_addTY:
	mul	r2,r1		// r2 = ty * 15
	add	r0,r0,r2	// r0 = screen' + vy'
	mov	r2,r6
	bpl	@@scrollV_addTX
@@scrollV_offsetTX:
	add	r2,15
//	bmi	@@scrollV_offsetTX
@@scrollV_addTX:
	add	r0,r0,r2	// r0 = screen' + vy' + vx'
	lsl	r0,r0,1h
	ldr	r1,[sp]		// r1 = data
	ldr	r1,[r1,10h]	// r1 = block array ptr
	add	r5,r1,r0	// r5 = block ptr

@@scrollV_block:
	// load tile pointer
	ldrh	r0,[r5]		// r0 = block
	lsl	r0,r0,3h	// r0 = block * 8
	ldr	r1,[sp]		// r1 = data
	ldr	r1,[r1,0Ch]	// r1 = tile array ptr
	add	r1,r0,r1	// r1 = tile ptr
	ldr	r2,[r1]		// load tileAB
	ldr	r3,[r1,4h]	// load tileCD

@@scrollV_writeTile:
	// calc vram ptr
	ldr	r0,[sp,18h]	// r0 = vx
	lsl	r1,r0,17h
	lsr	r1,r1,1Fh
	lsl	r1,r1,0Bh	// r1 = ((vx & 0x100) >> 8) * 0x800
	lsr	r0,r0,4h
	lsl	r0,r0,1Ch
	lsr	r0,r0,1Ah	// r0 = ((vx & 0xFF) / 16) * 0x4
	add	r0,r0,r1	// r0 = vx'
	ldr	r1,[sp,1Ch]	// r1 = vy
	lsr	r1,r1,4h
	lsl	r1,r1,1Ch
	lsr	r1,r1,15h	// r1 = ((vy & 0xFF) / 16) * 0x80
	add	r0,r0,r1	// r0 = vx' + vy'
	ldr	r1,[sp,8h]
	add	r0,r0,r1	// r0 = vram ptr
	str	r2,[r0]		// store tileAB
	str	r3,[r0,40h]	// store tileCD

	// decrement i
	ldr	r0,[sp,20h]
	sub	r0,1h
	str	r0,[sp,20h]
	bmi	@@end

	// increment block ptr
	add	r5,1*2		// move to block on next column

	// increment vx
	ldr	r0,[sp,18h]
	add	r0,16		// vx += 16
	str	r0,[sp,18h]

	// increment tx
	add	r6,1h
	beq	@@scrollV_screen
	cmp	r6,15
	blt	@@scrollV_block

@@scrollV_nextScreen:
	// move to next screen
	mov	r6,0h		// reset tx to 0
	add	r4,1h		// move to screen on next column
	b	@@scrollV_screen

@@end:
	add	sp,30h
	pop	r4-r7,r15

	.pool
.endarea



// TODO: find out what this is
.org 0x0200C544
	cmp	r0,0Fh
.org 0x0200C556
	cmp	r0,0Fh
.org 0x0200C580
	cmp	r3,15h
.org 0x0200C58E
	cmp	r3,15h
.org 0x0200C980		// probably level v-scroll stuff
	cmp	r2,0Fh
.org 0x0200C9DE
	cmp	r5,12h



//---------------------------------------------------
// Mask out-of-bounds level tiles on screen reloads.
//---------------------------------------------------
ZC_ReloadLevel:
.org 0x0200C6F4
.area 0xCC
	push	r4-r7,r14
	add	sp,-0Ch

	ldr	r4,[r1]		// r4 = camX
	ldr	r5,[r1,4h]	// r5 = camY
	str	r4,[r0]
	str	r5,[r0,4h]

	lsl	r6,r4,17h
	lsr	r6,r6,17h
	lsl	r7,r5,17h
	lsr	r7,r7,17h
	strh	r6,[r0,8h]
	strh	r7,[r0,0Ah]

	asr	r4,r4,4h
	asr	r5,r5,4h
	mov	r12,r4
	mov	r14,r5

	ldr	r0,[r0,0Ch]
	str	r0,[sp]		// sp+00 = [r0,0Ch]
	ldr	r1,[r3]
	str	r1,[sp,4h]	// sp+04 = mapWidth
	str	r2,[sp,8h]	// sp+08 = r2
	add	r3,4h

	mov	r7,0Ch		// r7 = i
@@loop_i:
	mov	r6,10h		// r6 = j
@@loop_j:
	mov	r0,r12
	mov	r1,r14
	add	r1,r1,r7	// r1 = ty
	bmi	@@hide		// if (ty < 0)
	add	r0,r0,r6	// r0 = tx
	bmi	@@hide2		// if (tx < 0)

	ldr	r2,[sp,4h]
	cmp	r0,r2
	bge	@@hide2		// if (tx >= mapWidth)

	mul	r2,r1
	add	r2,r2,r0	// r2 = mapWidth * ty + tx

	ldr	r5,=ZC_MaxMapSizes
	ldr	r4,=2040524h
	ldrb	r4,[r4,1h]
	sub	r4,1h		// r4 = current game
	lsl	r4,r4,1h
	ldrh	r4,[r5,r4]
	lsl	r4,r4,2h	// r4 = max map size
	cmp	r2,r4
	bge	@@hide2		// if (mapWidth * ty + tx >= maxMapSize)

	lsl	r2,r2,1h
	ldrh	r2,[r3,r2]	// r2 = block
	lsl	r2,r2,3h
	ldr	r4,[sp]
	add	r2,r2,r4
	ldr	r4,[r2]		// r4 = tileAB
	ldr	r5,[r2,4h]	// r5 = tileCD
	b	@@write

@@hide:
	add	r0,r0,r6	// r0 = tx
@@hide2:
	mov	r4,0h		// r4 = tileAB
	mov	r5,0h		// r5 = tileCD

@@write:
	lsl	r2,r0,1Bh
	lsr	r2,r2,1Fh
	lsl	r2,r2,0Bh
	lsl	r0,r0,1Ch
	lsr	r0,r0,1Ah
	lsl	r1,r1,1Ch
	lsr	r1,r1,15h
	add	r0,r0,r1
	add	r0,r0,r2
	ldr	r1,[sp,8h]
	add	r0,r0,r1
	str	r4,[r0]
	str	r5,[r0,40h]

	sub	r6,1h
	bpl	@@loop_j
	sub	r7,1h
	bpl	@@loop_i

	add	sp,0Ch
	pop	r4-r7,r15

	.pool

ZC_MaxMapSizes:
	// Multiply by 4 to get actual value.
	// Fits in 16-bit values this way.
	.dh	57604 / 4	// Zero 1
	.dh	89104 / 4	// Zero 2
	.dh	89104 / 4	// Zero 3
	.dh	89104 / 4	// Zero 4
.endarea

.close