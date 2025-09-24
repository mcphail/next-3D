/*
 * Title:			Line and Triangle Clipping Routines
 * Author:			Dean Belfield
 * Created:			20/08/2025
 * Last Updated:	22/09/2025
 *
 * Modinfo:
 */

#ifndef __CLIPPING_H__
#define __CLIPPING_H__

extern uint8_t clipRegion(Point16 * p) __z88dk_callee;
extern uint8_t clipLine(Point16 * p1, Point16 * p2) __z88dk_callee;
extern void lineL2C(Point16 p1, Point16 p2, uint8_t c) __z88dk_callee;
extern void triangleL2C(Point16 p1, Point16 p2, Point16 p3, uint8_t c) __z88dk_callee;
extern void triangleL2CF(Point16 p1, Point16 p2, Point16 p3, uint8_t c) __z88dk_callee;

#endif 	//__CLIPPING_H__