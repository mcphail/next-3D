    			SECTION KERNEL_CODE

    			INCLUDE "globals.inc"


; extern void drawObject(Object_3D * o) __z88dk_callee;
;
PUBLIC _drawObject

_drawObject:		POP	HL		; The return address	
			POP	IY		; Pointer to the model data
			PUSH	HL		; Restore the return address
			RET