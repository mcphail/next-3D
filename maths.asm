    			SECTION KERNEL_CODE

    			INCLUDE "globals.inc"

			EXTERN	sin_table		; In ram.inc

; These are declared here
; https://github.com/z88dk/z88dk/tree/master/libsrc/_DEVELOPMENT/math/integer/z80n

			EXTERN	l_z80n_muls_32_16x16	; DEHL =   HL x DE
			EXTERN	l_divu_32_32x16		; DEHL = DEHL / BC

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

; extern int16_t fastSin(uint8_t a, int8_t m) __z88dk_callee;
; extern int16_t fastCos(uint8_t a, int8_t m) __z88dk_callee;
;
PUBLIC _fastSin
PUBLIC _fastCos

_fastSin:		POP	BC
			POP	DE			; D: Angle, E: Multiplier
			LD	A,D 			; A: Angle
			CALL	sin
			LD	L,A
			ADD	A,A			; Sign extend A to 16-bit value
			SBC	A,A
			LD	H,A
			PUSH	BC
			RET

_fastCos:		POP	BC
			POP	DE			; E: Angle, D: Multiplier
			LD	A,D 
			CALL	cos
			LD	L,A
			ADD	A,A			; Sign extend A to 16-bit value
			SBC	A,A
			LD	H,A
			PUSH	BC
			RET

; A=COS(A)*E/256
; A=SIN(A)*E/256
; 
cos:			ADD	A,64			; Cosine is a quarter revolution copy of the sin wave
sin:			LD	H,sin_table >> 8	; The sin table is a 128 byte table on a page boundary
			LD	L,A			; Index into the table
			RES	7,L			; It's only a 128 byte table, so clear the top bit
			LD 	D,(HL)			; Fetch the value from the sin table
			RLCA				; Get the sign of the angle
			LD	A,E			;  A: The multiplicand
			JR	C,sin_neg_angle		; Skip to the case where the sin angle is negative
;
sin_pos_angle:		AND	A			; The multiplicand is also positive
			JP	P,sin_mul_pos		; So return a positive result
			NEG				; Otherwise negate the multiplicand
			JR	sin_mul_neg		; And return a negative result
;	
sin_neg_angle:		AND	A			; The multiplicand is positive
			JP	P,sin_mul_neg 		; So return a negative result
			NEG 
			JR	sin_mul_pos		; Otherwise return a positive result
;
sin_mul_pos:		LD	E,A			; A = +(D*A/256)
			MUL	D,E
			LD	A,D 
			RET 
;
sin_mul_neg:		LD	E,A			; A = -(D*A/256)
			MUL	D,E 
			LD	A,D 
			NEG
			RET

; Trig rotation
; C = C*COS(A)-B*SIN(A)
; B = C*SIN(A)+B*COS(A)
;
angle:			DB	0
;
rotate:			LD	(angle),A		; Store the angle for calculations
			LD	E,B
			CALL	sin			; A: B*SIN(A)
			LD	(@M1+1),A 
			LD	A,(angle)			
			LD	E,C
			CALL	cos			; A: C*COS(A)
@M1:			SUB	A,0			; A: C*COS(A)-B*SIN(A)
			LD	(@M3+1),A
;
			LD	A,(angle)
			LD	E,B
			CALL	cos			; A: B*COS(A)
			LD	(@M1+2),A 
			LD	A,(angle)			
			LD	E,C
			CALL	sin			; A: C*SIN(A)
@M2:			ADD	A,0			; A: C*SIN(A)+B*COS(A)
			LD	B,A 
@M3:			LD	C,0
			RET 

; extern int16_t fastMulDiv(int16_t a, int16_t b, int16_t c) __z88dk_callee
; Calculates a * b / c, with the internal calculation done in 32-bits
;
PUBLIC _fastMulDiv, fastMulDiv

_fastMulDiv:		POP	IY
			POP	HL	; a
			POP	DE	; b
			POP	BC	; c
			PUSH	IY

; HL = HL * DE / BC
;
fastMulDiv:		PUSH	BC			; Save this somewhere
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