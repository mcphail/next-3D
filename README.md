# Next3D - a 3D engine for the ZX Spectrum Next

## v0.5 BETA (Not production ready)

The Next-3D implementation is meant to be used in C via z88dk, but since we are aiming for high performance, all its core functionalities (rendering, projects, etc) are implemented in Z80 assembler, fully documented and built to take advantage of the Next hardware as much as possible.

This means the core library is easily portable to any environment, and its parts (such as plot or triangle) can easily be used in any C, Boriel Basic or other languages inline.

For sake of simplicity, the engine requires Layer 2 set to a resolution of 256x192.

## Why am I doing this?

Henrique Olifiers reached out to me the beginning of August 2025 - he had started coding this as part of the KS3 offering, and had discovered a couple of rendering bugs in the filled triangle routine I'd written for BBC BASIC for Next. I was aware of one of them, and got back to him to say that I'd be happy for either of us to work on a solution, and I'd roll it back into BBC BASIC for Next.

Long story short, he asked me that, given my experience, would I like to take this on as a project.

## Who is this for?

The code is targetting:

- Folk who want to understand how to write a 3D engine from scratch
- Folk who want a springboard to develop their own 3D games on the Next

As ever, the code is designed for readability, with each block of the assembler code commented.

## Etiquette

This software is a public BETA. Please do not submit any pull requests or issues at this point in time; they will be ignored.

## Creating Models

Models can be imported from Blender via an intermediate step:

- Export from Blender as an Wavefront (.obj) file
- Convert to a C file using the script convert_model.py in the [python](./python/) directory

Models can contain colour information and must be scaled to fit within the 8-bit model space.

There are example models and converted files in the [models](./models/) directory:

- *.blend: The models in Blender format
- *.obj: The models exported from Blender in Wavefront (.obj) format
- *.h: The models as converted by convert_model.py

## Core Modules

### [clipping.h/asm](documentation/clipping.md)

This includes an implementation of the Cohen-Sutherland line clipping algorithm and Sutherland-Hodgman polygon clipping algorithm, along with routines to draw the following clipped primitives:

- lines
- wireframe triangles
- filled triangles

### [kernel.h/asm](documentation/kernel.md)

This contains routines to initialise the Next kernel along with low-level routines for reading the keyboard, DMA, and interrupts.

### [maths.h/asm](documentation/maths.md)

This contains fast routines for rotating and projecting vertices in 8-bit (model) and 16-bit (world) space.

### [render_3D.h/asm](documentation/render_3D.md)

This contains high level routines for rendering and moving models in 16-bit (world) space

### [render.h/asm](documentation/render.md)

This contains low level routines for rendering unclipped 2D primitives on Layer 2 (256x192 resolution only), including:

- plot
- lines
- wireframe triangles
- filled triangles
- filled circles

Primitives are drawn on an offscreen Layer 2 surface, and there are functions for clearing it and swapping it with the onscreen Layer 2 surface.

### [sprites.h/asm](documentation/sprites.md)

This contains low level routines for manipulating Next sprites

### experiments.h/c

This file contains experimental routines that I'm evaluating prior to porting to Z80. These may never see the light of day. Use at your peril.