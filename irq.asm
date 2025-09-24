;
; Title:	IRQ and Interrupt Handlers
; Author:	Dean Belfield
; Created:	20/08/2025
; Last Updated:	22/09/2025
;
; Modinfo:
;

		SECTION KERNEL_IRQ
                
                PUBLIC _initIRQs
                PUBLIC _VBlank,_Port123b

; ******************************************************************************************************************************
;   Main IRQ vector - org'd at $FCFC  (as per Spectrum IM2 rules of Lo/Hi need to be the same value)
; ******************************************************************************************************************************
                
IM2Routine:     EI
                JP      IRQHandler

; $FD00    ($FCFC + 4 bytes)
;
vectorTable:	DW	IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                DW	IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                DW	IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                DW	IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                DW	IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                DW	IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                DW	IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                DW	IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                DW	IM2Routine

; ******************************************************************************************************************************
;   Setup IRQ function - 512 bytes left at this point
; ******************************************************************************************************************************

_initIRQs:      DI
                LD	A,vectorTable>>8
                LD	I,A    
                IM	2
                EI                
                RET

; ******************************************************************************************************************************
;   Main IRQ function - 512 bytes left at this point
; ******************************************************************************************************************************

IRQHandler:	PUSH	AF               
                LD	A,1
                LD	(_VBlank),a	; Flag VBlank
		POP	AF
                RETI

; ******************************************************************************************************************************
;   IRQ Data
; ******************************************************************************************************************************

_VBlank:        DB	0
_Port123b:      DB	0

; ******************************************************************************************************************************
;   Write this so that we can detect overruns from the IRQ segment
; ******************************************************************************************************************************

SECTION KERNEL_END

ENDIRQ:         RET     





