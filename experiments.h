/*
 * Title:			Experimental Code
 * Author:			Dean Belfield
 * Created:			20/08/2025
 * Last Updated:	24/09/2025
 *
 * Modinfo:
 */

#ifndef __EXPERIMENTS_H__
#define __EXPERIMENTS_H__

int16_t dotp(Point16_3D p1, Point16_3D p2);
int16_t crossp(Point16_3D p1, Point16_3D p2);
Point8_3D calculateNormal(Point8_3D p1, Point8_3D p2, Point8_3D p3);

void initStars(void);
void drawStars(int speed);

#endif 	//__EXPERIMENTS_H__