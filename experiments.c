#include <arch/zxn.h>
#include <stdint.h>             // standard names for ints with no ambiguity 
#include <stdio.h>
#include <stdlib.h>
#include <z80.h>
#include <math.h>				// TODO: Delete from here and makefile once finished

#include "core.h"
#include "render.h"
#include "clipping.h"
#include "maths.h"
#include "experiments.h"

extern int pd;
extern uint8_t renderMode;
extern Point16 point_t[64];
extern Angle_3D cam_theta;
extern Point16_3D cam_pos;

// ***************************************************************************************************************************************
//  Sample routines
// ***************************************************************************************************************************************

Point8_3D rotate8_3D(Point8_3D * p, Angle_3D * theta) {
	Point8_3D r1 = rotate8_X(*p, theta->x);
	Point8_3D r2 = rotate8_Y(r1, theta->y);
	Point8_3D r3 = rotate8_Z(r2, theta->z);
	return r3;
}

Point16_3D rotate16_X(Point16_3D p, uint8_t a) {
	float r = a*M_PI/128;
	Point16_3D q = {
		p.x,
		p.y * cos(r) - p.z * sin(r),
		p.y * sin(r) + p.z * cos(r),
	};
	return q;
}

Point16_3D rotate16_Y(Point16_3D p, uint8_t a) {
	float r = a*M_PI/128;
	Point16_3D q = {
		p.x * cos(r) - p.z * sin(r),
		p.y,
		p.x * sin(r) + p.z * cos(r),
	};
	return q;
}

Point16_3D rotate16_Z(Point16_3D p, uint8_t a) {
	float r = a*M_PI/128;
	Point16_3D q = {
		p.x * cos(r) - p.y * sin(r),
		p.x * sin(r) + p.y * cos(r),
		p.z,
	};
	return q;
}

Point16_3D rotate16_3D(Point16_3D *p, Angle_3D * theta) {
	Point16_3D r1 = rotate16_X(*p, theta->x);
	Point16_3D r2 = rotate16_Y(r1, theta->y);
	Point16_3D r3 = rotate16_Z(r2, theta->z);
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
		fastMulDiv(pos->x + r->x, pd, z) + 128, // r->x * pd / z
		fastMulDiv(pos->y + r->y, pd, z) + 96,  // r->y * pd / z
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

void drawObject(Object_3D * o) {
	int i;

	// Rotate the universe around the camera
	//
	Point16_3D u_pos = {
		o->pos.x - cam_pos.x,
		o->pos.y - cam_pos.y,
		o->pos.z - cam_pos.z,
	};
	u_pos = rotate16_3D(&u_pos, &cam_theta);
	Angle_3D u_ang = {
		cam_theta.x - o->theta.x,
		cam_theta.y - o->theta.y,
		cam_theta.z - o->theta.z,
	};

	// Check if the ship is in our field of view, if so then draw it
	// This might need fine-tuning for objects close up
	//
	if(abs(u_pos.x) >= u_pos.z || abs(u_pos.y) >= u_pos.z ) {
		zx_border(INK_RED);
	}
	else {
		zx_border(INK_GREEN);

		Model_3D * model = o->model;

		// Translate the vertices in 3D space
		//
		for(i=0; i<model->numVertices; i++) {
			Point8_3D v = (*model->vertices)[i];
			Point8_3D r = rotate8_3D(&v, &u_ang);
			point_t[i] = project3D(&u_pos, &r);
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
