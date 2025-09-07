    			SECTION KERNEL_CODE

    			INCLUDE "globals.inc"

			EXTERN	sin_table		; In ram.inc

; These are declared here
; https://github.com/z88dk/z88dk/tree/master/libsrc/_DEVELOPMENT/math/integer/z80n

			EXTERN	l_z80n_muls_32_16x16	; DEHL =   HL x DE (signed)
			EXTERN	l_z80n_muls_16_16x8	;   HL =    L x DE (signed)
			EXTERN	l_z80n_mulu_16_16x8	;   HL =    L x DE (unsigned)
			EXTERN	l_z80n_mulu_24_16x8	;  AHL =    E x HL (unsigned)
			EXTERN	l_divu_32_32x16		; DEHL = DEHL / BC (unsigned)

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



; extern Point8_3D rotate8_X(Point8_3D p, uint8_t a) __z88dk_callee;
; This is an optimised version of this C routine
;
; Point8_3D r = {
;     p.x,
;     fastCos(p.y, a) - fastSin(p.z, a),
;     fastSin(p.y, a) + fastCos(p.z, a),
; };
; return r;
;
PUBLIC _rotate8_X

_rotate8_X:		POP	HL		; Pop the return address
			POP	IY		; Return data address
			POP	BC		; C: p.x, B: p.y
			POP	DE		; E: p.z, D: a
			PUSH	HL		; Stack the return address
			LD	(IY+0),C	; Set r.x
;			LD	B,B		; B: p.y
			LD	C,E		; C: p.z
			CALL	fastCMS8
			LD	(IY+1),A	; Set r.y
			CALL	fastSPC8	
			LD	(IY+2),A	; Set r.z
			RET 

; extern Point8_3D rotate8_Y(Point8_3D p, uint8_t a) __z88dk_callee;
; This is an optimised version of this C routine
;
; Point8_3D r2 = {
; 	fastCos(p.x, a) - fastSin(p.z, ay),
; 	p.y,
; 	fastSin(p.x, a) + fastCos(p.z, a),
; };
; return r;
;
PUBLIC _rotate8_Y

_rotate8_Y:		POP	HL		; Pop the return address
			POP	IY		; Return data address
			POP	BC		; C: p.x, B: p.y
			POP	DE		; E: p.z, D: a
			PUSH	HL		; Stack the return address
			LD	(IY+1),B	; Set r.y
			LD	B,C		; B: p.y
			LD	C,E		; C: p.z
			CALL	fastCMS8
			LD	(IY+0),A	; Set r.x
			CALL	fastSPC8
			LD	(IY+2),A	; Set r.z
			RET 

; extern Point8_3D rotate8_Z(Point8_3D p, uint8_t a) __z88dk_callee;
; This is an optimised version of this C routine
;
; Point8_3D r = {
;     fastCos(p.x, a) - fastSin(p.y, a),
;     fastSin(p.x, a) + fastCos(p.y, a),
;     p.z,	
; };
; return r;
;
PUBLIC _rotate8_Z

_rotate8_Z:		POP	HL		; Pop the return address
			POP	IY		; Return data address
			POP	BC		; C: p.x, B: p.y
			POP	DE		; E: p.z, D: a
			PUSH	HL		; Stack the return address
			LD	(IY+2),E	; Set r.z
			LD	A,B
			LD	B,C		; B: p.x
			LD	C,A		; C: p.y
			CALL	fastCMS8
			LD	(IY+0),A	; Set r.x
			CALL	fastSPC8
			LD	(IY+1),A	; Set r.y
			RET 

; Do A=fastCos(B,D)-fastSin(C,D)
;
fastCMS8:		PUSH	BC		; BC: The multipliers
			PUSH	DE		;  E: The angle
			LD	A,D		;  A: Angle
			LD	E,C		;  E: Multiplier for sin
			PUSH	AF		; Stack the angle
			CALL	sin8		;  A: fastSin(C,A)
			LD	C,A		;  C: fastSin(C,A)
			POP	AF
			LD	E,B		;  E: Multiplier for cos
			CALL	cos8		;  A: fastCos(B,A)
			SUB	C		;  A: fastCos(B,A)-fastSin(C,A)
			POP	DE
			POP	BC
			RET

; Do A=fastSin(B,D)+fastCos(C,D)
; 
fastSPC8:		PUSH	BC		; BC: The multipliers
			PUSH	DE		;  E: The angle
			LD	A,D		;  A: Angle
			LD	E,C		; E: Multiplier for cos
			PUSH	AF		; Stack the angle
			CALL	cos8		; A: fastCos(C,A)
			LD	C,A		; C: fastCos(C,A)
			POP	AF
			LD	E,B		; E: Multiplier for sin
			CALL	sin8		; A: fastSin(B,A)
			ADD	C		; A: fastSin(B,A)+fastCos(C,A)
			POP	DE
			POP	BC
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
			POP	DE			; E: Angle, D: Multiplier
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