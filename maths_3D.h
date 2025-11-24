/*
 * Title:			Fast 3D Maths Routines
 * Author:			Dean Belfield
 * Created:			23/11/2025
 * Last Updated:	24/11/2025
 *
 * Modinfo:
 * 24/11/2025:		Removed individual axis rotate functions
 */

#ifndef __MATHS_3D_H__
#define __MATHS_3D_H__

#include "structs.h"

extern int pd;		// The perspective distance

extern Point8_3D rotate8_3D(Point8_3D p, Angle_3D theta) __z88dk_callee;

extern Point16_3D rotate16_3D(Point16_3D p, Angle_3D theta) __z88dk_callee;

extern Point16 project3D(Point16_3D pos, Point8_3D r) __z88dk_callee;
extern uint8_t windingOrder(Point16 p1, Point16 p2, Point16 p3) __z88dk_callee;

#endif 	//__MATHS_3D_H__