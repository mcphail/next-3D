## Core Modules

### [clipping.h/asm](clipping.md)

This includes an implementation of the Cohen-Sutherland line clipping algorithm and Sutherland-Hodgman polygon clipping algorithm, along with routines to draw the following clipped primitives:

- lines
- wireframe triangles
- filled triangles

### [kernel.h/asm](kernel.md)

This contains routines to initialise the Next kernel along with low-level routines for reading the keyboard, DMA, and interrupts.

### [maths.h/asm](maths.md)

This contains fast routines for rotating and projecting vertices in 8-bit (model) and 16-bit (world) space.

### [render_3D.h/asm](render_3D.md)

This contains high level routines for rendering and moving models in 16-bit (world) space

### [render.h/asm](render.md)

This contains low level routines for rendering 2D primitives on Layer 2 (256x192 resolution only), including:

- plot
- unclipped lines
- unclipped wireframe and filled triangles
- clipped wireframe and filled circles

Primitives are drawn on an offscreen Layer 2 surface, and there are functions for clearing it and swapping it with the onscreen Layer 2 surface.

### [sprites.h/asm](sprites.md)

This contains low level routines for manipulating Next sprites

### experiments.h/c

This file contains experimental routines that I'm evaluating prior to porting to Z80. These may never see the light of day. Use at your peril.