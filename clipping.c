#include <arch/zxn.h>
#include <stdint.h>             // standard names for ints with no ambiguity 
#include <stdio.h>
#include <stdlib.h>
#include <z80.h>

#include "core.h"
#include "render.h"
#include "clipping.h"

uint8_t clipLineC(Point16 * p1, Point16 * p2) {
	uint8_t code1, code2, codeout;
	uint8_t	accept = 0;
	uint8_t done = 0;
	int16_t	x, y;

	code1 = clipRegion(p1);
	code2 = clipRegion(p2);

	do {
		if((code1|code2)==0) {					// Accept because both endpoints are in screen
			accept++;
			done++;
		}
		else if((code1&code2)!=0) {				// Reject because the line is not visible on screen
			done++;
		}
		else {									// No trivial reject or accept, so just continue the loop
			codeout = code1 ? code1 : code2;	// This is the code that needs clipping
			
			int16_t dx = p2->x - p1->x;
			int16_t dy = p2->y - p1->y;

			if(codeout & 1) {					// Top
				x = p1->x + clipMulDiv(dx, -p1->y, dy);		// x = p1->x + dx * -p1->y / dy;
				y = 0;
			}
			else if(codeout & 2) {				// Bottom
				x = p1->x + clipMulDiv(dx, 192-p1->y, dy);	// x = p1->x + dx * (192 - p1->y) / dy;
				y = 191;
			}
			else if(codeout & 4) {				// Right
				y = p1->y + clipMulDiv(dy, 256-p1->x, dx);	// y = p1->y + dy * (256 - p1->x) / dx;
				x = 255;
			}
			else {								// Left
				y = p1->y + clipMulDiv(dy, -p1->x, dx);		// y = p1->y + dy * -p1->x / dx;
				x = 0;
			}

			if(codeout == code1) {				// First endpoint clipped
				p1->x = x;
				p1->y = y;
				code1 = clipRegion(p1);
			}
			else {								// Second endpoint clipped
				p2->x = x;
				p2->y = y;
				code2 = clipRegion(p2);
			}
		}
	} while(!done);

	return accept;
}

void drawClippedLineC(Point16 p1, Point16 p2, uint8_t colour) {
	if(clipLineC(&p1, &p2)) {
		Point8 c1 = { p1.x, p1.y };
		Point8 c2 = { p2.x, p2.y };
		lineL2(c1, c2, colour);		
	}
}