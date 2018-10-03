#include	<stdio.h>
#include	<math.h>

void main(void)
{
	int i;
	double a;
	for( i=0; i<256; i++)
	{
		a=sin((double)i/256*2*3.1459)*100.0;
		printf("%4.0lf\n",a);
	}
}
