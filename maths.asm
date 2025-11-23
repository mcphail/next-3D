;
; Title:	Fast 3D Maths Routines
; Author:	Dean Belfield
; Created:	20/08/2025
; Last Updated:	22/11/2025
;
; Modinfo:
; 20/11/2025:		Added fastDiv16
; 21/11/2025		Improved performance of project3D
; 22/11/2025:		Refactored multiply and divide routines 
;

    			SECTION KERNEL_CODE

    			INCLUDE "globals.inc"

			EXTERN	sin_table		; In ram.inc
			EXTERN	div_table		; In ram.inc

; These are declared here
; https://github.com/z88dk/z88dk/tree/master/libsrc/_DEVELOPMENT/math/integer/z80n

			EXTERN	l_z80n_muls_32_16x16	; DEHL =   HL x DE (signed)
			EXTERN	l_z80n_mulu_24_16x8	;  AHL =    E x HL (unsigned)
			EXTERN	l_divu_32_32x16		; DEHL = DEHL / BC (unsigned)

			PUBLIC	_pd			; int pd

			PUBLIC	sin8		
			PUBLIC	cos8		
			PUBLIC	sin16		
			PUBLIC	cos16		
			PUBLIC	negHL	
			PUBLIC	negDE	
			PUBLIC	negBC	
			PUBLIC 	negDEHL

			PUBLIC	muldivs16_16x16
			PUBLIC	muldivs32_16x16

			PUBLIC	muls16_16x16
			PUBLIC	mulu16_16x16
			PUBLIC	divs16_16x16
			PUBLIC 	divu16_16x16

_pd:			DW	256			; Perspective distance

; Negates HL
;
PUBLIC	negHL

negHL: 			XOR 	A	
			SUB	L 
			LD 	L,A
			SBC	A,A
			SUB	H
			LD	H,A
			RET 

; Negates DE
;
PUBLIC	negDE

negDE:			XOR 	A	
			SUB	E
			LD 	E,A
			SBC	A,A
			SUB	D
			LD	D,A
			RET

; Negates BC
;
PUBLIC	negBC 

negBC:			XOR 	A
			SUB	C 
			LD 	C,A
			SBC	A,A
			SUB	B
			LD	B,A
			RET

; Negates DEHL
;
negDEHL:		LD A,L	
			CPL
			LD L,A
			LD A,H
			CPL
			LD H,A
			LD A,E
			CPL
			LD E,A
			LD A,D
			CPL
			LD D,A
			INC L
			RET NZ
			INC H
			RET NZ
			INC DE
			RET

; 8-bit unsigned quick multiply, with divide by 256
; Returns A=(B*C)/256
;
MUL8_DIV256:		EX	DE,HL
			LD 	D,B
			LD	E,C
			MUL	D,E
			LD	A,D
			EX	DE,HL
			RET

; extern int8_t fastSin8(uint8_t a, int8_t m) __z88dk_callee;
; extern int8_t fastCos8(uint8_t a, int8_t m) __z88dk_callee;
;
PUBLIC _fastSin8
PUBLIC _fastCos8

_fastSin8:		POP	BC
			POP	DE			; D: Angle, E: Multiplier
			LD	A,D 			; A: Angle
			CALL	sin8
			LD	L,A
			PUSH	BC
			RET

_fastCos8:		POP	BC
			POP	DE			; D: Angle, E: Multiplier
			LD	A,D 
			CALL	cos8
			LD	L,A
			PUSH	BC
			RET

; A=COS(A)*E/256
; A=SIN(A)*E/256
; 
cos8:			ADD	A,64			; Cosine is a quarter revolution copy of the sin wave
sin8:			LD	H,sin_table >> 8	; The sin table is a 128 byte table on a page boundary
			LD	L,A			; Index into the table
			RES	7,L			; It's only a 128 byte table, so clear the top bit
			LD 	D,(HL)			; Fetch the value from the sin table
			RLCA				; Get the sign of the angle
			LD	A,E			;  A: The multiplicand
			JR	C,sin8_neg_angle		; Skip to the case where the sin angle is negative
;
sin8_pos_angle:		AND	A			; The multiplicand is also positive
			JP	P,sin8_mul_pos		; So return a positive result
			NEG				; Otherwise negate the multiplicand
			JR	sin8_mul_neg		; And return a negative result
;	
sin8_neg_angle:		AND	A			; The multiplicand is positive
			JP	P,sin8_mul_neg 		; So return a negative result
			NEG 				; Otherwise negate the multiplicand
			JR	sin8_mul_pos		; And return a positive result
;
sin8_mul_pos:		LD	E,A			; A = +(D*A/256)
			MUL	D,E
			LD	A,D 
			RET 
;
sin8_mul_neg:		LD	E,A			; A = -(D*A/256)
			MUL	D,E 
			LD	A,D 
			NEG
			RET

; extern int16_t fastSin16(uint8_t a, int16_t m);
; extern int16_t fastCos16(uint8_t a, int16_t m);
;
PUBLIC _fastSin16
PUBLIC _fastCos16

_fastSin16:		LD	HL,2
			ADD	HL,SP			; Skip over return address
			LD	A,(HL)			;  A: Angle
			INC	HL
			LD	E,(HL)
			INC	HL
			LD	D,(HL)			; DE: Multiplier
			JR	sin16 

_fastCos16:		LD	HL,2
			ADD	HL,SP			; Skip over return address
			LD	A,(HL)			;  A: Angle
			INC	HL
			LD	E,(HL)
			INC	HL
			LD	D,(HL)			; DE: Multiplier
			JR	cos16 

; HL=COS(A)*DE/256
; HL=SIN(A)*DE/256
; 
cos16:			ADD	A,64			; Cosine is a quarter revolution copy of the sin wave
sin16:			LD	H,sin_table >> 8	; The sin table is a 128 byte table on a page boundary
			LD	L,A			; Index into the table
			RES	7,L			; It's only a 128 byte table, so clear the top bit
			LD	L,(HL)			; Fetch the value from the sin table
			RLCA				; Get the sign of the angle
			LD	A,D			;  A: High byte of the multiplicand
			JR	C,sin16_neg_angle	; Skip to the case where the sin angle is negative
;
sin16_pos_angle:	AND	A			; The multiplicand is also positive
			JP	P,sin16_mul_pos		; So return a positive result
			CALL	negDE			; Otherwise negate the multiplicand
			JR	sin16_mul_neg		; And return a negative result
;	
sin16_neg_angle:	AND	A			; The multiplicand is positive
			JP	P,sin16_mul_neg 	; So return a negative result
			CALL	negDE			; Otherwise negate the multiplicand
			JR	sin16_mul_pos		; And return a positive result
;
sin16_mul_pos:		EX	DE,HL
			CALL	l_z80n_mulu_24_16x8	; AHL = E x HL
			LD	L,H			; Divide by 256
			LD	H,A
			RET 
;
sin16_mul_neg:		EX	DE,HL
			CALL	l_z80n_mulu_24_16x8	; AHL = E x HL
			LD	L,H 			; Divide by 256
			LD	H,A 
			JP	negHL


; extern int16_t muldivs32_16x16(int16_t a, int16_t b, int16_t c) __z88dk_callee
; Calculates a * b / c, with the internal calculation done in 32-bits
;
PUBLIC _muldivs32_16x16, muldivs32_16x16

_muldivs32_16x16:	POP	IY
			POP	HL	; a
			POP	DE	; b
			POP	BC	; c
			PUSH	IY

; HL = HL * DE / BC
;
muldivs32_16x16:	PUSH	BC			; Save this somewhere
			CALL 	l_z80n_muls_32_16x16	; DEHL: 32-bit signed product
			POP	BC
			LD	A,B			; Get the sign 
			XOR	D 
			PUSH 	AF
			BIT	7,D			; Is DEHL negative?
			CALL	NZ,negDEHL		; Yes, so make it positive
			BIT 	7,B			; Is BC negative?
			CALL	NZ,negBC		; Yes, so make it positive
			CALL	l_divu_32_32x16	
			POP 	AF
			RET	P 			; Answer is positive
			JP	negHL			; Answer is negative so negate it 

; extern int16_t muldivs16_16x16(int16_t a, int16_t b, int16_t c) __z88dk_callee
; Calculates a * b / c, with the internal calculation done in 16-bits
;
PUBLIC _muldivs16_16x16, muldivs16_16x16

_muldivs16_16x16:	POP	IY
			POP	HL	; a
			POP	DE	; b
			POP	BC	; c
			PUSH	IY

; HL = HL * DE / BC
;
muldivs16_16x16:	LD	A,H
			XOR	D
			XOR	B
			PUSH	AF 			; Work out the final sign
			BIT	7,H			; Make all the operands positve
			CALL	NZ,negHL
			BIT	7,D
			CALL	NZ,negDE
			BIT 	7,B
			CALL	NZ,negBC
			PUSH	BC			; BC: Save the divisor
			CALL	mulu16_16x16		; HL: 16-bit product (HL*DE)
			POP	DE			; DE: The divisor
			CALL	divu16_16x16		; HL: HL*DE/BC
			POP	AF			;  F: The sign
			RET	P 			; Answer is positive
			JP	negHL		

; extern uint16_t mulu16_16x16(uint16_t a, uint16_t b) __z88dk_callee;
; Calculates a * b (unsigned)
;
PUBLIC _mulu16_16x16, mulu16_16x16

_mulu16_16x16:		POP	IY
			POP	HL
			POP	DE
			PUSH	IY

; HL: Multiplicand
; DE: Multiplier
; Returns
; HL: Result (HL*DE)
;
mulu16_16x16:		LD	A,D
			LD	D,H
			LD	H,A
			LD	C,E
			LD	B,L
			MUL	D,E
			EX	DE,HL		; HL: H*E
			MUL	D,E		; DE: D*L
			ADD	HL,DE		; HL: H*E+D*L - Adding the cross products
			LD	E,C
			LD	D,B
			MUL	D,E		; DE: E*L
			LD	A,L		;  A: Cross product LSB
			ADD	A,D
			LD	H,A
			LD	L,E
			RET 

; extern int16_t muls16_16x16(int16_t a, int16_t b) __z88dk_callee;
; Calculates a * b (signed)
;
PUBLIC _muls16_16x16, muls16_16x16

_muls16_16x16:		POP	IY
			POP	HL
			POP	DE
			PUSH	IY

; HL: Multiplicand
; DE: Multiplier
; Returns
; HL: Result (HL*DE)
;
muls16_16x16:		LD	A,H
			XOR	D
			PUSH	AF
			BIT	7,H
			CALL	NZ,negHL
			BIT	7,D
			CALL	NZ,negDE
			CALL	mulu16_16x16
			POP	AF
			RET	P
			JP	negHL

; extern uint16_t divu16_16x16(uint16_t a, uint16_t b) __z88dk_callee;
; Calculates an estimate of a / b (unsigned)
; Inspired by https://blog.segger.com/algorithms-for-division-part-3-using-multiplication/
;
PUBLIC _divu16_16x16, divu16_16x16

_divu16_16x16:		POP	IY
			POP	HL		; HL: Dividend
			POP	DE		; DE: Divisor
			PUSH	IY

; HL: Dividend
; DE: Divisor
; Returns:
; HL: The result (HL/DEV)
;
divu16_16x16:		LD	A,D		; Check for divide by zero
			OR	E
			RET	Z
			EX	DE,HL		; Swap the dividend and divisor
			LD	A,15		; The bit counter
@L1:			BIT	7,H		; Check high byte of HL
			JR	NZ,@S1	
			ADD	HL,HL		; Normalise HL by shifting it right
			DEC	A		; Increment the bit counter
			JR	@L1	
@S1:			EX	AF,AF		; Store the bit counter for later
;
; Look up the reciprocal in the table
;
			LD	A,H		; A = HL >> 8
			ADD	A,A		; Now index into the table
			LD	L,A
			LD	H,div_table >> 8
			LD	A,(HL)
			INC	L
			LD	H,(HL)
;			LD	L,A 		; Not needed, use A instead of L in next block
;
; Modified from l_z80n_mulu_32_16x16 in z88dk
;		
			LD	B,A		; x0 - was originally LD B,L
			ld	C,E		; y0
			ld	E,A		; x0 - was originally LD E,L
			ld	L,D
			PUSH	HL		; x1 y1
			LD	L,C		; y0
			MUL	DE		; y1*x0
			EX	DE,HL
			MUL	DE		; x1*y0
			XOR	A	
			ADD	HL,DE		; sum cross products p2 p1
			ADC	A,A		; capture carry p3
			LD	E,C		; x0
			ld	D,B		; y0
			MUL	DE		; y0*x0
			LD	B,A		; carry from cross products
			LD	C,H		; LSB of MSW from cross products
			LD	A,D
			ADD	A,L
			LD	H,A
			LD	L,E		; LSW in HL p1 p0
			POP	DE
			MUL	DE		; x1*y1
			EX	DE,HL
			ADC	HL,BC
			EX	DE,HL		; DE = final MSW
			EX	AF,AF		; The bit counter
			LD	B,A
			BSRL 	DE,B		; Undo the normalisation by shifting right B times
			EX	DE,HL
			RET

; extern int16_t divs16_16x16(int16_t a, int16_t b) __z88dk_callee;
; Calculates an estimate of a / b (signed)
;
PUBLIC _divs16_16x16, divs16_16x16

_divs16_16x16:		POP	IY
			POP	HL		; HL: Dividend
			POP	DE		; DE: Divisor
			PUSH	IY

; HL: Dividend
; DE: Divisor
; Returns:
; HL: The result (HL/DEV)
;
divs16_16x16:		LD	A,H
			XOR	D
			PUSH	AF
			BIT	7,H
			CALL	NZ,negHL
			BIT	7,D
			CALL	NZ,negDE
			CALL	divu16_16x16
			POP	AF
			RET	P
			JP	negHL
