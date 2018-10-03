//    FILELINK FILE SEARCHER system release ver.2      //
// copyright (c) 1993 T.Kobayashi All Rights Reserved. //
#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>
#include	"fl.h"
#define		MAX_FILELINK	64

char		FILELINK_library_file[256];
int			FILELINK_use_switch=EOF;
FILEINFO	file_info[MAX_FILELINK];
FILEDEF		finf;
int fl_file(char *file)
{
	int i;
	char header[10];
	FILE *fpr;
	long fp;
	
	FILELINK_use_switch = EOF;
	strcpy( FILELINK_library_file , file );

	if( (fpr=fopen(file,"rb"))==NULL )return EOF;

	for( i=0 ; i<4 ; i++ )header[i] = fgetc(fpr);
	header[4]='\0';

	if( ddn_strcmp(header,"Fl2\x1a") ){
		header[2] = '\0';
		if( ddn_strcmp(header,"MZ")!=0 )return EOF;
		fseek(fpr,-5L,SEEK_END);
		if( fgetc(fpr)!='*' ){
			fclose(fpr);
			return EOF;
		}
		fread(&fp,sizeof(long),1,fpr);
		fseek(fpr,fp+4,SEEK_SET);
	}
	FILELINK_use_switch=0;
	
	while( fgetc(fpr)==1 ){
		fread( &file_info[FILELINK_use_switch].finf,sizeof(FILEDEF),1,fpr );
		file_info[FILELINK_use_switch].fp = ftell(fpr);
		fseek( fpr,file_info[FILELINK_use_switch].finf.size,SEEK_CUR );
		FILELINK_use_switch++;
	}
	fclose(fpr);
	return FILELINK_use_switch;
}
void fl_switch(int SW)
{
	FILELINK_use_switch=SW;
}
FILE *fl_open(char *file,char *open_mode)
{
	FILE *fpr,*fpr2;
	int c,i;
	long fp;
	
	if(FILELINK_use_switch==EOF){
		fpr2 = fopen(file,open_mode);
		if( !fpr2 )return NULL;
		finf.atr  = 0;
		finf.time = 0;
		finf.date = 0;
		fseek(fpr2,0L,SEEK_END);
		finf.size = ftell(fpr2);
		fseek(fpr2,0L,SEEK_SET);
		strcpy(finf.fname,file);
		return(fpr2);
	}

	c=EOF;
	for( i=0 ; i<FILELINK_use_switch ; i++){
		if( !stricmp(file_info[i].finf.fname,file) ){
			finf = file_info[i].finf;
			c    = NULL;
			fp   = file_info[i].fp;
			break;
		}
	}
	if(c==EOF)return(NULL);
	if( (fpr=fopen(FILELINK_library_file,open_mode))==NULL )return NULL;
	fseek(fpr,fp,SEEK_SET);
	return(fpr);
}
