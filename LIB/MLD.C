/*
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 Driver Loader
//                               MLD(tm)
//   copyright (c) 1994 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
*/
#include	<stdio.h>
#include	<string.h>
#include	<dos.h>
#include	"mfxddn.h"
#if			CONFIG_FILELINK == TRUE
#include	"fl.h"
#endif

static char x_argv[32][256];
static int  x_argc;

static char far *xdv_driver;
static unsigned size;

int  load_xdv(char *);
int  start_xdv(int);
void ddn_int51_start(int);
void ddn_int51_end(void);
int  ddn_check_xdv_driver(unsigned);
int  ddn_run_xdv_driver(unsigned);
int  ddn_regist_xdv_driver(unsigned);

#if		CONFIG_FILELINK == TRUE
int mfxddn_load_driver_filelink(char *filename,char *parameter,int mesgflag)
#else
int mfxddn_load_driver(char *filename,char *parameter,int mesgflag)
#endif
{
	int x_setc;
	char *token;

	if( mfxddn_install_check()==EOF )return EOF;

	token = strtok(parameter," ");
	for( x_argc=0; x_argc<32 && token!=NULL ; x_argc++)
	{
		strcpy(x_argv[x_argc],token);
		token = strtok(NULL," ");
	}
	if( load_xdv(filename)==EOF )return EOF;
	return start_xdv(mesgflag);
}

/*
// ドライバーのロード
*/
static int load_xdv(char *filename)
{
	FILE *fpr;
	unsigned i;

#if		CONFIG_FILELINK == TRUE
	if( (fpr=fl_open(filename,"rb"))==NULL )return EOF;
#else
	if( (fpr=fopen(filename,"rb"))==NULL )return EOF;
#endif

#if		CONFIG_FILELINK == TRUE
	size = finf.size;
#else
	fseek( fpr,0L,SEEK_END );
	size = ftell(fpr);
	fseek( fpr,0L,SEEK_SET );
#endif
	if( (xdv_driver = ddn_keep_highmemory((long)(size+0x100)))==NULL ){
		fclose(fpr);
		return EOF;
	}

#if		__TURBOC__ && (__COMPACT__+__LARGE__+__HUGE__==1)
	fread( xdv_driver+0x100,size,1,fpr );
#else
	for( i=0; i<size; i++)*(xdv_driver+0x100+i)=fgetc(fpr);
#endif

	fclose(fpr);
	return NULL;
}

/*
// XDVドライバー実行
*/
static int start_xdv(int mesgflag)
{
	unsigned seg;
	int ch,stayf;
	char *xdv_id;

	seg    = FP_SEG(xdv_driver);
//	type   = ddn_check_xdv_driver( seg );

	ddn_int51_start(mesgflag);					/* int51h割り込みを占有 */
	ch   = ddn_run_xdv_driver( seg );	/* XDVのDRV_INIT実行    */
	ddn_int51_end();					/* int51h割り込みを解放 */

	if( ch!=NULL )	stayf = TRUE;
	else			stayf = FALSE;

	if( stayf==TRUE )
		if( ddn_regist_xdv_driver( seg )==EOF )return EOF;

	ddn_stay_memory( xdv_driver );
	return NULL;
}

#if		CONFIG_FILELINK == FALSE

long ddn_get_option_parameter( char *option,int type )
{
	int i,l1,l2,x;
	char xa1[256],xa2[256];
	
	for( i=0; i<x_argc; i++){
		strcpy( xa1,option      );
		strcpy( xa2,x_argv[i]+1 );
	
		if( *x_argv[i]=='/' || *x_argv[i]=='-' ){
			x = ddn_instr(xa2,'=');
			if( x!=EOF )l2 = x-1;
			else {
				x = ddn_instr(xa2,':');
				if( x!=EOF )l2 = x-1;
				else {
					l2 = strlen( xa2 );
				}
			}
			
			l1 = strlen( xa1 );
		
			if( l1==l2 && strnicmp(xa1,xa2,l1)==NULL ){
				switch( type ){
					case 0:			/* オプションなしの場合 */
						if( x!=EOF )return -1;
						return 0;
					case 1:			/* 数値 */
						if( x==EOF )return -1;
						return((long)ddn_valtonum(xa2+x));
					case 2:			/* 文字 */
						if( x==EOF )return -1;
						return((long)(x_argv[i]+x+1));
					case 3:			/* +-スイッチ */
						if( x==EOF )return -1;
						if( xa2[x]=='+' )return 0;
						else if(xa2[x]=='-' )return 1;
						else return -1;
					case 4:			/* on,offスイッチ */
						if( x==EOF )return -1;
						if( stricmp(xa2+x,"on")==NULL )return 0;
						else if( stricmp(xa2+x,"off")==NULL )return 1;
						else return -1;
					case 5:			/* true,falseスイッチ */
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

char far *ddn_load_file_main(char *filename)
{
	FILE *fpr;
	unsigned size,i;
	char far *file_buffer;

	if( (fpr=fopen(filename,"rb"))==NULL )return(NULL);

	fseek( fpr,0L,SEEK_END );
	size = ftell(fpr);
	fseek( fpr,0L,SEEK_SET );

	if( (file_buffer=ddn_keep_highmemory((long)size))==NULL ){
		fclose(fpr);
		return(NULL);
	}

#if		__TURBOC__ && (__COMPACT__+__LARGE__+__HUGE__==1)
	fread( file_buffer,size,1,fpr );
#else
	for( i=0; i<size; i++)*(file_buffer+i) = fgetc(fpr);
#endif

	fclose( fpr );
	return file_buffer;
}

char far *ddn_load_file_stay_main(char *filename)
{
	FILE *fpr;
	unsigned size;
	char far *file_buffer;
	
	file_buffer = ddn_load_file_main(filename);
	if( !file_buffer )return(NULL);
	ddn_stay_memory(file_buffer);
	return file_buffer;
}

#endif
