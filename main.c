/*
 * Title:			Spectrum Next 3D Engine
 * Author:			Dean Belfield
 * Contributors:	Henrique Olifiers, Michael "Flash" Ware
 * Created:			20/08/2025
 * Last Updated:	04/09/2025
 *
 * Modinfo:
 * 04/09/2025:		Moved models to includes in models folder
 */

#pragma output REGISTER_SP = 0xbfff

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
#include "experiments.h"		// Work-in-progress stuff

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

const int pd = 256;				// The perspective distance

uint8_t	renderMode = 0;			// 0: Wireframe, 1: Filled
Point16 point_t[64];			// Buffer for the translated points 
Angle_3D camera = { 0, 0, 0 };	// The global camera view

// ***************************************************************************************************************************************
//  Main startup and loop
// ***************************************************************************************************************************************

void main(void)
{
//  BREAK;
    NextReg(0x57,2);          	// Page in kernel
    InitKernel();
    SetUpIRQs();
    NextReg(0x8,0x4A);        	// Disable RAM contention, enable DAC and turbosound
//  NextReg(0x5,0x04);			// 60Hz mode
	setCPU(3);					// 28Mhz
    initL2();
	zx_border(INK_BLACK);

//	int16_t dpn[64];			// Buffer for the face normal dot products
//	Point8_3D cube_n[12];		// Buffer for the precalculated normals

	Object3D o1 = {
		{0, 0, pd * 2},			// Position
		{0, 0, 0},				// Angle
	};

	Object3D o2 = {
		{0, 0, pd * 3},			// Position
		{0, 128, 0},			// Angle
	};

	// Precalculate the normals
	//
/*
	for(i=0; i<12; i++) {
		cube_n[i] = calculateNormal(
			cube_p[cube_v[i].p1,
			cube_p[cube_v[i].p2,
			cube_p[cube_v[i].p3
		);
	}
*/
	while(1) {
		clearL2(0);
		ReadKeyboard();
		
		if(Keys[VK_O])	o2.pos.x -= 2;	// Move object left
		if(Keys[VK_P])	o2.pos.x += 2;	// Move object right
		if(Keys[VK_Q])	o2.pos.y -= 2;	// Move object up
		if(Keys[VK_A])	o2.pos.y += 2;	// Move object down
		if(Keys[VK_W])	o2.pos.z -= 2;	// Move object forward
		if(Keys[VK_S])	o2.pos.z += 2;	// Move object back

		if(Keys[VK_Z])	camera.z -= 1;	// Rotate camera around Z axis (in and out of screen)
		if(Keys[VK_X])	camera.z += 1;
		if(Keys[VK_E])	camera.x -= 1;	// Rotate camera around X axis (axis is horizontal on screen)
		if(Keys[VK_D])	camera.x += 1;
		if(Keys[VK_K])	camera.y -= 1;	// Rotate camera around Y axis (axis is vertical on screen)
		if(Keys[VK_L])	camera.y += 1;

		if(Keys[VK_1])	setCPU(0);
		if(Keys[VK_2])	setCPU(1);
		if(Keys[VK_3])	setCPU(2);
		if(Keys[VK_4])	setCPU(3);

		if(Keys[VK_SPACE])	renderMode = 1-renderMode;

//		Point8 c = {56,56};		// Draw a filled circle
//		circleL2F(c,35,0xFC);
		drawModel(&station_m, &o2);
//		drawModel(&cobra_m, &o1);

		// Do some rotation
		//
/*
		o1.theta.x+=1;
		o1.theta.y+=2;
		o1.theta.z-=1;
*/
//		o2.theta.x-=2;
//		o2.theta.y+=3;
//		o2.theta.z+=1;

		swapL2(); 		// Do the double-buffering
	};
}
