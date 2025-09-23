#include <arch/zxn.h>
#include <stdint.h>             // standard names for ints with no ambiguity 
#include <stdio.h>
#include <stdlib.h>
#include <z80.h>

#include "core.h"
#include "render.h"
#include "clipping.h"
#include "maths.h"
#include "render_3D.h"
#include "experiments.h"

extern int pd;
extern uint8_t renderMode;
extern Point16 point_t[64];
extern Angle_3D cam_theta;
extern Point16_3D cam_pos;

// ***************************************************************************************************************************************
//  Sample routines
// ***************************************************************************************************************************************

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

void drawObjectC(Object_3D * o) {

	// Rotate the world around the camera
	//
	Point16_3D u_pos = {
		o->pos.x - cam_pos.x,
		o->pos.y - cam_pos.y,
		o->pos.z - cam_pos.z,
	};
	u_pos = rotate16_3D(u_pos, cam_theta);
	Angle_3D u_ang = {
		cam_theta.x - o->theta.x,
		cam_theta.y - o->theta.y,
		cam_theta.z - o->theta.z,
	};

	// Check if the ship is in our field of view, if so then draw it
	// This might need fine-tuning for objects close up
	//
	if(u_pos.z > 200 && abs(u_pos.x) < u_pos.z && abs(u_pos.y) < u_pos.z ) {
		rotateModel(&point_t[0], u_pos, u_ang, o->model);
		renderModel(&point_t[0], o->model, renderMode);
	}
}
