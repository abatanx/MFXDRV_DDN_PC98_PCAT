//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 SMF converter XMML object maker.
//                         MCV(tm) version 2.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
#include	<stdio.h>
#include	<stdlib.h>
#include	<dos.h>
#include	<string.h>
#include	<dir.h>
#include	<alloc.h>
#include	<mem.h>
#include	<mylib.h>

#define		TMPFILE_NAME	"mwctmp.$$$"

#define		version_int		1
#define		version_real	20
#define		version_char	' '
#define		mem()			printf("\n	Available memory  :  %ldbytes.\n\n",coreleft())

void compile( char *,char *,char * );
void make_header( char *,char *,int,long );
void mwc_exit(int);
void usage(void);

typedef struct {
	char module[16];
	char channel;
} MODULE;

typedef struct {
	MODULE chain[4];
	long   fp;
	long   size;
	unsigned compless;
	unsigned ext;
} TRACK;

char TMPFILE[256];

int main(int argc,char **argv)
{
	char	dr[MAXDRIVE],di[MAXDIR],fi[MAXFILE],ex[MAXEXT],*tmp,
			wrd[MAXPATH],mbj[MAXPATH],filename[MAXPATH],objname[256],buf[256];
	int		i;
	
	printf(
		"music driver MFXDDN wordfile compiler MWC version %1d.%02d%c\n"
		"copyright (c) 1994 by ABA / T.Kobayashi and Interfair  "
		"All Rights Reserved.\n",
		version_int,
		version_real,
		version_char
	);
	
	if( argc<=1 )usage();
	
	strcpy( filename,"" );
	strcpy( objname,"" );
	for( i=1; i<argc; i++){
		if( **(argv+i)!='/' && **(argv+i)!='-' ){
			strcpy( filename,*(argv+i) );
		}
		else {
			switch( *(*(argv+i)+1) ){
				case 'o':case 'O':			// オブジェクト名
					strncpy( objname,*(argv+ ++i),255 );
					break;
				default:
					printf("Illigal Option : -%c\n",*(*(argv+i)+1) );
					break;
			}
		}
	}
	
	if( (tmp=getenv("TMP"))==NULL )strcpy(TMPFILE,TMPFILE_NAME);
	else {
		strcpy(buf,tmp);
		cut_dirmark(buf);
		sprintf(TMPFILE,"%s\\%s",buf,TMPFILE_NAME);
	}
	
	if( !filename[0] )usage();

	fnsplit( filename ,dr,di,fi,ex     );
	fnmerge( wrd      ,dr,di,fi,".lyr" );
	fnmerge( mbj      ,dr,di,fi,".mbj" );

	if( objname[0]==NULL )
		sprintf( objname  ,"_%s.lyric",fi );

	compile( wrd,mbj,objname );
	puts("");
	mwc_exit(NULL);
	return NULL;
}

void usage(void)
{
	printf(
		"Syntax ;\n"
		"         lyric.exe [filename] <option...>\n"
		"Option ;\n"
		"         -o (objename)  オブジェクト名を設定します\n"
	);
	mwc_exit(EOF);
}
void mwc_exit(int c)
{
	unlink(TMPFILE);
	mem();
	exit(c);
}

void cut_cr(char *buf)
{
	int i;
	for( i=0; i<255 && buf[i]!=NULL ; i++ )
		if( buf[i]==0x0d || buf[i]==0x0a ){
			buf[i]=NULL;
			break;
	}
}

void compile( char *wrdfile,char *mbjfile,char *objname )
{
	FILE *fpr,*fpw;
	unsigned char buf[256],*tp;
	int timebase=48,x,y,line,nf,uwait,lx,ly,llx;
	long size;
	
	uwait = timebase*4;
	
	printf("%s:",wrdfile);
	if( (fpr=fopen(wrdfile,"r"))==NULL )
	{
		printf("Can\'t open.\n");
		mwc_exit(EOF);
	}
	if( (fpw=fopen(TMPFILE,"wb"))==NULL )
	{
		printf("Can\'t creat tmpfile.\n" );
		mwc_exit(EOF);
	}
	line = 0;
	while( fgets(buf,255,fpr)!=NULL )
	{
		line++;
		cut_cr(buf);
		if( buf[0]==';' )continue;
		if( buf[0]=='\\' )
		{
			tp=buf;
			cut_space(tp);
			tp++;
			if( (x=instr(tp,':'))!=EOF )tp[x-1]='\0';
/*-- color --*/
			if( strcmp(tp,"color")==NULL ){
				tp+=x;
				if( x==EOF )
					printf("(%d) color のパラメータが違います。\n",line);
				putc( 0xe1,fpw   );
				putw( 0x0001,fpw );
				putc( 0x20,fpw   );
				putw( 0x02,fpw   );

				putc( 1,fpw );
				putc( valtonum(tp),fpw );
				continue;
			}
/*-- locate --*/
			else if( strcmp(tp,"locate")==NULL ){
				tp+=x;
				if( (y=instr(tp,','))==EOF || x==EOF )
					printf("(%d) locate のパラメータが違います。\n",line);
				tp[y-1]='\0';
				putc( 0xe1,fpw   );
				putw( 0x0001,fpw );
				putc( 0x20,fpw   );
				putw( 0x03,fpw   );

				putc( 2,fpw );
				putc( llx=lx=atoi(tp)  ,fpw );
				putc( ly=atoi(tp+y),fpw );
				continue;
			}
/*-- wait --*/
			else if( strcmp(tp,"wait")==NULL ){
				tp+=x;
				if( x==EOF )
					printf("(%d) wait のパラメータが違います。\n",line);
				putc(0x91        ,fpw);
				putw(valtonum(tp),fpw);		// まーーーつーーーわ。
				continue;
			}
/*-- uwait --*/
			else if( strcmp(tp,"uwait")==NULL ){
				tp+=x;
				if( x==EOF )
					printf("(%d) uwait のパラメータが違います。\n",line);
				uwait = atoi(tp);
				continue;
			}
		}
		x  = strlen(buf);
		nf = 0;
		if( buf[x-1]=='\\' ){
			buf[x-1]='\0';
			nf=1;
		}
		else if( buf[x-1]=='+' ){
			buf[x-1]='\0';
			nf=2;
		}
		else if( buf[x-1]=='&' ){
			buf[x-1]='\0';
			nf=3;
		}
		putc( 0xe1,fpw );				// ECM機能(MMLBIN参照)
		putw( 0x0001,fpw );				// DRV-ID   number
		putc( 0x20,fpw );				// DRV-Type(20h:etcdev)
		putw(strlen(buf)+1,fpw);		// Message長さ(CTLID+MES)

		putc( 0x00,fpw );				// WORD.XDV コントロールID
		fputs(buf,fpw);					// WORD.XDV 文字列

		if( nf!=1 && nf!=3 ){
			putc(0x91      ,fpw);		// １小節まつのぉ
			putw(uwait,fpw);			// まーーーつーーーわ。
		}
		if( nf==2 || nf==3 )
		{
			llx+=strlen(buf);
			putc( 0xe1,fpw   );
			putw( 0x0001,fpw );
			putc( 0x20,fpw   );
			putw( 0x03,fpw   );

			putc( 2,fpw );
			putc( llx ,fpw );
			putc( ly  ,fpw );
		}
		else if( llx!=lx )
		{
			putc( 0xe1,fpw   );
			putw( 0x0001,fpw );
			putc( 0x20,fpw   );
			putw( 0x03,fpw   );

			putc( 2,fpw );
			putc( lx ,fpw );
			putc( ly  ,fpw );
			llx=lx;
		}
	}
	putc(0xe2,fpw);						// データ終了

	size = ftell(fpw);
	fclose(fpw);
	fclose(fpr);
	
	make_header(mbjfile,objname,timebase,size);
}

void make_header(char *mbjfile,char *objname,int timebase,long size)
{
	FILE *fpw,*fpr;
	TRACK trk;
	long fp,endfp,l;
	int i;
	
	if( (fpw=fopen(mbjfile,"wb"))==NULL )
	{
		printf("Can\'t creat.\n");
		mwc_exit(EOF);
	}
	fprintf( fpw,
		"XMML3.00 object - wordfile compiler MWC.exe version %1d.%02d%c\n"
		"copyright (c) 1994 by ABA / T.Kobayashi and Interfair "
		"All Rights Reserved.\n\x1a%c",
		version_int,
		version_real,
		version_char,0
	);
	
	fputc( 0x01,fpw );								// Object start
	fprintf(fpw,"%s%c",objname,NULL);				// Object name
	 putw(timebase,fpw);							// Timebase
	
	fp    = ftell(fpw);
	endfp = fp+32*(sizeof(TRACK)+1)+1;

// TRACK情報書き込み
// 主要トラック書き込み
	strcpy( trk.chain[0].module,"*COND          " );
	trk.chain[0].channel = 0;
	for( i=1; i<4; i++){
		strcpy( trk.chain[i].module,"OFF            ");
		trk.chain[i].channel = 0;
	}
	printf("%ld",trk.fp       = endfp);
	printf("%ld",trk.size     = size );
	trk.compless = 'NC';
	trk.ext      = NULL;
	fputc( 0x00,fpw );						// このobject
	fwrite( &trk,sizeof(TRACK),1,fpw );		// トラックデータ
// のこり
	for( i=0; i<4; i++){
		strcpy( trk.chain[i].module,"OFF            " );
		trk.chain[i].channel = 0;
	}
	trk.fp       = NULL;
	trk.size     = NULL;
	trk.compless = 'NC';
	trk.ext      = NULL;
	for( i=1; i<32; i++){
		fputc( 0x00,fpw );					// このobject
		fwrite( &trk,sizeof(TRACK),1,fpw );	// トラックデータ
	}
// おしまい
	fputc( 0x00,fpw );						// track info おしまい
// append書き込み
	if( (fpr=fopen(TMPFILE,"rb"))==NULL )
	{
		printf("Can\'t open tmpfile.\n");
		mwc_exit(EOF);
	}
	for( l=0; l<size; l++)putc(getc(fpr),fpw);
	fclose(fpr);
	fclose(fpw);
}
