# maths.h/asm

The trigonometry assumes 256 bytes per full rotation of a circle for convenience and performance reasons.

## Functions

### Trigonometry 

All trig functions do f(a,m) = f(a)*m/256

	int16_t cos16(uint8_t a, int16_t m);
	int16_t sin16(uint8_t a, int16_t m);
	int8_t cos8(uint8_t a, int16_t m);
	int8_t sin8(uint8_t a, int16_t m);

### Multiplication and Division

	uint32_t mulu32_16x16(uint16_t a, uint16_t b);
	uint16_t mulu16_16x16(uint16_t a, uint16_t b);
	uint16_t divu16_16x16(uint16_t a, uint16_t b);

	int32_t muls32_16x16(int16_t a, int16_t b);
	int16_t muls16_16x16(int16_t a, int16_t b);
	int16_t divs16_16x16(int16_t a, int16_t b);

### Compound Functions

	int16_t muldivs32_16x16(int16_t a, int16_t b, int16_t c);
	int16_t muldivs16_16x16(int16_t a, int16_t b, int16_t c);

Returns a * b / c, with the internal calculation done in 32 or 16 bits
