
/*
3D Next engine, by Henrique Olifiers
*/

#pragma output REGISTER_SP = 0xbfff

#include <arch/zxn.h>
#include <stdint.h>             // standard names for ints with no ambiguity 
#include <stdio.h>
#include <stdlib.h>
#include <z80.h>
#include <im2.h>
#include <intrinsic.h>

#include <math.h>				// added for the trig, can be removed once optimised

#include "core.h"
#include "main.h"
#include "kernel.h"
#include "render.h"
#include "clipping.h"
#include "maths.h"

// ***************************************************************************************************************************************
// Sample data, may move later
// ***************************************************************************************************************************************

// Struct containing a 3D coordinate
//
typedef struct SPoint3D {           
    int16_t x;
    int16_t y;
	int16_t z;
} Point3D;

// Struct containing a 3D angle
//
typedef struct SAngle3D {
	float x;
	float y;
	float z;
} Angle3D;

// Struct containing the vertice information (joining the points)
//
typedef struct SVertice3D {
	uint8_t p1;
	uint8_t p2;
	uint8_t p3;
	uint8_t colour;
} Vertice3D;

// Struct for edges (for Elite data)
//
typedef struct SEdge3D {
	uint8_t v1;
	uint8_t v2;
	uint8_t f1;
	uint8_t f2;
} Edge3D;

// Struct containing a single 3D objects data
//
typedef struct SObject3D {
	Point3D pos;
	Angle3D theta;
} Object3D;
 
// Struct containing the precalculated trigs
//
typedef struct STrig {
	float cos_theta_x; 
	float sin_theta_x;
	float cos_theta_y;
	float sin_theta_y;
	float cos_theta_z;
	float sin_theta_z;
} Trig;

// Some shape data
//
Point3D cube_p[] = {
	 {-40, 40, 40},
	 { 40, 40, 40},
	 { 40,-40, 40},
	 {-40,-40, 40},
	 {-40, 40,-40},
	 { 40, 40,-40},
	 { 40,-40,-40},
	 {-40,-40,-40},
};
Vertice3D cube_v[] = {
	{0,1,2,16},{2,3,0,16},
	{0,4,5,17},{5,1,0,17},
	{7,6,5,18},{5,4,7,18},
	{3,2,6,19},{6,7,3,19},
	{1,5,6,20},{6,2,1,20},
	{0,3,7,21},{7,4,0,21},
};

// Cobra MkIII data courtesy of Mark Moxon
// https://elite.bbcelite.com/6502sp/main/variable/ship_cobra_mk_3.html
//
Point3D cobra_p[] = {
	{   32,    0,   76 }, //    15,     15,   15,    15,         31    \ Vertex 0
	{  -32,    0,   76 }, //    15,     15,   15,    15,         31    \ Vertex 1
	{    0,   26,   24 }, //    15,     15,   15,    15,         31    \ Vertex 2
	{ -120,   -3,   -8 }, //     3,      7,   10,    10,         31    \ Vertex 3
	{  120,   -3,   -8 }, //     4,      8,   12,    12,         31    \ Vertex 4
	{  -88,   16,  -40 }, //    15,     15,   15,    15,         31    \ Vertex 5
	{   88,   16,  -40 }, //    15,     15,   15,    15,         31    \ Vertex 6
	{  128,   -8,  -40 }, //     8,      9,   12,    12,         31    \ Vertex 7
	{ -128,   -8,  -40 }, //     7,      9,   10,    10,         31    \ Vertex 8
	{    0,   26,  -40 }, //     5,      6,    9,     9,         31    \ Vertex 9
	{  -32,  -24,  -40 }, //     9,     10,   11,    11,         31    \ Vertex 10
	{   32,  -24,  -40 }, //     9,     11,   12,    12,         31    \ Vertex 11
	{  -36,    8,  -40 }, //     9,      9,    9,     9,         20    \ Vertex 12
	{   -8,   12,  -40 }, //     9,      9,    9,     9,         20    \ Vertex 13
	{    8,   12,  -40 }, //     9,      9,    9,     9,         20    \ Vertex 14
	{   36,    8,  -40 }, //     9,      9,    9,     9,         20    \ Vertex 15
	{   36,  -12,  -40 }, //     9,      9,    9,     9,         20    \ Vertex 16
	{    8,  -16,  -40 }, //     9,      9,    9,     9,         20    \ Vertex 17
	{   -8,  -16,  -40 }, //     9,      9,    9,     9,         20    \ Vertex 18
	{  -36,  -12,  -40 }, //     9,      9,    9,     9,         20    \ Vertex 19
	{    0,    0,   76 }, //     0,     11,   11,    11,          6    \ Vertex 20
	{    0,    0,   90 }, //     0,     11,   11,    11,         31    \ Vertex 21
	{  -80,   -6,  -40 }, //     9,      9,    9,     9,          8    \ Vertex 22
	{  -80,    6,  -40 }, //     9,      9,    9,     9,          8    \ Vertex 23
	{  -88,    0,  -40 }, //     9,      9,    9,     9,          6    \ Vertex 24
	{   80,    6,  -40 }, //     9,      9,    9,     9,          8    \ Vertex 25
	{   88,    0,  -40 }, //     9,      9,    9,     9,          6    \ Vertex 26
	{   80,   -6,  -40 }, //     9,      9,    9,     9,          8    \ Vertex 27
};

Edge3D cobra_e[] = {
	{  0,  1,  0, 11 }, // 31    \ Edge 0
	{  0,  4,  4, 12 }, // 31    \ Edge 1
	{  1,  3,  3, 10 }, // 31    \ Edge 2
	{  3,  8,  7, 10 }, // 31    \ Edge 3
	{  4,  7,  8, 12 }, // 31    \ Edge 4
	{  6,  7,  8,  9 }, // 31    \ Edge 5
	{  6,  9,  6,  9 }, // 31    \ Edge 6
	{  5,  9,  5,  9 }, // 31    \ Edge 7
	{  5,  8,  7,  9 }, // 31    \ Edge 8
	{  2,  5,  1,  5 }, // 31    \ Edge 9
	{  2,  6,  2,  6 }, // 31    \ Edge 10
	{  3,  5,  3,  7 }, // 31    \ Edge 11
	{  4,  6,  4,  8 }, // 31    \ Edge 12
	{  1,  2,  0,  1 }, // 31    \ Edge 13
	{  0,  2,  0,  2 }, // 31    \ Edge 14
	{  8, 10,  9, 10 }, // 31    \ Edge 15
	{ 10, 11,  9, 11 }, // 31    \ Edge 16
	{  7, 11,  9, 12 }, // 31    \ Edge 17
	{  1, 10, 10, 11 }, // 31    \ Edge 18
	{  0, 11, 11, 12 }, // 31    \ Edge 19
	{  1,  5,  1,  3 }, // 29    \ Edge 20
	{  0,  6,  2,  4 }, // 29    \ Edge 21
	{ 20, 21,  0, 11 }, //  6    \ Edge 22
	{ 12, 13,  9,  9 }, // 20    \ Edge 23
	{ 18, 19,  9,  9 }, // 20    \ Edge 24
	{ 14, 15,  9,  9 }, // 20    \ Edge 25
	{ 16, 17,  9,  9 }, // 20    \ Edge 26
	{ 15, 16,  9,  9 }, // 19    \ Edge 27
	{ 14, 17,  9,  9 }, // 17    \ Edge 28
	{ 13, 18,  9,  9 }, // 19    \ Edge 29
	{ 12, 19,  9,  9 }, // 19    \ Edge 30
	{  2,  9,  5,  6 }, // 30    \ Edge 31
	{ 22, 24,  9,  9 }, //  6    \ Edge 32
	{ 23, 24,  9,  9 }, //  6    \ Edge 33
	{ 22, 23,  9,  9 }, //  8    \ Edge 34
	{ 25, 26,  9,  9 }, //  6    \ Edge 35
	{ 26, 27,  9,  9 }, //  6    \ Edge 36
	{ 25, 27,  9,  9 }, //  8    \ Edge 37
};

Point3D cobra_f[] = {
	{   0,  62,  31 }, // 31      \ Face 0
	{ -18,  55,  16 }, // 31      \ Face 1
	{  18,  55,  16 }, // 31      \ Face 2
	{ -16,  52,  14 }, // 31      \ Face 3
	{  16,  52,  14 }, // 31      \ Face 4
	{ -14,  47,   0 }, // 31      \ Face 5
	{  14,  47,   0 }, // 31      \ Face 6
	{ -61, 102,   0 }, // 31      \ Face 7
	{  61, 102,   0 }, // 31      \ Face 8
	{   0,   0, -80 }, // 31      \ Face 9
	{  -7, -42,   9 }, // 31      \ Face 10
	{   0, -30,   6 }, // 31      \ Face 11
	{   7, -42,   9 }, // 31      \ Face 12
};

// ***************************************************************************************************************************************
//  Sample routines
// ***************************************************************************************************************************************

float degToRad(float deg) {
	return deg*M_PI/180;
}

// Precalculate the trig
//
void precalcTrig(Trig * t, Angle3D * theta) {
	t->cos_theta_x = cos(theta->x);
	t->sin_theta_x = sin(theta->x);
	t->cos_theta_y = cos(theta->y);
	t->sin_theta_y = sin(theta->y);
	t->cos_theta_z = cos(theta->z);
	t->sin_theta_z = sin(theta->z);
}

// Rotate a point in 3D space
//
Point3D rotate3D(Point3D * p, Trig * t) {

	// Rotate around the X axis
	//
	Point3D r1 = {
		p->x,
		p->y*t->cos_theta_x-p->z*t->sin_theta_x,
		p->y*t->sin_theta_x+p->z*t->cos_theta_x
	};
	
	// Rotate around the Y axis
	//
	Point3D r2 = {
		r1.x*t->cos_theta_y-r1.z*t->sin_theta_y,
		r1.y,
		r1.x*t->sin_theta_y+r1.z*t->cos_theta_y
	};
	
	// Rotate around the Z axis
	//
	Point3D r3 = {
		r2.x*t->cos_theta_z-r2.y*t->sin_theta_z,
		r2.x*t->sin_theta_z+r2.y*t->cos_theta_z,
		r2.z		
	};

	return r3;
}

// ***************************************************************************************************************************************
//  Main startup and loop
// ***************************************************************************************************************************************

void main(void)
{
//  BREAK;
    NextReg(0x57,2);          	// page in kernel
    InitKernel();
    SetUpIRQs();
    NextReg(0x7,3);           	// 28Mhz
    NextReg(0x8,0x4A);        	// Disable RAM contention, enable DAC and turbosound
//  NextReg(0x5,0x04);			// 60Hz mode

    initL2();
	zx_border(INK_RED);

	int i;
	Trig t;						// Buffer for precalculated trig rotation
	Point16 point_t[64];		// Buffer for the translated points 
	Point3D point_n[64];		// Buffer for the translated normals
	int pd = 256;				// The perspective distance

	Object3D o = {
		{0, 0, pd},				// Position
		{0, 0, 0},				// Angle
	};

	while(1) {
		clearL2(0);
		ReadKeyboard();
		
		if(Keys[VK_O])	o.pos.x -= 2;
		if(Keys[VK_P])	o.pos.x += 2;
		if(Keys[VK_Q])	o.pos.y -= 2;
		if(Keys[VK_A])	o.pos.y += 2;
		if(Keys[VK_W])	o.pos.z -= 2;
		if(Keys[VK_S])	o.pos.z += 2;

		// Draw a circle as a test
		// 
		Point8 c = {56,56};
		circleL2F(c,35,0xFC);

		if(o.pos.z > 128) {
			precalcTrig(&t, &o.theta); // Precalculate the sin/cos values for each axis of rotation
			
			// Translate the normals in 3D space
			//
			for(i=0; i<13; i++) {
				point_n[i] = rotate3D(&cobra_f[i], &t);
			}

			// Translate the points in 3D space
			//
			for(i=0; i<28; i++) {
				Point3D   r = rotate3D(&cobra_p[i], &t);
				Point16 * t = &point_t[i];	

				// Translate
				//
				r.z += o.pos.z;  

				// Perspective
				//
				int16_t x = fastMulDiv(r.x, pd, r.z); // pd * r.x / r.z;
				int16_t y = fastMulDiv(r.y, pd, r.z); // pd * r.y / r.z;

				// Bodge put here to avoid overflow
				//
				x += o.pos.x;
				y += o.pos.y;

				// Screen offset and store in t
				//
				t->x=x+128;
				t->y=y+96;
			}

			// Draw them (Elite style)
			//
			for(i=0;i<38;i++) {
				Edge3D * e = &cobra_e[i];
				Point16 p1 = point_t[e->v1];
				Point16 p2 = point_t[e->v2];
				if(point_n[e->f1].z < 0 || point_n[e->f2].z < 0) {
					lineL2C(p1,p2,255);
				}
			}
/*	
			// Draw them
			//
			for(i=0; i<12; i++) {
				Vertice3D * v = &cube_v[i];
				Point16 p1 = point_t[v->p1];
				Point16 p2 = point_t[v->p2];
				Point16 p3 = point_t[v->p3];
				if(p1.x*(p2.y-p3.y)+p2.x*(p3.y-p1.y)+p3.x*(p1.y-p2.y)>0) {
					triangleL2C(p1,p2,p3,v->colour);
				}
			}
*/
		}

		// Do some rotation
		//
		o.theta.x+=degToRad(1);
		o.theta.y+=degToRad(2);
		o.theta.z-=degToRad(3);

		swapL2(); 		// Do the double-buffering
	};
}
