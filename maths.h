/*
 * Title:			Fast Maths Routines
 * Author:			Dean Belfield
 * Created:			20/08/2025
 * Last Updated:	23/11/2025
 *
 * Modinfo:
 * 20/11/2025:		Added fastDiv16
 * 22/11/2025:		Refactored multiply and divide routines
 * 23/11/2025:		Moved 3D specific routines to maths_3D
 */

#ifndef __MATHS_H__
#define __MATHS_H__

extern int8_t fastSin8(uint8_t a, int8_t m) __z88dk_callee;
extern int8_t fastCos8(uint8_t a, int8_t m) __z88dk_callee;

extern int16_t fastSin16(uint8_t a, int16_t m);
extern int16_t fastCos16(uint8_t a, int16_t m);

extern int16_t muldivs32_16x16(int16_t a, int16_t b, int16_t c) __z88dk_callee;
extern int16_t muldivs16_16x16(int16_t a, int16_t b, int16_t c) __z88dk_callee;

extern uint16_t mulu16_16x16(uint16_t a, uint16_t b) __z88dk_callee;
extern uint16_t divu16_16x16(uint16_t a, uint16_t b) __z88dk_callee;

extern int16_t muls16_16x16(int16_t a, int16_t b) __z88dk_callee;
extern int16_t divs16_16x16(int16_t a, int16_t b) __z88dk_callee;

#endif 	//__MATHS_H__