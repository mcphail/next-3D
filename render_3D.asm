    			SECTION KERNEL_CODE

    			INCLUDE "globals.inc"

			EXTERN	rotate8_3D	; In maths.asm
			EXTERN	project3D	; In maths.asm
			EXTERN	windingOrder	; In maths.asm
			EXTERN	scratchpad	; In ram.inc
			EXTERN	shape_buffer	; In render.asm
			EXTERN	triangleL2C	; In clipping.asm
			EXTERN	triangleL2CF	; In clipping.asm


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
			LD	IY,scratchpad	; Used to store results of calculations

;
; First get the number of vertices to plot
;
@L1:			PUSH	BC		; Push theta.y, theta.z
			PUSH	DE		; Push theta.x, loop counter
;
; Read a vertice in from the model
;
			LD	A,(HL)		; v.x
			LD	(scratchpad+0),A
			INC	HL 
			LD	A,(HL)		; v.y
			LD	(scratchpad+1),A
			INC	HL
			LD	A,(HL)		; v.z
			LD	(scratchpad+2),A
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
			LD	HL,(R1): LD (scratchpad+0),HL
			LD	HL,(R2): LD (scratchpad+2),HL
			LD	HL,(R3)		; p.z
			CALL	project3D	; Do the projection, Point16 result in (IY)
;
; Store the transformed point in the buffer
;
			LD	HL,(scratchpad+0)
			LD	DE,(scratchpad+2)
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


; extern void renderModel(Point16 * buffer, Model_3D * m, uint8_t mode) __z88dk_callee;
; This is an optimised version of this C routine
;
; for(i=0; i<m->numFaces; i++) {
;     Vertice_3D * v = &(*m->faces)[i];
;     Point16 p1 = buffer[v->p1];
;     Point16 p2 = buffer[v->p2];
;     Point16 p3 = buffer[v->p3];
;     if(windingOrder(p1,p2,p3)) {
;         if(mode == 1) {
;             triangleL2CF(p1,p2,p3,v->colour);
;         }
;         else {
;             triangleL2C(p1,p2,p3,0xFF);
;         }
;     }
; }
;
PUBLIC _renderModel

_renderModel:		POP	BC		; The return address
			POP	HL: LD (R7),HL	; Pointer to the vector buffer
			POP	IY		; Pointer to the model data
			DEC	SP		; Correct the stack address for single byte
			POP	AF		;  A: mode
			PUSH	BC		; Restore the return address
;
			LD	B,(IY+1)	;  B: Number of faces
			LD	L,(IY+4)	; HL: Pointer to the face data
			LD	H,(IY+5)

			LD	(R6+1),A	; R6H = mode
;
@L1:			PUSH	BC		; Stack the loop counter
;
; Fetch all the face data (four bytes)
;
			XOR	A		;  A: 0
			LD	B,2		;  B: Multiplier for shift (x4)
;
			LD	D,A
			LD	E,(HL)		;  E: Fetch the first face
			BSLA	DE,B 		; DE: Multiply by 4
			LD	IY,(R7)		; IY: Pointer to the vector buffer
			ADD	IY,DE		; IY: Now points to the vertice
			LD	E,(IY+0)	; DE: First point X coordinate
			LD	D,(IY+1)
			LD	(R0),DE		; R0: X1
			LD	E,(IY+2)	; DE: First point Y coordinate
			LD	D,(IY+3)
			LD	(R1),DE		; R1: Y1
			INC	HL
;
			LD	D,A
			LD	E,(HL)		;  E: Fetch the second face
			BSLA	DE,B		; DE: Multiply by 4
			LD	IY,(R7)		; IY: Pointer to the vector buffer
			ADD	IY,DE		; IY: Now points to the vertice
			LD	E,(IY+0)	; DE: Second point X coordinate
			LD	D,(IY+1)
			LD	(R2),DE		; R2: X2
			LD	E,(IY+2)	; DE: Second point Y coordinate
			LD	D,(IY+3)
			LD	(R3),DE		; R3: Y2
			INC	HL
;
			LD	D,A
			LD	E,(HL)		;  E: Fetch the third face
			BSLA	DE,B		; DE: Multiply by 4
			LD	IY,(R7)		; IY: Pointer to the vector buffer
			ADD	IY,DE		; IY: Now points to the vertice
			LD	E,(IY+0)	; DE: Third point X coordinate
			LD	D,(IY+1)
			LD	(R4),DE		; R4: X3
			LD	E,(IY+2)	; DE: Third point Y coordinate
			LD	D,(IY+3)
			LD	(R5),DE		; R5: Y3
			INC	HL
;
			LD	A,(HL)
			LD	(R6),A		; R6L: The face colour
			INC	HL
;
			PUSH	HL		; Stack the pointer to the face data
			CALL	windingOrder	; Do the backface culling calculation
			JR	Z,@M1		; This face is culled, so skip
			LD	HL,(R6)		;  L: face colour
			DEC	H		;  H: mode (0 = wireframe, 1 = filled)
			JR	NZ, @M2		; Not 1, so jump to wireframe version
			LD	A,L		;  A: face colour
			CALL	triangleL2CF	; Only draw triangles that are facing us
@M1:			POP	HL		; Restore the pointer to the face data
			POP	BC		; And loop
			DEC	B
			JP	NZ,@L1
			RET
;
@M2:			LD	A,0xFF		; Always do wireframe in white
			CALL	triangleL2C
			JR	@M1
