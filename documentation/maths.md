# maths.h/asm

The trigonometry assumes 256 bytes per full rotation of a circle for convenience and performance reasons.

## Structures

### SPoint8_3D
```
typedef struct SPoint8_3D {           
    int8_t x;
    int8_t y;
	int8_t z;
} Point8_3D;
```
Describes a point in 3D space - 8 bit so used to describe vertices in model data only

### SPoint16_3D
```
typedef struct SPoint16_3D {           
    int16_t x;
    int16_t y;
	int16_t z;
} Point16_3D;
```
Describes a point in 3D space - 16 bit so used to describe model coordinates in world space

### SAngle_3D
```
typedef struct SAngle_3D {
	uint8_t x;
	uint8_t y;
	uint8_t z;
} Angle_3D;
```
Describes a 3D angle. It assumes there are 256 degrees in a full rotation.

### SVertice_3D
```
typedef struct SVertice_3D {
	uint8_t p1;
	uint8_t p2;
	uint8_t p3;
	uint8_t colour;
} Vertice_3D;
```
Describe a face within a model, where:

- p1: Index to the first vertice
- p2: Index to the second vertice
- p3: Index to the third vertice
- colour: The face colour

## Functions

### Rotate (8-bit model space)

`Point8_3D rotate8_3D(Point8_3D p, Angle_3D theta);`

Rotate point P around all axes in the order x,y,z by the angles specified in theta

`Point8_3D rotate8_X(Point8_3D p, uint8_t a);`

Rotate point p around the X axis by angle a

`Point8_3D rotate8_Y(Point8_3D p, uint8_t a);`

Rotate point p around the Y axis by angle a

`Point8_3D rotate8_Z(Point8_3D p, uint8_t a);`

Rotate point p around the Z axis by angle a

### Rotate (16-bit world space)

`Point16_3D rotate16_3D(Point16_3D p, Angle_3D theta);`

Rotate point P around all axes in the order x,y,z by the angles specified in theta

`Point16_3D rotate16_X(Point16_3D p, uint8_t a);`

Rotate point p around the X axis by angle a

`Point16_3D rotate16_Y(Point16_3D p, uint8_t a);`

Rotate point p around the Y axis by angle a

`Point16_3D rotate16_Z(Point16_3D p, uint8_t a);`

Rotate point p around the Z axis by angle a

### Trigonometry 

`int16_t fastSin16(uint8_t a, int16_t m);`

sin(a)*m/256

`int16_t fastCos16(uint8_t a, int16_t m);`

cos(a)*m/256

### Other

`int16_t fastMulDiv(int16_t a, int16_t b, int16_t c);`

Returns a * b / c, with the internal calculation done in 32-bits

`Point16 project3D(Point16_3D pos, Point8_3D r);`

Projects a point from model space (r) into world space (pos) with perspective

Optimised version of this C routine:
```
int16_t z = pos.z + r.z;  
Point16 p = {
    fastMulDiv(pos.x + r.x, pd, z) + 128, // r.x * pd / z
    fastMulDiv(pos.y + r.y, pd, z) + 96,  // r.y * pd / z
};
return p;
```
- pos: he position of the object in space
- r: The point to project

`uint8_t windingOrder(Point16 p1, Point16 p2, Point16 p3);`

For backface culling using polygon winding order, where p1, p2 and p3 describe the three vertices of the face

Returns p1.x*(p2.y-p3.y)+p2.x*(p3.y-p1.y)+p3.x*(p1.y-p2.y)<0

If true (1) then the face can be rendered