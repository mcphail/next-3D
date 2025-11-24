# structs.h

Common structures used in the 3D engine

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
