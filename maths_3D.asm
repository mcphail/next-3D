;
; Title:	Fast 3D Maths Routines
; Author:	Dean Belfield
; Created:	23/11/2025
; Last Updated:	25/11/2025
;
; Modinfo:
; 23/11/2025:	Refactored project3D, fixed bug in windingOrder
; 24/11/2025:	Removed individual axis rotate functions
; 25/11/2025:	Optimised project3D, rotate8_3D
;
    			SECTION KERNEL_CODE

    			INCLUDE "globals.inc"

			EXTERN	sin8			; In maths.asm
			EXTERN	cos8			; In maths.asm
			EXTERN	sin16			; In maths.asm
			EXTERN	cos16			; In maths.asm
			EXTERN	negHL			; In maths.asm
			EXTERN	negBC			; In maths.asm
			EXTERN	muls16_16x16		; In maths.asm

; These are declared here
; https://github.com/z88dk/z88dk/tree/master/libsrc/_DEVELOPMENT/math/integer/z80n

			EXTERN	l_divu_32_32x16		; DEHL = DEHL / BC (unsigned)

; extern Point8_3D rotate8_3D(Point8_3D p, Angle_3D theta) __z88dk_callee;
; This is an optimised version of this C routine
;
; Point8_3D r1 = rotate8_X( p, theta.x);
; Point8_3D r2 = rotate8_Y(r1, theta.y);
; Point8_3D r3 = rotate8_Z(r2, theta.z);
; return r3;
;
PUBLIC _rotate8_3D, rotate8_3D

_rotate8_3D:		POP	IY		; Pop the return address
			POP	HL		; Return data address
			LD	(@M1+1),HL	; Self mod it for later
			POP	BC
			LD	A,C		; A: p.x (C)
;			LD	B,B		; B: p.y (B)
			POP	DE
			LD	C,E		; C: p.z (E)
			LD	E,D		; L: theta.x (D)	
			POP	HL
			LD	D,L		; D: theta.y (L)
			LD	L,H		; L: theta.z (H)
			LD	C,A		; C: p.x
			PUSH	IY		; Push the return address
			CALL	rotate8_3D
@M1:			LD	HL,0		; Where to store the return data
			LD	(HL),E		; p.x
			INC	HL
			LD	(HL),D		; p.y
			INC	HL
			LD	(HL),A		; p.z
			RET 
;
; Do rotate8_X
; At this point:
;  E: theta.x
;  D: theta.y
;  L: theta.z
;  H: p.x
;  B: p.y
;  C: p.z
; Returns: (NB: These registers plug straight into project3D)
;  E: p.x
;  D: p.y
;  A: p.z
;
rotate8_3D:		PUSH	DE		; Rotate X
			PUSH	HL
			LD	D,E		; D: theta.x
			CALL	CMS8		; A=cos8(B,D)-sin8(C,D)
			EX	AF,AF'
			CALL	SPC8		; A=sin8(B,D)+cos8(C,D)
			POP	HL
			POP	DE
			LD	C,A		; p.z
			EX	AF,AF'
			LD	B,A		; p.y
;
			PUSH	BC		; Rotate Y
			PUSH	HL
			LD	B,H		; B: p.x
			CALL	CMS8		; A=cos8(B,D)-sin8(C,D)
			EX	AF,AF'
			CALL	SPC8		; A=sin8(B,D)+cos8(C,D)
			POP	HL
			POP	BC
			PUSH	AF		; p.z
			EX 	AF,AF'
;
			LD	D,L		; D: theta.z
			LD	C,B		; C: p.y
			LD	B,A		; B: p.x
			CALL	CMS8		; A=cos8(B,D)-sin8(C,D)
			EX	AF,AF'
			CALL	SPC8		; A=sin8(B,D)+cos8(C,D)
			LD	D,A		; p.y
			EX 	AF,AF'
			LD	E,A		; p.x
			POP	AF		; p.z
			RET

; Do A=cos8(B,D)-sin8(C,D)
;
CMS8:			PUSH	BC		; BC: The multipliers
			PUSH	DE		;  D: The angle
			LD	A,D		;  A: Angle
			LD	E,C		;  E: Multiplier for sin
			LD	C,A		;  C: Angle (temp)
			CALL	sin8		;  D: sin(C,D)
			LD	A,C		;  A: Angle
			LD	C,D		;  C: sin(C,D)
			LD	E,B		;  E: Multiplier for cos
			CALL	cos8		;  A: cos(B,D)
			LD	A,D
			SUB	C		;  A: cos(B,D)-sin(C,D)
			POP	DE
			POP	BC
			RET

; Do A=sin8(B,D)+cos8(C,D)
; 
SPC8:			PUSH	BC		; BC: The multipliers
			PUSH	DE		;  D: The angle
			LD	A,D		;  A: Angle
			LD	E,C		; E: Multiplier for cos
			LD	C,A		; C: Angle (temp)
			CALL	cos8		; A: cos(C,D)
			LD	A,C		; A: Angle
			LD	C,D		; C: cos(C,D)
			LD	E,B		; E: Multiplier for sin
			CALL	sin8		; A: sin(B,D)
			LD	A,D
			ADD	C		; A: sin(B,D)+cos(C,D)
			POP	DE
			POP	BC
			RET

; extern Point16_3D rotate16_3D(Point16_3D p, Angle_3D theta) __z88dk_callee;
; This is an optimised version of this C routine
;
; Point16_3D r1 = rotate16_X( p, theta.x);
; Point16_3D r2 = rotate16_Y(r1, theta.y);
; Point16_3D r3 = rotate16_Z(r2, theta.z);
; return r3;
;
PUBLIC _rotate16_3D, rotate16_3D

_rotate16_3D:		POP	HL		; Pop the return address
			POP	IY		; Return data address
			POP	BC		; BC: p.x
			LD	(R1),BC		
			POP	BC		; BC: p.y
			LD	(R2),BC
			POP	BC		; BC: p.z
			LD	(R3),BC
			POP	BC		; C: theta.x, B: theta.y
			DEC	SP
			POP	AF		; A: theta.z
			PUSH	HL		; Stack the return address
;
			CALL	rotate16_3D	; Do the rotation
;
; Set the return data; note HL already contains R2
;
			LD	BC,(R1)
			LD	DE,(R3)	
			LD	(IY+0),C
			LD	(IY+1),B
			LD	(IY+2),L
			LD	(IY+3),H
			LD	(IY+4),E
			LD	(IY+5),D
			RET

;
; Do rotate16_X
; R1: p.x
; R2: p.y
; R3: p.z
;  C: theta.x
;  B: theta.y
;  A: theta.z
;	
rotate16_3D:		PUSH	AF		; Stack theta.z
			PUSH	BC		; Stack theta.x, theta.y		
			LD	A,C		;  A: theta.x
			LD	BC,(R2)		; BC: p.y
			LD	DE,(R3)		; DE: p.z
			PUSH	AF
			PUSH	BC
			PUSH	DE
			CALL	CMS16		; HL: Cos16(BC,A) - Sin16(DE,A)
			LD	(R2),HL
			POP	DE
			POP	BC
			POP	AF
			CALL	SPC16		; HL: sin16(BC,A) + cos16(DE,A)
			LD	(R3),HL
;
; Do rotate16_Y
;
			POP	BC		; Restore theta.y
			LD	A,B		;  A: theta.y
			LD	BC,(R1)		; BC: p.x
			LD	DE,(R3)		; DE: P.Z
			PUSH	AF
			PUSH	BC
			PUSH	DE
			CALL	CMS16		; HL: cos16(BC,A) - sin16(DE,A)
			LD	(R1),HL
			POP	DE
			POP	BC
			POP	AF
			CALL	SPC16		; HL: sin16(BC,A) + cos16(DE,A)
			LD	(R3),HL
;
; Do rotate16_Z
;
			POP	AF		;  A: theta.z
			LD	BC,(R1)		; BC: p.x
			LD	DE,(R2)		; DE: p.y
			PUSH	AF
			PUSH	BC
			PUSH	DE
			CALL	CMS16		; HL: cos16(BC,A) - sin16(DE,A)
			LD	(R1),HL
			POP	DE
			POP	BC
			POP	AF
			CALL	SPC16		; HL: sin16(BC,A) + cos16(DE,A)
			LD	(R2),HL
			RET

; Do HL=cos16(BC,A)-sin16(DE,A)
;
CMS16:			PUSH	AF		; Stack the angle
			PUSH	BC		; Stack the fastCos multiplier
			CALL	sin16		; HL: fastSin(DE,A)
			POP	DE		
			POP	AF
			PUSH	HL		; Stack the first result
			CALL	cos16		; HL: fastCos(HL,A)
			POP	DE		; DE: fastSin(DE,A)
			XOR	A
			SBC	HL,DE		; HL: fastCos(HL,A)-fastSin(DE,A)
			RET

; Do HL=sin16(BC,A)+cos16(DE,A)
; 
SPC16:			PUSH	AF		; Stack the angle
			PUSH	BC		; Stack the fastSin multiplier
			CALL	cos16		; HL: fastCos(DE,A)
			POP	DE 
			POP	AF 
			PUSH	HL		; Stack the first result
			CALL	sin16		; HL: fastSin(HL,A)
			POP	DE		; DE: fastCos(DE,A)
			ADD	HL,DE		; HL: fastSin(HL,A)+fastCos(DE,A)
			RET


; extern Point16 project3D(Point16_3D pos, Point8_3D r) __z88dk_callee;
; Optimised version of this C routine:
;
; int16_t z = pos.z + r.z;  
; Point16 p = {
;     muldivs16_16x16(pos.x + r.x, pd, z) + 128, // r.x * pd / z
;     muldivs16_16x16(pos.y + r.y, pd, z) + 96,  // r.y * pd / z
; };
; return p;
;
; pos: he position of the object in space
;   r: The point to project
;
PUBLIC _project3D, project3D

_project3D:		POP	BC		; The return address
			POP	IY		; Return data address
			POP	HL: LD (R1),HL	; R1: pos.x
			POP	HL: LD (R2),HL	; R2: pos.y
			POP	HL: LD (R3),HL	; HL: pos.z
			POP	DE		;  E: r.x, D: r.y
			DEC	SP
			POP	AF		;  A: r.z
			PUSH	BC		; Restore the return address
			CALL	project3D
			LD	(IY+0),E	; Populate the Point16 structure
			LD	(IY+1),D
			LD	(IY+2),L
			LD	(IY+3),H
			RET
;
; At this point
; R1: pos.x
; R2: pos.y
; R3: pos.z
;  E: r.x
;  D: r.y
;  A: r.z
; Calculate z
; Returns Point16 value stored in (DE,HL)
;
; First, translate the rotated 8-bit z coordinate into 16-bit world space by adding it to the models z coordinate
;
project3D:		LD	BC,(R3)		; BC: R3+A (signed)
			OR	A
			JP	P,@M1
			DEC	B
@M1:			ADD	A,C
			LD	C,A
			ADC	A,B
			SUB	C
			LD	B,A
;
;
; Calculate x perspective point
;
			PUSH	BC		; DE: pos.z + r.z
			PUSH	DE		; DE: r.x, r.y
			LD	HL,(R1)		; HL: pos.x
			LD	A,E		;  A: r.x
			CALL	project3D_vp	; HL: Perspective calculation (x * 256 / z)
			ADD	HL,128		; Add screen X centre
;
; Calculate y perspective point
;
			POP	DE		; DE: r.x, r.y
			POP 	BC		; BC: z
			PUSH	HL		; Stack the translated x coordinate
			LD	HL,(R2)		; HL: pos.y
			LD	A,D		;  A: r.y
			CALL	project3D_vp	; HL: Perspective calculation (y * 256 / z)
			ADD	HL,96		; HL: The translated y coordinate
			POP	DE		; DE: The translated x coordinate
			RET

; Do the perspective calculation
; HL: The x or y coordinate of the model
;  A: The x or y coordinate of the rotated point
; BC: The z coordinate
; Returns:
; HL: The projected point (x or y)
;
; First translate the x or y coordinate into world space by adding it to the models x or y 16-bit world coordinate
;
project3D_vp:		LD	E,A		; Sign extend E into DE
   			ADD	A,A		; Sign bit of A into carry
   			SBC	A,A		;  A: 0 if carry is 0, otherwise 0xFF 
   			LD 	D,A		; DE: Sign-extended A (r.x or r.y)
   			ADD	HL,DE		; HL: coordinate + r
;
; Now do the perspective calculation HL*256/BC on that point now it has been translated into world space
; At this point:
; HL: Is the translated coordinate
; BC: Is the z position of the point in world space
;
			LD	A,H		; Preserve the result sign for later
			XOR	B
			EX	AF,AF
			BIT	7,H 		; Make all the values positive
			CALL	NZ,negHL
			BIT	7,B
			CALL	NZ,negBC
			LD	D,0		; DEHL = HL * 256 (the vanishing point)
			LD	E,H
			LD	H,L
			LD	L,D		; L: 0
			CALL	l_divu_32_32x16	; DEHL = DEHL / BC
			EX	AF,AF		; Restore the flags
			RET	P 		; Answer is positive so just return
			JP	negHL		; Answer is negative so negate it 

; extern uint8_t windingOrder(Point16 p1, Point16 p2, Point16 p3) __z88dk_callee;
; For backface culling using polygon winding order
; Optimised version of this C routine:
; return p1.x*(p2.y-p3.y)+p2.x*(p3.y-p1.y)+p3.x*(p1.y-p2.y)<0;
;
PUBLIC _windingOrder,windingOrder

_windingOrder:		POP	BC			; The returna address
			POP	HL: LD (R0),HL		; p1.x
			POP	HL: LD (R1),HL		; p1.y
			POP	HL: LD (R2),HL		; p2.x
			POP	HL: LD (R3),HL		; p2.y
			POP	HL: LD (R4),HL		; p3.x
			POP	HL: LD (R5),HL		; p3.y
			PUSH	BC			; Stack the return address

windingOrder:		LD	DE,(R0)			; DE: p1.x
			LD	HL,(R3)			; HL: p2.y
			LD	BC,(R5)			; BC: p3.y
			XOR	A
			SBC	HL,BC			; HL = p2.y-p3.y
			CALL	muls16_16x16		; HL - p1.x*(p2.y-p3.y)
			PUSH	HL
			LD	DE,(R2)			; DE: p2.x
			LD	HL,(R5)			; HL: p3.y
			LD	BC,(R1)			; BC: p1.y
			XOR	A
			SBC	HL,BC			; HL = p3.y-p1.y
			CALL	muls16_16x16		; HL - p2.x*(p3.y-p1.y)
			PUSH	HL
			LD	DE,(R4)			; DE: p3.x
			LD	HL,(R1)			; HL: p1.y
			LD	BC,(R3)			; BC: p2.y
			XOR	A
			SBC	HL,BC			; HL = p1.y-p2.y
			CALL	muls16_16x16		; HL - p3.x*(p1.y-p2.y)
			POP	DE
			POP	BC
			ADD	HL,DE
			ADD	HL,BC
			LD	L,0
			RL	H			; Rotate the sign bit into L
			RL	L			; Rotate it into L
			RET 