//
// Kernel functions
//
#ifndef __KERNEL_H__
#define __KERNEL_H__

#include "core.h"

// half row 1
#define VK_CAPS		0
#define VK_Z		1
#define VK_X		2
#define VK_C		3
#define VK_V		4
// half row 2
#define VK_A		5
#define VK_S		6
#define VK_D		7
#define VK_F		8
#define VK_G		9
// half row 3
#define VK_Q		10
#define VK_W		11
#define VK_E		12
#define VK_R		13
#define VK_T		14
// half row 4
#define VK_1		15
#define VK_2		16
#define VK_3		17
#define VK_4		18
#define VK_5		19
// half row 5
#define VK_0		20
#define VK_9		21
#define VK_8		22
#define VK_7		23
#define VK_6		24
// half row 6
#define VK_P		25
#define VK_O		26
#define VK_I		27
#define VK_U		28
#define VK_Y		29
// half row 7
#define VK_ENTER	30
#define VK_L		31
#define VK_K		32
#define VK_J		33
#define VK_H		34
// half row 8
#define VK_SPACE	35
#define VK_SYM		36
#define VK_M		37
#define VK_N		38
#define VK_B		39

extern	uint8	VBlank;
extern	uint8	Port123b;
extern	uint8	Keys[40];
extern	uint8	RawKeys[8];

extern void InitKernel(void);
extern void SetUpIRQs(void) __preserves_regs(b,c,d,e,h,l,iyl,iyh);
extern void WaitVBlank(void)  __preserves_regs(b,c,d,e,h,l,iyl,iyh);
extern void Layer2Enable(uint16 onoff) __z88dk_fastcall __preserves_regs(d,e,h,l,iyl,iyh);
extern void stop(void);
extern void setCPU(uint8 speed) __z88dk_fastcall;
extern void DMACopy(uint16 src, uint16 dst, uint16 len) __z88dk_callee __preserves_regs(a,d,e,iyl,iyh);
extern void DMAFill(uint16 dst, uint16 len, uint8 val) __z88dk_callee __preserves_regs(a,d,e,iyl,iyh);
extern void ReadKeyboard(void) __z88dk_callee;

extern uint16 ReadNextReg(uint16 reg) __z88dk_callee __preserves_regs(iyl,iyh);

#endif	//__KERNEL_H__



