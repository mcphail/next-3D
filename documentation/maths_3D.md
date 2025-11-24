# maths_3S.h/asm

The trigonometry assumes 256 bytes per full rotation of a circle for convenience and performance reasons.

## Functions

### Rotate (8-bit model space and 16-bit world space)

	Point8_3D rotate8_3D(Point8_3D p, Angle_3D theta);
	Point16_3D rotate16_3D(Point16_3D p, Angle_3D theta);

Rotate point P around all axes in the order x,y,z by the angles specified in theta

For performance reasons, models are rotated around their origin using the 8-bit function. Their origin is then rotated around the camera (viewer) using the 16-bit function, and their rotation adjusted to face the viewer in the correct orientation.

### Perspective Projection

	Point16 project3D(Point16_3D pos, Point8_3D r);

Projects a point from model space (r) into world space (pos) with perspective

Optimised version of this C routine:

	int16_t z = pos.z + r.z;  
	Point16 p = {
		muldivs32_16x16(pos.x + r.x, pd, z) + 128, // r.x * pd / z
		muldivs32_16x16(pos.y + r.y, pd, z) + 96,  // r.y * pd / z
	};
	return p;

- pos: he position of the object in space
- r: The point to project

### Backface Culling

Backface culling uses polygon winding order, where p1, p2 and p3 describe the three vertices of the face

	uint8_t windingOrder(Point16 p1, Point16 p2, Point16 p3);

Returns p1.x*(p2.y-p3.y)+p2.x*(p3.y-p1.y)+p3.x*(p1.y-p2.y)<0

If true (1) then the face can be rendered