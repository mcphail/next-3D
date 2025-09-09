// render_3D.h
#ifndef __RENDER_3D_H__
#define __RENDER_3D_H__

// Struct containing a single 3D objects model data
//
typedef struct SModel_3D {           
	uint8_t		numVertices;
	uint8_t		numFaces;
	Point8_3D	(*vertices)[];
	Vertice_3D	(*faces)[];
} Model_3D;

// Struct containing a single 3D objects position data
//
typedef struct SObject_3D {
	uint8_t		flags;
	void 		(*move)(int i);
	Model_3D *	model;
	Point16_3D	pos;
	Angle_3D	theta;
} Object_3D;

extern void drawObject(Object_3D * o) __z88dk_callee;

#endif 	//__RENDER_3D_H__