
                SECTION KERNEL_IRQ
                
                PUBLIC _SetUpIRQs
                PUBLIC _VBlank,_Port123b


; ******************************************************************************************************************************
;   Main IRQ vector - org'd at $FCFC  (as per sepctrum IM2 rules of Lo/Hi need to be the same value)
; ******************************************************************************************************************************
                
IM2Routine:     ei
                jp      IRQHandler

                ; $fd00    ($fcfc + 4 bytes)
VectorTable:            
                dw      IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                dw      IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                dw      IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                dw      IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                dw      IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                dw      IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                dw      IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                dw      IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine,IM2Routine
                dw      IM2Routine


; ******************************************************************************************************************************
;   Setup IRQ function - 512 bytes left at this point
; ******************************************************************************************************************************
_SetUpIRQs:      
                di
                ld      a,VectorTable>>8
                ld      i,a    
                im      2                       ; Setup IM2 mode
                ei                
                ret

; ******************************************************************************************************************************
;   Main IRQ function - 512 bytes left at this point
; ******************************************************************************************************************************
IRQHandler:
                push    af                

                ; Flag VBlank
                ld      a,1
                ld      (_VBlank),a

ExitIRQ:
                pop     af
                reti


; ******************************************************************************************************************************
; IRQ Data
; ******************************************************************************************************************************
_VBlank:        db      0
_Port123b:      db      0



; ******************************************************************************************************************************
; write this so that we can detect overruns from the IRQ segment
; ******************************************************************************************************************************
SECTION KERNEL_END
ENDIRQ:         ret     





