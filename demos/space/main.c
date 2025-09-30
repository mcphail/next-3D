/*
 * Title:			Spectrum Next 3D Engine Space Demo
 * Author:			Dean Belfield
 * Created:			20/08/2025
 * Last Updated:	30/09/2025
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
#include "../../experiments.h"

// ***************************************************************************************************************************************
// Model data
// ***************************************************************************************************************************************

// Elite model data courtesy of Mark Moxon
// https://elite.bbcelite.com/6502sp/main/variable/ship_cobra_mk_3.html
//
#include "../../models/cube.h"
#include "../../models/cobra_mk3.h"
#include "../../models/coriolis_station.h"

// ***************************************************************************************************************************************
// Global data
// ***************************************************************************************************************************************

uint8_t	renderMode = 1;					// 0: Wireframe, 1: Filled
Point16_3D sun_pos = { 0, 0, 20000 };	// The sun position
Object_3D object[MAX_OBJECTS];			// List of objects to display

// ***************************************************************************************************************************************
//  Main startup and loop
// ***************************************************************************************************************************************

// A sample movement routine, this one just rotates the cobra spaceship
//
void rotate(int i) {
	Object_3D * self = &object[i];
	self->theta.x+=1;
	self->theta.y+=2;
	self->theta.z-=1;
}

// Draw the sun in world space
// The camera position is the viewer, so everything rotates around that
//
void drawSun(void) {
	Point16_3D p = {					// Get the sun's position relative to the camera
		sun_pos.x - cam_pos.x,
		sun_pos.y - cam_pos.y,
		sun_pos.z - cam_pos.z,
	};
	p = rotate16_3D(p, cam_theta);		// Rotate the sun around the camera

	// Now check whether the sun is in the line of view, and if so, then project it
	//
	if(p.z >= 200 && abs(p.x) < p.z && abs(p.y) < p.z ) {
		Point16 t = {
		    fastMulDiv(p.x, pd, p.z) + 128,
		    fastMulDiv(p.y, pd, p.z) + 96,
		};
		int16_t r = (32768-p.z)/256;	// This sets the sun's radius (size)

		if(r > 0) {						// Only draw if that is greater than zero
			if(renderMode) {			// Select the wireframe or filled circle depending
				circleL2F(t,r,0xFC);	// upon the render mode
			}
			else {
				circleL2(t,r,0xFF);
			}
		}
	}
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
	zx_border(INK_BLACK);

	int i = 0;					// General loop index
	int v = 0;					// Ship forward velocity
	
	Point16_3D pos = { 1000, 0, pd*15 };
	Angle_3D theta = { 0,0,0 };

	// Set up the first cube
	//
	object[i].flags=1;
	object[i].move = NULL;
	object[i].model = &cube_m;
	object[i].theta = theta;
	object[i++].pos = pos;

	// And the second cube
	//
	pos.x = -1000;
	object[i].flags=1;
	object[i].move = NULL;			// Null the movement routine, doesn't need to move
	object[i].model = &cube_m;
	object[i].theta = theta;
	object[i++].pos = pos;

	// Now the cobra
	// 
	pos.x = 0;						// Position in space
	pos.z = pd * 1.5;
	object[i].flags=1;				// Flag: Bit 0 set means it is an active object
	object[i].move = &rotate;		// The movement routine callback
	object[i].model = &cobra_m;		// The model data
	object[i].theta = theta;		// The starting angle
	object[i++].pos = pos;			// And starting position

	initStars();

	while(1) {
		clearL2(0);
		readKeyboard();

		if(Keys[VK_Z])	cam_theta.z -= 1;	// Z and X: Rotate camera around Z axis (in and out of screen)
		if(Keys[VK_X])	cam_theta.z += 1;
		if(Keys[VK_Q])	cam_theta.x -= 1;	// Q and A: Rotate camera around X axis (axis is horizontal on screen)
		if(Keys[VK_A])	cam_theta.x += 1;	
		if(Keys[VK_O])	cam_theta.y -= 1;	// O and P: Rotate camera around Y axis (axis is vertical on screen)
		if(Keys[VK_P])	cam_theta.y += 1;
		
		if(Keys[VK_S])	v = 0;				// S: Stop
		if(Keys[VK_W])	{					// W: Accelerate forward
			if(v < 80) v+=8;				
		}
		else {
			if (v > 0) v--;
		}

		Point16_3D sp = { 0, 0, v/4 };
		Angle_3D dr = {
			-cam_theta.x,
			-cam_theta.y,
			-cam_theta.z,
		};
		Point16_3D zv = rotate16_3D(sp, dr);
		cam_pos.x += zv.x;					
		cam_pos.y += zv.y;					
		cam_pos.z += zv.z;	

		if(Keys[VK_1])	setCPU(0);			// 1:  3.5Mhz
		if(Keys[VK_2])	setCPU(1);			// 2:  7.0Mhz
		if(Keys[VK_3])	setCPU(2);			// 3: 14.0Mhz
		if(Keys[VK_4])	setCPU(3);			// 4: 28.0Mhz

		if(Keys[VK_SPACE]) {				// Space: Toggle between wireframe and filled
			renderMode = 1-renderMode;
			while (Keys[VK_SPACE]) {
				readKeyboard();
			}
		}
		
		drawStars(v/2);		// Draw the stars, move at half ships velocity
		drawSun();			// Draw the sun

		// Loop through the object array and draw/move any that are active
		//
		for(int i=0; i<MAX_OBJECTS; i++) {
			if(object[i].flags) {
				drawObject(&object[i], renderMode);
				if(object[i].move) {
					object[i].move(i);
				}
			}
		}	
		waitVBlank();	// Wait for the vblank before switching
		swapL2(); 		// Do the double-buffering
	};
}
