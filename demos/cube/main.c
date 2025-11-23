/*
 * Title:			Spectrum Next 3D Engine Cube Demo
 * Author:			Dean Belfield
 * Created:			29/09/2025
 * Last Updated:	23/11/2025
 *
 * Modinfo:
 * 23/11/2025:		Now includes maths_3D.h
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
#include "../../maths_3D.h"
#include "../../render_3D.h"
#include "../../sprites.h"
#include "../../experiments.h"

// ***************************************************************************************************************************************
// Model data
// ***************************************************************************************************************************************

#include "../../models/cube.h"

// ***************************************************************************************************************************************
// Global data
// ***************************************************************************************************************************************

uint8_t		renderMode = 1;			// Render mode: 0=Wireframe, 1=Filled
Object_3D	object[MAX_OBJECTS];	// Array of objects in the world

// ***************************************************************************************************************************************
//  Main startup and loop
// ***************************************************************************************************************************************

void rotate(int i) {
	Object_3D * self = &object[i];
	self->theta.x+=1;
	self->theta.y+=2;
	self->theta.z-=1;
}

void main(void)
{
//  BREAK;
    NextReg(0x57,2);          		// Page in kernel
    initKernel();
    initIRQs();
    NextReg(0x08,0x4A);        		// Disable RAM contention, enable DAC and turbosound
//  NextReg(0x05,0x04);				// 60Hz mode
	NextReg(0x15,0x21);				// Enable sprites and clipping, SLU priority
	setCPU(3);						// 28Mhz
    initL2();
	zx_border(INK_BLACK);

	// Set up the object
	//
	object[0].flags=1;				// Flag that the object is active
	object[0].move = &rotate;		// The callback routine to move the object
	object[0].model = &cube_m;		// The model to display
	object[0].pos.x = 0;			// The location of the object in world space
	object[0].pos.y = 0;
	object[0].pos.z = pd * 1.5;
	object[0].theta.x = 0;			// The rotation of the object around its origin
	object[0].theta.y = 0;
	object[0].theta.z = 0;

	while(1) {
		clearL2(0);					// Clear the offscreen drawing buffer
		readKeyboard();				// Read the keyboard

		if(Keys[VK_1])	setCPU(0);	// Set the turbo mode when keys 1-4 pressed
		if(Keys[VK_2])	setCPU(1);
		if(Keys[VK_3])	setCPU(2);
		if(Keys[VK_4])	setCPU(3);

		// Toggle the render mode between wireframe and filled when space pressed
		//
		if(Keys[VK_SPACE]) {
			renderMode = 1-renderMode;
			while (Keys[VK_SPACE]) {
				readKeyboard();
			}
		}

		// Loop through the objects array, draw and render any that are
		// active
		//
		for(int i=0; i<MAX_OBJECTS; i++) {
			if(object[i].flags) {
				drawObject(&object[i], renderMode);
				if(object[i].move) {
					object[i].move(i);
				}
			}
		}	
		waitVBlank();				// Wait for the vblank before switching
		swapL2(); 					// Do the double-buffering
	};
}
