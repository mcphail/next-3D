/*
 * Title:			Spectrum Next 3D Engine
 * Author:			Dean Belfield
 * Contributors:	Henrique Olifiers, Michael "Flash" Ware
 * Created:			20/08/2025
 * Last Updated:	22/09/2025
 *
 * Modinfo:
 * 04/09/2025:		Moved models to includes in models folder
 * 22/09/2025:		Beta version 0.5
 */

#pragma output REGISTER_SP = 0xbfff

//#define test_triangles

#include <arch/zxn.h>
#include <stdint.h>             // standard names for ints with no ambiguity 
#include <stdio.h>
#include <stdlib.h>
#include <z80.h>
#include <im2.h>
#include <intrinsic.h>

#include "core.h"
#include "main.h"
#include "kernel.h"
#include "render.h"
#include "clipping.h"
#include "maths.h"
#include "render_3D.h"
#include "sprites.h"
#include "experiments.h"		// Work-in-progress stuff

// ***************************************************************************************************************************************
// Sprites data
// ***************************************************************************************************************************************

#include "sprites/cursors.h"

// ***************************************************************************************************************************************
// Model data
// ***************************************************************************************************************************************

// Elite model data courtesy of Mark Moxon
// https://elite.bbcelite.com/6502sp/main/variable/ship_cobra_mk_3.html
//
#include "models/cube.h"
#include "models/cobra_mk3.h"
#include "models/coriolis_station.h"

// ***************************************************************************************************************************************
// Global data
// ***************************************************************************************************************************************

const int pd = 256;					// The perspective distance

uint8_t	renderMode = 1;				// 0: Wireframe, 1: Filled
Point16 point_t[MAX_POINTS];		// Buffer for the translated points 
Angle_3D cam_theta = { 0, 0, 0 };	// The global camera view
Point16_3D cam_pos = { 0, 0, 0 };	// The global camera position
Object_3D object[MAX_OBJECTS];		// List of objects to display

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
    NextReg(0x57,2);          	// Page in kernel
    initKernel();
    initIRQs();
    NextReg(0x08,0x4A);        	// Disable RAM contention, enable DAC and turbosound
//  NextReg(0x05,0x04);			// 60Hz mode
	NextReg(0x15,0x21);			// Enable sprites and clipping, SLU priority
	setCPU(3);					// 28Mhz
    initL2();
	zx_border(INK_BLACK);

	spriteInit(0x00, &sprite_circle[0]);
	spriteInit(0x01, &sprite_cross[0]);

	int i = 0;
	int v = 0;

	#ifdef test_triangles
	Point16 p1 = { 10,10 };
	Point16 p2 = { 250,50 };
	Point16 p3 = { 60,170 };
	Point16 *p = &p1;
	#endif 
	
	Point16_3D pos = { 1000, 0, pd*15 };
	Angle_3D theta = { 0,0,0 };
	object[i].flags=1;
	object[i].move = NULL;
	object[i].model = &cube_m;
	object[i].theta = theta;
	object[i++].pos = pos;

	pos.x = -1000;
	object[i].flags=1;
	object[i].move = NULL;
	object[i].model = &cube_m;
	object[i].theta = theta;
	object[i++].pos = pos;

	pos.x = 0;
	pos.z = pd * 1.5;
	object[i].flags=1;
	object[i].move = &rotate;
	object[i].model = &cobra_m;
	object[i].theta = theta;
	object[i++].pos = pos;

	while(1) {
		clearL2(0);
		readKeyboard();

		#ifdef test_triangles
		if(renderMode) {
			triangleL2CF(p1, p2, p3, 0xFC);
		}
		else {
			triangleL2C(p1, p2, p3, 0xFF);
		}
		if(Keys[VK_Q]) p->y--;
		if(Keys[VK_A]) p->y++;
		if(Keys[VK_O]) p->x--;	
		if(Keys[VK_P]) p->x++;
		if(Keys[VK_ENTER]) {
			renderMode = 1-renderMode;
			while (Keys[VK_ENTER]) {
				readKeyboard();
			}
		}
		if(Keys[VK_SPACE]) {
			if(p == &p1) p = &p2;
			else if(p == &p2) p = &p3;
			else p = &p1;
			while (Keys[VK_SPACE]) {
				readKeyboard();
			}
		}
		#else
		if(Keys[VK_Z])	cam_theta.z -= 1;	// Rotate camera around Z axis (in and out of screen)
		if(Keys[VK_X])	cam_theta.z += 1;
		if(Keys[VK_Q])	cam_theta.x -= 1;	// Rotate camera around X axis (axis is horizontal on screen)
		if(Keys[VK_A])	cam_theta.x += 1;
		if(Keys[VK_O])	cam_theta.y -= 1;	// Rotate camera around Y axis (axis is vertical on screen)
		if(Keys[VK_P])	cam_theta.y += 1;
		
		if(Keys[VK_S])	v = 0;
		if(Keys[VK_W])	{					
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

		if(Keys[VK_1])	setCPU(0);
		if(Keys[VK_2])	setCPU(1);
		if(Keys[VK_3])	setCPU(2);
		if(Keys[VK_4])	setCPU(3);

		if(Keys[VK_SPACE]) {
			renderMode = 1-renderMode;
			while (Keys[VK_SPACE]) {
				readKeyboard();
			}
		}

		Point8 c = {56,56};		// Draw a filled circle
		circleL2F(c,35,0xFC);

		for(int i=0; i<MAX_OBJECTS; i++) {
			if(object[i].flags) {
				drawObject(&object[i]);
				if(object[i].move) {
					object[i].move(i);
				}
			}
		}	
		#endif
		waitVBlank();	// Wait for the vblank before switching
		swapL2(); 		// Do the double-buffering
	};
}
