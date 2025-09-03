
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
uint8_t	renderMode = 0;			// 0: Wireframe, 1: Filled
Point16 point_t[64];			// Buffer for the translated points 


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

typedef struct SModel_3D {           
	uint8_t numVertices;
	uint8_t numFaces;
	Point8_3D (*vertices)[];
	Vertice_3D (*faces)[];
} Model_3D;

Model_3D cobra = {
	28,
	26,
	&cobra_p,
	&cobra_v,
};
Point8_3D cobra_p[] = {
    { 30, 0, 72 },
    { -30, 0, 72 },
    { 0, 25, 23 },
    { -122, -3, -8 },
    { 122, -3, -8 },
    { -84, 15, -38 },
    { 84, 15, -38 },
    { 122, -8, -38 },
    { -122, -8, -38 },
    { 0, 25, -38 },
    { -30, -23, -38 },
    { 30, -23, -38 },
    { -34, 8, -38 },
    { -8, 11, -38 },
    { 8, 11, -38 },
    { 34, 8, -38 },
    { 34, -11, -38 },
    { 8, -15, -38 },
    { -8, -15, -38 },
    { -34, -11, -38 },
    { 0, 0, 72 },
    { 0, 0, 86 },
    { -76, -6, -38 },
    { -76, 6, -38 },
    { -84, 0, -38 },
    { 76, 6, -38 },
    { 84, 0, -38 },
    { 76, -6, -38 },
};
Vertice_3D cobra_v[] = {
    { 14, 16, 17, 0xFF },
    { 13, 18, 19, 0xFF },
    { 23, 22, 24, 0xFF },
    { 27, 25, 26, 0xFF },
    { 5, 9, 10, 0xFF },
    { 1, 11, 0, 0xFF },
    { 2, 6, 9, 0xFF },
    { 9, 5, 2, 0xFF },
    { 0, 2, 1, 0xFF },
    { 0, 4, 6, 0xFF },
    { 3, 1, 5, 0xFF },
    { 8, 3, 5, 0xFF },
    { 6, 4, 7, 0xFF },
    { 2, 0, 6, 0xFF },
    { 5, 1, 2, 0xFF },
    { 10, 3, 8, 0xFF },
    { 4, 11, 7, 0xFF },
    { 4, 0, 11, 0xFF },
    { 1, 10, 11, 0xFF },
    { 10, 1, 3, 0xFF },
    { 13, 19, 12, 0xFF },
    { 14, 15, 16, 0xFF },
    { 9, 6, 11, 0xFF },
    { 6, 7, 11, 0xFF },
    { 11, 10, 9, 0xFF },
    { 10, 8, 5, 0xFF },
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

void lineT_8(uint8_t x1, uint8_t y1, uint8_t x2, uint8_t y2) {
	Point8 p1 = { x1, y1 };
	Point8 p2 = { x2, y2 };
	lineT(p1,p2);
}

uint8_t clipLineT(Point16 p1, Point16 p2) {
	Point16 c1 = p1;
	Point16 c2 = p2;
	uint8_t a = clipLine(&c1,&c2);
	if(a != 0) {
		lineT_8(c1.x, c1.y, c2.x, c2.y);
	}
	if(a > 1) {
		// TODO: Need to think about this
	}
	return a;
}

/*
	The vertical line gap fill can work out which table it is drawn in the same way that the normal line routine does,
	depending upon whether the line is drawn up or down. It can fill in either a full line or just the gap. Clip line now 
	returns > 1 if the line has been clipped. Then the X value is just whether either of the points are off to the 
	left or right of the screen
*/
void testTClipped(Point16 p1, Point16 p2, Point16 p3, int16_t colour) {
	uint8_t a1 = clipLineT(p1,p2);
	uint8_t a2 = clipLineT(p2,p3);
	uint8_t a3 = clipLineT(p3,p1);

	if(a1 | a2 | a3) {
		int min = p1.y;
		int max = p1.y;

		if(p2.y < min) min = p2.y;
		if(p3.y < min) min = p3.y;
		if(p2.y > max) max = p2.y;
		if(p3.y > max) max = p3.y;

		if(min < 0) min = 0;
		if(max > 191) max = 191;

		drawShapeTable(min,max-min+1,colour);
	}
}

void drawModel(Model_3D * model, Object3D * o) {
	int i;

	if(o->pos.z > 128) {

		// Translate the vertices in 3D space
		//
		for(i=0; i<model->numVertices; i++) {
			Point8_3D v = (*model->vertices)[i];
			Point8_3D r = rotate3D(&v, &o->theta);
			point_t[i] = project3D(&o->pos, &r);
		}

		// Draw the faces
		//
		for(i=0; i<model->numFaces; i++) {
			Vertice_3D * v = &(*model->faces)[i];
			Point16 p1 = point_t[v->p1];
			Point16 p2 = point_t[v->p2];
			Point16 p3 = point_t[v->p3];
			if(p1.x*(p2.y-p3.y)+p2.x*(p3.y-p1.y)+p3.x*(p1.y-p2.y)<0) {
				if(renderMode == 1) {
//					testTClipped(p1,p2,p3,v->colour);
					triangleL2CF(p1,p2,p3,v->colour);
				}
				triangleL2C(p1,p2,p3,0xFF);
			}
		}
	}
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

		if(Keys[VK_SPACE])	renderMode = 1-renderMode;

		Point8 c = {56,56};		// Draw a filled circle
		circleL2F(c,35,0xFC);
		drawModel(&cobra, &o);	// Draw the cobra model

		// Do some rotation
		//
		o.theta.x+=1;
		o.theta.y+=2;
		o.theta.z-=1;
		swapL2(); 		// Do the double-buffering
	};
}
