# clipping.asm/h

All functions clip to the Layer 2 screen resolution (256x192), the clipping rectangle.

## Functions

`uint8_t clipRegion(Point16 * p);`

A low leve function to return the clipping region of a point (p). The returned value is a byte with one or more of the following bits set:

- Bit 0: If the point is off the top of the screen
- Bit 1: If the point is off the bottom of the screen
- Bit 2: If the point is off the right of the screen
- Bit 3: If the point is off the left of the screen

This function is used in clipLine

`uint8_t clipLine(Point16 * p1, Point16 * p2);`

An implementation of the Cohen-Sutherland line clipping algorithm.

Pass it the pointers to two points describing the line, and it will update the points to fit within the clipping rectangle.

The return value is a flag indicating how the line has been clipped:

- 0: The line is offscreen, so doesn't need to be clipped or drawn.
- 1: The line is onscreen, so doesn't need to be clipped.

Any other value indicates the line has been clipped. The return value is the number of iterations taken to clip it

`void lineL2C(Point16 p1, Point16 p2, uint8_t c);`

Clip a single line (p1 to p2) to the screen and draw it with the specified colour (c)

`void triangleL2C(Point16 p1, Point16 p2, Point16 p3, uint8_t c);`

Clip a wirefraw triangle (p1, p2 and p3) to screen and draw it with the specified colour (c)

`void triangleL2CF(Point16 p1, Point16 p2, Point16 p3, uint8_t c);`

Clip a filled triangle (p1, p2 and p3) to screen and draw it with the specified colour
