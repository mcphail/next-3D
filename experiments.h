// experiments.h
#ifndef __EXPERIMENTS_H__
#define __EXPERIMENTS_H__

Point16_3D rotate16_3D(Point16_3D *p, Angle_3D * theta);

Point16 project3D(Point16_3D * pos, Point8_3D * r);

int16_t dotp(Point16_3D p1, Point16_3D p2);
int16_t crossp(Point16_3D p1, Point16_3D p2);
Point8_3D calculateNormal(Point8_3D p1, Point8_3D p2, Point8_3D p3);

void lineT_8(uint8_t x1, uint8_t y1, uint8_t x2, uint8_t y2);
uint8_t clipLineT(Point16 p1, Point16 p2);
void testTClipped(Point16 p1, Point16 p2, Point16 p3, int16_t colour);

void rotateModelC(Point16_3D p, Angle_3D a, Model_3D * m);
void renderModelC(Model_3D * m);
void drawObjectC(Object_3D * o);

#endif 	//__EXPERIMENTS_H__