/*
 * Title:			Spectrum Next 3D Engine
 * Author:			Dean Belfield
 * Contributors:	Henrique Olifiers, Michael "Flash" Ware
 * Created:			20/08/2025
 * Last Updated:	04/09/2025
 *
 * Modinfo:
 * 04/09/2025:		Moved models to includes in models folder
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
// Model data
// ***************************************************************************************************************************************

// Struct containing a single 3D objects position data
//
typedef struct SObject_3D {
	Point16_3D pos;
	Angle_3D theta;
} Object3D;

// Struct containing a single 3D objects model data
//
typedef struct SModel_3D {           
	uint8_t numVertices;
	uint8_t numFaces;
	Point8_3D (*vertices)[];
	Vertice_3D (*faces)[];
} Model_3D;

// Elite model data courtesy of Mark Moxon
// https://elite.bbcelite.com/6502sp/main/variable/ship_cobra_mk_3.html
//
#include "models/cube.h"
#include "models/cobra_mk3.h"
#include "models/coriolis_station.h"

// ***************************************************************************************************************************************
// Sample data, may move later
// ***************************************************************************************************************************************

const int pd = 256;				// The perspective distance
uint8_t	renderMode = 0;			// 0: Wireframe, 1: Filled
Point16 point_t[64];			// Buffer for the translated points 

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
				else {
					triangleL2C(p1,p2,p3,0xFF);
				}
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

	Object3D o1 = {
		{0, 0, pd * 2},			// Position
		{0, 0, 0},				// Angle
	};

	Object3D o2 = {
		{-10, -10, pd * 4},		// Position
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
		
		if(Keys[VK_O])	o1.pos.x -= 4;
		if(Keys[VK_P])	o1.pos.x += 4;
		if(Keys[VK_Q])	o1.pos.y -= 4;
		if(Keys[VK_A])	o1.pos.y += 4;
		if(Keys[VK_W])	o1.pos.z -= 4;
		if(Keys[VK_S])	o1.pos.z += 4;

		if(Keys[VK_1])	setCPU(0);
		if(Keys[VK_2])	setCPU(1);
		if(Keys[VK_3])	setCPU(2);
		if(Keys[VK_4])	setCPU(3);

		if(Keys[VK_SPACE])	renderMode = 1-renderMode;

		Point8 c = {56,56};		// Draw a filled circle
		circleL2F(c,35,0xFC);
		drawModel(&station_m, &o2);
		drawModel(&cobra_m, &o1);

		// Do some rotation
		//
		o1.theta.x+=1;
		o1.theta.y+=2;
		o1.theta.z-=1;
		o2.theta.x-=2;
		o2.theta.y+=3;
		o2.theta.z+=1;
		swapL2(); 		// Do the double-buffering
	};
}
