    			SECTION KERNEL_CODE

    			EXTERN DMAFill, scratchpad

    			INCLUDE "globals.inc"

screen_banks:		DB 0				; LSB: The visible screen
			DB 0				; MSB: The offscreen buffer

shapeT_X1:		EQU	scratchpad 
shapeT_X2:		EQU	scratchpad + $100

MIN			MACRO	P1			; Get min of P1 and A in A
			LOCAL 	S1
			CP 	P1			; Compare A with P1
			JR	C,S1			; Skip if P1 > A
			LD 	A,P1			; Assign P1 to A
S1:			
			ENDM

MAX			MACRO	P1			; Get max of P1 and A in A
			LOCAL	S1
			CP 	P1			; Compare A with P1
			JR 	NC,S1			; Skip if P1 > A
			LD 	A,P1			; Assign P1 to A
S1:			
			ENDM

DRAW_LINE_TABLE		MACRO	FLAG,PX1,PY1,PX2,PY2,TABLE
			LOCAL	S1
			LD A,(IY+FLAG)
			OR A
			JR Z,S1
			LD C,(IY+PX1)
			LD B,(IY+PY1)
			LD E,(IY+PX2)
			LD D,(IY+PY2)
			LD A,TABLE
			CALL lineT
S1:
			ENDM

; Shortcut to plot a circle quadrant
;
PLOT_CIRCLE_TABLE:	MACRO	TABLE, OPX, OPY
			LD H,TABLE >> 8
			LD A,B 				; Get the Y origin
			OPY IXH				; Add the Y coordinate
			LD L,A				; Store in L
			LD A,C 				; Get the X coordinate
			OPX IXL				; Add the X origin
			LD (HL), A			; Store in the table
			LD A,B				; Repeat the second quadrant
			OPY IXL
			LD L,A 
			LD A,C
			OPX IXH
			LD (HL),A
			ENDM


; void initL2(void)
; Initialises the Layer 2 Next screen mode into 256x192 256 colours in front of the ULA screen
; ============================================================================================
PUBLIC _initL2
_initL2:		LD	BC,$123B		; L2 Access Port
    			LD	A,%00000010		; Bit 1: Enable
    			OUT	(C),A		
			LD 	L,$12			; The initial visible screen (8K bank multiplier)
			LD 	H,$18			; The initial offscreen buffer (8K bank multiplier)
			LD 	(screen_banks),HL	; Initialise the paging register
			LD	A,L	
			SRL	A 			; Divide by 2 for 16K bank multiplier
			NEXTREG $12, A			; Display the visible screen 
    			RET


; void swapL2(void)
; Swap the screen banks round and page the visible one in
;
PUBLIC _swapL2
_swapL2:		LD	HL,(screen_banks)	; Swap the screen banks
			LD	A,H			; Get the current offscreen buffer 
			LD	H,L			; H: New offscreen buffer
			LD	L,A			; L: New visible buffer
			LD	(screen_banks), HL	
			SRL 	A 			; Divide by 2 for 16K bank multiplier
			NEXTREG $12, A			; Set the current visible buffer
			RET


; void clearL2(uint8 col) __z88dk_fastcall
; Clear the Layer 2 Next screen with a colour
;
PUBLIC _clearL2, clearL2

_clearL2:		LD 	E, L			; Get the colour from HL

;===========================================================================
; E = colour
;===========================================================================

clearL2:		LD      BC,$243B    		; Select NEXT register
			LD	A,MMU_REGISTER_0
			OUT     (C),A			; Read current bank register
			INC     B           		; $253b to access (read or write) value
			IN      A,(C)			; Get the current bank number
			PUSH	AF			; Save for later
			LD	A,(screen_banks+1)	; Get the offscreen screen bank
			LD	D,A 			; D: Offscreen bank
			LD 	B,6			; Number of banks to clear (6 x 8K = 48K for 256x192 L2)
;
@loop: 			PUSH	BC
			LD	A,D			; D: The bank to clear
			NEXTREG	MMU_REGISTER_0,a	; Page it in
			LD	HL,0
			LD 	BC,8192
			LD	A,E			; Get the colour 
			CALL	DMAFill			; Clear the screen
			POP	BC
			INC	D 			; Increment the bank number
			DJNZ	@loop 
			POP	AF 
			NEXTREG	MMU_REGISTER_0,A	; Restore the original bank number
			RET 

; Get pixel position
; Pages in the correct 16K Layer 2 screen bank into 0x0000
;   B: Y coordinate
;   C: X coordinate
; Returns:
;  HL: Address in memory (between 0x0000 and 0x3FFF)
;
get_pixel_address:	LD 	L,C 			; Set the X coordinate
get_pixel_address_y:	LD 	A,(screen_banks+1)	
			LD 	H,A			; H: Offscreen screen bank
			LD	A,B			; 0-31 per bank (8k)
			AND	%11100000		; 3 bits for the 8 banks we can use
			SWAPNIB
			RRCA
			ADD A, H			; Add the bank in
			NEXTREG MMU_REGISTER_0, A	; And set it
			LD	A,B
			AND	%00011111
			LD	H,A 
			RET 

; extern void plotL2(uint8_t xcoord, uint8_t ycoord, uint8_t colour) __z88dk_callee
; Generic plotting routine that can be called from C
; ========================================================================================
PUBLIC _plotL2, plotL2

_plotL2:		POP	HL			; Loads the stack value (sp) into hl for restoring later and moves variables into top of stack
   			POP	DE			; Loads next stack entry into e = x, d = y
   			DEC	SP			; Moves the stack up 1 byte, discarding a value and getting us to the third param, colour
   			EX	(SP), HL		; Restores the original value of the stack from hl, and puts the colour on h from the stack 
   			EX 	DE, HL      		; Put y and x into hl and the colour into d
    			LD 	IYL, D       		; Puts colour into iyl in order to free d for the drawline

;===========================================================================
;	HL = YX, IYL = colour -- IMPORTANT: DESTROYS H (and A)
;===========================================================================

plotL2:			LD	A,(screen_banks+1)	; Current offscreen bank
			LD	(plotL2_B+1),A		; Self-mod the plot
;
			LD 	A,H 			; 0-31 per bank (8k)
			AND 	%11100000		; 3 bits for the 8 banks we can use
			SWAPNIB
			RRCA
plotL2_B:		ADD 	A,0			; 8L bank for L2
			NEXTREG MMU_REGISTER_0,A  	; Set bank to write into
			LD 	A,H
			AND 	%00011111 	        ; This is our y (0-31)
			LD 	H,A 			; Puts y it back in h
    			LD 	A,IYL			; Loads colour from iyl into a
			LD 	(HL),A			; Draw our pixel
			RET

;===========================================================================
; This has no C calls and must be called from assembly!!!
;
;	HL = YX -- IMPORTANT: DESTROYS H (and A)
; We preset the colour and bank so we can use it directly
; by setting plotL2asm_colour and plotL2asm_bank with self-modifying code
;===========================================================================

PUBLIC	plotL2asm, plotL2asm_colour

plotL2asm:		LD	A,H 			; 0-31 per bank (8k)
			AND	%11100000		; 3 bits for the 8 banks we can use
			SWAPNIB
			RRCA				
plotL2asm_bank:		ADD 	A,0			; 8L bank for L2 (self-modded)
			NEXTREG MMU_REGISTER_0,A  	; Set bank to write into
			LD	A,H
			AND	%00011111		; This is our y (0-31)
			LD	H,A 			; Puts y it back in h
plotL2asm_colour:	LD 	(HL),0			; Draw our pixel (colour is going to be set by automodifying the code)
			RET    


; extern void lineL2(Point8 pt0, Point8 pt1, uintt8 colour) __z88dk_callee
; A Bresenham's line drawing catering for every type of line and direction, inspired by a bunch of Speccy algos online
; ====================================================================================================================
; Credits to Andy Dansby (https://github.com/andydansby/bresenham_torture_test/blob/main/bresenham_line3.asm)
; Credits to Dean Belfield (http://www.breakintoprogram.co.uk)
; Credits to Gabrield Gambetta's great book 'Computer Graphics From Scratch'
; Credits to Mike Flash Ware for helping optimise it!

PUBLIC _lineL2, lineL2, lineL2_NC

_lineL2:		POP	BC          		; Loads the stack value (sp) into bc for restoring later and moves variables into top of stack
    			POP	HL          		; Loads y1x1 into hl
    			POP	DE          		; Loads y2x2 into de
    			DEC	SP
    			POP	AF          		; Loads colour into A
    			PUSH	BC         		; Restores the stack value from bc

; Draw a line
; H,L: Y1,X1
; D,E: Y2,X2
;   A: Colour
;
lineL2:   		LD	(plotL2asm_colour+1),A	; Store the colour in plotL2asm through self-modifying the code
lineL2_NC:    		LD	A,(screen_banks+1)
    			LD	(plotL2asm_bank+1),A
    			LD	A,D             	; Loads y2 into a. We'll see if we need to swap coords to draw downwards
    			CP 	H               	; Compares y1 with y2
    			JR 	NC,lineL2_1  		; No need to swap the coords, jump
    			EX 	DE,HL           	; Swapped coordinates to ensure y2 > y1, so we draw downwards
;
lineL2_1:		LD	A,D             	; Loads y2 into a
    			SUB	H               	; y2 - y1
    			LD	B,A             	; b becomes deltay
    			LD	A,E             	; Loads x2 into a
    			SUB	L               	; x2 - x1, a now contains deltax
    			JR	C,lineL2_x1  		; If carry is set (x2 - x1 is negative) we are drawing right to left
    			LD	C,A             	; c becomes deltax
    			LD	A,0x2C          	; Replaces original code above to increase x1 as we're drawing left to right. 0x2C is inc l, and we modify the code to have this
    			JR	lineL2_x2     		; Skips next part of the code
lineL2_x1:		NEG                 		; deltax in a is negative, make it positive
    			LD	C,A             	; c becomes deltax
    			LD	A,0x2D          	; Replaces original code above to decrease x1 as we're drawing right to left. Self-modifying, puts dec l into the code
lineL2_x2:
    			LD	(lineL2_q1_m2), a	; a contains either inc l or dec l, and modifies the code accordingly
    			LD	(lineL2_q2_m2), a	; Same as above for verticalish lines
    			LD	A,B             	; We'll check if deltay (b) and deltax (ixl) are 0
    			OR	C                	; Checking...
    			JP	Z, plotL2asm		; When reaching zero, we're done, draw last pixel
;
; STATUS: b = deltay | c = deltax | d is free
; Find out what kind of diagonal we're dealing with, if horizontalish or verticalish
;
lineL2_q:         	LD	A,B             	; Loads deltay into a
    			CP 	C                	; Compares with deltax
    			JR	NC,lineL2_q2 		; If no cary, line is verticalish (or perfectly diagonal)			
lineL2_q1:		LD	A,C             	; a becomes deltax
    			LD	(lineL2_q1_m1+1), a 	; Self-modifying code: loads deltax onto the value of the opcode, in this case the loop
    			LD	C,B             	; c becomes deltay
    			LD	B,A             	; b becomes deltax for the loop counter
    			LD	E,B             	; e becomes deltax temporarily...
    			SRL	E               	; now e = deltax / 2 -- aka Bresenham's error
;
; Loop uses d as temp, hl bc e
;
lineL2_q1_l:		LD	D,H             	; OPTIMISE? Backs up h into d
    			CALL	plotL2asm 		; plotL2asm destroys h, so we need to preserve it
    			LD 	H,D            		; OPTIMISE? Restores h from d
    			LD	A,E             	; Loads Bresenham's error into a
    			SUB	C               	; error - deltay
    			LD	E,A            		; Stores new error value into e
    			JR	NC,lineL2_q1_m2  	; If there's no cary, jump
lineL2_q1_m1:		ADD	A,0            		; This 0 here will be modified by the self-modifying code above e = e + deltax
    			LD	E,A             	; Stores new error e = e + deltax back into e
    			INC	H               	; Increases line slope by adding to y1
lineL2_q1_m2:       	INC	L               	; Self-modified code: It will be either inc l or dec l depending on direction of horizontal drawing
lineL2_q1_s:         	DJNZ	lineL2_q1_l 		; Loops until line is drawn and zero flag set
    			JP	plotL2asm  	 	; This is the last pixel, draws and quits
;
; Here the line is verticalish or perfectly diagonal
;
lineL2_q2:           	LD	(lineL2_q2_m1+1),A 	; Self-modifies the code to store deltay in the loop
    			LD	E,B             	; e = deltay
    			SRL	E               	; e = deltay / 2 (Bressenham's error)
;
; Loop uses d as temp, hl bc e	
;
lineL2_q2_l:         	LD	D,H             	; OPTIMISE? Backs up h into d
    			CALL 	plotL2asm 		; plotL2asm destroys h, so we need to preserve it
    			LD	H,D             	; OPTIMISE? Restores h from d
    			LD	A,E             	; Adds deltax to the error
    			SUB	C               	; As above
    			JR	NC,lineL2_q2_s   	; If we don't get a carry, skip the next part
lineL2_q2_m1:		ADD	A,0            		; This is a target of self-modified code: e = e + deltax
lineL2_q2_m2:		INC	L               	; Self-modified code: It will be either inc l or dec l depending on direction of horizontal drawing
lineL2_q2_s:		LD	E,A             	; Restores the error value back in
    			INC	H               	; Increases y1
    			DJNZ	lineL2_q2_l 		; While zero flag not set, loop back to main loop
    			JP 	plotL2asm   		; This is the last pixel drawn, all done


;extern void triangleL2(Point8 pt0, Point8 pt1, Point8 pt2, uint8_t colour) __z88dk_callee;
; A triangle wireframe drawing routine, highly optimised (I hope!)
;=================================================================================================
PUBLIC _triangleL2, triangleL2

_triangleL2:		POP 	IY			; Pops SP into IY
			POP	BC			; Pops pt0.y and pt0.x into B,C
			POP	DE			; Pops pt1.y and pt1.x into D,E
			POP	HL			; Pops pt2.y and pt2.x into H,L
			DEC	SP
			POP	AF			; Pops colour value into A
			PUSH 	IY			; Restore the stack

; Draw a wireframe triangle
; BC: Point p1
; DE: Point p2
; HL: Point p3
;  A: colour
;
triangleL2:		LD 	(R0),BC			; Store the points
			LD	(R1),DE
			LD	(R2),HL		
			CALL	lineL2			; Draw DE to HL AND store the colour for subsquent lines
			LD	HL,(R0)
			LD	DE,(R1)
			CALL	lineL2_NC		; Draw BC to DE
			LD	HL,(R0)
			LD	DE,(R2)
			JP	lineL2_NC		; Draw BC to HL


;extern void triangleL2F(Point8 pt0, Point8 pt1, Point8 pt2, uint8_t colour) __z88dk_callee;
; A filled triangle drawing routine
;=================================================================================================
PUBLIC _triangleL2F, triangleL2F

_triangleL2F:		POP 	IY			; Pops SP into IY
			POP	BC			; Pops pt0.y and pt0.x into B,C
			POP	DE			; Pops pt1.y and pt1.x into D,E
			POP	HL			; Pops pt2.y and pt2.x into H,L
			DEC	SP
			POP	AF			; Pops colour value into A
			PUSH 	IY			; Restore the stack

; Draw a filled triangle
; BC: Point p1
; DE: Point p2
; HL: Point p3
;  A: Colour
;
triangleL2F:		EX	AF,AF'			; Store the colour in AF'
;
; Need to sort the points from top to bottom
;
; if B > D swap(BC,DE); // if (p1.y > p2.y) swap(p1, p2)
; if B > H swap(BC,HL); // if (p1.y > p3.y) swap(p1, p3)
; if D > H swap(DE,HL); // if (p2.y > p3.y) swap(p2, p3)
; 
			LD	A,D
			CP	B
			JR	NC,@M1
			LD	D,B
			LD	B,A
			LD	A,E
			LD	E,C
			LD	C,A
;
@M1:			LD	A,H
			CP	B
			JR	NC,@M2
			LD	H,B
			LD	B,A
			LD	A,L
			LD	L,C
			LD	C,A
;
@M2:			LD	A,H
			CP	D
			JR	NC,@M3 
			EX	DE,HL 
;
; The points are now ordered so that BC is the top point, DE is in the middle and HL is at the bottom
; We need to draw 3 lines
; From BC to DE, the first short line, in table 0
; From DE to HL, the second short line, in table 0
; From BC to HL, the long line, in table 1
;
@M3:			LD 	(R0),BC			; Store the points
			LD	(R1),DE
			LD	(R2),HL		
			XOR	A			; Draw line from BC to DE in table 0, already in registers
			CALL	lineT
			LD	BC,(R1)			; Draw line from DE to HL in table 0
			LD	DE,(R2)
			XOR	A
			CALL	lineT
			LD	BC,(R0)			; Draw line from BC to HL in table 1
			LD	DE,(R2)
			LD	A,1
			CALL	lineT
			LD	A,(R0+1)		; Get the top Y point
			LD	L,A 
			LD	A,(R2+1)		; And the bottom Y point
			SUB	L 
			RET	Z			; 
			LD	B,A			; B: The height
			EX	AF,AF'			; The colour from AF'
			JP 	drawShapeTable		; Draw the shape


; extern void circleL2F(Point8 pt0, uint16 radius, uint8 colour) __z88dk_callee;
; A filled circle drawing routine
;=================================================================================================
PUBLIC _circleL2F, circleL2F

_circleL2F:		POP 	IY			; Pops SP into IY
			POP 	BC			; The origin
			POP 	HL 			; The radius
			LD 	D,L 
			DEC	SP
			POP	AF			; Pops colour value into A
			PUSH 	IY			; Restore the stack
			PUSH 	IX
			CALL 	circleL2F
			POP 	IX 
			RET

; Draw a filled circle
; B = Y pixel position of circle centre
; C = X pixel position of circle centre
; D = Radius of circle
; A = Colour
;
circleL2F:		PUSH AF				; Store the colour
			LD A,D
			PUSH AF
			CALL circleT
			POP AF				; A = radius
			EXX				; BC' = YX origin
			LD C,A				; C = radius
			LD A, B				; Get the origin
			SUB C				; Subtract the radius
			JR NC, @M1			; Skip next bit if OK
			XOR A				; Set to zero if off top of screen
@M1:			LD L,A 				; Store in L
			LD A,B				; Get the origin
			ADD C				; Add the radius
			CP 192 				; Check bottom screen boundary
			JR C,@M2			; If off bottom then
			LD A,191			; Crop to 191
@M2:			SUB L 				; Subtract the top
			INC A				; Because height = bottom - top + 1
			LD B,A				; Store in B
			POP AF
			JP drawShapeTable		; Draw the table


; extern void lineT(Point8 pt0, Point8 pt1, uint8_t table) __z88dk_callee
;
PUBLIC _lineT, lineT

_lineT:			POP 	HL
			POP 	BC         		; Loads y1x1 into BC
			POP 	DE          		; Loads y2x2 into DE
			DEC	SP			; Correct the stack address for single byte
			POP	AF			; A: table
			PUSH 	HL

; Draw a line into the shape table
; Assume the line is always being drawn downwards
; A = table (0 or 1)
; B = Y pixel position 1
; C = X pixel position 1
; D = Y pixel position 2
; E = X pixel position 2
;
lineT:			ADD A,shapeT_X1 >> 8		; Select the correct table
			LD H, A
			LD L, B				; Y address -> index of table	
			LD A, C				; X address
			PUSH AF				; Stack the X address	
			LD A, D				; Calculate the line height in B
			SUB B
			LD B, A 
			LD A, E				; Calculate the line width
			SUB C 
			JR C, @L1
; 
; This bit of code mods the main loop for drawing left to right
;
			LD C, A				; Store the line width
			LD A,0x14			; Opcode for INC D
			JR  @L2
;
; This bit of code mods the main loop for drawing right to left
;
@L1:			NEG
			LD C,A
			LD A,0x15			; Opcode for DEC D
;
; We've got the basic information at this point
;
@L2:			LD (lineT_Q1_M2), A		; Code for INC D or DEC D
			LD (lineT_Q2_M2), A
			POP AF				; Pop the X address
			LD D, A				; And store in the D register
			LD A, B				; Check if B and C are 0
			OR C 
			JR NZ, lineT_Q			; There is a line to draw, so skip to the next bit
			LD (HL), D 			; Otherwise just plot the point into the table
			RET
;			
; At this point
; HL = Table address
;  B = Line height
;  C = Line width
;  D = X Position
;
lineT_Q:		LD A,B				; Work out which diagonal we are on
			CP C
			JR NC,lineT_Q2
;
; This bit of code draws the line where B<C (more horizontal than vertical)
;
lineT_Q1:		LD A,C
			LD (lineT_Q1_M1+1), A		; Self-mod the code to store the line width
			LD C,B
			LD B,A
			LD E,B				; Calculate the error value
			SRL E
lineT_Q1_L1:		LD A,E
			SUB C
			LD E,A
			JR NC,lineT_Q1_M2
lineT_Q1_M1:		ADD A,0				; Add the line height (self modifying code)
			LD E,A
			LD (HL),D			; Store the X position
			INC L				; Go to next pixel position down
lineT_Q1_M2:		INC D				; Increment or decrement the X coordinate (self-modding code)
			DJNZ lineT_Q1_L1		; Loop until the line is drawn
			LD (HL),D
			RET
;
; This bit draws the line where B>=C (more vertical than horizontal, or diagonal)
;
lineT_Q2:		LD (lineT_Q2_M1+1), A		; Self-mod the code to store the line width
			LD E,B				; Calculate the error value
			SRL E
lineT_Q2_L1:		LD (HL),D			; Store the X position
			LD A,E				; Get the error value
			SUB C				; Add the line length to it (X2-X1)
			JR NC,lineT_Q2_L2		; Skip the next bit if we don't get a carry
lineT_Q2_M1: 		ADD A,0				; Add the line height (self modifying code)
lineT_Q2_M2:		INC D				; Increment or decrement the X coordinate (self-modding code)
lineT_Q2_L2:		LD E,A				; Store the error value back in
			INC L				; And also move down
			DJNZ lineT_Q2_L1
			LD (HL),D
			RET	

; Draw a circle in the shape table
; B = Y pixel position of circle centre
; C = X pixel position of circle centre
; A = Radius of circle
;
circleT:		AND A				
			RET Z 

			PUSH BC 			; Get BC in BC'
			EXX 
			POP BC 

			LD IXH,A			; IXH = Y
			LD IXL,0			; IXL = X
;
; Calculate BC (D2) = 3-(R*2)
;
			LD H,0				; HL = R
			LD L,A
			ADD HL,HL			; HL = R*2
			EX DE,HL			; DE = R*2
			LD HL,3
			AND A
			SBC HL,DE			; HL = 3-(R*2)
			LD B,H
			LD C,L
;
; Calculate HL (Delta) = 1-R
;
			LD HL,1
			LD D,0
			LD E,IXL
			AND A
			SBC HL,DE			; HL = 1 - CR
;
; SET DE (D1) = 1
;
			LD DE,1
;
; The circle loop
; First plot all the octants
; B' = Y origin
; C' = X origin
;
@L1:			EXX				; Plot the circle quadrants
			PLOT_CIRCLE_TABLE shapeT_X1, ADD, ADD
			PLOT_CIRCLE_TABLE shapeT_X2, SUB, ADD
			PLOT_CIRCLE_TABLE shapeT_X1, ADD, SUB
			PLOT_CIRCLE_TABLE shapeT_X2, SUB, SUB
			EXX
;
; Now calculate the next point
;
			LD A,IXH			; Get Y in A
			CP IXL				; Compare with X
			RET C				; Return if X>Y
			LD A,2				; Used for additions later
			BIT 7,H				; Check for Hl<=0
			JR Z,@M1
			ADD HL,DE			; Delta=Delta+D1
			JR @M2 
@M1:			ADD HL,BC			; Delta=Delta+D2
			ADD BC,A 
			DEC IXH				; Y=Y-1
@M2:			ADD BC,A
			ADD DE,A
			INC IXL				; X=X+1
			JR @L1

; extern void drawShapeTable(uint8_t y, uint8_t h, uint8 colour) __z88dk_callee
;
PUBLIC _drawShapeTable, drawShapeTable

_drawShapeTable:	POP	IY
			POP	BC			; C: y, B: h 
			DEC	SP			; Correct the stack address for single byte
			POP	AF			; A: colour
			LD	L,C
			PUSH	IY

; Draw the contents of the shape tables
; L: Start Y position
; B: Height
; A: Colour
;
drawShapeTable:		LD (draw_horz_line_colour),A	; Store the colour
			LD A,(screen_banks+1)		; Self-mod the screen bank in for performance
			LD (drawShapeTable_B+1),A
			LD C,L 				; Store the Y position in C
			CALL drawShapeTable_A		; Do the initial banking
drawShapeTable_L:	PUSH BC				; Stack the loop counter (B) and Y coordinate (C)
			LD H, shapeT_X1 >> 8		; Get the MSB table in H - HL is now a pointer in that table
			LD L,C  			; The Y coordinate
			LD D,(HL)			; Get X1 from the first table
			INC H				; Increment H to the second table (they're a page apart)
			LD E,(HL) 			; Get X2 from the second table
			LD H,A				; H: Screen addreess MSB
			EX AF,AF'			; Preserve screen address
			CALL draw_horz_line		; Draw the line
			EX AF,AF'			; Restore screen address
			POP BC 				; Pop loop counter (B) and Y coordinate (C) off the stack
			INC C				; Increase the row number
			INC A 				; Increment the screen address
	 		CP %00100000			; Check if we've gone onto the next bank
			CALL Z,drawShapeTable_A		; If so, do the banking and update H
			DJNZ drawShapeTable_L
			RET
;
; This routine pages in the correct bank at address $0000 (over the ROM, but for write only)
; Returns:
; A: MSB of screen address
;
drawShapeTable_A:	LD A,C				; A: Y coordinate
			AND %11100000			; 3 bits for the 8 banks we can use
			SWAPNIB
			RRCA
drawShapeTable_B:	ADD A,0				; Add the bank in (self-modded at top of routine)
			NEXTREG MMU_REGISTER_0,A	; And set it
			LD A,C				; A: Y coordinate
			AND %00011111
			RET

; Draw Horizontal Line routine
; HL = Screen address (first character row)
; D = X pixel position 1
; E = X pixel position 2
;
draw_horz_line:		LD A,E				; Check if E > D
			SUB D 
			JR NC,@S1			; If > then just draw the line
			NEG
			LD L,E 				; The second point is the start point
			JR @S2				; Skip to carry on drawing the line
@S1:			LD L,D 				; The first point is the start point
@S2:			JR Z,@M1			; If it is a single point, then just plot it
			LD (draw_horz_line_dst),HL	; HL: The destination address
			LD B,0				
			LD C,A 				; BC: The line length in pixels - 1
			CP 16				; Check if less than 16
			JR C,@M2			; It's quicker to LDIR fill short lines
;
; Now just DMA it (377 T-states)
;
			INC BC				; T:   6
			LD (draw_horz_line_len),BC 	; T:  20 - Now just DMA it
			LD HL,draw_horz_line_dma	; T:  10
			LD BC,draw_horz_line_dma_len	; T:  10
			OTIR 				; T: 331 (21 x 15 + 16)
			RET 
;
; Plot a single point
; 
@M1:			LD A,(draw_horz_line_colour)	; Shortcut to plot a single point
			LD (HL),A
			RET
;
; LDIR fill short lines (34 T-states to set up, plus the LDIR)
; Only worth doing if less than 377 T states (15 pixels long), otherwise do DMA
; - 15 pixels = 365
; - 16 pixels = 386
;
@M2:			LD A,(draw_horz_line_colour)	; T:  13
			LD D,H				; T:   4
			LD E,L				; T:   4
			INC DE 				; T:   6
			LD (HL),A			; T:   7
			LDIR				; T: 331 (21 x 15 + 16)
			RET


draw_horz_line_colour:	DB	0			; Storage for the DMA value to fill with
draw_horz_line_dma:	DB	$83			; R6-Disable DMA
			DB	%01111101		; R0-Transfer mode, A -> B, write address
			DW	draw_horz_line_colour	; Address of the fill byte
draw_horz_line_len:	DW	0			; Number of bytes to fill
;			DB	%00100100		; R0-Block length, A->B
			DB	%00010000		; R1-Port A address incrementing
			DB	%10101101		; R4-Continuous mode
draw_horz_line_dst:	DW	0			; Destination address
			DB	$CF			; R6-Load	
			DB	$87			; R6-Enable DMA

			DC 	draw_horz_line_dma_len = (ASMPC - draw_horz_line_dma) * 256 + Z80DMAPORT