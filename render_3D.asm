    			SECTION KERNEL_CODE

    			INCLUDE "globals.inc"


; extern void rotateModel(Point16 * buffer, Point16_3D p, Angle_3D a, Model_3D * m) __z88dk_callee;
; This is an optimised version of this C routine
;
; for(i=0; i<m->numVertices; i++) {
;     Point8_3D v = (*m->vertices)[i];
;     Point8_3D r = rotate8_3D(v, a);
;     *buffer++ = project3D(&p, &r);
; }
;
PUBLIC _rotateModel

_rotateModel:		POP	BC		; The return address
			POP	HL		; HL: Pointer to Point16 buffer
			POP	HL		; HL: p.x
			POP	HL		; HL: p.y
			POP	HL		; HL: p.z
			POP	DE		;  E: a.x, D: a.y
			DEC	SP		; Correct the stack address for single byte
			POP	AF		;  A: a.z
			POP	IY		; IY: Pointer to Model_3D object
			PUSH	BC		; Restore the return address
			RET

; extern void drawObject(Object_3D * o) __z88dk_callee;
;
PUBLIC _drawObject

_drawObject:		POP	HL		; The return address	
			POP	IY		; Pointer to the model data
			PUSH	HL		; Restore the return address
			RET