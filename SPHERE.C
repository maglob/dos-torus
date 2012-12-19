/* sphere.c
 *	Generates a 3D sphere
 *
 *	23.2.1996	Marko Aalto, maaalto@cc.helsinki.fi
 */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

typedef struct {
	double x, y, z;
} Point;

int main(int argc, char *argv[])
{
	int vstep, hstep, radius, i, j, color, multip;
	int ix, iy, iz;
	double vad, had, ha, va, x, y, z;
	Point *p, *points;
	
	if(argc != 6) {
		puts("usage: sphere <vertica steps> <horizontal steps> <radius> <color> <multip>");
		return 0;
	}

	vstep = atoi(argv[1]);
	hstep = atoi(argv[2]);
	radius = atoi(argv[3]);
	color = atoi(argv[4]);
	multip = atoi(argv[5]);

	points = malloc(vstep*hstep * sizeof(Point));
	if(!points) {
		puts("Out of memory.");
		return -1;
	}

	vad = M_PI*2 / vstep;
	had = M_PI*2 / hstep;
	p = points;
	for(ha=0, j=0; j<hstep/2; j++, ha+=had) {
		for(va=0, i=0; i<vstep; i++, va+=vad, p++) {
			z = 0;
			x = cos(va) * radius;
			y = sin(va) * radius;
			p->y = y;
			p->x = cos(ha)*x + sin(ha)*z;
			p->z = sin(ha)*x - cos(ha)*z;
		}
	}

	/* Print out the points/vertices
	 */
	p = points;
	for(j=0; j<hstep/2; j++) {
		for(i=0; i<vstep; i++, p++) {
			/* printf("\tdd\t%6.4f, %6.4f, %6.4f\n", p->x, p->y, p->z); */
			ix = p->x * multip;
			iy = p->y * multip;
			iz = p->z * multip;
			printf("\tdd %10d, %10d, %10d\n", ix, iy, iz);	
		}
	}

	/* Print out the polygons/triangles
	 */
	color = 0;
	for(j=0; j<hstep/2-1; j++) {
		for(i=0; i<vstep-1; i++) {
			printf("\tdb %3d, %3d, %3d, %d\n",
				j*vstep+i, j*vstep+i+1, (j+1)*vstep+i, color++&255);
			printf("\tdb %3d, %3d, %3d, %d\n",
				(j+1)*vstep+i+1, (j+1)*vstep+i, j*vstep+i+1, color++&255);
		}
		printf("\tdb %3d, %3d, %3d, %d\n",
			j*vstep+i, j*vstep, (j+1)*vstep+i, color++&255);
		printf("\tdb %3d, %3d, %3d, %d\n",
			(j+1)*vstep, (j+1)*vstep+i, j*vstep, color++&255);
	}

	for(i=0; i<vstep-1; i++) {
		printf("\tdb %3d, %3d, %3d, %d\n",
			j*vstep+i, j*vstep+i+1, i, color++&255);
		printf("\tdb %3d, %3d, %3d, %d\n",
			i+1, i, j*vstep+i+1, color++&255);
	}
	printf("\tdb %3d, %3d, %3d, %d\n",
		j*vstep+i, j*vstep, i, color++&255);
	printf("\tdb %3d, %3d, %3d, %d\n",
		0, i, j*vstep, color++&255);
				
	return 0;
}
