    			SECTION KERNEL_CODE

    			INCLUDE "globals.inc"
;
; Clipping algorithm courtesy of 
; https://www.geeksforgeeks.org/dsa/line-clipping-set-1-cohen-sutherland-algorithm/
;

p1_x:			DS 	2
p1_y:			DS	2
p2_x:			DS	2
p2_y:			DS	2
dx:			DS	2
dy:			DS 	2

			EXTERN	fastMulDiv		; From maths.asm
			EXTERN	negDE 			; From maths.asm
			EXTERN	plotL2asm_colour	; From render.asm
			EXTERN	lineL2			; From render.asm
			EXTERN	lineL2_NC		; From render.asm
			EXTERN	triangleL2F		; From render.asm

; extern void lineL2C(Point16 p1, Point16 p2, uint8_t c) __z88dk_callee
;
PUBLIC _lineL2C, lineL2C

_lineL2C:		POP	BC			; Get the return address
			POP	HL: LD (R0),HL
			POP	HL: LD (R1),HL
			POP	HL: LD (R2),HL
			POP	HL: LD (R3),HL
    			DEC	SP
    			POP	AF          		; Loads colour into A
			PUSH	BC			; Stack the return address

; Draw a clipped line
; R0: p1.x
; R1: p1.y
; R2: p2.x
; R3: p2.y
;  A: colour
;
lineL2C:		LD	(plotL2asm_colour+1),A	; Store the colour
			JR	triangleL2C_1		; Jump to the last part of the triangle routine


; extern void triangleL2CF(Point16 p1, Point16 p2, Point p3, uint8_t c) __z88dk_callee;
;
PUBLIC _triangleL2C, triangleL2C:	

_triangleL2C:		POP	BC			; The return address
			POP	HL: LD (R0),HL		; R0: p1.x
			POP	HL: LD (R1),HL		; R1: p1.y
			POP	HL: LD (R2),HL		; R2: p2.x
			POP	HL: LD (R3),HL		; R3: p2.y
			POP	HL: LD (R4),HL		; R4: p3.x
			POP	HL: LD (R5),HL		; R5: p3.y
			DEC	SP
			POP	AF			;  A: Colour
			PUSH	BC			; Restore the return address
;
; Draw a clipped wireframe triangle
; R0: p1.x
; R1: p1.y
; R2: p2.x
; R3: p2.y
; R4: p3.x
; R5: p3.Y
;  A: colour
;
triangleL2C:		LD	(plotL2asm_colour+1),A	; Store the colour
			LD	HL,(R2): LD (p1_x),HL	; p2
			LD	HL,(R3): LD (p1_y),HL	
			LD	HL,(R4): LD (p2_x),HL	; p3
			LD	HL,(R5): LD (p2_y),HL
			CALL	clipLine
			CALL	NZ,triangleL2C_L
			LD	HL,(R0): LD (p1_x),HL	; p1
			LD	HL,(R1): LD (p1_y),HL	
			LD	HL,(R4): LD (p2_x),HL	; p3
			LD	HL,(R5): LD (p2_y),HL
			CALL	clipLine
			CALL	NZ,triangleL2C_L
triangleL2C_1:		LD	HL,(R0): LD (p1_x),HL	; p1
			LD	HL,(R1): LD (p1_y),HL	
			LD	HL,(R2): LD (p2_x),HL	; p2
			LD	HL,(R3): LD (p2_y),HL
			CALL	clipLine
			RET	Z
triangleL2C_L:		LD	A,(p1_x): LD L,A
			LD	A,(p1_y): LD H,A
			LD	A,(p2_x): LD E,A
			LD	A,(p2_y): LD D,A
			JP	lineL2_NC


; extern void triangleL2CF(Point16 p1, Point16 p2, Point p3, uint8_t c) __z88dk_callee;
;
PUBLIC _triangleL2CF, triangleL2CF

_triangleL2CF:		POP	BC			; The return address
			POP	HL: LD (R0),HL		; R0: p1.x
			POP	HL: LD (R1),HL		; R1: p1.y
			POP	HL: LD (R2),HL		; R2: p2.x
			POP	HL: LD (R3),HL		; R3: p2.y
			POP	HL: LD (R4),HL		; R4: p3.x
			POP	HL: LD (R5),HL		; R5: p3.y
			DEC	SP
			POP	AF			;  A: Colour
			PUSH	BC			; Restore the return address
;
triangleL2CF:;		CALL	sortTriangle16		; Sort the triangle points from top to bottom
			LD 	A,(R0): LD C,A
			LD	A,(R1): LD B,A
			LD 	A,(R2): LD E,A
			LD	A,(R3): LD D,A
			LD	A,(R4): LD L,A
			LD	A,(R5): LD H,A 
			LD	A,0xFD
			JP	triangleL2F

; For the filled triangle
; Need to sort the points from top to bottom
;
; if R1 > R3 swap({R2,R3},{R0,R1}); // if (p1.y > p2.y) swap(p2, p1)
; if R1 > R5 swap({R4,R5},{R0,R1}); // if (p1.y > p3.y) swap(p3, p1)
; if R3 > R5 swap({R4,R5},{R2,R3}); // if (p2.y > p3.y) swap(p3, p2)
;
sortTriangle16:		LD	HL,(R3)
			LD	DE,(R1)
			CMP_HL	DE	; C if R1 > R3, otherwise NC
			JR	NC,@M1	
			LD	(R3),DE
			LD	(R1),HL
			LD	HL,(R2)
			LD	DE,(R0)
			LD	(R2),DE
			LD	(R0),HL
;
@M1:			LD	HL,(R5)
			LD	DE,(R1)
			CMP_HL	DE	; C if R1 > R5, otherwise NC
			JR	NC,@M2
			LD	(R5),DE
			LD	(R1),HL
			LD	HL,(R4)
			LD	DE,(R0)
			LD	(R4),DE
			LD	(R0),HL
;
@M2:			LD	HL,(R5)
			LD	DE,(R3)
			CMP_HL	DE	; C if R3 > R5, otherwise NC
			RET	NC
			LD	(R5),DE
			LD	(R3),HL
			LD	HL,(R4)
			LD	DE,(R2)
			LD	(R4),DE
			LD	(R2),HL
			RET


; extern uint8_t clipRegion(Point16 * p) __z88dk_callee
;
PUBLIC _clipRegion, clipRegion

_clipRegion:		POP	BC
			POP	IY		; Pointer to the Point16 struct
			LD	C,(IY+0)	; Fetch the X coordinate
			LD	B,(IY+1)
			LD	E,(IY+2)	; Fetch the Y coordinate
			LD	D,(IY+3)
			PUSH 	BC
			CALL	clipRegion
			LD	L,A		; Return the clip region
			RET

; BC: X coordinate of interest
; DE: Y coordinate of interest
; Returns:
;  A: Clip region(s) the point is in, with the following bits set:
;  Bit 0: Top
;      1: Bottom
;      2: Right
;      3: Left
;
clipRegion:		XOR	A		; The return value
;
clipRegionV:		RLC	D 		; D: Test the Y coordinate MSB
			JR	C, clipRegionT	; Off top of the screen
			JR	NZ, clipRegionB ; Off bottom of screen 
			LD	D,A		; Store A temporarily
			LD	A,E		; E: Y (LSB)
			CP	192
			LD	A,D		; Restore A
			JR	C, clipRegionH 	; We're in the top 192 lines of the screen, so skip 
clipRegionB:		OR	2		; Bottom
			JR	clipRegionH
clipRegionT:		OR	1		; Top
;		
clipRegionH:		RLC 	B		; B: Test the X coordinate MSB
			RET	Z 		; We're on screen, so ignore
			JR	C, clipRegionL	; We're off the left of the screen, so skip to that
			OR	4		; Right
			RET 
clipRegionL:		OR	8		; Left
			RET 		

; extern uint8_t clipLine(Point16 * p1, Point16 * p2) __z88dk_callee
; 
PUBLIC _clipLine, clipLine

_clipLine: 		POP	IY
			LD	DE,p1_x		; Where we're going to store the coordinates
			POP 	HL		; Pointer to p1
			LD	(_clipLine_M1+1),HL
			LDI 			; Copy p1 (4 bytes)
			LDI
			LDI
			LDI
			POP	HL		; Pointer to p2
			LD	(_clipLine_M2+1),HL
			LDI			; Copy p2 (4 bytes)
			LDI
			LDI
			LDI 	
			PUSH 	IY
			CALL	clipLine
;
			LD	HL,p1_x		; Copy the values back to the pointers
_clipLine_M1:		LD	DE,0
			LDI
			LDI
			LDI
			LDI
			LD	HL,p2_x
_clipLine_M2:		LD	DE,0
			LDI
			LDI
			LDI
			LDI
			LD	L,A		; The return value
			RET

; Parameters:
;  p1: Set to the first point to clip
;  p2: Set to the second point to clip
; Returns:
;   A:
;	1 if the line hasn't been clipped as both points are on screen
;	0 if the line does not need to be drawn as both points are off screen
;   Otherwise returns number of iterations of clipping required
;
clipLine:		LD	BC,(p1_x)
			LD	DE,(p1_y)
			CALL	clipRegion	
			LD	L,A 			; L: code1		
			LD	BC,(p2_x)
			LD	DE,(p2_y)
			CALL	clipRegion
			LD	H,A			; H: code2
			LD	IYL, 0			; Iteration counter
;
; Trivial check if both points are on screen
;
clipLine_L1:		INC	IYL			; Increment iteration counter
			LD	A,H 			; code1|code2==0
			OR	L
			JR 	NZ, clipLine_M1		; No, so skip
			LD	A,IYL			; A: Accept
			OR	A			; Set the flags (for when called from assembler)
			RET
;
; Trivial check if both points are off screen
;
clipLine_M1:		LD 	A,H			; code1&code2!=0	
			AND 	L
			JR	Z, clipLine_M2		; No, so skip
			XOR	A
			RET 				; A: Reject
;
; Check which point needs clipping (codeout)
;
clipLine_M2:		LD	A,L			; Is L (code1) on screen
			OR	A
			JR	NZ, clipLine_M3		; NZ - L (code1) is codeout
			LD	A,H 			;  Z - H (code2) is codeout
;
; Calculate the deltas
;	
clipLine_M3:		PUSH	HL			; Stack code1 and code2
			PUSH	AF			; Stack codeout and Z flag
			LD	C,A			; C: codeout
;
			LD	HL,(p2_x)		; Calculate dx (p2_x - p1_x)
			LD	DE,(p1_x)
			OR	A
			SBC	HL,DE
			LD	(dx),HL 
;
			LD	HL,(p2_y)		; Calculate dy (p2_y - p1_y)
			LD	DE,(p1_y)
			OR	A
			SBC	HL,DE
			LD	(dy),HL
;
; Do the clipping
;
			SRL	C
			JR	C, clipLine_Top
			SRL	C			
			JR	C, clipLine_Bottom
			SRL	C
			JR	C, clipLine_Right
;
; Clip Left
; Returns
;  BC: Clipped X point
;  DE: Clipped Y point
;
clipLine_Left:		LD	DE,(p1_x)		; Do p1->y + fastMulDiv(dy, -p1->x, dx)
			CALL	negDE
			LD	HL,(dy)
			LD	BC,(dx)
			CALL	fastMulDiv
			LD	DE,(p1_y)
			ADD	HL,DE
			EX	HL,DE			; DE: Y
			LD	BC, 0			; BC: X
;
; Set up for next iteration
;
clipLine_Next:		POP	AF			; A: codeout, flag set from previous calculation
			POP	HL			; L: code1, H: code2
			JR	NZ, @M1 		; F: NZ if code1=codeout
;
; codeout = H (code2) at this point
;
			LD	(p2_x),BC
			LD	(p2_y),DE
			CALL	clipRegion
			LD	H,A			; H: code2
			JP	clipLine_L1
;
; codeout = L (code1) at this point
;
@M1:			LD	(p1_x),BC
			LD	(p1_y),DE
			CALL	clipRegion		
			LD 	L,A			; L: code1
			JP	clipLine_L1
;
; Clip Top
; Returns
;  BC: Clipped X point
;  DE: Clipped Y point
;
clipLine_Top:		LD	DE,(p1_y)		; Do p1->x + fastMulDiv(dx, -p1->y, dy)
			CALL	negDE 
			LD	HL,(dx)			; HL: dx
			LD	BC,(dy)			; BC: dy
			CALL	fastMulDiv		; HL: fastMulDiv(dx, -p1->y, dy); 
			LD	DE,(p1_x)
			ADD	HL,DE 			; HL: p1_x +fastMulDiv(dx, -p1->y, dy)
			PUSH	HL
			POP	BC			; BC: X
			LD	DE,0			; DE: Y
			JR 	clipLine_Next
;
; Clip Bottom
; Returns
;  BC: Clipped X point
;  DE: Clipped Y point
;					
clipLine_Bottom:	LD	HL,192			; Do p1->x + fastMulDiv(dx, 192-p1->y, dy)
			LD	DE,(p1_y)
			OR	A
			SBC	HL,DE
			EX	DE,HL
			LD	HL,(dx)
			LD	BC,(dy)
			CALL	fastMulDiv
			LD	DE,(p1_x)
			ADD	HL,DE
			PUSH	HL
			POP	BC			; BC: X
			LD	DE, 191			; DE: Y
			JR	clipLine_Next
;
; Clip Right
; Returns
;  BC: Clipped X point
;  DE: Clipped Y point
; 
clipLine_Right:		LD	HL,256			; Do p1->y + fastMulDiv(dy, 256-p1->x, dx)
			LD	DE,(p1_x)
			OR	A
			SBC	HL,DE
			EX	DE,HL
			LD	HL,(dy)
			LD	BC,(dx)
			CALL	fastMulDiv	
			LD	DE,(p1_y)
			ADD	HL,DE
			EX	DE,HL			; DE: Y
			LD	BC,255			; BC: X			
			JR 	clipLine_Next

