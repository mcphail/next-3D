/*
 * Title:			Structures
 * Author:			Dean Belfield
 * Created:			23/11/2025
 * Last Updated:	23/11/2025
 *
 * Modinfo:
 */

#ifndef __STRUCTS_H__
#define __STRUCTS_H__

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

#endif 	//__STRUCTS_H__