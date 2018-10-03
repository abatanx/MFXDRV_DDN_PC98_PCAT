#include	<stdio.h>
int main(int argc,char **argv)
{
	FILE *fpr;
	unsigned char *buf;
	
	if( argc<=1 )return 1;

	if( (fpr=fopen(argv[1],"rb"))==NULL )
	{
		puts("Can\'t open file.\n");
		return 1;
	}
	