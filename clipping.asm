    			SECTION KERNEL_CODE

    			INCLUDE "globals.inc"
;
; Line clipping algorithm pseudocode courtesy of 
; https://www.geeksforgeeks.org/dsa/line-clipping-set-1-cohen-sutherland-algorithm/
;

p1_x:			DS 	2
p1_y:			DS	2
p2_x:			DS	2
p2_y:			DS	2
dx:			DS	2
dy:			DS 	2

			EXTERN	Scratchpad		; From ram.inc
			EXTERN	fastMulDiv		; From maths.asm
			EXTERN	negDE 			; From maths.asm
			EXTERN	plotL2asm_colour	; From render.asm
			EXTERN	lineL2			; From render.asm
			EXTERN	lineL2_NC		; From render.asm
			EXTERN	triangleL2F		; From render.asm
			EXTERN	lineT			; From render.asm
			EXTERN	drawShapeTable		; From render.asm


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

triangleIn:		EQU	Scratchpad + $0C0
triangleOut:		EQU	Scratchpad + $1C0

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
triangleL2CF:		PUSH	IX
			LD	(@M2+1),A		; Store the colour for later
;			CALL	sortTriangle16		; Sort the triangle points from top to bottom

			LD	A,1
			LD	DE,(R0)			; Add the first coordinate
			LD	HL,(R1)
			LD	(triangleIn+$0),A
			LD	(triangleIn+$1),DE	; DE: The X coordinate
			LD	(triangleIn+$3),HL	; HL: The Y coordinate
			CALL	clipRegion
			LD	C,A 			; The first clipping region
			LD	A,1
			LD	DE,(R2)			; Add the second coordinate
			LD	HL,(R3)
			LD	(triangleIn+$5),A
			LD	(triangleIn+$6),DE
			LD	(triangleIn+$8),HL
			CALL	clipRegion		; The second clipping region
			OR	C 			; OR it with the first
			LD	C,A
			LD	A,1
			LD	DE,(R4)			; Add the third coordinate
			LD	HL,(R5)
			LD	(triangleIn+$A),A
			LD	(triangleIn+$B),DE
			LD	(triangleIn+$D),HL
			LD	(p1_x),DE		; The previous points for the clipping
			LD	(p1_y),HL
			CALL	clipRegion		; The third clipping region
			OR	C			; OR it with the first two
			LD	A,0
			LD	(triangleIn+$F),A	; End of table marker
			JR	Z,@M1			; All clipping regions are on screen, so just draw
;
			LD	HL,clipTriangleLeft	; The callback routine to clip the left edge
			LD	IX,triangleIn 		; The input list
			LD	IY,triangleOut		; The output list
			CALL	clipTriangle		; Clip the triangle
			CALL	clipTriangleInit	; Initialise the clipping for the next pass
;
			LD	HL,clipTriangleTop	; The callback routine to clip the top edge
			LD	IX,triangleOut 		; The input list (the previous output list)
			LD	IY,triangleIn		; The output list (the previous input list)
			CALL	clipTriangle		; Clip the triangle
			CALL	clipTriangleInit	; Initialise the clipping for the next pass
;
			LD	HL,clipTriangleRight	; The callback routine to clip the right edge
			LD	IX,triangleIn 		; The input list
			LD	IY,triangleOut		; The output list
			CALL	clipTriangle		; Clip the triangle
			CALL	clipTriangleInit	; Initialise the clipping for the next pass
;
			LD	HL,clipTriangleBottom	; The callback routine to clip the bottom edge
			LD	IX,triangleOut 		; The input list (the previous output list)
			LD	IY,triangleIn		; The output list (the previous input list)
			CALL	clipTriangle		; Clip the triangle
;
@M1:			LD	A,(triangleIn)		; Check if the first entry in the list is $00
			OR	A			; indicating nothing to draw
@M2:			LD	A,0			; The colour
			CALL	NZ,drawTriangle		; No, so draw the triangle
			POP	IX
			RET

; Draw the triangle
;
drawTriangle:		LD	IY,triangleIn		; IY: The output (clipped) vertice list
			LD	IX,$FF00		; IX: Highest and lowest vertical coords (IXH=top, IXL=bottom)
			LD	(@M2+1),A		; Self-mod the colour for later
@L1:			LD	A,(IY+5)	
			OR	A
			LD	L,(IY+1)		; The first coordinate
			LD	H,(IY+3)
			JR	Z,@M1			; If there is no second point, then skip to the end
			LD	E,(IY+6)		; The second coordinate
			LD	D,(IY+8)	
			CALL	drawTriangleSide	; Get the side
			LD	A,C
			LD	B,H
			LD	C,L
			CALL	lineT			; Draw the line
			LD	A,IYL
			ADD	A,5
			LD	IYL,A
			JR	@L1
;
@M1:			LD	IY,triangleIn		; Reset the list
			LD	E,(IY+1)		; The second coordinate (the first point of the shape)
			LD	D,(IY+3)
			CALL	drawTriangleSide	; Get the side
			LD	A,C
			LD	B,H
			LD	C,L
			CALL	lineT			; Draw the final connecting line
;
; Finally, draw the triangle
;
			LD	A,IXH			; Get the top Y point
			LD	L,A 
			LD	A,IXL			; And the bottom Y point
			SUB	L 
			RET	Z			; Don't do anything here
			RET	C			; Bit of a bodge to fix bug where bottom is above the top
			LD	B,A			; B: The height
@M2:			LD	A,0 			; A: The colour (self-modded)
			JP 	drawShapeTable		; Draw the shape

;
drawTriangleSide:	LD	A,H			; Calculate the colour depending upon
			CP	D			; which way the line is being drawn up or down
			JR	NC,drawTriangleSideUp	;  F: NC set if we are drawing up
;
; Drawing down at this point
;
			LD	C,0			;   C: The side 
			LD	A,D			;   A: The vertice to check against
			CP	IXL			; IXL: The current lowest point
			RET	C 			; Return if D < current lowest point
			LD	IXL,A			; IXL: Now the lowest point
			RET
;
; Drawing up at this point
;
drawTriangleSideUp:	LD	C,1			;  C: The side 
			EX	DE,HL
			LD	A,H			;  A: The vertice to check against
			CP	IXH			;  D: The vertice to check against
			RET	NC
			LD	IXH,A
			RET

; Clip a triangle using the Sutherland-Hodgman algorithm
; https://en.wikipedia.org/wiki/Sutherland%E2%80%93Hodgman_algorithm
;
; Clipping uses the following algorithm
;
; if (currentPoint inside clipEdge) {
;     if (previousPoint not inside clipEdge) {
;         outputList.add(intersectingPoint);
;     }
;     outputList.add(currentPoint);
; }
; else if (previousPoint inside clipEdge) {
;     outputList.add(intersectingPoint);
; }
;
clipTriangle:		LD	(clipTriangleCall+1),HL	; The clipping operation self-modded code
;
; Loop through and clip top, bottom, left, then right
; Checks the current point (IX+5) with the previous (IX+0)
;
clipTriangle_L:		LD	A,(IX+0)		; Check for the end of list marker
			OR	A
			LD	(IY+0),A
			RET	Z			; Yes, so finish
;
			LD	L,(IX+1)		; Fetch the current X coordinate
			LD	H,(IX+2)
			LD	(p2_x),HL
			LD	DE,(p1_x)		; Calculate dx (p2_x - p1_x)
;			OR	A			; We don't need to do this, C is clear at this point
			SBC	HL,DE
			LD	(dx),HL 
;
			LD	L,(IX+3)		; Fetch the current X coordinate
			LD	H,(IX+4)
			LD	(p2_y),HL
			LD	DE,(p1_y)		; Calculate dy (p2_y - p1_y)
			OR	A
			SBC	HL,DE
			LD	(dy),HL
;
clipTriangleCall:	CALL	0			; Call the relevant clip routine, self-modded
;
			LD	DE,(p2_x)		; Get the current coordinates
			LD	HL,(p2_y)
			LD	(p1_x),DE		; Store the new previous coordinates
			LD	(p1_y),HL
			LD	A,IXL
			ADD	A,5
			LD	IXL,A
			JR	clipTriangle_L


; Clip the triangle at the top edge
;
clipTriangleTop:	LD	A,(p2_y+1)		;  A: The current Y point (MSB)	
			RLA				;  F: C set if point is OUTSIDE the clip area
			LD	A,(p1_y+1)		;  A: The previous Y point (MSB)
			JR	C,@M1			; If the current point is OUTSIDE then jump here
;
; Here the current point is INSIDE the clip edge
; Need to check if the previous point is OUTSIDE the clip edge
;
			RLA				;  A: The previous Y point (MSB)
			CALL	C,@M2			; It is OUTSIDE, so add the intersection
			JR	clipTriangleOutCurrent	; And add the current point in
;
; Here, the current point is OUTSIDE the clip edge
;
@M1:			RLA				; Check if the previous point is also OUTSIDE the clip edge
			RET	C			; Yes, so do nothing
;
; Here, the current point is OUTSIDE the clip edge and the previous point is INSIDE it.
;
@M2:			CALL	clipTop
			JR	clipTriangleOutVertex


; Clip the triangle at the left edge
;
clipTriangleLeft:	LD	A,(p2_x+1)		;  A: The current X point (MSB)	
			RLA				; F: C set if point is OUTSIDE the clip area
			LD	A,(p1_x+1)		;  A: The previous Y point (MSB)
			JR	C,@M1			; If the current point is OUTSIDE then jump here
;
; Here the current point is INSIDE the clip edge
; Need to check if the previous point is OUTSIDE the clip edge
;
			RLA				;  A: The previous X point (MSB)
			CALL	C,@M2			; It is OUTSIDE, so add the intersection
			JR	clipTriangleOutCurrent	; Finally add the current point in
;
; Here, the current point is OUTSIDE the clip edge
;
@M1:			RLA				; Check if the previous point is INSIDE the clip edge
			RET	C			; No, so do nothing
;
; Here, the current point is OUTSIDE the clip edge and the previous point is INSIDE it.
;
@M2:			CALL	clipLeft
			JR	clipTriangleOutVertex


; Clip the triangle at the right edge
;
clipTriangleRight:	LD	A,(p2_x+1)		;  A: The current X point (MSB)	
			OR	A			;  F: NZ if point is OUTSIDE the clip area
			LD	A,(p1_x+1)		;  A: The previous Y point (MSB)
			JR	NZ,@M1			; No, so go here
;
; Here the current point is INSIDE the clip edge
; Need to check if the previous point is outside the clip edge
;	
			OR	A			;  A: The previous X point (MSB)
			CALL	NZ,@M2			; It is OUTSIDE, so add the intersection
			JR	clipTriangleOutCurrent	; Finally add the current point in
;
; Here, the current point is OUTSIDE the clip edge
;
@M1:			OR	A			; Check if the previous point is INSIDE the clip edge
			RET	NZ			; No, so do nothing
;
; Here, the current point is outside the clip edge, but the previous point is in it
;
@M2:			CALL	clipRight
			JR	clipTriangleOutVertex


; Clip the triangle at the bottom edge
;
clipTriangleBottom:	LD	HL,(p2_y)		; HL: The current X point	
			LD	DE,192			; The bottom of the screen
			CMP_HL	DE	
			LD	HL,(p1_y)		; HL: The previous Y point
			JR	NC,@M1			; No, so go here
;
; Here the current point is inside the clip edge
; Need to check if the previous point is outside the clip edge
;	
			CMP_HL	DE			; Check if the previous point is inside the clip edge
			CALL	NC,@M2			; It is outside, so add the intersection
			JR	clipTriangleOutCurrent	; Finally add the current point in
;
; Here, the current point is outside the clip edge
;		
@M1:			CMP_HL	DE			; Check if the previous point is inside the clip edge
			RET	NC			; No, so do nothing
;
; Here, the current point is outside the clip edge, but the previous point is in it
;
@M2:			CALL	clipBottom
			JR	clipTriangleOutVertex


clipTriangleOutCurrent:	LD	DE,(p2_x)		; Add the current point in
			LD	HL,(p2_y)

; Output a vertex and increment to the next slot
; DE: X coordinate
; HL: Y coordinate
;
clipTriangleOutVertex:	LD	(IY+0),1		; Mark as being a valid vertex		
			LD	(IY+1),E		; Store a point in the output table
			LD	(IY+2),D
			LD	(IY+3),L
			LD	(IY+4),H
			LD	A,IYL
			ADD	A,5
			LD	IYL,A
			RET

; Initialise the clipping for the next pass
;
clipTriangleInit:	LD	E,(IY-4)		; Fetch the last points entered in the output list
			LD	D,(IY-3)
			LD	L,(IY-2)
			LD	H,(IY-1)
			LD	(p1_x),DE		; Store in p1_x and p1_y
			LD	(p1_y),HL		; ready for clipping against the next screen edge
			RET


; For the filled triangle
; Need to sort the points from top to bottom
;
; if R1 > R3 swap({R2,R3},{R0,R1}); // if (p1.y > p2.y) swap(p2, p1)
; if R1 > R5 swap({R4,R5},{R0,R1}); // if (p1.y > p3.y) swap(p3, p1)
; if R3 > R5 swap({R4,R5},{R2,R3}); // if (p2.y > p3.y) swap(p3, p2)
;
;sortTriangle16:	LD	HL,(R3)
;			LD	DE,(R1)
;			CMP_HL	DE	; C if R1 > R3, otherwise NC
;			JR	NC,@M1	
;			LD	(R3),DE
;			LD	(R1),HL
;			LD	HL,(R2)
;			LD	DE,(R0)
;			LD	(R2),DE
;			LD	(R0),HL
;
;@M1:			LD	HL,(R5)
;			LD	DE,(R1)
;			CMP_HL	DE	; C if R1 > R5, otherwise NC
;			JR	NC,@M2
;			LD	(R5),DE
;			LD	(R1),HL
;			LD	HL,(R4)
;			LD	DE,(R0)
;			LD	(R4),DE
;			LD	(R0),HL
;
;@M2:			LD	HL,(R5)
;			LD	DE,(R3)
;			CMP_HL	DE	; C if R3 > R5, otherwise NC
;			RET	NC
;			LD	(R5),DE
;			LD	(R3),HL
;			LD	HL,(R4)
;			LD	DE,(R2)
;			LD	(R4),DE
;			LD	(R2),HL
;			RET


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

; DE: X coordinate of interest
; HL: Y coordinate of interest
; Returns:
;  A: Clip region(s) the point is in, with the following bits set:
;  Bit 0: Top
;      1: Bottom
;      2: Right
;      3: Left
;
clipRegion:		XOR	A		; The return value
;
clipRegionV:		RLC	H 		; H: Test the Y coordinate MSB
			JR	C, clipRegionT	; Off top of the screen
			JR	NZ, clipRegionB ; Off bottom of screen 
			LD	H,A		; Store A temporarily
			LD	A,L		; L: Y (LSB)
			CP	192
			LD	A,H		; Restore A
			JR	C, clipRegionH 	; We're in the top 192 lines of the screen, so skip 
clipRegionB:		OR	2		; Bottom
			JR	clipRegionH
clipRegionT:		OR	1		; Top
;		
clipRegionH:		RLC 	D		; B: Test the X coordinate MSB
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
clipLine:		LD	DE,(p1_x)
			LD	HL,(p1_y)
			CALL	clipRegion	
			LD	C,A 			; C: code1		
			LD	DE,(p2_x)
			LD	HL,(p2_y)
			CALL	clipRegion
			LD	B,A			; B: code2
			LD	IYL, 0			; Iteration counter
;
; Trivial check if both points are on screen
;
clipLine_L1:		INC	IYL			; Increment iteration counter
			LD	A,B 			; code1|code2==0
			OR	C
			JR 	NZ, clipLine_M1		; No, so skip
			LD	A,IYL			; A: Accept
			OR	A			; Set the flags (for when called from assembler)
			RET
;
; Trivial check if both points are off screen
;
clipLine_M1:		LD 	A,B			; code1&code2!=0	
			AND 	C
			JR	Z, clipLine_M2		; No, so skip
			XOR	A
			RET 				; A: Reject
;
; Check which point needs clipping (codeout)
;
clipLine_M2:		LD	A,C			; Is L (code1) on screen
			OR	A
			JR	NZ, clipLine_M3		; NZ - L (code1) is codeout
			LD	A,B 			;  Z - H (code2) is codeout
;
; Calculate the deltas
;	
clipLine_M3:		PUSH	BC			; Stack code1 and code2
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
			PUSH	clipLine_Next		; Stack the return address
			SRL	C
			JR	C,clipTop
			SRL	C			
			JR	C,clipBottom
			SRL	C
			JR	C,clipRight
			JR	clipLeft
;
; Set up for next iteration
;
clipLine_Next:		POP	AF			; A: codeout, flag set from previous calculation
			POP	BC			; The codes
			JR	NZ, @M1 		; F: NZ if code1=codeout
;
; codeout = H (code2) at this point
;
			LD	(p2_x),DE
			LD	(p2_y),HL
			CALL	clipRegion
			LD	B,A			; B: code2
			JR	clipLine_L1
;
; codeout = L (code1) at this point
;
@M1:			LD	(p1_x),DE
			LD	(p1_y),HL
			CALL	clipRegion		
			LD 	C,A			; C: code1
			JR	clipLine_L1


; Clip a line against the top edge
; p1_x,y: The start point of the line to be clipped
; p2_x,y: The end point of the line to be clipped
; dx: p2_x - p1_x
; dy: p2_y - p1_y
; Returns:
; DE: X coordinate of clipped point
; HL: Y coordinate of clipped point
;
clipTop:		LD	HL,(dx)			; Do p1->x + fastMulDiv(dx, -p1->y, dy)
			LD	DE,(p1_y)
			LD	BC,(dy)
			CALL	negDE 
			CALL	fastMulDiv		; HL: fastMulDiv(dx, -p1->y, dy); 
			LD	DE,(p1_x)
			ADD	HL,DE 			; HL: p1_x +fastMulDiv(dx, -p1->y, dy)
			EX	DE,HL			; DE: X
			LD	HL,0			; HL: Y
			RET


; Clip a line against the left edge
; p1_x,y: The start point of the line to be clipped
; p2_x,y: The end point of the line to be clipped
; dx: p2_x - p1_x
; dy: p2_y - p1_y
; Returns:
; DE: X coordinate of clipped point
; HL: Y coordinate of clipped point
;
clipLeft:		LD	HL,(dy)			; Do p1->y + fastMulDiv(dy, -p1->x, dx)
			LD	DE,(p1_x)		
			LD	BC,(dx)
			CALL	negDE
			CALL	fastMulDiv
			LD	DE,(p1_y)
			ADD	HL,DE			; HL: Y
			LD	DE,0			; DE: X
			RET


; Clip a line against the bottom edge
; p1_x,y: The start point of the line to be clipped
; p2_x,y: The end point of the line to be clipped
; dx: p2_x - p1_x
; dy: p2_y - p1_y
; Returns:
; DE: X coordinate of clipped point
; HL: Y coordinate of clipped point
;
clipBottom:		LD	HL,191			; Do p1->x + fastMulDiv(dx, 191-p1->y, dy)
			LD	DE,(p1_y)
			OR	A
			SBC	HL,DE
			EX	DE,HL
			LD	HL,(dx)
			LD	BC,(dy)
			CALL	fastMulDiv
			LD	DE,(p1_x)
			ADD	HL,DE			; HL: X
			EX	DE,HL			; DE: X
			LD	HL,191			; HL: Y
			RET


; Clip a line against the right edge
; p1_x,y: The start point of the line to be clipped
; p2_x,y: The end point of the line to be clipped
; dx: p2_x - p1_x
; dy: p2_y - p1_y
; Returns:
; DE: X coordinate of clipped point
; HL: Y coordinate of clipped point
;
clipRight:		LD	HL,255			; Do p1->y + fastMulDiv(dy, 255-p1->x, dx)
			LD	DE,(p1_x)
			OR	A
			SBC	HL,DE
			EX	DE,HL
			LD	HL,(dy)
			LD	BC,(dx)
			CALL	fastMulDiv	
			LD	DE,(p1_y)
			ADD	HL,DE			; HL: Y
			LD	DE,255			; DE: X		
			RET