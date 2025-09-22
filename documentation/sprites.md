# sprites.h/asm

It is recommended that the Next sprites layer is initialised with the following NextReg command:

`NextReg(0x15,0x21); // Enable sprites and clipping, SLU priority`

## Functions

`void spriteInit(uint8_t pattern, uint8_t * data) __z88dk_callee;`

Initialise a sprite

- pattern: Index to store the sprite data in the Next
- data: Pointer to a 256 byte array of sprite data to store in the pattern

`void spriteDraw(uint8_t sprite, uint8_t pattern, uint16_t x, uint16_t y) __z88dk_callee;`

Draw a single sprite

- sprite: The sprite to use (set bit 7 to draw, reset bit 7 to erase)
- pattern: The pattern to use for the sprite
- x,y: Screen coordinates for the sprite