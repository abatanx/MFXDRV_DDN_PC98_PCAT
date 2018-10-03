/*---------------------------------------------------------------------------
       MFXDRV/DDN system XMML3.00 compiler MPLUS(mfxc+) release 1.00
  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
 *---------------------------------------------------------------------------*/
//
// リロケータブルラベリングシステムライブラリ
//
#include	<stdio.h>
#include	<stdlib.h>
#include	<mfile.h>
#include	"mplus.h"

#define		MAXLABEL		1500

typedef struct {
	long fp;
	int  type;
	long value;
	int  size;
} LABEL;
static LABEL label[MAXLABEL];

// リロケータブルラベリングシステム -------------------------------------------
void init_label( void )
{
	int i;
	for( i=0; i<MAXLABEL; i++)label[i].fp = EOF;
}

void set_label( MFILE *fp,int type,int size )
{
	int i,j,label_no;
	
	label_no = EOF;
	for( i=0; i<MAXLABEL; i++){
		if( label[i].fp==EOF ){
			label_no = i;
			break;
		}
	}
	if( label_no==EOF ){
		erl(NULL,SYS|ERR);
		printf("set_label():Label buffer が不足しています。\n");
		exits(1);
	}
	
	label[ label_no ].fp   = fp->fp;
	label[ label_no ].type = type;
	label[ label_no ].value= EOF;
	label[ label_no ].size = size;
	mwrite( "@@@@@@@@",size,fp );
}

void set_label_value( int type,long value )
{
	int i,j,label_no;

	label_no = EOF;
	for( i=0; i<MAXLABEL; i++){
		if( label[i].type==type ){
			label_no = i;
			break;
		}
	}
	if( label_no==EOF ){
		erl(NULL,ERR|SYS);
		printf("set_label_value():Relocatable Buffer が破壊されています。\n");
		exits(1);
	}
	
	label[ label_no ].type = EOF;
	label[ label_no ].value= value;
}

void write_label(char *fname)
{
	int i;
	FILE *fpw;
	
	if( (fpw=fopen(fname,"r+b"))==NULL ){
		erl(NULL,ERR|SYS);
		printf("write_label(\"%s\"):ファイルが更新できません。\n",fname );
		exits(1);
	}
	for( i=0; i<MAXLABEL; i++){
		if( label[i].fp   ==EOF )continue;
		if( label[i].value==EOF ){
			printf("m\n");
		}
		
		fseek ( fpw,label[i].fp,SEEK_SET );
		fwrite( &label[i].value,label[i].size,1,fpw );
	}
	fclose( fpw );
}

