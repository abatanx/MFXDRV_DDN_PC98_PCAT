//
// OPN Sound Editor 
//

#include	<stdio.h>
#include	<mylib.h>
#include	"opns.h"

OPNPARAM	opn[128];
int			param[11][5];

#define		version		"1.00"

void load_xsdfile( char * );

void main(int argc,char **argv)
{
	printf(
		"YM2203(OPN) xsd sound file editor version %s\n"
		"copyright (c) 1994 by ABA / T.Kobayashi and Interfair "
		"all rights reserved.\n",
		version
	);

	if( argc<=1 ){
		puts( "usage ; opnseh [filename.xsd]");
		exit(EOF);
	}
	
	load_xsdfile( *(argv+1) );
}

// xsdファイル読み込み
void load_xsdfile( char *filename )
{
	FILE *fpr;
	int i;
	char buf[256];
	
	if( (fpr=fopen( filename,"rb" ))==NULL ){
		printf("\'%s\' が見つかりません。\n", filename );
		exit(EOF);
	}
	fread( buf,6,1,fpr );
	if( strncmp(buf,"OPNX1A",6)!=NULL ){
		printf("xsdファイルではありません。\n");
		fcloseall();
		exit(EOF);
	}
	if( getw(fpr)!=sizeof(OPNPARAM) ){
		printf("ファイルのフォーマットが違います。\n");
		fcloseall();
		exit(EOF);
	}
	for( i=0; i<128; i++)fread( &opn[i],sizeof(OPNPARAM),1,fpr );
	fclose(fpr);
}

// 各パラメータに分離
void param_split(void)
{
	for( i=0; i<4; i++ ){
		




