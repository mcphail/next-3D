// maths.h
#ifndef __MATHS_H__
#define __MATHS_H__

// Struct containing a 3D coordinate
//
typedef struct SPoint8_3D {           
    int8_t x;
    int8_t y;
	int8_t z;
} Point8_3D;

typedef struct SPoint16_3D {           
    int16_t x;
    int16_t y;
	int16_t z;
} Point16_3D;

// Struct containing a 3D angle
// Assumes 256 degrees in a full rotation to make it suitable for 8-bit maths
//
typedef struct SAngle_3D {
	uint8_t x;
	uint8_t y;
	uint8_t z;
} Angle_3D;

// Struct containing the vertice information (joining the points)
//
typedef struct SVertice_3D {
	uint8_t p1;
	uint8_t p2;
	uint8_t p3;
	uint8_t colour;
} Vertice_3D;

extern Point8_3D rotate8_3D(Point8_3D p, Angle_3D theta) __z88dk_callee;
extern Point8_3D rotate8_X(Point8_3D p, uint8_t a) __z88dk_callee;
extern Point8_3D rotate8_Y(Point8_3D p, uint8_t a) __z88dk_callee;
extern Point8_3D rotate8_Z(Point8_3D p, uint8_t a) __z88dk_callee;

extern int8_t fastSin8(uint8_t a, int8_t m) __z88dk_callee;
extern int8_t fastCos8(uint8_t a, int8_t m) __z88dk_callee;

extern Point16_3D rotate16_3D(Point16_3D p, Angle_3D theta) __z88dk_callee;
extern Point16_3D rotate16_X(Point16_3D p, uint8_t a) __z88dk_callee;
extern Point16_3D rotate16_Y(Point16_3D p, uint8_t a) __z88dk_callee;
extern Point16_3D rotate16_Z(Point16_3D p, uint8_t a) __z88dk_callee;

extern int16_t fastSin16(uint8_t a, int16_t m);
extern int16_t fastCos16(uint8_t a, int16_t m);

extern int16_t fastMulDiv(int16_t a, int16_t b, int16_t c) __z88dk_callee;

extern Point16 project3D(Point16_3D pos, Point8_3D r) __z88dk_callee;
extern uint8_t windingOrder(Point16 p1, Point16 p2, Point16 p3) __z88dk_callee;

#endif 	//__MATHS_H__