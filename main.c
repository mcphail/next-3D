
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

#include "core.h"
#include "main.h"
#include "kernel.h"
#include "render.h"
#include "clipping.h"
#include "maths.h"

// ***************************************************************************************************************************************
// Sample data, may move later
// ***************************************************************************************************************************************

const int pd = 256;				// The perspective distance

// Struct containing a single 3D objects data
//
typedef struct SObject_3D {
	Point16_3D pos;
	Angle_3D theta;
} Object3D;
 
// Some shape data
//
Point8_3D cube_p[] = {
	 {-70, 70, 70},
	 { 70, 70, 70},
	 { 70,-70, 70},
	 {-70,-70, 70},
	 {-70, 70,-70},
	 { 70, 70,-70},
	 { 70,-70,-70},
	 {-70,-70,-70},
};
Vertice_3D cube_v[] = {
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

// Struct for edges (for Elite data)
//
typedef struct SEdge_3D {
	uint8_t v1;
	uint8_t v2;
	uint8_t f1;
	uint8_t f2;
} Edge_3D;

Point8_3D cobra_p[] = {
	{   32,    0,   76 }, // Vertex 0
	{  -32,    0,   76 }, // Vertex 1
	{    0,   26,   24 }, // Vertex 2
	{ -120,   -3,   -8 }, // Vertex 3
	{  120,   -3,   -8 }, // Vertex 4
	{  -88,   16,  -40 }, // Vertex 5
	{   88,   16,  -40 }, // Vertex 6
	{  120,   -8,  -40 }, // Vertex 7
	{ -120,   -8,  -40 }, // Vertex 8
	{    0,   26,  -40 }, // Vertex 9
	{  -32,  -24,  -40 }, // Vertex 10
	{   32,  -24,  -40 }, // Vertex 11
	{  -36,    8,  -40 }, // Vertex 12
	{   -8,   12,  -40 }, // Vertex 13
	{    8,   12,  -40 }, // Vertex 14
	{   36,    8,  -40 }, // Vertex 15
	{   36,  -12,  -40 }, // Vertex 16
	{    8,  -16,  -40 }, // Vertex 17
	{   -8,  -16,  -40 }, // Vertex 18
	{  -36,  -12,  -40 }, // Vertex 19
	{    0,    0,   76 }, // Vertex 20
	{    0,    0,   90 }, // Vertex 21
	{  -80,   -6,  -40 }, // Vertex 22
	{  -80,    6,  -40 }, // Vertex 23
	{  -88,    0,  -40 }, // Vertex 24
	{   80,    6,  -40 }, // Vertex 25
	{   88,    0,  -40 }, // Vertex 26
	{   80,   -6,  -40 }, // Vertex 27
};

Edge_3D cobra_e[] = {
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

Point8_3D cobra_f[] = {
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

Point8_3D rotate3D(Point8_3D * p, Angle_3D * theta) {
	Point8_3D r1 = rotateX(*p, theta->x);
	Point8_3D r2 = rotateY(r1, theta->y);
	Point8_3D r3 = rotateZ(r2, theta->z);
	return r3;
}

// Project an object in 3D space with perspective
// Parameters:
// - pos: The position of the object in space
// -   r: The point to project
//
Point16 project3D(Point16_3D * pos, Point8_3D * r) {
	//
	// NB: If pd is fixed at 256, could do a quick multiply by shifting 8 bits left
	//
	int16_t z = pos->z + r->z;  
	Point16 p = {
		pos->x + fastMulDiv(r->x, pd, z) + 128, // r->x * pd / z
		pos->y + fastMulDiv(r->y, pd, z) + 96,  // r->y * pd / z
	};
	return p;
}

int16_t dotp(Point16_3D p1, Point16_3D p2) {
	return (p1.x * p2.x) + (p1.y * p2.y) + (p1.z * p2.z);
}

int16_t crossp(Point16_3D p1, Point16_3D p2) {
	return (p1.x * p2.x) - (p1.y * p2.y) - (p1.z * p2.z);
}

Point8_3D calculateNormal(Point8_3D p1, Point8_3D p2, Point8_3D p3) {
	Point8_3D a = {
		p2.x - p1.x,
		p2.y - p1.y,
		p2.z - p1.z,
	};
	Point8_3D b = {
		p3.x - p1.x,
		p3.y - p1.y,
		p3.z - p1.z,
	};
	Point8_3D n = {
		(a.y * b.z) - (a.z * b.y),
		(a.z * b.x) - (a.x * b.z),
		(a.x * b.y) - (a.y * b.x),
	};
	return n;
}

// ***************************************************************************************************************************************
//  Main startup and loop
// ***************************************************************************************************************************************

void main(void)
{
//  BREAK;
    NextReg(0x57,2);          	// Page in kernel
    InitKernel();
    SetUpIRQs();
    NextReg(0x8,0x4A);        	// Disable RAM contention, enable DAC and turbosound
//  NextReg(0x5,0x04);			// 60Hz mode
	setCPU(3);					// 28Mhz
    initL2();
	zx_border(INK_RED);

	int i;						// General loop index
	Point16 point_t[64];		// Buffer for the translated points 
//	int16_t dpn[64];			// Buffer for the face normal dot products
//	Point8_3D cube_n[12];		// Buffer for the precalculated normals

	Object3D o = {
		{0, 0, pd * 2},			// Position
		{0, 0, 0},				// Angle
	};

	// Precalculate the normals
	//
/*
	for(i=0; i<12; i++) {
		cube_n[i] = calculateNormal(
			cube_p[cube_v[i].p1,
			cube_p[cube_v[i].p2,
			cube_p[cube_v[i].p3
		);
	}
*/
	while(1) {
		clearL2(0);
		ReadKeyboard();
		
		if(Keys[VK_O])	o.pos.x -= 4;
		if(Keys[VK_P])	o.pos.x += 4;
		if(Keys[VK_Q])	o.pos.y -= 4;
		if(Keys[VK_A])	o.pos.y += 4;
		if(Keys[VK_W])	o.pos.z -= 4;
		if(Keys[VK_S])	o.pos.z += 4;

		if(Keys[VK_1])	setCPU(0);
		if(Keys[VK_2])	setCPU(1);
		if(Keys[VK_3])	setCPU(2);
		if(Keys[VK_4])	setCPU(3);

		// Draw a circle as a test
		// 
		Point8 c = {56,56};
		circleL2F(c,35,0xFC);

		if(o.pos.z > 128) {
/*
			// Calculate the face normal dot product relative to viewpoint
			//
			for(i=0; i<12; i++) {
				Point8_3D r = rotate3D(&cube_n[i], &o.theta);
				Point16_3D p = {
					r.x,
					r.y,
					r.z,
				};
				dpn[i] = dotp(o.pos, p);
			}
*/
			// Translate the points in 3D space
			//
			for(i=0; i<8; i++) {
				Point8_3D r = rotate3D(&cube_p[i], &o.theta);
				point_t[i] = project3D(&o.pos, &r);
			}
/*
			// Draw them (Elite style)
			//
			for(i=0;i<38;i++) {
				Edge_3D * e = &cobra_e[i];
				if(dpn[e->f1] < 0 || dpn[e->f2] < 0) {
					lineL2C(point_t[e->v1],point_t[e->v2],255);
				}
			}
*/
			// Draw the cube
			//
			for(i=0; i<12; i++) {
				Vertice_3D * v = &cube_v[i];
				Point16 p1 = point_t[v->p1];
				Point16 p2 = point_t[v->p2];
				Point16 p3 = point_t[v->p3];
				if(p1.x*(p2.y-p3.y)+p2.x*(p3.y-p1.y)+p3.x*(p1.y-p2.y)>0) {
					triangleL2CF(p1,p2,p3,v->colour);
				}
			}
		}

		// Do some rotation
		//
		o.theta.x+=1;
		o.theta.y+=2;
		o.theta.z-=1;
		swapL2(); 		// Do the double-buffering
	};
}
