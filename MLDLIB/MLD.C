//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 Driver Loader
//                               MLD(tm)
//   copyright (c) 1994 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
#include	<stdio.h>
#include	<dos.h>
#include	<dir.h>
#include	<string.h>
#include	<mfxddn.h>

static char x_argv[32][256];
static int  x_argc;

static char far *xdv_driver;
static unsigned size;

int  load_xdv(char *);
int  start_xdv(void);
void int51_start(void);
void int51_end(void);
int  check_xdv_driver(unsigned);
int  run_xdv_driver(unsigned);
int  regist_xdv_driver(unsigned);

int mfxddn_load_driver(char *filename,char *parameter,...)
{
	int x_setc;
	char *token;

	if( MFXDDN_Initialize==EOF )return EOF;

	token = strtok(parameter," ");
	for( x_argc=0; x_argc<32 && token!=NULL ; x_argc++)
	{
		strcpy(x_argv[x_argc],token);
		token = strtok(NULL," ");
	}
	if( load_xdv(filename)==EOF )return EOF;
	return start_xdv();
}

// ドライバーのロード
static int load_xdv(char *filename)
{
	FILE *fpr;
	
	if( (fpr=fopen(filename,"rb"))==NULL )return EOF;

	fseek( fpr,0,SEEK_END );
	size = ftell(fpr);
	fseek( fpr,0,SEEK_SET );
		if( (xdv_driver = ddn_keep_highmemory(size+0x100))==NULL ){
		fclose(fpr);
		return EOF;
	}
	fread( xdv_driver+0x100,size,1,fpr );
	fclose(fpr);
	return NULL;
}

// XDVドライバー実行
static int start_xdv(void)
{
	unsigned seg,type;
	int ch,stayf;
	char *xdv_id;

	seg    = FP_SEG(xdv_driver);
	type   = check_xdv_driver( seg );

	int51_start();						/* int51h割り込みを占有 */
	ch   = run_xdv_driver( seg );		/* XDVのDRV_INIT実行    */
	int51_end();						/* int51h割り込みを解放 */

	stayf = FALSE;
	if     ( type==0x0000 )
		if( ch!=NULL )stayf = TRUE;
	else if( type==0x1000 )
		if( ch!=NULL )stayf = TRUE;
	else if( type==0x2000 )
		if( ch!=NULL )stayf = TRUE;

	if( stayf==TRUE )
		if( regist_xdv_driver( seg )==EOF ){
			return EOF;
		}
	ddn_stay_memory( xdv_driver );
	return NULL;
}

static long get_option_parameter( char *option,int type )
{
	int i,l1,l2,x;
	char xa1[256],xa2[256];
	
	for( i=0; i<x_argc; i++){
		strcpy( xa1,option      );
		strcpy( xa2,x_argv[i]+1 );
	
		if( *x_argv[i]=='/' || *x_argv[i]=='-' ){
			x = instr(xa2,'=');
			if( x!=EOF )l2 = x-1;
			else {
				x = instr(xa2,':');
				if( x!=EOF )l2 = x-1;
				else {
					l2 = strlen( xa2 );
				}
			}
			
			l1 = strlen( xa1 );
		
			if( l1==l2 && strnicmp(xa1,xa2,l1)==NULL ){
				switch( type ){
					case 0:			// オプションなしの場合
						if( x!=EOF )return -1;
						return 0;
					case 1:			// 数値
						if( x==EOF )return -1;
						return((long)ddn_valtonum(xa2+x));
					case 2:			// 文字
						if( x==EOF )return -1;
						return((long)(x_argv[i]+x+1));
					case 3:			// +-スイッチ
						if( x==EOF )return -1;
						if( xa2[x]=='+' )return 0;
						else if(xa2[x]=='-' )return 1;
						else return -1;
					case 4:			// on,offスイッチ
						if( x==EOF )return -1;
						if( stricmp(xa2+x,"on")==NULL )return 0;
						else if( stricmp(xa2+x,"off")==NULL )return 1;
						else return -1;
					case 5:			// true,falseスイッチ
						if( x==EOF )return -1;
						if( stricmp(xa2+x,"true")==NULL )return 0;
						else if( stricmp(xa2+x,"false")==NULL )return 1;
						else return -1;
					default:
						return -1;
				}
			}
		}
	}
	return (unsigned long)0xffff0000L;
}

static char *load_file_main(char *filename)
{
	FILE *fpr;
	unsigned size;
	char *file_buffer;
	
	if( (fpr=fopen(filename,"rb"))==NULL )return(NULL);
	
	fseek( fpr,0,SEEK_END );
	size = (unsigned)ftell(fpr);
	fseek( fpr,0,SEEK_SET );
	if( (file_buffer=ddn_keep_highmemory(size))==NULL ){
		fclose(fpr);
		return(NULL);
	}
	fread( file_buffer,size,1,fpr );
	fclose( fpr );
	return file_buffer;
}

static char *load_file_stay_main(char *filename)
{
	FILE *fpr;
	unsigned size;
	char *file_buffer;
	
	file_buffer = load_file_main(filename);
	if( !file_buffer )return(NULL);
	ddn_stay_memory(file_buffer);
	return file_buffer;
}
