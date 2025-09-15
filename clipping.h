// clipping.h
#ifndef __CLIPPING_H__
#define __CLIPPING_H__

extern uint8_t clipRegion(Point16 * p) __z88dk_callee;
extern int16_t clipMulDiv(int16_t a, int16_t b, int16_t c) __z88dk_callee;
extern uint8_t clipLine(Point16 * p1, Point16 * p2) __z88dk_callee;
extern void lineL2C(Point16 p1, Point16 p2, uint8_t c) __z88dk_callee;
extern void triangleL2C(Point16 p1, Point16 p2, Point16 p3, uint8_t c) __z88dk_callee;
extern void triangleL2CF(Point16 p1, Point16 p2, Point16 p3, uint8_t c) __z88dk_callee;

/*
uint8_t clipLineC(Point16 * p1, Point16 * p2);
void drawClippedLineC(Point16 p1, Point16 p2, uint8_t colour);
*/

#endif 	//__CLIPPING_H__