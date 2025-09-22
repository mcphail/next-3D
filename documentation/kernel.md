# kernel.asm/h

## Functions

`void InitKernel(void);`

Initialise the kernel (currently stubbed, does nothing)

`void SetUpIRQs(void);`

Set up the default IRQs for the Spectrum Next

`void WaitVBlank(void);`

Wait for the vertical blank interrupt

`void Layer2Enable(uint16 onoff);`

Enable Layer 2 - pass 1 to enable it, 0 to disable

`void stop(void);`

Stop execution of the program (goes into an infinite JP loop) - used for debugging in emulators

`void setCPU(uint8 speed);`

Set the Next CPU speed, where speed is one of:

- 0: 3.5Mhz
- 1: 7Mhz
- 2: 14Mhz
- 3: 28Mhz

`void DMACopy(uint16 src, uint16 dst, uint16 len);`

Use the DMA to copy data between the addresses src and dst, with the size of the data block specified by len.

There is an overhead in setting up the DMA; for small amounts of data (less than 20 bytes) it is faster to use LDIR.

`void DMAFill(uint16 dst, uint16 len, uint8 val);`

Use the DMA to fill a block of data with the specified value from address dst, with the size of the block specified by len.

There is an overhead in setting up the DMA; for small blocks of memory (less than 16 bytes) it is faster to use LDIR.

`void ReadKeyboard(void);`

Read the Next keyboard. This sets a flag in the array Keys for the corresponding key. The key values are in global.inc.

For example, to check for the key 'SPACE', use the following code:

```
	ReadKeyboard(); // This only needs to be done once per game loop
	...
	if(Keys[VK_SPACE]) {
		...
	}
```

`uint16 ReadNextReg(uint16 reg);`

Read a Next register (specified by reg)
