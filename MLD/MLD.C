//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 Driver Loader
//                               MLD(tm)
//   copyright (c) 1994 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
#include	<stdio.h>
#include	<dos.h>
#include	<dir.h>
#include	<string.h>
#include	<mylib.h>
#include	<mem.h>

#define		version		"2.30"
#define		DELIMITER	","

enum {
	_A,_B,_C,_D,_E,_F,_G,_H,_I,_J,_K,_L,_M,
	_N,_O,_P,_Q,_R,_S,_T,_U,_V,_W,_X,_Y,_Z
};

int opt[_Z-_A+1];

char *x_argv[32];
int  x_argc;

char far *xdv_driver;
unsigned size;

int  load_xdv(char *,char *);
void start_xdv(void);

void int51_start(void);
void int51_end(void);
int  check_xdv_driver(unsigned);
int  run_xdv_driver(unsigned);
int  regist_xdv_driver(unsigned);

void main(int argc,char **argv)
{
	unsigned char	pa[MAXPATH],dr[MAXDRIVE],di[MAXDIR],fi[MAXFILE],ex[MAXEXT],
					filename[MAXPATH],optstr[1024],*x_setv[256],*tp,ff[MAXPATH];
	int i,l,ai,opt_ofs,x_setc;

	if( argc<=1 ){
		printf(
			"Multi module music driver MFXDRV/DDN xdv driver loader version %s\n"
			"copyright (c) 1994 ABA / T.Kobayashi and Interfair  all rights reserved.\n"
			"usage ;\n"
			"        mld.exe <-|/[w]> [filename] <driver's option...>\n"
			"option ;\n"
			"        w     強制組み込み\n",
			version
		);
		exit(EOF);
	}

	if( mfxddn_bgm_init2(0)==EOF ){
		printf("MFXDRV/DDN が常駐してません。\n");
		exit(EOF);
	}

	for( i=_A; i<=_Z; i++)opt[i] = FALSE;
	
	if( *argv[1]=='-' || *argv[1]=='/' )
	{
		ai = 2;
		for( i=1; *(argv[1]+i)!=NULL ; i++ )
		{
			switch (*(argv[1]+i))
			{
				case 'w':case 'W':		/* 強制組み込み */
					opt[_W] = TRUE;
					break;
				default:
					printf("オプションのエラーです。\n");
					break;
			}
		}
	}
	else ai = 1;

	optstr[0]=NULL;

	for( i=ai; i<argc; i++)
	{
		strcat( optstr,argv[i] );
		strcat( optstr," "     );
	}

	x_setc = 0;
	tp = strtok(optstr,DELIMITER);
	while( tp!=NULL )
	{
		x_setv[x_setc++] = tp;
		tp = strtok(NULL,DELIMITER);
		if( x_setc>255 )break;
	}

	for( i=0; i<x_setc; i++)
	{
		x_argc = -1;
		tp = strtok(x_setv[i]," ");
		while( tp!=NULL )
		{
			if( x_argc==-1 )
				strcpy( filename,strlwr(tp) );
			else
				x_argv[x_argc] = tp;
			
			x_argc++;
			tp = strtok(NULL," ");
		}
		fnsplit( filename ,dr,di,fi,ex     );
		if( ex[0]==NULL )
			fnmerge( pa,dr,di,fi,".xdv" );
		else
			fnmerge( pa,dr,di,fi,ex     );

		fnmerge( ff,"","",strlwr(fi),"" );
		strcpy( pa,strlwr(pa) );

		if( load_xdv(pa,ff)==EOF )continue;
		start_xdv();
	}
}

// ドライバーのロード
int load_xdv(char *filename,char *xdvfile)
{
	FILE *fpr;
	char *oldname,dta[256],dtype;
	oldname = filename;
	
	printf("loading...");
	if( (fpr=fopen(filename,"rb"))==NULL ){
		if( (filename=searchpath(filename))==NULL ){
			printf("\'%s\' が見つかりません。\n",oldname );
			clearerr(fpr);
			return EOF;
		}
		clearerr( fpr );
		if( (fpr=fopen(filename,"rb"))==NULL ){
			printf("\'%s\' が open できません。\n",oldname );
			clearerr(fpr);
			return EOF;
		}
	}
	printf("\r");
	
	fseek( fpr,0,SEEK_END );
	size = ftell(fpr);
	fseek( fpr,0,SEEK_SET );

	if( (xdv_driver = keep_highmemory(size+0x100))==NULL ){
		printf("メモリーが %dbytes 足りません。\n",size+0x100);
		exit(EOF);
	}
	memset( xdv_driver,0,size+0x100 );
	make_psp( FP_SEG(xdv_driver) );
	
	fread( xdv_driver+0x100,size,1,fpr );
	fclose(fpr);
	
	switch(xdv_driver[0x104+1])
	{
		case 0x00:		dtype = 's';	break;
		case 0x10:		dtype = 't';	break;
		case 0x20:		dtype = 'e';	break;
		default:		dtype = 'X';	break;
	}
	sprintf(dta,"mld v"version"[%c]%s\x0d",dtype,xdvfile);
	xdv_driver[0x80] = (char)strlen(dta);
	strcpy( xdv_driver+0x81,dta );
	return NULL;
}

// XDVドライバー実行
void start_xdv(void)
{
	unsigned seg,type;
	int ch,stayf;
	FILE *fpw;
	char *xdv_id;

	seg    = FP_SEG(xdv_driver);
	type   = check_xdv_driver( seg );
	xdv_id = MK_FP(seg , 0x106);

	if( mfxddn_get_driver_table(xdv_id)!=EOF && opt[_W]==FALSE )
	{
		printf("同じIDのドライバがすでに組み込まれています。\n");
		return;
	}

	int51_start();						/* int51h割り込みを占有 */
	ch   = run_xdv_driver( seg );		/* XDVのDRV_INIT実行    */
	int51_end();						/* int51h割り込みを解放 */

	stayf = FALSE;

	if( (int)ch==-1 )
	{
		printf("以上のオプションが使用可能です。\n");
		exit(0);
	}

	if( type==0x0000 ){
		if( ch!=NULL ){
			printf("音源が %dチャンネル使用可能です。\n",ch );
			stayf = TRUE;
		}
		else
			printf("音源が搭載されていません。\n");
	}
	else if( type==0x1000 ){
		if( ch!=NULL ){
			printf("タイマーを初期化しました。\n");
			stayf = TRUE;
		}
		else
			printf("タイマーが使用不能です。\n");
	}
	else if( type==0x2000 ){
		if( ch!=NULL ){
			stayf = TRUE;
		}
		else
			printf("組み込めません。\n");
	}
	if( stayf==TRUE ){
		if( regist_xdv_driver( seg )==EOF ){
			printf("MFXDDNのドライバーテーブルがいっぱいです。\n");
			return;
		}

		stay_memory( xdv_driver );
		printf(
			"常駐しました。 \n"
			"   Enabled : [%s] seg=%04x(h) size=%5u(Bytes) Type=",
			xdv_id,
			seg,
			size
		);
		switch( type ){
			case 0x0000:
				puts("SOUND-Driver");
				break;
			case 0x1000:
				puts("TIMER-Driver");
				break;
			case 0x2000:
				puts("ETC-Driver");
				break;
			default:
				printf("謎(%04x)\n",(word)type);
				break;
		}
	}
	printf("\n");
}

