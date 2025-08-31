// render.h
#ifndef __RENDER_H__
#define __RENDER_H__

// Point struct containing the coords of each triangle's vertex
//
typedef struct SPoint8 {           
    uint8_t x;
    uint8_t y;
} Point8;

typedef struct SPoint16 {           
    int16_t x;
    int16_t y;
} Point16;

// Line struct containing two points
//
typedef struct SLine8 {
	Point8 p1;
	Point8 p2;
} Line8;

typedef struct SLine16 {
	Point16 p1;
	Point16 p2;
} Line16;

extern void stop(void);                                             // asm to stop program for debugging
extern void test(void);												// asm to test functions

extern void setCPU(void);                                           // asm to set CPU parameters to 28MHz etc.
extern void initL2(void);                                           // asm to initialise Layer2 screen mode, addresses, banks etc.
extern void swapL2(void);											// asm to swap the offscreen buffer in
extern void clearL2(uint8 col) __z88dk_fastcall;					// asm to clear the offscreen buffer
extern void PlotPixel8K(uint8_t xcoord, uint8_t ycoord, uint8 colour) __z88dk_callee;
extern void lineL2(Point8 pt0, Point8 pt1, uint16 colour) __z88dk_callee;
extern void triangleL2(Point8 pt0, Point8 pt1, Point8 pt2, uint16 colour) __z88dk_callee;
extern void triangleL2F(Point8 pt0, Point8 pt1, Point8 pt2, uint16 colour) __z88dk_callee;
extern void circleL2F(Point8 pt0, uint16 radius, uint16 colour) __z88dk_callee;

#endif 	//__RENDER_H__

