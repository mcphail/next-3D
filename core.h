/*
 * Title:			Core Definitions
 * Author:			Dean Belfield
 * Created:			20/08/2025
 * Last Updated:	25/10/2025
 *
 * Modinfo:
 * 25/10/2025:		Removed SCREEN_WIDTH, SCREEN_HEIGHT and START_8K_BANK
 */

#ifndef __CORE_H__
#define __CORE_H__

#define BREAK { intrinsic_emit(0xFD); intrinsic_emit(0x00); }
#define EXIT  { intrinsic_emit(0xDD); intrinsic_emit(0x00); }
#define NOP  { intrinsic_emit(0x00); }
#define NextReg(r,v)    ZXN_NEXTREG_helper(r,v)
#define NextRegA(r,var) ZXN_NEXTREGA_helper(r,var)

// nicer types
typedef	uint8_t		uint8;
typedef	int8_t		int8;
typedef	uint16_t	uint16;
typedef	int16_t		int16;
typedef	uint32_t	uint32;
typedef	int32_t		int32;

#endif //__CORE_H__
