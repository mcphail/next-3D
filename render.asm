    			SECTION KERNEL_CODE

    			EXTERN DMAFill, Scratchpad

    			INCLUDE "globals.inc"

shape_buffer:		DS 15				; For up to 3 x/y pairs of coordinates and a flag
screen_banks:		DB 0				; LSB: The visible screen
			DB 0				; MSB: The offscreen buffer

shapeT_X1:		EQU	Scratchpad 
shapeT_X2:		EQU	Scratchpad + $100

			PUBLIC	shape_buffer
 
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

DRAW_LINE_TABLE		MACRO	FLAG,PX1,PY1,PX2,PY2
			LOCAL	S1
			LD A,(IY+FLAG)
			OR A
			JR Z,S1
			LD C,(IY+PX1)
			LD B,(IY+PY1)
			LD E,(IY+PX2)
			LD D,(IY+PY2)
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

; extern void stop(void)
; A debugging tool. Jump here (jp _stop) from your code so you can stop and inspect registers etc.
; ============================================================================================
PUBLIC _stop
_stop:			JP _stop
    

; extern void test(void)
; A debugging tool. Used for testing asm functions
; ============================================================================================
PUBLIC _test

_test:	
			RET


; extern void setCPU(uint8 speed) __z88dk_fastcall
; Sets the Next CPU to maximum speed, 28MHz
; ===========================================================================================
PUBLIC _setCPU

_setCPU:		LD	A,L
			NEXTREG 07h,A           ; Set CPU speed
    			RET


; void initL2(void)
; Initialises the Layer 2 Next screen mode into 256x192 256 colours in front of the ULA screen
; ============================================================================================
PUBLIC _initL2
_initL2:		LD BC, $123B		; L2 Access Port
    			LD A, %00000010		; Bit 1: Enable
    			OUT (C), A	
			LD L, $12		; The initial visible screen (8K bank multiplier)
			LD H, $18		; The initial offscreen buffer (8K bank multiplier)
			LD (screen_banks), HL	; Initialise the paging register
			LD A,L
			SRL A 			; Divide by 2 for 16K bank multiplier
			NEXTREG $12, A		; Display the visible screen 
    			RET


; void swapL2(void)
; Swap the screen banks round and page the visible one in
;
PUBLIC _swapL2
_swapL2:		LD HL,(screen_banks)	; Swap the screen banks
			LD A,H			; Get the current offscreen buffer 
			LD H,L			; H: New offscreen buffer
			LD L,A			; L: New visible buffer
			LD (screen_banks), HL
			SRL A 			; Divide by 2 for 16K bank multiplier
			NEXTREG $12, A		; Set the current visible buffer
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

; extern void PlotPixel8K(uint8_t xcoord, uint8_t ycoord, uint8_t colour) __z88dk_callee
; Generic plotting routine that can be called from C
; ========================================================================================
PUBLIC _PlotPixel8K, PlotPixel8K
_PlotPixel8K:
    	
   	pop hl          ; Loads the stack value (sp) into hl for restoring later and moves variables into top of stack
   	pop de          ; Loads next stack entry into e = x, d = y
   	dec sp          ; Moves the stack up 1 byte, discarding a value and getting us to the third param, colour
   	ex (sp), hl     ; Restores the original value of the stack from hl, and puts the colour on h from the stack 
   	ex de, hl       ; Put y and x into hl and the colour into d
    	ld iyl, d       ; Puts colour into iyl in order to free d for the drawline

PlotPixel8K:
;===========================================================================
;	HL = YX, IYL = colour -- IMPORTANT: DESTROYS H (and A)
;===========================================================================

	LD A,(screen_banks+1)		; Current offscreen bank
	LD (PlotPixel8K_B+1),A		; Self-mod the plot
;
	ld a, h 			; 0-31 per bank (8k)
	and %11100000			; 3 bits for the 8 banks we can use
	swapnib
	rrca
PlotPixel8K_B:
	add a, 0			; 8L bank for L2
	nextreg MMU_REGISTER_0,a  	; Set bank to write into
	ld a, h
	and %00011111 		        ; This is our y (0-31)
	ld h, a 			; Puts y it back in h
    	ld a, iyl                   	; Loads colour from iyl into a
	ld (hl), a			; Draw our pixel
	ret


PlotPixel8KCol:
;===========================================================================
; This has no C calls and must be called from assembly!!!
;
;	HL = YX -- IMPORTANT: DESTROYS H (and A)
; We preset the colour and bank so we can use it directly
; by setting plotPixel8KColour and plotPixel8KBank with self-modifying code
;===========================================================================

	ld a, h 			; 0-31 per bank (8k)
	and %11100000			; 3 bits for the 8 banks we can use
	swapnib
	rrca
plotPixel8KBank:			; Set the bank to write into (self-modded)
	add a, 0			; 8L bank for L2
	nextreg MMU_REGISTER_0,a  	; Set bank to write into
	ld a, h
	and %00011111 		        ; This is our y (0-31)
	ld h, a 			; Puts y it back in h
plotPixel8KColour:	
    	ld (hl), 0			; Draw our pixel (colour is going to be set by automodifying the code)
	ret    


; extern void lineL2(Point8 pt0, Point8 pt1, uint16 colour) __z88dk_callee
; A Bresenham's line drawing catering for every type of line and direction, inspired by a bunch of Speccy algos online
; ====================================================================================================================
; Credits to Andy Dansby (https://github.com/andydansby/bresenham_torture_test/blob/main/bresenham_line3.asm)
; Credits to Dean Belfield (http://www.breakintoprogram.co.uk)
; Credits to Gabrield Gambetta's great book 'Computer Graphics From Scratch'
; Credits to Mike Flash Ware for helping optimise it!
PUBLIC _lineL2, lineL2

_lineL2:
; or, even better, set the colour in AF, and store that in the PlotPixel8KCol
    pop bc          ; Loads the stack value (sp) into bc for restoring later and moves variables into top of stack
    pop hl          ; Loads y1x1 into hl
    pop de          ; Loads y2x2 into de
    pop iy          ; Use iyl for the colour
    push bc         ; Restores the stack value from bc

lineL2:
;=========================================================================
;   HL = Y1X1, DE = Y2X2, IYL = colour
;=========================================================================
    ld a, iyl           ; Loads colour into a
    ld (plotPixel8KColour + 1), a ; Store the colour in the plotPixel8KColour through self-modifying the code
    ld a,(screen_banks+1)
    ld (plotPixel8KBank+1), a
    ld a, d             ; Loads y2 into a. We'll see if we need to swap coords to draw downwards
    cp h                ; Compares y1 with y2
    jr nc, draw_line_1  ; No need to swap the coords, jump
    ex de, hl           ; Swapped coordinates to ensure y2 > y1, so we draw downwards
draw_line_1:
    ld a, d             ; Loads y2 into a
    sub h               ; y2 - y1
    ld b, a             ; b becomes deltay
    ld a, e             ; Loads x2 into a
    sub l               ; x2 - x1, a now contains deltax
    jr c, draw_line_x1  ; If carry is set (x2 - x1 is negative) we are drawing right to left
    ld c, a             ; c becomes deltax
    ld a, 0x2C          ; Replaces original code above to increase x1 as we're drawing left to right. 0x2C is inc l, and we modify the code to have this
    jr draw_line_x2     ; Skips next part of the code
draw_line_x1:
    neg                 ; deltax in a is negative, make it positive
    ld c, a             ; c becomes deltax
    ld a, 0x2D          ; Replaces original code above to decrease x1 as we're drawing right to left. Self-modifying, puts dec l into the code
draw_line_x2:
    ld (draw_line_q1_m2), a ; a contains either inc l or dec l, and modifies the code accordingly
    ld (draw_line_q2_m2), a ; Same as above for verticalish lines
    ld a, b             ; We'll check if deltay (b) and deltax (ixl) are 0
    or c                ; Checking...
    jp z, PlotPixel8KCol    ; When reaching zero, we're done, draw last pixel
    ; STATUS: b = deltay | c = deltax | d is free
draw_line_q:            ; Find out what kind of diagonal we're dealing with, if horizontalish or verticalish
    ld a, b             ; Loads deltay into a
    cp c                ; Compares with deltax
    jr nc, draw_line_q2 ; If no cary, line is verticalish (or perfectly diagonal)
draw_line_q1:
    ld a, c             ; a becomes deltax
    ld (draw_line_q1_m1 + 1), a ; Self-modifying code: loads deltax onto the value of the opcode, in this case the loop
    ld c, b             ; c becomes deltay
    ld b, a             ; b becomes deltax for the loop counter
    ld e, b             ; e becomes deltax temporarily...
    srl e               ; now e = deltax / 2 -- aka Bresenham's error
; loop uses d as temp, hl bc e
draw_line_q1_l:
    ld d, h             ; OPTIMISE? Backs up h into d
    call PlotPixel8KCol ; PlotPixel8KCol destroys h, so we need to preserve it
    ld h, d             ; OPTIMISE? Restores h from d
    ld a, e             ; Loads Bresenham's error into a
    sub c               ; error - deltay
    ld e, a             ; Stores new error value into e
    jr nc, draw_line_q1_m2  ; If there's no cary, jump
draw_line_q1_m1:
    add a, 0            ; This 0 here will be modified by the self-modifying code above e = e + deltax
    ld e, a             ; Stores new error e = e + deltax back into e
    inc h               ; Increases line slope by adding to y1
draw_line_q1_m2:        ; This either increases or decreases l by the self modified code that targeted this
    inc l               ; Self-modified code: It will be either inc l or dec l depending on direction of horizontal drawing
draw_line_q1_s:         ; Tests to loop and keep drawing line
    djnz draw_line_q1_l ; Loops until line is drawn and zero flag set
    jp PlotPixel8KCol   ; This is the last pixel, draws and quits
draw_line_q2:           ; Here the line is verticalish or perfectly diagonal
    ld (draw_line_q2_m1 + 1), a ; Self-modifies the code to store deltay in the loop
    ld e, b             ; e = deltay
    srl e               ; e = deltay / 2 (Bressenham's error)
; loop uses d as temp, hl bc e
draw_line_q2_l:         ; The main drawline loop for this case
    ld d, h             ; OPTIMISE? Backs up h into d
    call PlotPixel8KCol ; PlotPixel8KCol destroys h, so we need to preserve it
    ld h, d             ; OPTIMISE? Restores h from d
    ld a, e             ; Adds deltax to the error
    sub c               ; As above
    jr nc, draw_line_q2_s   ; If we don't get a carry, skip the next part
draw_line_q2_m1:
    add a, 0            ; This is a target of self-modified code: e = e + deltax
draw_line_q2_m2:
    inc l               ; Self-modified code: It will be either inc l or dec l depending on direction of horizontal drawing
draw_line_q2_s:
    ld e, a             ; Restores the error value back in
    inc h               ; Increases y1
    djnz draw_line_q2_l ; While zero flag not set, loop back to main loop
    jp PlotPixel8KCol   ; This is the last pixel drawn, all done


;extern void triangleL2(Point8 pt0, Point8 pt1, Point8 pt2, uint8_t colour) __z88dk_callee;
; A triangle wireframe drawing routine, highly optimised (I hope!)
;=================================================================================================
PUBLIC _triangleL2, triangleL2

_triangleL2:		POP	BC
			POP	DE			; Pops pt0.y and pt0.x into DE
			POP	HL			; Pops pt1.y and pt1.x into HL
			LD	(shape_buffer+$01), DE	; 1st point of line 1
			LD	(shape_buffer+$03), HL	; 2nd point of line 1
			LD	(shape_buffer+$06), HL	; 1st point of line 2
			POP	HL			; Pops pt2.y and pt2.x into HL
			LD	(shape_buffer+$08), HL	; 2nd point of line 2
			LD	(shape_buffer+$0B), HL	; 1st point of line 3
			LD	(shape_buffer+$0D), DE	; 2nd point of line 3
			POP	HL			; Pops colour value into L
			LD	A,1			; Set all line flags for draw as this is the non-
			LD	(shape_buffer+$00),A	; clipped version of the line routine
			LD	(shape_buffer+$05),A
			LD	(shape_buffer+$0A),A
			LD	A,L
			PUSH	BC

; Draw a wireframe triangle
; A: colour
; Point data in shape_buffer, each line occupying 5 bytes:
; - flag: Draw this line? (0: don't draw, 1: draw)
; - x1y1: First point (two bytes)
; - x2y2: Second point (two bytes)
;
triangleL2:		LD	IYL,A			; Put the colour into IYL
			LD	A,(shape_buffer+$00)
			OR	A
			JR	Z,@M1
			LD	HL,(shape_buffer+$01)
			LD	DE,(shape_buffer+$03)
			CALL	lineL2
@M1:			LD	A,(shape_buffer+$05)
			OR	A
			JR	Z,@M2
			LD	HL,(shape_buffer+$06)
			LD	DE,(shape_buffer+$08)
			CALL	lineL2
@M2:			LD	A,(shape_buffer+$0A)
			OR	A
			RET	Z
			LD	HL,(shape_buffer+$0B)
			LD	DE,(shape_buffer+$0D)
			JP	lineL2


;extern void triangleL2F(Point8 pt0, Point8 pt1, Point8 pt2, uint8_t colour) __z88dk_callee;
; A filled triangle drawing routine
;=================================================================================================
PUBLIC _triangleL2F, triangleL2F

_triangleL2F:		POP 	BC			; Pops SP into BC
			POP	DE			; Pops pt0.y and pt0.x into DE
			POP	HL			; Pops pt1.y and pt1.x into HL
			LD	(shape_buffer+$01), DE	; 1st point of line 1
			LD	(shape_buffer+$03), HL	; 2nd point of line 1
			LD	(shape_buffer+$06), HL	; 1st point of line 2
			POP	HL			; Pops pt2.y and pt2.x into HL
			LD	(shape_buffer+$08), HL	; 2nd point of line 2
			LD	(shape_buffer+$0B), HL	; 1st point of line 3
			LD	(shape_buffer+$0D), DE	; 2nd point of line 3
			POP	HL			; Pops colour value into L
			LD	A,1			; Set all line flags for draw as this is the non-
			LD	(shape_buffer+$00),A	; clipped version of the line routine
			LD	(shape_buffer+$05),A
			LD	(shape_buffer+$0A),A
;
			LD A,L
			PUSH BC				; Restore the stack
			LD IY,shape_buffer

; Draw a filled triangle
; IY: Pointer to 6 bytes worth of coordinate data
; A: Colour
;
triangleL2F:		LD (triangleL2F_M1+1),A		; Store the colour
;
; Trivial reject if the polygon is off screen
;
			LD A,(IY+$0)			; If all the lines are flagged 0
			OR (IY+$5)			; then there is no polygon to draw
			OR (IY+$A)
			RET Z
;
			DRAW_LINE_TABLE $0,$1,$2,$3,$4	; Side 1
			DRAW_LINE_TABLE $5,$6,$7,$8,$9	; Side 2
			DRAW_LINE_TABLE $A,$B,$C,$D,$E	; Side 3
;
			LD A,(IY+$2)			; Get the min Y
			MIN  ((IY+$7))
			MIN  ((IY+$C))
			LD L,A				; Store in L
			LD A,(IY+$2)			; Get the max Y
			MAX  ((IY+$7))
			MAX  ((IY+$C))
			SUB L				; Subtract from L (the min)
			LD B,A				; Get the height
;
triangleL2F_M1:		LD A,0				; Get the colour
			RET Z
			JP drawShapeTable		; Only draw if not zero

; extern void circleL2F(Point8 pt0, uint16 radius, uint16 colour) __z88dk_callee;
; A filled circle drawing routine
;=================================================================================================
PUBLIC _circleL2F, circleL2F

_circleL2F:		POP IY				; Pops SP into IY
			POP BC				; The origin
			POP HL 				; The radius
			LD D,L 
			POP HL				; The colour
			LD A,L 
			PUSH IY				; Restore the stack
			PUSH IX
			CALL circleL2F
			POP IX 
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


; extern void lineT(Point8 pt0, Point8 pt1) __z88dk_callee
;
PUBLIC _lineT, lineT

_lineT:			POP HL
			POP BC          ; Loads y1x1 into BC
			POP DE          ; Loads y2x2 into DE
			PUSH HL

; Draw a line into the shape table
; B = Y pixel position 1
; C = X pixel position 1
; D = Y pixel position 2
; E = X pixel position 2
;
lineT:			LD H,shapeT_X1 >> 8		; Default to drawing in this table
			LD A,D				; Check whether we are going to be drawing up
			CP B
			JR NC, lineT_1
			INC H				; If we're drawing up, then draw in second table
			PUSH BC				; And use this neat trick to swaps BC and DE
			PUSH DE				; using the stack, forcing the line to be always
			POP BC				; drawn downwards
			POP DE

lineT_1:		LD L, B				; Y address -> index of table	
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

; extern void drawShapeTable(uint8_t y, uint8_t h, uint16 colour) __z88dk_callee
;
PUBLIC _drawShapeTable, drawShapeTable

_drawShapeTable:	POP	IY
			POP	BC			; C: y, B: h 
			POP	DE			; A: colour
			LD	A,E
			LD	L,C 
			PUSH	IY

; Draw the contents of the shape tables
; L: Start Y position
; B: Height
; A: Colour
;
drawShapeTable:		LD (drawShapeTable_C+1),A	; Store the colour
			LD A,(screen_banks+1)		; Self-mod the screen bank in for performance
			LD (drawShapeTable_B+1),A
			LD C,L 				; Store the Y position in C
drawShapeTable_L:	PUSH BC				; Stack the loop counter (B) and Y coordinate (C)
			LD H, shapeT_X1 >> 8		; Get the MSB table in H - HL is now a pointer in that table
			LD L,C  			; The Y coordinate
			LD D,(HL)			; Get X1 from the first table
			INC H				; Increment H to the second table (they're a page apart)
			LD E,(HL) 			; Get X2 from the second table
			LD A,L				; A: Y coordinate
			AND %11100000			; 3 bits for the 8 banks we can use
			SWAPNIB
			RRCA
drawShapeTable_B:	ADD A, 0			; Add the bank in (self-modded at top of routine)
			NEXTREG MMU_REGISTER_0, A	; And set it
			LD A,L
			AND %00011111
			LD H,A 				; H: The MSB of the screen address
drawShapeTable_C:	LD C,0				; The colour (self-modded)
			CALL draw_horz_line		; Draw the line
			POP BC 				; Pop loop counter (B) and Y coordinate (C) off the stack
			INC C 				; Go to the next line
			DJNZ drawShapeTable_L
			RET

; Draw Horizontal Line routine
; HL = Screen address (first character row)
; D = X pixel position 1
; E = X pixel position 2
; C = Colour
;
draw_horz_line:		LD A,E				; Check if E > D
			SUB D 
			JR NC,@S1			; If > then just draw the line
			NEG
			LD L,E 				; The second point is the start point
			JR @S2				; Skip to carry on drawing the line
@S1:			LD L,D 				; The first point is the start point
@S2:			LD B,A				; The horizontal length of the line
			INC B				; Line length is X2-X1+1
@L1:			LD (HL),C 			; Plot the point
			INC L				; Increment to next pixel
			DJNZ @L1			; And loop
			RET 	
