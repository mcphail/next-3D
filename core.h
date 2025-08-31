// main.h
#ifndef __CORE_H__
#define __CORE_H__

#define BREAK { intrinsic_emit(0xFD); intrinsic_emit(0x00); }
#define EXIT  { intrinsic_emit(0xDD); intrinsic_emit(0x00); }
#define NOP  { intrinsic_emit(0x00); }
#define NextReg(r,v)    ZXN_NEXTREG_helper(r,v)
#define NextRegA(r,var) ZXN_NEXTREGA_helper(r,var)

#define START_8K_BANK	18	   // START_16K_BANK * 2

#define SCREEN_WIDTH 256       // Our resolution
#define SCREEN_HEIGHT 192

// nicer types
typedef	uint8_t		uint8;
typedef	int8_t		int8;
typedef	uint16_t	uint16;
typedef	int16_t		int16;
typedef	uint32_t	uint32;
typedef	int32_t		int32;

#endif //__CORE_H__
