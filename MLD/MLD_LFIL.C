// ÉtÉ@ÉCÉãÇÃì«Ç›çûÇ›
#include	<stdio.h>
#include	<string.h>
#include	<dos.h>
#include	<mylib.h>

char *load_file_main(char *filename)
{
	FILE *fpr;
	unsigned size;
	char *file_buffer;
	
	if( (fpr=fopen(filename,"rb"))==NULL )return(NULL);
	
	fseek( fpr,0,SEEK_END );
	size = (unsigned)ftell(fpr);
	fseek( fpr,0,SEEK_SET );
	if( (file_buffer=keep_highmemory(size))==NULL ){
		fclose(fpr);
		return(NULL);
	}
	fread( file_buffer,size,1,fpr );
	fclose( fpr );
	return file_buffer;
}

char *load_file_stay_main(char *filename)
{
	FILE *fpr;
	unsigned size;
	char *file_buffer;
	
	file_buffer = load_file_main(filename);
	if( !file_buffer )return(NULL);
	stay_memory(file_buffer);
	return file_buffer;
}
