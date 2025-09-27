# render_3D.h/asm

## Structures

### SModel_3D
```
typedef struct SModel_3D {           
	uint8_t		numVertices;
	uint8_t		numFaces;
	Point8_3D	(*vertices)[];
	Vertice_3D	(*faces)[];
} Model_3D;
```
Describes a model, as created by convert_model.py

- numVertices: The vertice count for the object
- numFaces: The face count for the object.
- vertices: A pointer to an array of vertices (points)
- faces: A pointer to an array of faces (triangle mesh)

### SObject_3D
```
typedef struct SObject_3D {
	uint8_t		flags;
	void 		(*move)(int i);
	Model_3D *	model;
	Point16_3D	pos;
	Angle_3D	theta;
} Object_3D;
```
Describes an object in world space

- flags: Various flags
- move: Pointer to a function that contains the logic to move the object
- model: Pointer to a model
- pos: Position of the object in world space
- angle: Rotation of the object in world space

## Functions

`void rotateModel(Point16 * buffer, Point16_3D p, Angle_3D a, Model_3D * m);`

Rotate and project a model

- buffer: A buffer to store the vertices in, projected into world space
- p: The position of the object in world space
- a: The rotation of the object
- m: Pointer to the model data

`void renderModel(Point16 * buffer, Model_3D * m, uint8_t mode);`

Render a model

- buffer: Pointer to a buffer of vertices previously projected by rotateModel
- m: Pointer to the model
- mode: 0 for wireframe, 1 for filled

`void drawObject(Object_3D * o, uint8_t renderMode);`

Rotate, project and draw an object in world space

- o: Pointer to the object's data
- renderMode: 0: wireframe, 1: filled