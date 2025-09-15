// sprites.h
#ifndef __SPRITES_H__
#define __SPRITES_H__

extern void spriteInit(uint8_t pattern, uint8_t * data) __z88dk_callee;
extern void spriteDraw(uint8_t sprite, uint8_t pattern, uint16_t x, uint16_t y) __z88dk_callee;

#endif 	//__SPRITES_H__