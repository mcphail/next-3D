/*
 * Title:			Sprite Helper Functions
 * Author:			Dean Belfield
 * Created:			20/08/2025
 * Last Updated:	22/09/2025
 *
 * Modinfo:
 */

#ifndef __SPRITES_H__
#define __SPRITES_H__

extern void spriteInit(uint8_t pattern, uint8_t * data) __z88dk_callee;
extern void spriteDraw(uint8_t sprite, uint8_t pattern, uint16_t x, uint16_t y) __z88dk_callee;

#endif 	//__SPRITES_H__