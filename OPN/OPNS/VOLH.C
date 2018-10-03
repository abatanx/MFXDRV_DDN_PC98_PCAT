#include	<stdio.h>
#include	<math.h>

void main(void)
{
	double l;
	for( l=1.0; l<30; l+=30/128.0 )
	{
		printf("%3d ",(int)(log(l)*37.5));
	}
}
