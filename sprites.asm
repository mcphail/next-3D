;
; Title:	Sprite Helper Functions
; Author:	Dean Belfield
; Created:	20/08/2025
; Last Updated:	22/09/2025
;
; Modinfo:
;

    			SECTION KERNEL_CODE

    			INCLUDE "globals.inc"

; extern void spriteInit(uint8_t pattern, uint8_t * data) __z88dk_callee;

PUBLIC _spriteInit, spriteInit

_spriteInit:		POP	BC          		; Loads the stack value (sp) into bc for restoring later and moves variables into top of stack
    			DEC	SP
    			POP	AF          		; The sprite number
			POP	HL			; Address of the data
    			PUSH	BC         		; Restores the stack value from bc

;  A: Sprite to initialise
; HL: Address of sprite data
;
spriteInit:		NEXTREG 0x34, A			; Select Sprite A
			LD 	B, 0			; Write out the 256 byte pattern data
@L1:			LD	A, (HL)
			INC 	HL
			OUT	(0x5B), A
			DJNZ	@L1
			RET


; extern void spriteDraw(uint8_t sprite, uint8_t pattern, uint16_t x, uint16_t y) __z88dk_callee;

PUBLIC _spriteDraw, spriteDraw	

_spriteDraw:		POP	IY
			POP	HL		; H: Pattern, L: Sprite
			POP	BC		; BC: X
			POP	DE		; DE: Y
			PUSH	IY

; BC: X coordinate
; DE: Y coordinate
;  H: Sprite pattern (set bit 7 to draw)
;  L: Sprite number
;
spriteDraw:		LD A,L
			NEXTREG 0x34, A
			LD A,H			
			NEXTREG 0x38, A
			LD HL,0x18
			ADD HL,BC
			LD A,L: NEXTREG 0x35, A
			LD A,H
			AND 0x01
			NEXTREG 0x37, A
			LD HL,0x18
			ADD HL,DE
			LD A,L: NEXTREG 0x36, A
			RET
