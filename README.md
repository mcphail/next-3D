# Next3D - a 3D engine for the ZX Spectrum Next

## v0.4 -- DEBUG MODE, NOT READY FOR PRODUCTION

The Next3D implementation is meant to be used in C via z88dk, but since we are aiming for high performance, all its core functionalities (plot, draw, triangle, filled triangle, projections, lightining etc.) are implemented in Z80 Assembly fully documented and built to take advantage of the Next hardware as much as possible.

This means the core library is easily portable to any environment, and its parts (such as plot or triangle) can easily be used in any C, Boriel Basic or other languages inline.

I took a lot of care to describe each single line of the asm code for easiness of following what's going on, targetting anyone willing to reuse it (or improve!)

For now, this is what works:

### render.h/asm

**initL2: 256x192 video mode with 256 colours**  
I haven't implemented other video modes as they would require 16 bit logic and for now, Next3D is a 8 bit engine.

**setCPU: sets CPU speed**  
Your choice of MHz. Default value is 3 (28MHz).

**swapL2: Swaps the offscreen buffer in***
All rendering is done in an offscreen buffer to avoid flicker; this swaps the offscreen buffer onto the visible screen.

**clearL2: clear the screen**  
Clear the offscreen buffer with the colour of your choice.  

**PlotPixel8K: fast plotting (soon to be renamed plotL2)**  
Plots a pixel on the screen at x, y with colour.

**lineL2: fast drawing**  
Draws a line from x1, y1 to x2, y2 with colour.

**triangleL2: fast wireframe triangle**  
Draws a triangle between pt0, pt1, pt2 with colour (p being a structure containing x, y coordinates).

**triangleL2F: fast filled triangle**  
Draws a filled triangle between pt0, pt1 and pt2 with colour (p being a structure containing x, y coordinates).

**circleL2F: fast filled circle**
Draws a filled circle centred on pt0 with a radius and colour.

### clipping.h/asm

**clipRegion**
Support function for the Cohen Sutherland clip routine to establish whether a point is on-screen and, if offscreen, which region(s) it is in.

**clipLine**
Clip two points describing the line p1,p2 to screen.

**lineL2C: Fast clipped line**
Draws a clipped line between p1 and p2 with given colour.

**triangleL2C: Fast clipped wireframe triangle**
Draws a clipped triangle between p1,p2 and p3, with given colour.

**triangleL2CF: Fast clipped filled triangle**
Draws a clipped and filled triangle between p1,p2 and p3, with given colour.

### maths.h/asm

**fastMulDiv: Fast multiple and divide***
Calculates a * b / c, 32-bit signed internally, with 16-bit parameters and result.
