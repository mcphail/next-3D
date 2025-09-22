			SECTION KERNEL_CODE

    			PUBLIC  _waitVBlank, _enableL2, _DMACopy, DMACopy, _DMAFill, DMAFill, _readKeyboard, _initKernel
			PUBLIC  _readNextReg, _setCPU, _stop
    			PUBLIC  _Keys, _RawKeys

    			EXTERN  _VBlank, _Port123b

    			include "globals.inc"
    			include "ram.inc"

; ******************************************************************************************************************************
;   Function: void initKernel(void);
;   Init the Kernel
; ******************************************************************************************************************************

_initKernel:		RET

; ******************************************************************************************************************************
;   Function: void waitVBlank(void)
;   Wait for a Vertical Blank (uses VBlank IRQ)
; ******************************************************************************************************************************

_waitVBlank:		XOR	A
    			LD 	(_VBlank),A

waitForVBlank:		LD	A,(_VBlank)
    			AND	A
    			JR	Z,waitForVBlank
    			RET

; ******************************************************************************************************************************
;   Function: void enableL2(uint16 onoff)
;   Enable the 256 colour Layer 2 bitmap
;
;   In:     L=0  off        (fastcall passes bool as a byte in L)
;           L!=0 on
; ******************************************************************************************************************************

_enableL2:		LD	A,L
			AND	A
			JR	Z,@off
			LD	L,2
			
@off:			LD	A,(_Port123b)
			OR 	L
			LD	(_Port123b),A
			LD	BC,$123B
			OUT	(C),A     
			RET                          

; ******************************************************************************************************************************
;   Function: void DMACopy(uint16 src, uint16 dst, uint16 len)
;   Do a DMA copy
;
;   In:       hl = src
;             de = dst
;             bc = len
; ******************************************************************************************************************************

_DMACopy:		POP	IY 
			POP	HL	; Get src
			POP	DE	; Get dst
			POP	BC	; Get len 
			PUSH	IY

DMACopy:		LD	(DMACopySrc),HL
    			LD	(DMACopyDst),DE
    			LD	(DMACopyLen),BC

DMACopyInternal:	LD	HL,DMACopyProg                  
    			LD	BC,DMACopyProgL * 256 + Z80DMAPORT 
    			OTIR
			RET

; ******************************************************************************************************************************
;   Function: void DMAFill(uint16 dst, uint16 len, uint8 val)
;   Do a DMA fill
;
;   In:        a = val
;	      hl = dst
;             bc = len
; ******************************************************************************************************************************

_DMAFill:		POP	IY 
			POP	HL	; Get dst
			POP	BC	; Get len 
			POP	DE
			LD	A,E	; Get val
			PUSH	IY

DMAFill:		LD	(DMAFillDst),HL
    			LD	(DMAFillLen),BC
			LD	(DMAFillVal),A

DMAFillInternal:	LD	HL,DMAFillProg                  
    			LD	BC,DMAFillProgL * 256 + Z80DMAPORT 
    			OTIR
			RET

; ******************************************************************************************************************************
;   Function: void readKeyboard(void)
;   Scan the whole keyboard
; ******************************************************************************************************************************

_readKeyboard:		LD	B,39
		        LD	HL,_Keys
		        XOR	A
@lp1:   		LD 	(HL),A
		        INC	HL
		        DJNZ    @lp1

		        LD 	IY,_Keys
		        LD 	BC,$FEFE	; Caps,Z,X,C,V
		        LD	HL,_RawKeys

@readAllKeys:   	IN	A,(C)
		        LD	(HL),A
		        INC	HL      
		        LD	DE,$05FF

@doAll: 		SRL	A
		        JR 	C,@notset
		        LD	(IY+0),E
			
@notset:		INC	IY
		       	DEC	D
		       	JR	NZ,@doAll

		        LD	A,B
		        SLA	A
		        RET	NC
		        OR 	1
		        LD 	B,A
		        JP  	@readAllKeys
        		RET

; ******************************************************************************************************************************
;   Function: uint16 readNextReg(uint16 reg)
;   Read a next register
; ******************************************************************************************************************************

_readNextReg:		POP	DE		; DE: return address
		        POP	HL		; HL: reg
		        LD      BC,$243B	; Select NEXT register
		        OUT     (C),L
		        INC     B		; $253B to access (read or write) value
		        IN      L,(C)
		        LD      H,0		; HL: return value
		        PUSH    DE		; Push return address back
		        RET


; ******************************************************************************************************************************
;   Function: void setCPU(uint8 speed)
;   Sets the Next CPU
;   speed: 0 -  3.5Mhz
;          1 -  7.0Mhz
;          2 - 14.0Mhz
;          3 - 28.0Mhz
; ******************************************************************************************************************************

_setCPU:		LD	A,L		; A: speed
			NEXTREG 07h,A           ; Set CPU speed
    			RET

; ******************************************************************************************************************************
;   Function: void stop(void)
;   A debugging tool. Jump here (jp _stop) from your code so you can stop and inspect registers etc.
; ******************************************************************************************************************************

_stop:			JP _stop

; ******************************************************************************************************************************
;   Kernel Data
; ******************************************************************************************************************************

_Keys:      		DS  40
_RawKeys:   		DS  8

; ******************************************************************************************************************************
;   Writable DMA Programs
; ******************************************************************************************************************************

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
