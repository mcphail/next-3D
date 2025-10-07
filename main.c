/*
 * Title:			Spectrum Next 3D Engine
 * Author:			Dean Belfield
 * Contributors:	Henrique Olifiers, Michael "Flash" Ware
 * Created:			20/08/2025
 * Last Updated:	07/10/2025
 *
 * Modinfo:
 * 04/09/2025:		Moved models to includes in models folder
 * 22/09/2025:		Beta version 0.5
 * 07/10/2025:		Moved demo code to demos folder
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
#include "render_3D.h"
#include "sprites.h"
#include "experiments.h"		// Work-in-progress stuff

// ***************************************************************************************************************************************
// Global data
// ***************************************************************************************************************************************

// ***************************************************************************************************************************************
//  Main startup and loop
// ***************************************************************************************************************************************

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

	while(1) {
		clearL2(0);
		readKeyboard();
		//
		// TODO: Your code here
		//
		waitVBlank();	// Wait for the vblank before switching
		swapL2(); 		// Do the double-buffering
	};
}
