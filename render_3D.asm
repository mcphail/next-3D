    			SECTION KERNEL_CODE

    			INCLUDE "globals.inc"

			EXTERN	rotate8_3D	; In maths.asm
			EXTERN	project3D	; In maths.asm
			EXTERN	Scratchpad	; In ram.inc
			EXTERN	R0,R1,R2,R3 	; In ram.inc


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
			POP	HL: LD (R0),HL	; R0: Pointer to Point16 buffer
			POP	HL: LD (R1),HL	; R1: p.x
			POP	HL: LD (R2),HL	; R2: p.y
			POP	HL: LD (R3),HL	; R3: p.z
			POP	DE		;  E: theta.x, D: theta.y
			DEC	SP		; Correct the stack address for single byte
			POP	AF		;  A: theta.z
			POP	IY		; IY: Pointer to Model_3D object
			PUSH	BC		; Restore the return address
;
			PUSH	IX
			LD	IX,(R0)		; Pointer to the Point16 buffer
;
; Sort out the angles for rotate
;
			LD	B,A		; B: theta.z
			LD	C,D		; C: theta.y
			LD	D,E		; D: theta.x
			LD	E,(IY+0)	; Fetch number of vertices from the model
			LD	L,(IY+2)	; Fetch pointer to the vertices
			LD	H,(IY+3)
;
			LD	IY,Scratchpad	; Used to store results of calculations

;
; First get the number of vertices to plot
;
@L1:			PUSH	BC		; Push theta.y, theta.z
			PUSH	DE		; Push theta.x, loop counter
;
; Read a vertice in from the model
;
			LD	A,(HL)		; v.x
			LD	(Scratchpad+0),A
			INC	HL 
			LD	A,(HL)		; v.y
			LD	(Scratchpad+1),A
			INC	HL
			LD	A,(HL)		; v.z
			LD	(Scratchpad+2),A
			INC	HL			
;
; Apply rotation
;
			PUSH	HL
			CALL	rotate8_3D	; Do the rotation, Point8_3D result in (IY)
;
; Apply projection
;
			LD	E,(IY+0)	; r.x
			LD	D,(IY+1)	; r.y
			LD	A,(IY+2)	; r.z
			LD	HL,(R1): LD (Scratchpad+0),HL
			LD	HL,(R2): LD (Scratchpad+2),HL
			LD	HL,(R3)		; p.z
			CALL	project3D	; Do the projection, Point16 result in (IY)
;
; Store the transformed point in the buffer
;
			LD	HL,(Scratchpad+0)
			LD	DE,(Scratchpad+2)
			LD	(IX+0),L	; Store the rotated point
			LD	(IX+1),H
			LD	(IX+2),E
			LD	(IX+3),D
			LD	BC,4
			ADD	IX,BC
;
; Loop
;
			POP	HL		; Pop pointer to vertices
			POP	DE		; Pop theta.x, loop counter
			POP	BC		; Pop theta.y, theta.z
			DEC	E			
			JR	NZ,@L1
			POP	IX		; Restore IX
			RET

; extern void drawObject(Object_3D * o) __z88dk_callee;
;
PUBLIC _drawObject

_drawObject:		POP	HL		; The return address	
			POP	IY		; Pointer to the model data
			PUSH	HL		; Restore the return address
			RET