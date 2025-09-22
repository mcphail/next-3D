# render.h/asm

Note that the rendering routines here are high speed, and make no attempts to check or clip to screen boundaries.

## Structures

### SPoint8
```
typedef struct SPoint8 {           
    uint8_t x;
    uint8_t y;
} Point8;
```
Used in all the 8-bit (model-level) routines to store a single vertex (point)

### SPoint16
```
typedef struct SPoint16 {           
    int16_t x;
    int16_t y;
} Point16;
```
Used in all the 16-bit (universe-level) routines to store a single vertex (point)

### SLine8
```
typedef struct SLine8 {
	Point8 p1;
	Point8 p2;
} Line8;
```
Used to store the endpoints for a single line (in screen space)

### SLine16
```
typedef struct SLine16 {
	Point16 p1;
	Point16 p2;
} Line16;
```
Used to store the endpoints for a single line

## Functions

`void initL2(void);`

Initialise Layer 2

`void swapL2(void);`

Swap the offscreen buffer to make it visible

`void clearL2(uint8 col);`

Clear the offscreen buffer

`void plotL2(uint8_t xcoord, uint8_t ycoord, uint8 colour);`

Plot a single point to the offscreen buffer at coordinates x, y, with the specified colour

`void lineL2(Point8 pt0, Point8 pt1, uint8 colour);`

Draw a line from pt0 to pt1 in the specified colour

`void triangleL2(Point8 pt0, Point8 pt1, Point8 pt2, uint8 colour);`

Draw a wireframe triangle between the points pt0, pt1 and pt2, in the specified colour

`void triangleL2F(Point8 pt0, Point8 pt1, Point8 pt2, uint8 colour);`

Draw a filled triangle between the points pt0, pt1 and pt2, in the specified colour

`void circleL2F(Point8 pt0, uint16 radius, uint8 colour);`

Draw a filled circle with the centre pt0 with the specified radius and colour

`void lineT(Point8 pt0, Point8 pt1, uint8_t table);`

Low level routine to draw a line in the shape table between the points pt0 and pt1, in the specified table (0 or 1)

`void drawShapeTable(uint8_t y, uint8_t h, uint8 colour);`

Low level routine to render the shape table to screen, from screen row Y, height H, in the specified colour