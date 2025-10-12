/*
 * Title:			Spectrum Next 3D Engine Circle Test
 * Author:			Dean Belfield
 * Created:			12/10/2025
 * Last Updated:	12/10/2025
 *
 * Modinfo:
 */

#pragma output REGISTER_SP = 0xbfff

#include <arch/zxn.h>
#include <stdint.h>             // standard names for ints with no ambiguity 
#include <stdio.h>
#include <stdlib.h>
#include <z80.h>
#include <im2.h>
#include <intrinsic.h>

#include "../../core.h"
#include "../../main.h"
#include "../../kernel.h"
#include "../../render.h"
#include "../../clipping.h"
#include "../../maths.h"
#include "../../render_3D.h"
#include "../../sprites.h"
#include "../../experiments.h"		// Work-in-progress stuff

// ***************************************************************************************************************************************
// Global data
// ***************************************************************************************************************************************

// ***************************************************************************************************************************************
//  Main startup and loop
// ***************************************************************************************************************************************

void circleTest(Point16 p, int r, uint8_t c) {
	int x = -r;
	int y = 0;
	int e = 2-2*r;

	do {
		plotL2(p.x+x, p.y+y, c);
		plotL2(p.x+x, p.y-y ,c);
		plotL2(p.x-x, p.y+y, c);
		plotL2(p.x-x, p.y-y, c);
		r = e;
		if(r <= y) {
			y++;
			e += y*2+1;
		}
		if (r > x || e > y) {
			x++;
			e += x*2+1;
		}
	} while(x <= 0);
}

void main(void)
{
//  BREAK;
    NextReg(0x57,2);          	// Page in kernel
    initKernel();
    initIRQs();
    NextReg(0x08,0x4A);        	// Disable RAM contention, enable DAC and turbosound
//  NextReg(0x05,0x04);			// 60Hz mode
	NextReg(0x15,0x21);			// Enable sprites and clipping, SLU priority
	setCPU(3);					// 28Mhz
    initL2();
	zx_border(INK_RED);

 	Point16 p = { 128, 96 };
    uint16 r = 95;
    uint8_t renderMode = 0;

    while(1) {
        clearL2(0);
        readKeyboard();
        //
        // TODO: Your code here
        //
		zx_border(INK_YELLOW);
        if(renderMode) {
            circleL2F(p, r, 0xFF);
        }
        else {
//			circleTest(p, r, 0xFF);
            circleL2(p, r, 0xFF);
        }
		zx_border(INK_RED);
        if(Keys[VK_Q]) p.y--;
        if(Keys[VK_A]) p.y++;
        if(Keys[VK_O]) p.x--;
        if(Keys[VK_P]) p.x++;
        if(Keys[VK_1]) r--;
        if(Keys[VK_2]) r++;
        if(Keys[VK_SPACE]) {
            renderMode = 1-renderMode;
            do {
                readKeyboard();
            } while(Keys[VK_SPACE]);
        }

        waitVBlank();   // Wait for the vblank before switching
        swapL2();       // Do the double-buffering
    };
}
