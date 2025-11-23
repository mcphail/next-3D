;
; Title:	Fast 3D Maths Routines
; Author:	Dean Belfield
; Created:	23/11/2025
; Last Updated:	23/11/2025
;
; Modinfo:
;
    			SECTION KERNEL_CODE

    			INCLUDE "globals.inc"

			EXTERN	sin8			; In maths.asm
			EXTERN	cos8			; In maths.asm
			EXTERN	sin16			; In maths.asm
			EXTERN	cos16			; In maths.asm
			EXTERN	negHL			; In maths.asm
			EXTERN	negBC			; In maths.asm
			EXTERN	fastMulS16_16x16	; In maths.asm

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

_rotate8_3D:		POP	HL		; Pop the return address
			POP	IY		; Return data address
			POP	BC		; C: p.x, B: p.y
			POP	DE		; E: p.y, D: theta.x
			LD	(IY+0),C	; p.x
			LD	(IY+1),B	; p.y
			LD	(IY+2),E	; p.z
			POP	BC		; C: theta.y, B: theta.z
			PUSH	HL		; Push the return stack back
;
; Do rotate8_X
; At this point:
;  D: theta.x
;  C: theta.y
;  B: theta.z
; IY: Pointer to buffer containing Point8 data
;
rotate8_3D:		PUSH	BC		; Store angles for later	
;			LD	D,D		; D: theta.x
			LD	B,(IY+1)	; B: p.y
			LD	C,(IY+2)	; C: p.z
			CALL	fastCMS8	; A=fastCos8(B,D)-fastSin8(C,D)
			EX	AF,AF'
			CALL	fastSPC8	; A=fastSin8(B,D)+fastCos8(C,D)
			LD	(IY+2),A	; Set r.z
			EX	AF,AF'
			LD	(IY+1),A	; Set r.y
;
; Do rotate8_Y
;
			POP	DE		; E: theta.y, D: theta.z
			PUSH	DE
			LD	D,E		; D: theta.y
			LD	B,(IY+0)	; B: p.x
			LD	C,(IY+2)	; C: p.z
			CALL	fastCMS8	; A=fastCos8(B,D)-fastSin8(C,D)
			EX	AF,AF'
			CALL	fastSPC8	; A=fastSin8(B,D)+fastCos8(C,D)
			LD	(IY+2),A	; Set r.z
			EX 	AF,AF'
			LD	(IY+0),A	; Set r.x
;
; Do rotate8_Z
;
			POP	DE		; E: theta.y, D: theta.z
			LD	B,(IY+0)	; B: p.x
			LD	C,(IY+1)	; C: p.y
			CALL	fastCMS8	; A=fastCos8(B,D)-fastSin8(C,D)
			EX	AF,AF'
			CALL	fastSPC8	; A=fastSin8(B,D)+fastCos8(C,D)
			LD	(IY+1),A	; Set r.y
			EX	AF,AF'
			LD	(IY+0),A	; Set r.x
			RET


; extern Point8_3D rotate8_X(Point8_3D p, uint8_t a) __z88dk_callee;
; This is an optimised version of this C routine
;
; Point8_3D r = {
;     p.x,
;     fastCos8(p.y, a) - fastSin8(p.z, a),
;     fastSin8(p.y, a) + fastCos8(p.z, a),
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
			CALL	fastCMS8	; A=fastCos8(B,D)-fastSin8(C,D)
			LD	(IY+1),A	; Set r.y
			CALL	fastSPC8	; A=fastSin8(B,D)+fastCos8(C,D)
			LD	(IY+2),A	; Set r.z
			RET 

; extern Point8_3D rotate8_Y(Point8_3D p, uint8_t a) __z88dk_callee;
; This is an optimised version of this C routine
;
; Point8_3D r2 = {
; 	fastCos8(p.x, a) - fastSin8(p.z, ay),
; 	p.y,
; 	fastSin8(p.x, a) + fastCos8(p.z, a),
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
			CALL	fastCMS8	; A=fastCos8(B,D)-fastSin8(C,D)
			LD	(IY+0),A	; Set r.x
			CALL	fastSPC8	; A=fastSin8(B,D)+fastCos8(C,D)
			LD	(IY+2),A	; Set r.z
			RET 

; extern Point8_3D rotate8_Z(Point8_3D p, uint8_t a) __z88dk_callee;
; This is an optimised version of this C routine
;
; Point8_3D r = {
;     fastCos8(p.x, a) - fastSin8(p.y, a),
;     fastSin8(p.x, a) + fastCos8(p.y, a),
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
			CALL	fastCMS8	; A=fastCos8(B,D)-fastSin8(C,D)
			LD	(IY+0),A	; Set r.x
			CALL	fastSPC8	; A=fastSin8(B,D)+fastCos8(C,D)
			LD	(IY+1),A	; Set r.y
			RET 

; Do A=fastCos8(B,D)-fastSin8(C,D)
;
fastCMS8:		PUSH	BC		; BC: The multipliers
			PUSH	DE		;  D: The angle
			LD	A,D		;  A: Angle
			LD	E,C		;  E: Multiplier for sin
			PUSH	AF		; Stack the angle
			CALL	sin8		;  A: fastSin(C,D)
			LD	C,A		;  C: fastSin(C,D)
			POP	AF
			LD	E,B		;  E: Multiplier for cos
			CALL	cos8		;  A: fastCos(B,D)
			SUB	C		;  A: fastCos(B,D)-fastSin(C,D)
			POP	DE
			POP	BC
			RET

; Do A=fastSin8(B,D)+fastCos8(C,D)
; 
fastSPC8:		PUSH	BC		; BC: The multipliers
			PUSH	DE		;  D: The angle
			LD	A,D		;  A: Angle
			LD	E,C		; E: Multiplier for cos
			PUSH	AF		; Stack the angle
			CALL	cos8		; A: fastCos(C,D)
			LD	C,A		; C: fastCos(C,D)
			POP	AF
			LD	E,B		; E: Multiplier for sin
			CALL	sin8		; A: fastSin(B,D)
			ADD	C		; A: fastSin(B,D)+fastCos(C,D)
			POP	DE
			POP	BC
			RET

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
			CALL	fastMulS16_16x16	; HL - p1.x*(p2.y-p3.y)
			PUSH	HL
			LD	DE,(R2)			; DE: p2.x
			LD	HL,(R5)			; HL: p3.y
			LD	BC,(R1)			; BC: p1.y
			XOR	A
			SBC	HL,BC			; HL = p3.y-p1.y
			CALL	fastMulS16_16x16	; HL - p2.x*(p3.y-p1.y)
			PUSH	HL
			LD	DE,(R4)			; DE: p3.x
			LD	HL,(R1)			; HL: p1.y
			LD	BC,(R3)			; BC: p2.y
			XOR	A
			SBC	HL,BC			; HL = p1.y-p2.y
			CALL	fastMulS16_16x16	; HL - p3.x*(p1.y-p2.y)
			POP	DE
			POP	BC
			ADD	HL,DE
			ADD	HL,BC
			LD	L,0
			RL	H			; Rotate the sign bit into L
			RL	L			; Rotate it into L
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
			CALL	fastCMS16	; HL: fastCos16(BC,A) - fastSin16(DE,A)
			LD	(R2),HL
			POP	DE
			POP	BC
			POP	AF
			CALL	fastSPC16	; HL: fastSin16(BC,A) + fastCos16(DE,A)
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
			CALL	fastCMS16	; HL: fastCos16(BC,A) - fastSin16(DE,A)
			LD	(R1),HL
			POP	DE
			POP	BC
			POP	AF
			CALL	fastSPC16	; HL: fastSin16(BC,A) + fastCos16(DE,A)
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
			CALL	fastCMS16	; HL: fastCos16(BC,A) - fastSin16(DE,A)
			LD	(R1),HL
			POP	DE
			POP	BC
			POP	AF
			CALL	fastSPC16	; HL: fastSin16(BC,A) + fastCos16(DE,A)
			LD	(R2),HL
			RET

; extern Point16_3D rotate16_X(Point16_3D p, uint8_t a);
; This is an optimised version of this C routine
;
; Point16_3D r = {
;     p.x,
;     fastCos16(p.y, a) - fastSin16(p.z, a),
;     fastSin16(p.y, a) + fastCos16(p.z, a),
; };
; return r;
;
PUBLIC _rotate16_X

_rotate16_X:		POP	HL		; Pop the return address
			POP	IY		; Return data address
			POP	BC		; BC: p.x
			LD	(IY+0),C	; Don't need to calculate this, just store for return
			LD	(IY+1),B
			POP	BC		; BC: p.y
			POP	DE		; DE: p.z
			DEC	SP		; Correct the stack address for single byte
			POP	AF
			PUSH	HL		; Stack the return address
;
			PUSH	AF		; Do the calculation
			PUSH	BC
			PUSH	DE
			CALL	fastCMS16
			LD	(IY+2),L
			LD	(IY+3),H
			POP	DE
			POP	BC
			POP	AF	
			CALL	fastSPC16 
			LD	(IY+4),L
			LD	(IY+5),H
			RET 

; extern Point16_3D rotate16_Y(Point16_3D p, uint8_t a) __z88dk_callee;
; This is an optimised version of this C routine
;
; Point16_3D r2 = {
; 	fastCos16(p.x, a) - fastSin16(p.z, ay),
; 	p.y,
; 	fastSin16(p.x, a) + fastCos16(p.z, a),
; };
; return r;
;
PUBLIC _rotate16_Y

_rotate16_Y:		POP	HL		; Pop the return address
			POP	IY		; Return data address
			POP	BC		; BC: p.x
			POP	DE		; DE: p.y
			LD	(IY+2),E	; Don't need to calculate this, just store for return
			LD	(IY+3),D
			POP	DE		; DE: p.z
			DEC	SP		; Correct the stack address for single byte
			POP	AF
			PUSH	HL		; Stack the return address
;
			PUSH	AF		; Do the calculation
			PUSH	BC
			PUSH	DE
			CALL	fastCMS16
			LD	(IY+0),L
			LD	(IY+1),H
			POP	DE
			POP	BC
			POP	AF	
			CALL	fastSPC16 
			LD	(IY+4),L
			LD	(IY+5),H
			RET 

; extern Point16_3D rotate16_Z(Point16_3D p, uint8_t a) __z88dk_callee;
; This is an optimised version of this C routine
;
; Point16_3D r = {
;     fastCos16(p.x, a) - fastSin16(p.y, a),
;     fastSin16(p.x, a) + fastCos16(p.y, a),
;     p.z,	
; };
; return r;
;
PUBLIC _rotate16_Z

_rotate16_Z:		POP	HL		; Pop the return address
			POP	IY		; Return data address
			POP	BC		; BC: p.x
			POP	DE		; DE: p.y
			EX	(SP),HL		;
			LD	(IY+4),L	; Don't need to calculate this, just store for return
			LD	(IY+5),H
			EX	(SP),HL
			INC	SP
			POP	AF
			PUSH	HL		; Stack the return address
;
			PUSH	AF		; Do the calculation
			PUSH	BC
			PUSH	DE
			CALL	fastCMS16
			LD	(IY+0),L
			LD	(IY+1),H
			POP	DE
			POP	BC
			POP	AF	
			CALL	fastSPC16 
			LD	(IY+2),L
			LD	(IY+3),H
			RET 

; Do HL=fastCos16(BC,A)-fastSin16(DE,A)
;
fastCMS16:		PUSH	AF		; Stack the angle
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

; Do HL=fastSin16(BC,A)+fastCo16s(DE,A)
; 
fastSPC16:		PUSH	AF		; Stack the angle
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
;     fastMulDiv(pos.x + r.x, pd, z) + 128, // r.x * pd / z
;     fastMulDiv(pos.y + r.y, pd, z) + 96,  // r.y * pd / z
; };
; return p;
;
; pos: he position of the object in space
;   r: The point to project
;
PUBLIC _project3D, project3D

_project3D:		POP	BC		; The return address
			POP	IY		; Return data address
			POP	HL		; BC: pos.x
			LD	(IY+0),L
			LD	(IY+1),H
			POP	HL		; BC: pos.y
			LD	(IY+2),L
			LD	(IY+3),H
			POP	HL		; HL: pos.z
			POP	DE		;  E: r.x, D: r.y
			DEC	SP
			POP	AF		;  A: r.z
			PUSH	BC		; Restore the return address
;
; At this point
; IY: Pointer to Point16 structure containing pos.x and pos.y
; HL: pos.z
;  E: r.x
;  D: r.y
;  A: r.z
; Calculate z
; Returns Point16 value stored in IY
;
project3D:		LD 	C,A		;  C: r.z - sign extend into BC
   			ADD	A,A		; Sign bit of A into carry
   			SBC	A,A		;  A: 0 if carry is 0, otherwise 0xFF 
   			LD 	B,A		; BC: Sign-extended A
   			ADD	HL,BC		; HL: pos.z + r.z
			PUSH	HL
			PUSH	DE		; DE: r.x, r.y
			PUSH	HL
;
; Calculate x = fastMulDiv(pos.x + r.x, pd, z) + 128
;
			LD	L,(IY+0)	; HL: pos.x
			LD	H,(IY+1)
			LD	A,E		;  E: r.x
   			ADD	A,A		; Sign bit of A into carry
   			SBC	A,A		;  A: 0 if carry is 0, otherwise 0xFF 
   			LD 	D,A		; DE: Sign-extended A
   			ADD	HL,DE		; HL: pos.x + r.x
			POP 	BC		; BC: z
			CALL	project3D_vp	; HL: Perspective calculation (pos.x + r.x) * 256 / z
			ADD	HL,128		; Add screen X centre
			LD 	(IY+0),L	; Store in return value
			LD	(IY+1),H
;
; Calculate y = fastMulDiv(pos.y + r.y, pd, z) + 96,
;
			POP	DE		; DE: r.x, r.y
			LD	L,(IY+2)	; HL: pos.Y
			LD	H,(IY+3)
			LD	E,D		;  E: r.y
			LD	A,E		;  D: r.y
   			ADD	A,A		; Sign bit of A into carry
   			SBC	A,A		;  A: 0 if carry is 0, otherwise 0xFF 
   			LD 	D,A		; BC: Sign-extended A
   			ADD	HL,DE		; HL: pos.y + r.y
			POP 	BC		; BC: z
			CALL	project3D_vp	; HL: Perspective calculation (pos.y + r.y) * 256 / z
			ADD	HL,96		; Add screen Y centre
			LD 	(IY+2),L	; Store in return value
			LD	(IY+3),H
			RET

; Do the perspective calculation
; HL: The x or y coordinate
; BC: The z coordinate
; Returns:
; HL: The projected point (x or y)
;
project3D_vp:		LD	A,H		; Preserve the sign for later
			XOR	B
			EX	AF,AF		; Preserve the flags
			BIT	7,H 		; Make all the values positive
			CALL	NZ,negHL
			BIT	7,B
			CALL	NZ,negBC
			LD	D,0		; DEHL = HL * 256 (the vanishing point)
			LD	E,H
			LD	H,L
			LD	L,0
			CALL	l_divu_32_32x16	; DEHL = DEHL / BC
			EX	AF,AF		; Restore the flags
			RET	P 		; Answer is positive so just return
			JP	negHL		; Answer is negative so negate it 
