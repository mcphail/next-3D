
			SECTION KERNEL_CODE

    			PUBLIC  _WaitVBlank, _Layer2Enable, _DMACopy, DMACopy, _DMAFill, DMAFill, _ReadKeyboard, _InitKernel
    			PUBLIC  _Keys, _RawKeys, _ReadNextReg

    			EXTERN  _VBlank, _Port123b, _SpriteData, _SpriteShape

    			include "globals.inc"
    			include "ram.inc"


; ******************************************************************************************************************************
;   Init the Kernel
; ******************************************************************************************************************************
_InitKernel:
			RET


; ******************************************************************************************************************************
;   Wait for a Vertical Blank (uses VBlank IRQ)
; ******************************************************************************************************************************
_WaitVBlank:
    			xor a
    			ld  (_VBlank),a

WaitForVBlank:
    			ld  a,(_VBlank)
    			and a
    			jr  z,WaitForVBlank
    			ret


; ************************************************************************
;   Enable the 256 colour Layer 2 bitmap
;
;   In:     L=0  off        (fastcall passes bool as a byte in L)
;           L!=0 on
; ************************************************************************

_Layer2Enable:		ld  a,l
			and a
			jr  z,@Layer2Off
			ld  l,2

@Layer2Off:		ld  a,(_Port123b)
			or  l
			ld  (_Port123b),a
			ld  bc, $123b
			out (c),a     
			ret                          


; ******************************************************************************
; Function: DMACopy
; extern void DMACopy(uint16 src, uint16 dst, uint16 len) __z88dk_callee __preserves_regs(a,d,e,iyl,iyh);
;
; In:       hl = src
;           de = dst
;           bc = len
; ******************************************************************************

_DMACopy:		POP IY 
			POP HL	; Get src
			POP DE	; Get dst
			POP BC	; Get len 
			PUSH IY

DMACopy:		LD (DMACopySrc),HL
    			LD (DMACopyDst),DE
    			LD (DMACopyLen),BC

DoDMACopyInternal:	LD  HL,DMACopyProg                  
    			LD  BC,DMACopyProgL * 256 + Z80DMAPORT 
    			OTIR
			RET

; ******************************************************************************
; Function: DMAFill
; extern void DMAFill(uint16 dest, uint16 len, uint8 value) __z88dk_callee __preserves_regs(a,d,e,iyl,iyh);
;
; In:        a = val
;	    hl = dst
;           bc = len
; ******************************************************************************

_DMAFill:		POP IY 
			POP HL	; Get dst
			POP BC	; Get len 
			POP DE
			LD A,E  ; Get val
			PUSH IY

DMAFill:		LD (DMAFillDst),HL
    			LD (DMAFillLen),BC
			LD (DMAFillVal),A

DMAFillInternal:	LD  HL,DMAFillProg                  
    			LD  BC,DMAFillProgL * 256 + Z80DMAPORT 
    			OTIR
			RET


; ******************************************************************************
; Function: Scan the whole keyboard
; ******************************************************************************

_ReadKeyboard:
		        ld  b,39
		        ld  hl,_Keys
		        xor a
@lp1:   		ld  (hl),a
		        inc hl
		        djnz    @lp1

		        ld  iy,_Keys
		        ld  bc,$fefe            ; Caps,Z,X,C,V
		        ld  hl,_RawKeys
@ReadAllKeys:   
		        in  a,(c)
		        ld  (hl),a
		        inc hl      

		        ld  d,5
		        ld  e,$ff
@DoAll: 
		        srl a
		        jr  c,@notset
		        ld  (iy+0),e
@notset:
		       	inc iy
		       	dec d
		       	jr  nz,@DoAll

		        ld  a,b
		        sla a
		        ret nc
		        or  1
		        ld  b,a
		        jp  @ReadAllKeys
        		ret


; ******************************************************************************
; Function: Read a next register
;           uint16 v = ReadNextReg(uint16 reg)
; ******************************************************************************
_ReadNextReg:
		        pop     de          ; get return address
		        pop     hl
; read MSB of raster first
		        ld      bc,$243b    ; select NEXT register
		        out     (c),l
		        inc     b           ; $253b to access (read or write) value
		        in      l,(c)
		        ld      h,0
		        push    de          ; push return address back
		        ret                 ; return in HL


; ******************************************************************************************************************************
; ******************************************************************************************************************************
; ******************************************************************************************************************************
;       Kernel Data
; ******************************************************************************************************************************
; ******************************************************************************************************************************
; ******************************************************************************************************************************

_Keys:      		DS  40
_RawKeys:   		DS  8

; ******************************************************************************
; Writable DMA Programs
; ******************************************************************************

DMAFillVal:		DB 0		; Storage for the DMA value to fill with

DMAFillProg:		DB $83		; R6-Disable DMA
			DB %01111101	; R0-Transfer mode, A -> B, write address
DMAFillSrc:		DW DMAFillVal	; Address of the fill byte
DMAFillLen:		DW 0		; Number of bytes to fill
			DB %00100100	; R0-Block length, A->B
			DB %00010000	; R1-Port A address incrementing
			DB %10101101	; R4-Continuous mode
DMAFillDst:		DW 0		; Destination address
			DB $CF		; R6-Load	
			DB $B3		; R6-Force Ready
			DB $87		; R6-Enable DMA

			DC DMAFillProgL = ASMPC - DMAFillProg

DMACopyProg:		DB  $C3  	; R6-RESET DMA
			DB  $C7  	; R6-RESET PORT A Timing
        		DB  $CB  	; R6-SET PORT B Timing same as PORT A
        		DB  $7D  	; R0-Transfer mode, A -> B
DMACopySrc:    		DW  $0000	; R0-Port A, Start address      (source address)
DMACopyLen:    		DW  6912 	; R0-Block length               (length in bytes)
            		DB  $54  	; R1-Port A address incrementing, variable timing
            		DB  $02  	; R1-Cycle length port A
            		DB  $50  	; R2-Port B address fixed, variable timing
            		DB  $02  	; R2-Cycle length port B
            		DB  $AD  	; R4-Continuous mode            (use this for block tansfer)
DMACopyDst:   	  	DW  $4000	; R4-Dest address               (destination address)
            		DB  $82  	; R5-Restart on end of block, RDY active LOW
            		DB  $CF  	; R6-Load
            		DB  $B3  	; R6-Force Ready
            		DB  $87  	; R6-Enable DMA

			DC DMACopyProgL = ASMPC - DMACopyProg

_EndKernel:


