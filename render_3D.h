// render_3D.h
#ifndef __RENDER_3D_H__
#define __RENDER_3D_H__

#define MAX_POINTS	64				// Maximum points per shape
#define MAX_OBJECTS 16				// Maximum number of objects in the universe

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

extern void rotateModel(Point16 * buffer, Point16_3D p, Angle_3D a, Model_3D * m) __z88dk_callee;
extern void drawObject(Object_3D * o) __z88dk_callee;

#endif 	//__RENDER_3D_H__