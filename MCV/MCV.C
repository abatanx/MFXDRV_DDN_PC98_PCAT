//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 SMF converter XMML object maker.
//                         MCV(tm) version 2.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
#include	<stdio.h>
#include	<stdlib.h>
#include	<alloc.h>
#include	<dos.h>
#include	<string.h>
#include	<dir.h>
#include	<io.h>
#include	<fcntl.h>
#include	<sys\stat.h>
#include	<mfile.h>
#include	<mylib.h>
#include	<process.h>
#include	"mcv.h"

#define		version_int		1
#define		version_real	21
#define		version_char	'c'
#define		mem()			printf("	Available memory  :  %ldbytes.\n\n",coreleft())

#define		TMPFILE_F1		"mcvtch"
#define		TMPFILE_F2		"mcvtmp"
#define		MAX_LABEL		200
#define		CONDUCTOR		256

#define		fputw(a,b)		putw(a,b)

typedef struct instrument_adt {
	int no,bank;
	struct instrument_adt *left,*right;
} ADT;

typedef struct {
	int ll,mm;
} MMLL;

typedef struct {
	long fp;
	int  type;
	long value;
	int  size;
} LABEL;
LABEL label[MAX_LABEL];
int label_no = 0;

void usage_out( void );
void mcv_exit ( int );
void mcv_exit2( int );
long smfgetl( FILE * );
int  smfgetw( FILE * );
long smf7bit( FILE * );
void convert( char *,int a[] );
void makeobj( char *,int a[] );
void makeeud( char *,int );
void makemap( char *,char *,int [] );
void makesobj( char * );
void load_inffile( char *,char * );
int  track_wrt( FILE *,int );

char linkopt[1024];
ADT *root;
int midibank[32],midiprog[32];

struct {
	char text[1024];
	char copyright[1024];
	char trackname[1024];
	char instrument[1024];
	char lyric[1024];
	char maker[1024];
	char cuepoint[1024];
	int timebase;
	int format;
	int track;
} smf = {
	"","","","","","","",48,1,0
};

struct {
	int hr,mn,se,fr,ff;
} smpte;

struct {
	int nn,dd,cc,bb;
} timesign;

struct {
	int sf,mi;
} keysign;
long fgetcount;
int fgetcbuf=EOF , option[26];

enum {
	OPT_A,OPT_B,OPT_C,OPT_D,OPT_E,OPT_F,OPT_G,OPT_H,OPT_I,OPT_J,OPT_K,OPT_L,
	OPT_M,OPT_N,OPT_O,OPT_P,OPT_Q,OPT_R,OPT_S,OPT_T,OPT_U,OPT_V,OPT_W,OPT_X,
	OPT_Y,OPT_Z
} OptionSelector;

typedef struct {
	char name[256];
	int track;
} EXTOBJ;
typedef struct {
	struct {
		char name[256];
		int channel;
	} chain[4];
} EXTMODULE;

char title[1024],composer[1024],arranger[1024],lyric[1024],artist[1024],
	 copyright[1024],*memo,*memo_trace,*trackname[32];

int vol_facter=100,exp_facter=100,vel_facter=100,mastervol_facter=100,
	chgtimebase=-1;
float waitmultiple;

EXTOBJ    extern_object[32];
EXTMODULE extern_module[32];

void main(int argc,char **argv)
{
	char	dr[MAXDRIVE],di[MAXDIR],fi[MAXFILE],ex[MAXEXT],
			obj[MAXPATH],mbj[MAXPATH],mbs[MAXPATH],eud[MAXPATH],inf[MAXPATH],
			map[MAXPATH],tdr[MAXDRIVE],tdi[MAXDIR],*tmp,
			filename[MAXPATH],buf[256];
	int		filech[32],i,me,eudch=15;
	
	root = NULL;
	
	strcpy( linkopt,"" );
	for( i=0; i<26; i++)option[ i ] = FALSE;
	for( i=0; i<32; i++)
	{
		trackname[i]  = keep_highmemory(256);
		*trackname[i] = NULL;
		midibank[i]   = 0;
		midiprog[i]   = 0;
	}
	
	printf(
		"music driver MFXDDN Standerd MIDI file converter MCV version %1d.%02d%c\n"
		"copyright (c) 1993 by ABA / T.Kobayashi and Interfair  "
		"All Rights Reserved.\n\x1b[>5l",
		version_int,
		version_real,
		version_char
	);
	
	if( argc<=1 )	usage_out();
	
	strcpy( filename,"" );
	for( i=1; i<argc; i++){
		if( **(argv+i)!='/' && **(argv+i)!='-' ){
			fnsplit( *(argv+i),dr,di,fi,ex );
			if( stricmp(ex,".mbj")==NULL ){
				sprintf( buf," %s",*(argv+i));
				strcat (linkopt,buf);
			}
			else
				strcpy( filename,*(argv+i) );
		}
		else {
			switch( *(*(argv+i)+1) ){
				case 'V':
				case 'v':
					switch(  *(*(argv+i)+2) ){
						case 'v':case 'V':
							vol_facter = atoi(*(argv+i)+3);
							break;
						case 'e':case 'E':
							exp_facter = atoi(*(argv+i)+3);
							break;
						case 'k':case 'K':
							vel_facter = atoi(*(argv+i)+3);
							break;
						case 'm':case 'M':
							mastervol_facter = atoi(*(argv+i)+3);
							break;
						default:
							printf("Illigal Volume Option : -v%c\n",*(*(argv+i)+2) );
							break;
					}
					break;
					/* Make only usual object */
				case 'c':
				case 'C':
					option[ OPT_C ] = TRUE;
					break;
					/* Make Effect File */
				case 'e':
				case 'E':
					if( *(argv[i]+2)>='0' && *(argv[i]+2)<='9' )
					{
						eudch = atoi(argv[i]+2);
					}
					printf("-- 効果音ファイルを作成します(CH=%d). --\n",
						eudch
					);
					
					option[ OPT_E ] = TRUE;
					break;
					/* りんかにわたす */
				case 'L':
				case 'l':
					sprintf( buf," -%s",*(argv+i)+2 );
					strcat( linkopt,buf );
					break;
				case 'X':
				case 'x':
					puts("-- mapファイルを作成しません. --");
					option[ OPT_M ] = TRUE;
					break;
				case 'W':
				case 'w':
					puts("-- 強制モード(隠しだ) --");
					option[ OPT_W ] = TRUE;
					break;
				case 't':
				case 'T':
					puts("-- TIMEBASEを変更します --");
					chgtimebase = atoi(*(argv+i)+2);
					break;
				default:
					printf("Illigal Option : -%c\n",*(*(argv+i)+1) );
					break;
			}
		}
	}
	
	if( !filename[0] )	usage_out();
	
	tmp = getenv("TMP");
	if( tmp==NULL || option[ OPT_C ]==TRUE )
	{
		strcpy(tdr,"");
		strcpy(tdi,"");
	}
	else
	{
		strcpy(tdr,tmp);
		add_dirmark(tdr);
		strcpy(tdi,"");
	}
	
	fnsplit( filename ,dr , di, fi, ex     );
	fnmerge( obj      ,dr , di, fi, ".mid" );
	fnmerge( inf      ,dr , di, fi, ".inf" );
	fnmerge( mbj      ,tdr,tdi, fi, ".mbj" );
	fnmerge( mbs      ,tdr,tdi, fi, ".mbs" );
	fnmerge( eud      ,"","",fi,".eud" );
	fnmerge( map      ,"","",fi,".map" );

	mbufsize(65000);

	for( i=0; i<32; i++) filech[i]=EOF;

	load_inffile( mbj,inf );

	convert( obj,filech );			/* コンバート             */

	if( option[ OPT_X ]==FALSE ){
		makemap( map,obj,filech );
	}

	if( option[ OPT_E ]==TRUE ){	/* 効果音ファイルの作成   */
		me = FALSE;
		for( i=0; i<32; i++){
			if( filech[i]==eudch ){
				makeeud( eud,i );
			}
			me = TRUE;
			break;
		}
		if( me==FALSE ){
			printf("EUD file use Channel.16 file , can\'t make file.\n");
		}
		mcv_exit(NULL);
	}
	makeobj( mbj,filech );			/* オブジェクトのリンク   */
	if( option[OPT_C]==FALSE ){
		makesobj( mbs );			/* ソースオブジェクト作成 */
		mem();
		
		mll( mbs,mbj );				/* リンク                 */
		unlink(mbs);
		unlink(mbj);
		mcv_exit2(NULL);
	}
	else {
		makesobj( mbs );			/* ソースオブジェクト作成 */
		mcv_exit( NULL );
	}
}

// 環境変数 TMP の取得
void get_temporary(char *tmpfile)
{
	char *env;
	env = getenv("TMP");
	if( env==NULL ){
		strcpy( tmpfile,"" );
	}
	else {
		strcpy(tmpfile,env);
		cut_dirmark(tmpfile);
	}
}
// ADTシステム ----------------------------------------------------------------
ADT *makeadt(ADT *p,int bank,int no)
{
	long a,b;
	if( p==NULL )
	{
		if( (p = (ADT *)malloc(sizeof(ADT)))==NULL )return NULL;
		p->bank = bank;
		p->no   = no;
		p->left = NULL;
		p->right= NULL;
	}
	else
	{
		a = bank*256L+(long)no;
		b = p->bank*256L+(long)p->no;
		if( a < b )
			p->left = makeadt(p->left ,bank,no);
		else if( a > b)
			p->right= makeadt(p->right,bank,no);
		else return p;
	}
	return p;
}

void printadt(ADT *p,int fpw)
{
	if( p!=NULL )
	{
		printadt(p->left,fpw);
		write( fpw,&p->bank,2 );
		write( fpw,&p->no  ,1 );
		printadt(p->right,fpw);
	}
}

// リロケータブルラベリングシステム -------------------------------------------
void init_label( void )
{
	int i;
	for( i=0; i<MAX_LABEL; i++)label[i].fp = EOF;
}

void set_label( int fp,int type,int size )
{
	int i,j,label_no;
	
	label_no = EOF;
	for( i=0; i<MAX_LABEL; i++){
		if( label[i].fp==EOF ){
			label_no = i;
			break;
		}
	}
	if( label_no==EOF ){
		printf("Sorry! Relocatable stack over.\n");
		mcv_exit(EOF);
	}
	
	label[ label_no ].fp   = tell(fp);
	label[ label_no ].type = type;
	label[ label_no ].value= EOF;
	label[ label_no ].size = size;
	write( fp,"@@@@@@@@",size );
}

void set_label_value( int type,long value )
{
	int i,j,label_no;

	label_no = EOF;
	for( i=0; i<MAX_LABEL; i++){
		if( label[i].type==type ){
			label_no = i;
			break;
		}
	}
	if( label_no==EOF ){
		printf("Broken relocatable stack.\n");
		mcv_exit(EOF);
	}
	
	label[ label_no ].type = EOF;
	label[ label_no ].value= value;
}

void write_label(char *fname)
{
	int i;
	FILE *fpw;
	
	if( (fpw=fopen(fname,"r+b"))==NULL ){
		printf("Can\'t rewrite file : %s\n",fname );
		mcv_exit(EOF);
	}
	for( i=0; i<MAX_LABEL; i++){
		if( label[i].fp   ==EOF )continue;
		if( label[i].value==EOF ){
			printf("m\n");
		}
		
		fseek ( fpw,label[i].fp,SEEK_SET );
		fwrite( &label[i].value,label[i].size,1,fpw );
	}
	fclose( fpw );
}

//-----------------------------------------------------------------------------
void mcv_exit( int erl )
{
	char tmp[256],rfile[256],wfile[256];
	int i;
	
	get_temporary(tmp);
	for( i=0; i<32; i++){
		sprintf(rfile,"%s\\%s%d.$$$",tmp,TMPFILE_F1,i);
		sprintf(wfile,"%s\\%s%d.$$$",tmp,TMPFILE_F2,i);
		unlink(rfile);
		unlink(wfile);
	}
	mem();
	exit( erl );
}

void mcv_exit2( int erl )
{
	char tmp[256],rfile[256],wfile[256];
	int i;
	
	get_temporary(tmp);
	for( i=0; i<32; i++){
		sprintf(rfile,"%s\\%s%d.$$$",tmp,TMPFILE_F1,i);
		sprintf(wfile,"%s\\%s%d.$$$",tmp,TMPFILE_F2,i);
		unlink(rfile);
		unlink(wfile);
	}
	exit( erl );
}

//-----------------------------------------------------------------------------
void usage_out(void)
{
	puts(
		"Syntax ;\n"
		"         mcv.exe [filename] <option 1>.....<option n>....\n"
		"Option ;\n"
		"         *.mbj       一緒にリンカに渡して、LINKします\n"
		"         -l(cmd)     リンカにオプションを引き渡します\n"
		"         -c          コンバートのみを行います\n"
		"         -x          mapファイルを作成しません\n"
		"         -e          効果音ファイルを作成します(テスト中)\n"
		"         -vv?         全TrackのVolumeを調整する   (?:1-200\%)\n"
		"         -ve?        全TrackのExpressionを調整する(?:1-200\%)\n"
		"         -vm?        Mastervolumeを調整する       (?:1-200\%)\n"
		"         -ve?        全キーのVelocityを調整する   (?:1-200\%)\n"
	);
	mcv_exit( NULL );
}

//-----------------------------------------------------------------------------
int fgetcb(FILE *fpr)
{
	int a;
	fgetcount++;
	if( fgetcbuf!=EOF ){
		a = fgetcbuf;
		fgetcbuf = EOF;
		return a;
	}
	a=fgetc(fpr);
	if( a==EOF ){
		printf("File stream error : overread (%dbytes)\n",fgetcount);
		mcv_exit(EOF);
	}
	return a;
}
int freadb(char *buf,int size,int block,FILE *fpr)
{
	int a,i,j;
	for( j=0; j<block; j++){
		for( i=0; i<size; i++)buf[i]=fgetcb(fpr);
	}
	return NULL;
}

long smfgetl( FILE *fpr )
{
	long num;
	num  = ( (long)fgetcb(fpr)*0x01000000L );
	num |= ( (long)fgetcb(fpr)*0x00010000L );
	num |= ( (long)fgetcb(fpr)*0x00000100L );
	num |= ( (long)fgetcb(fpr)             );
	return num;
}
int smfgetw( FILE *fpr )
{
	int num;
	num  = ( (int) fgetcb(fpr)<<8  );
	num |= ( (int) fgetcb(fpr)     );
	return num;
}
long smf7bit( FILE *fpr )
{
	long num;
	int b1,b2;
	
	num = 0;
	do {
		b1   = fgetcb(fpr);
		num  = num << 7L;
		b2   = b1 & 0x7f;
		num += (long)b2;
	}
	while( (b1&0x80)!=0 );
	return num;
}
//------------------------------------------------ MIDIファイルコンバート -----
void convert( char *midifile,int filech[] )
{
	FILE *fpr;
	char buf[256],rfile[256],wfile[256],tmp[256];
	long header,delta,trkadr,stackfp;
	int i;
	char *filebuf;
	
	if( (filebuf=keep_highmemory(16000))==NULL ){
		puts("Not enough to memory.");
		mcv_exit(EOF);
	}
	
	get_temporary(tmp);
	for( i=0; i<32; i++){
		sprintf(rfile,"%s\\%s%d.$$$",tmp,TMPFILE_F1,i);
		sprintf(wfile,"%s\\%s%d.$$$",tmp,TMPFILE_F2,i);
		unlink(rfile);
		unlink(wfile);
	}

	printf("%s:",midifile);
	if( (fpr=fopen(midifile,"rb"))==NULL ){
		printf("Can\'t open.");
		mcv_exit(EOF);
	}
	setvbuf(fpr,filebuf,_IOFBF,16000);
	
	freadb( buf,4,1,fpr );
	buf[4] = '\0';
	
	if( strcmp(buf,"MThd")!=NULL ){
		puts("Not Standerd MIDI file.");
		mcv_exit(EOF);
	}
/*	header    = */ smfgetl(fpr);
	smf.format   = smfgetw(fpr);
	smf.track    = smfgetw(fpr);
	smf.timebase = smfgetw(fpr);
	
	if( smf.format==2 )
	{
		printf("Can\'t convert the file of FORMAT2\n");
		mcv_exit(EOF);
	}
	printf("	FORMAT%d TRACK%d TIMEBASE%d",smf.format,smf.track,smf.timebase);
	if( chgtimebase!=-1 )
	{
		waitmultiple = (float)chgtimebase/(float)smf.timebase;
		printf("->%d (x%f)\n",chgtimebase,waitmultiple);
		smf.timebase = chgtimebase;
	}
	else
	{
		waitmultiple = 1.0;
		printf("\n");
	}
	
	for( i=0; i<smf.track; i++){
		freadb( buf,4,1,fpr );
		buf[4] = '\0';
		if( strcmp(buf,"MTrk")!=NULL ){
			puts("MTrk Header cunck is broken.");
			mcv_exit(EOF);
		}
		delta  = smfgetl(fpr);
		stackfp= ftell(fpr);
		
		printf("\x1b[2K\r	MTrk %2d : (%6ld) - ",i,delta);
		filech[i] = track_wrt( fpr,i );
		
		fseek( fpr,stackfp,SEEK_SET );
		fseek( fpr,delta  ,SEEK_CUR );
		fgetcbuf = EOF;
	}
	printf("\r\x1b[2K");
	fclose( fpr );
}
void check_write( int cmd,MMLL *buf,MFILE *fpw )
{
	if( buf->mm==EOF || buf->ll==EOF )return;
	mputc( cmd,fpw );
	mputc( buf->ll,fpw );
	mputc( buf->mm,fpw );
	buf->ll = EOF;
	buf->mm = EOF;
}
int track_wrt( FILE *fpr,int track )
{
	MFILE fpw;
	char wfile[MAXPATH],tmp[256],textbuf[1024];
	long step,tempo,ttt;
	int note,velo,cmd,val,para,exc_len,exclusive[1024],track_endflag,oldcmd=FALSE;
	int i,j,ch=0,noteflag=FALSE,repeatflag=FALSE,kf=0,wch=0;
	int noteonsw = FALSE,a,b,c;
	float calc;
	
	MMLL pitchbend={EOF,EOF};
	
	get_temporary(tmp);
	
	sprintf(wfile,"%s\\%s%d.$$$",tmp,TMPFILE_F1,track);
	if( mopen(wfile,&fpw)==EOF ){
		puts("Can\'t make temporary file.");
		mcv_exit(EOF);
	}
	if( option[ OPT_E ]==TRUE ){
		mputc( 0xb5,&fpw );
		mputc( 0xb4,&fpw );
		mputc( 0xb6,&fpw );				// 効果音だったら、最初に
										// All Note OFF をかます。
	}
	
	track_endflag = FALSE;
	step          = smf7bit(fpr);
	if( smf.format==0 )step = 1;
	fgetcount     = 0;
	
	do {
		cmd  = fgetcb  (fpr);
		
		if( chgtimebase!=-1 )
		{
			ttt  = step;
			calc = (float)step*waitmultiple;
			step = (long)calc;
			if( (float)step>calc )
			{
//				printf("(-)%ld/%f ",ttt,calc);
				step+=kf;
				if( step<0 )
					step = 0;
				else
					kf = 0;
				kf += -1;
				printf("%d ",kf);
			}
			else if( (float)step<calc )
			{
//				printf("(+)%ld/%f ",ttt,calc);
				step+=kf;
				if( step<0 )
					step = 0;
				else
					kf = 0;
				kf += 1;
				printf("%d ",kf);
			}
			else
			{
				step+=kf;
				if( step<0 )
					step = 0;
				else
					kf = 0;
				printf("%d ",kf);
			}
		}

		if( step>=256L ){
			while( step>0L ){
				mputc( 0x91,&fpw );
				if( step>65535L ){
					mputw( 65535,&fpw );
					step -= 65535L;
				}
				else {
					mputw( step,&fpw );
					step  =   0L;
					break;
				}
			}
		}
		else if( step>0 ){
			mputc( 0x90,&fpw );
			mputc( (int)step,&fpw );
		}
		
		if( cmd<0x80 ){
			fgetcbuf = cmd;
			cmd = oldcmd;
		}
		if( (cmd & 0xf0)!=0xf0 )
		{
			if( smf.format==0 )
			{
				if( (cmd&0x0f)!= ch )
				{
					mputc( cmd|0xf0,&fpw );
				}
			}
			ch = cmd & 0x0f;
		}
		switch( cmd & 0xf0 ){
			case 0x80:		// NOTE OFF ///////////////////////////////////////////
				note = fgetcb(fpr);
				velo = fgetcb(fpr);
				mputc( note,&fpw );
				mputc( 0   ,&fpw );
				break;
	
			case 0x90:		// NOTE ON/OFF ////////////////////////////////////////
				if( option[OPT_W]==TRUE )
				{
					mputc( wch+0xf0,&fpw );
					wch++;
					if( wch>=3 )wch = 0;
				}

				noteflag = TRUE;
				note = fgetcb(fpr);
				velo = fgetcb(fpr);
				velo = (velo*vel_facter)/100;
				if( velo>127 )
				{
					printf(" Warning: Velocity Overflow(%d)\n",velo);
					velo = 127;
				}
				mputc( note,&fpw );
				mputc( velo,&fpw );
				if( noteonsw==FALSE )
				{
					root = makeadt(root,midibank[track],midiprog[track]);
					noteonsw = TRUE;
				}
				break;
	
			case 0xa0:		// POLYFONIC KEY PRESSER //////////////////////////////
				note = fgetcb(fpr);
				val  = fgetcb(fpr);
				mputc( 0xa0,&fpw );
				mputc( note,&fpw );
				mputc( val ,&fpw );
				
							// MFXDRV/DDN 拡張命令疑似表示解析
							// A0h 0Ch CMD
				if( note==13 ){
					printf("[RO%d]",val);
					repeatflag = TRUE;
					mputc( 0xd0,&fpw );
					mputc( val,&fpw );
					break;
				}
				else if( note==12 ){
					switch( val ){
						case 0:
							printf("[RO]");
							repeatflag = TRUE;
							mputc( 0xd0,&fpw );
							mputc( 0x00,&fpw );
							break;
						case 1:
							if( repeatflag==TRUE ){
								printf("[RC]");
								mputc( 0xd1,&fpw );
							}
							break;
						case 2:
							if( repeatflag==TRUE ){
								printf("[R>]");
								mputc( 0xd2,&fpw );
							}
							break;
						default:
							printf("Non Support MFXDRV/DDN cmd %02Xh\n",val);
							break;
					}
				}
				break;
	
			case 0xb0:		// Controll ///////////////////////////////////////////
				val  = fgetcb(fpr);
				para = fgetcb(fpr);
				switch( val ){
					case 0x00:		// BANK SELECT
						mputc( 0xa1 ,&fpw );
						mputw( para*0x100 ,&fpw );
						midibank[track] = para*0x100;
						noteonsw = FALSE;
					case 0x20:
						break;
					
					case 0x01:		// MODULATION
						mputc( 0xa2,&fpw );
						mputc( para,&fpw );
						break;
					
					case 0x05:		// POLTAMENT TIME
						mputc( 0xa3,&fpw );
						mputc( para,&fpw );
						break;
					
					case 0x06:		// DATA ENTRY
						mputc( 0xa4,&fpw );
						mputc(    0,&fpw );
						mputc( para,&fpw );
						break;
					case 0x26:
						mputc( 0xa4,&fpw );
						mputc(    1,&fpw );
						mputc( para,&fpw );
						break;
					
					case 0x07:		// VOLUME
						para = (para*vol_facter)/100;
						if( para>127 )
						{
							printf(" Warning: Volume Overflow(%d)\n",para);
							para = 127;
						}
						mputc( 0xa5,&fpw );
						mputc( para,&fpw );
						break;
					
					case 0x0a:		// PANPOT
						mputc( 0xa6,&fpw );
						mputc( para,&fpw );
						break;
					
					case 0x0b:		// EXPRESSION
						para = (para*exp_facter)/100;
						if( para>127 )
						{
							printf(" Warning: Expression Overflow(%d)\n",para);
							para = 127;
						}
						mputc( 0xa7,&fpw );
						mputc( para,&fpw );
						break;
					
					case 0x40:		// HOLD1
						mputc( 0xa8,&fpw );
						mputc( para,&fpw );
						break;
					
					case 0x41:		// POLTAMENT
						mputc( 0xa9,&fpw );
						mputc( para,&fpw );
						break;
					
					case 0x42:		// SUSTENUTO
						mputc( 0xaa,&fpw );
						mputc( para,&fpw );
						break;
					
					case 0x43:		// SOFT
						mputc( 0xab,&fpw );
						mputc( para,&fpw );
						break;
					
					case 0x54:		// POLTAMENT CTRL
						mputc( 0xac,&fpw );
						mputc( para,&fpw );
						break;
					
					case 0x5b:		// REBERB SEND LEVEL
						mputc( 0xad,&fpw );
						mputc( para,&fpw );
						break;
					
					case 0x5d:		// CORUS SEND LEVEL
						mputc( 0xae,&fpw );
						mputc( para,&fpw );
						break;
					
					case 0x63:		// NRPN
						mputc( 0xaf,&fpw );
						mputc(    0,&fpw );
						mputc( para,&fpw );
						break;
					case 0x62:
						mputc( 0xaf,&fpw );
						mputc(    1,&fpw );
						mputc( para,&fpw );
						break;
					
					case 0x65:		// RPN
						mputc( 0xb0,&fpw );
						mputc(    0,&fpw );
						mputc( para,&fpw );
						break;
					case 0x64:
						mputc( 0xb0,&fpw );
						mputc(    1,&fpw );
						mputc( para,&fpw );
						break;
					
					case 0x78:		// ALL SOUND OFF
						mputc( 0xb4,&fpw );
						break;
					
					case 0x79:		// RESET ALL CONTROLLER
						mputc( 0xb5,&fpw );
						break;
					
					case 0x7b:		// ALL NOTE OFF
						mputc( 0xb6,&fpw );
						break;
					
					case 0x7c:		// OMNI OFF
						mputc( 0xb7,&fpw );
						break;
					
					case 0x7d:		// OMNI ON
						mputc( 0xb8,&fpw );
						break;
					
					case 0x7e:		// MONO
						mputc( 0xb9,&fpw );
						break;
					
					case 0x7f:		// POLY
						mputc( 0xba,&fpw );
						break;
					
					default:
						printf(" Undefined CONTROLL CHG : 80h %02Xh %02Xh\n",
							val,para );
						break;
				}
				break;
	
			case 0xc0:		// Program Change /////////////////////////////////////
				para = fgetcb(fpr);
				mputc( 0xb1,&fpw );
				mputc( para,&fpw );
				midiprog[track] = para;
				noteonsw = FALSE;
				break;
			
			case 0xd0:		// Channel Presser ////////////////////////////////////
				para = fgetcb(fpr);
				mputc( 0xb2,&fpw );
				mputc( para,&fpw );
				break;
			
			case 0xe0:		// Pitch Bend Range ///////////////////////////////////
				pitchbend.ll = fgetcb(fpr);
				pitchbend.mm = fgetcb(fpr);
/*---*/
				a = pitchbend.ll | (pitchbend.mm<<7);
				a = a-8192;
/*---*/
				mputc( 0xb3,&fpw );
				mputw( a   ,&fpw );
				break;
			
			case 0xf0:		// SYSTEM REALTIME MSG
					// Active Sensing -------------------------
				if( cmd==0xfe )break;
					// Exclusive Message ----------------------
				else if( cmd==0xf0 ){
					exc_len = 0;
					fgetc( fpr );
					while( (exclusive[exc_len]=fgetcb(fpr))!=0xf7 )exc_len++;
					if( exclusive[0]==0x41 ){
						if( exclusive[4]==0x40 && exclusive[5]==0x00 &&
							exclusive[6]==0x04 ){
							mputc( 0xc1,&fpw );
							para = exclusive[7];
							para = (para*mastervol_facter)/100;
							if( para>127 )
							{
								printf(" Warning: Master-volume Overflow(%d)\n",para);
								para = 127;
							}
							mputc( para,&fpw );
							break;
						}
					}
					else if( (exclusive[1]==0x7f) ){
						if( exclusive[2]==0x04 && exclusive[3]==0x01 &&
							exclusive[4]==0x00 ){
							mputc( 0xc1,&fpw );
							mputc( exclusive[5],&fpw );
							break;
						}
					}
					else {
						for( i=0; i<4; i++){
							printf("%02x ",exclusive[i]);
						}
						printf("Be not GS-format Exclusive messages.\n");
					}
					mputc( 0xbb   ,&fpw );
					mputc( exc_len,&fpw );
					for( i=0; i<exc_len; i++ ){
						mputc( exclusive[i],&fpw );
					}
					break;
				}
					// SMF Meta-Event -------------------------
				else if( cmd==0xff ){
					val = fgetcb(fpr);
					switch( val ){
						case 0x00:		// Sequence Number
							if( (val=fgetcb(fpr))!=0x02 ){
								printf("Illigal Number for Sequence Number : ffh 00h %02xh\n",val);
							}
							fgetcb(fpr);
							fgetcb(fpr);
							break;
						case 0x01:		// Text Event
							val = (int)smf7bit(fpr);
							freadb( smf.text,val,1,fpr );
							smf.text[val]='\0';
						//	printf("Text Event  : \"%s\"\n",smf.text);
							break;
						case 0x02:		// Copyright Notice
							val = (int)smf7bit(fpr);
							freadb( smf.copyright,val,1,fpr );
							smf.copyright[val]='\0';
						//	printf("Copyriight  : \"%s\"\n",smf.copyright);
							break;
						case 0x03:		// Sequence / Track Name
							val = (int)smf7bit(fpr);
							freadb( textbuf,val,1,fpr );
							textbuf[val]='\0';
							strncpy( trackname[track],textbuf,255 );
							break;
						case 0x04:		// Instrument Name
							val = (int)smf7bit(fpr);
							freadb( smf.instrument,val,1,fpr );
							smf.instrument[val]='\0';
						//	printf("Instrument  : \"%s\"\n",smf.instrument);
							break;
						case 0x05:		// Lyric
							val = (int)smf7bit(fpr);
							freadb( smf.lyric,val,1,fpr );
							smf.lyric[val]='\0';
						//	printf("Lyric       : \"%s\"\n",smf.lyric);
							break;
						case 0x06:		// Marker
							val = (int)smf7bit(fpr);
							freadb( smf.maker,val,1,fpr );
							smf.maker[val]='\0';
						//	printf("Maker       : \"%s\"\n",smf.maker);
							break;
						case 0x07:		// Cue Point
							val = (int)smf7bit(fpr);
							freadb( smf.cuepoint,val,1,fpr );
							smf.cuepoint[val]='\0';
						//	printf("Cue Point   : \"%s\"\n",smf.cuepoint);
							break;
						case 0x21:		// なにこれ？
							fgetcb(fpr);
							fgetcb(fpr);
							break;

						case 0x7f:		// Specific Meta-Event
							val = (int)smf7bit(fpr);
							fseek( fpr,val,SEEK_CUR );
							fgetcbuf = EOF;
							break;

						case 0x2f:		// End Of Track
							if( (val=fgetcb(fpr))!=0x00 ){
								printf("Illigal Number for End of Track : ffh 2fh %02xh\n",val);
							}
							track_endflag = TRUE;
							break;
						case 0x51:		// Set Tempo
							if( (val=fgetcb(fpr))!=0x03 ){
								printf("Illigal Number for Set Tempo : ffh 51h %02xh\n",val);
							}
							tempo = 0;
							tempo+= fgetcb(fpr)*0x10000L;
							tempo+= fgetcb(fpr)*0x100L;
							tempo+= fgetcb(fpr);
							if( option[ OPT_E ]==TRUE )break;
							if( tempo==0 ){
								printf("Tempo is Zero.\n");
							}
							else {
								tempo = 60000000L/tempo;
								mputc( 0xc4,&fpw );
								mputw( (int)tempo ,&fpw );
							}
							break;
						case 0x54:		// SMPTE OFFSET
							if( (val=fgetcb(fpr))!=0x05 ){
								printf("Illigal Number for SMPTE Offset : ffh 58h %02xh\n",val);
							}
							smpte.hr = fgetcb(fpr);
							smpte.mn = fgetcb(fpr);
							smpte.se = fgetcb(fpr);
							smpte.fr = fgetcb(fpr);
							smpte.ff = fgetcb(fpr);
							break;
						case 0x58:		// TIME SIGNATURE
							if( (val=fgetcb(fpr))!=0x04 ){
								printf("Illigal Number for TIME Signature : ffh 58h %02xh\n",val);
							}
							timesign.nn = fgetcb(fpr);
							timesign.dd = fgetcb(fpr);
							timesign.cc = fgetcb(fpr);
							timesign.bb = fgetcb(fpr);
							break;
						case 0x59:		// KEY SIGNATURE
							if( (val=fgetcb(fpr))!=0x02 ){
								printf("Illigal Number for KEY Signature : ffh 59h %02xh\n",val);
							}
							keysign.sf = fgetc(fpr);
							keysign.mi = fgetc(fpr);
							break;
						default:
							printf(" Undefined REALTIME EV  : FFh %02Xh\n",val);
							break;
					}
				}
				break;

			default:
				printf(" Undefined MIDI EVENT   : %02Xh\n",
					cmd );
				break;
		}
		oldcmd = cmd;
		if( track_endflag==FALSE )step = smf7bit(fpr);
	}
	while( track_endflag==FALSE );
	printf(" Converted! MIDI Channel is %2d.",ch);
	
	if( repeatflag==TRUE ){
		mputc( 0xd1,&fpw );
	}
	mputc( 0xe2,&fpw );
	mclose( &fpw );
	
	if( smf.format==0   )ch=0;
	if( noteflag==FALSE )ch=CONDUCTOR;
	
	return ch;
}
//------------------------------------------------------ オブジェクト作成 -----
void makeobj( char *objectfile,int filech[] )
{
	TRACK trk[32];
	int i,j,p,fdr,fdw;
	long size,fp,l,si;
	char tmp[256],trkfile[256],buf[1024],*copymem;
	char dr[MAXDRIVE],di[MAXDIR],fi[MAXFILE],ex[MAXEXT],objname[256];
	fnsplit(objectfile,dr,di,fi,ex);
	sprintf(objname,"_%s_midi",strlwr(fi));

	init_label();
	
	printf( "%s:\n", objectfile );
	
	if( (fdw=open(objectfile,O_WRONLY|O_BINARY|O_CREAT,S_IREAD|S_IWRITE))==EOF){
		printf("Can\'t make object.\n");
		mcv_exit(EOF);
	}
// 識別子
	sprintf( buf,
		"XMML3.00 object - Standerd MIDI file converter mcv.exe ver.%d.%02d%c\n"
		"copyright (c) 1993,94 by Interfair all rights reserved.\n"
		"\x1a%c",
		version_int,version_real,version_char,0 );

	write( fdw,buf,strlen(buf)+1 );
	
// オブジェクトフラグ／オブジェクト名
	sprintf( buf,"%c%s%c",1,objname,0 );
	write( fdw,buf,strlen(buf)+1 );

// タイムベース
	write( fdw,&smf.timebase,sizeof(int) );

// 音源チェインデータ作成
	get_temporary(tmp);
	
	for( i=0; i<32; i++){
		
		if( extern_object[i].name[0]!=NULL ){
			write( fdw,"\x01",1 );
			l = strlen( extern_object[i].name );
			write( fdw, extern_object[i].name ,l+1 );
			write( fdw,&extern_object[i].track,1   );
			continue;
		}
		write( fdw,"\x00",1 );
		
		if( extern_module[i].chain[0].name[0]!=NULL ){
			l = 4;
			for( j=0; j<4; j++){
				if( extern_module[i].chain[j].name[0]!=NULL ){
					p = strlen( extern_module[i].chain[j].name        );
					write( fdw, extern_module[i].chain[j].name   ,p+1 );
					write( fdw,&extern_module[i].chain[j].channel,1   );
					l--;
				}
			}
		}
		else {
			if( filech[i]==CONDUCTOR ){
				write( fdw,"MIDI" ,5 );
				write( fdw,"",1 );
				write( fdw,"*COND",6 );
				write( fdw,"",1 );
				l = 2;
			}
			else {
				if( filech[i]!=EOF )write( fdw,"MIDI"  ,5 );
				else						write( fdw,"OFF"   ,4 );
				write( fdw,&filech[i],1 );
				l = 3;
			}
		}
		for( j=0; j<l; j++){
			write( fdw,"OFF",4 );
			write( fdw,&filech[i],1 );
		}

		if( filech[i]!=EOF ){
			set_label( fdw,i    ,4 );
			set_label( fdw,i+100,4 );
		}
		else {
			write( fdw,"\0\0\0\0",4 );
			write( fdw,"\0\0\0\0",4 );
		}
		write( fdw,"NC",2 );
		write( fdw,"\0\0",2 );
	}
	copymem = keep_highmemory(32000);
	for( i=0; i<32; i++){
		if( filech[i]==EOF )continue;
		if( extern_object[i].name[0]!=NULL )continue;

		sprintf(trkfile,"%s\\%s%d.$$$",tmp,TMPFILE_F1,i);
		
		fdr = open(trkfile,O_RDONLY|O_BINARY);
		fp = tell(fdw);
		si = filelength(fdr);
		set_label_value( i    ,fp );
		set_label_value( i+100,si );
		
		while( (size=read(fdr,copymem,32000))!=NULL ){
			write( fdw,copymem,size );
		}
		close(fdr);
	}
	free_memory(copymem);
// 音色テーブル
	printadt(root,fdw);
	write( fdw,"\xff\xff",2 );
//
	write( fdw,"\0",1 );
	close(fdw);
	write_label( objectfile );
}

//-------------------------------------------------- 情報ファイル読み込み -----
void load_inffile(char *objectfile,char *inffile)
{
	FILE *fpw,*fpr;
	char dr[MAXDRIVE],di[MAXDIR],fi[MAXFILE],ex[MAXEXT],objname[256],
		 buf[1024],spr[1024],com[1024],arg[1024],*agx;
	unsigned l;
	int i,j,tf,ci,x,num,x1,x2,track;
	for( i=0; i<32; i++){
		strcpy( extern_object[i].name,"" );
		extern_object[i].track = 0;
		for( j=0; j<4; j++){
			strcpy( extern_module[i].chain[j].name,"" );
			extern_module[i].chain[j].channel = 0;
		}
	}
	
	if( memo==NULL ){
		if( (memo=keep_highmemory(65500))==NULL ){
			printf("Not enough to memory.");
			mcv_exit(EOF);
		}
	}
	memo_trace = memo;
	
	strcpy( title,    "" );
	strcpy( composer, "" );
	strcpy( arranger, "" );
	strcpy( lyric,    "" );
	strcpy( artist,   "" );
	strcpy( copyright,"" );
	strcpy( memo,     "" );
	
	if( access(inffile,0)==EOF ){
		if( (fpw=fopen(inffile,"w"))==NULL ){
			printf("Information file \'%s\' が作成できません。\n",inffile);
			clearerr(fpw);
		}
		else {
			fprintf( fpw,
				";--- Information Header \"%s\" ---\n"
				"title      = \"\"\n"
				"artist     = \"\"\n"
				"lyric      = \"\"\n"
				"composer   = \"\"\n"
				"arranger   = \"\"\n"
				"copyright  = \"\"\n\n"
				";--- Track Informations ---\n"
				";track?    = _ｵﾌﾞｼﾞｪｸﾄ名(ﾄﾗｯｸ番号)        : 外部ｵﾌﾞｼﾞｪｸﾄ参照\n"
				";track?    = 音源(ﾁｬﾝﾈﾙ),音源(ﾁｬﾝﾈﾙ), ... : 拡張音源割り当て\n"
				";記述がない場合は、音源はMIDI、チャンネルは自動判別で行います。\n"
				"\n",
				objectfile
			);
			for( i=0; i<32; i++){
				fprintf( fpw,"track%-2d    = \n",i );
			}
			fprintf( fpw,
				"\n;--- Memo ---\n"
				"memo\n\n"
			);
			
			fclose( fpw );
		}
	}
	
	if( (fpr=fopen(inffile,"r"))!=NULL ){
		printf( "%s:\n", inffile );
		while( fgets(buf,1024,fpr)!=NULL ){
			strcpy( spr,buf );
			cut_space(spr);
			if( stricmp(spr,"memo")==NULL ){
				l = 0;
				while( !feof(fpr) ){
					*(memo_trace++) = fgetc(fpr);
					l++;
					if( l>=65000 )break;
				}
				*memo_trace = '\0';
				break;
			}
			if( (x=instr(spr,'='))==EOF )continue;
			strcpy( com,spr   );com[x-1] = '\0';
			strcpy( arg,spr+x );
			if( !stricmp( com,"title" ) )			strcpy( title,arg   );
			else if( !stricmp( com,"artist"  ) )	strcpy( artist,arg  );
			else if( !stricmp( com,"lyric"  ) )		strcpy( lyric,arg  );
			else if( !stricmp( com,"composer" ) )	strcpy( composer,arg );
			else if( !stricmp( com,"arranger" ) )	strcpy( arranger,arg );
			else if( !stricmp( com,"copyright"  ) )	strcpy( copyright,arg  );
			else if( !strnicmp( com,"track",5  ) ){
				track = atoi(com+5);
				if( *(com+5)<'0' || *(com+5)>'9' ){
					printf("Track? で トラック番号が数値ではありません。\n");
				}
				else if( track<0 || track>31 ){
					printf("Track%d は存在しません。\n",track);
				}
				else if( arg[0]!='\0' ){
					if( arg[0]=='_' ){
						x1 = instr    (arg,'(');
						x2 = instrback(arg,')');
						arg[x1-1] = '\0';
						arg[x2-1] = '\0';
						num = atoi(arg+x1);
						if( num<0 || num>31 ){
							printf("外部オブジェクト参照 Track 番号が不正です。\n");
						}
						else {
							strcpy( extern_object[track].name,arg );
							extern_object[track].track = num;
						}
					}
					else {
						tf  = TRUE;
						agx = arg;
						ci  = 0;
						while( tf==TRUE ){
							tf = FALSE;
							x1 = instr(agx,'(');
							x2 = instr(agx,')');
							if( agx[x2]!=',' && agx[x2]!='\0' ){
								printf("Track%d のセパレータが不正です。\n",track);
							}
							if( agx[x2]==',' )tf = TRUE;
							agx[x1-1] = '\0';
							agx[x2-1] = '\0';
							num = atoi(agx+x1);
							strcpy( extern_module[track].chain[ci].name,agx );
							extern_module[track].chain[ci].channel = num;
							agx = agx+x2+1;
							ci++;
							if( ci>4 ){
								printf("Track%d の音源チェインが 4を越えました。\n",ci );
								break;
							}
						}
					}
				}
			}
		}
		fclose( fpr );
	}
	else {
		clearerr( fpr );
	}
}
//------------------------------------------------ ソースオブジェクト作成 -----
void makesobj( char *objectfile )
{
	FILE *fpr,*fpw;
	struct date da;
	struct time ti;
	char dr[MAXDRIVE],di[MAXDIR],fi[MAXFILE],ex[MAXEXT],objname[256],
		 buf[1024],spr[1024],inffile[256],com[1024],arg[1024];
	unsigned l;
	int i,x;
	
	fnsplit(objectfile,dr,di,fi,ex);
	sprintf(objname,"_%s_midi",strlwr(fi));
	printf( "%s:\n", objectfile );

	if( (fpw=fopen( objectfile,"wb" ))==NULL ){
		puts("Can\'t make source object.");
		mcv_exit( EOF );
	}
// 識別子
	fprintf( fpw,
		"XMML3.00 source object - Standerd MIDI file converter mcv.exe ver.%d.%02d%c\n"
		"copyright (c) 1993,94 by Interfair all rights reserved.\n"
		"\x1a%c",
		version_int,version_real,version_char,0 );

	fprintf( fpw,"%s%c",title,0 );							// タイトル
	fprintf( fpw,"%s%c",composer,0 );						// 作曲者
	fprintf( fpw,"%s%c",arranger,0 );						// 編曲者
	fprintf( fpw,"%s%c",lyric,0 );							// 作詞者
	fprintf( fpw,"%s%c",artist,0 );							// アーティスト
	fprintf( fpw,"%s%c",copyright,0 );						// コピーライト
	fprintf( fpw,"%s%c",memo,0 );							// メモ

	getdate( &da );
	gettime( &ti );
	
	fprintf( fpw,"%c%c%c%c%c%c",
		da.da_year%100,da.da_mon,da.da_day,
		ti.ti_hour,ti.ti_min,ti.ti_sec );

// 優先関係
	fputc( 0xff,fpw );

// 一般オブジェクト
	fprintf( fpw,"%s%c",objname,0 );

	fclose( fpw );
	free_memory( memo );
}

//---------------------------------------------------------------- リンク -----
int mll( char *mbs,char *mbj )
{
	if( searchpath("ml.exe")==NULL ){
		printf("Warning : Can\'t find ml.exe\n");
		return NULL;
	}
	spawnlp( P_WAIT,"ml.exe","ml.exe",mbs,mbj,linkopt,NULL );
	return NULL;
}
//---------------------------------------------------- 効果音ファイル作成 -----
void makeeud( char *objectfile,int chn )
{
	TRACK trk[32];
	int i,j,fdr,fdw;
	long size,fp,l;
	char tmp[256],trkfile[256],buf[1024],*copymem;
	
	get_temporary(tmp);
	
	printf( "%s:\n", objectfile );
	
	copymem = keep_highmemory(32000);
	if( (fdw=open(objectfile,O_WRONLY|O_BINARY|O_CREAT,S_IREAD|S_IWRITE))==EOF){
		printf("Can\'t make eud file.\n");
		mcv_exit(EOF);
	}
	sprintf(trkfile,"%s\\%s%d.$$$",tmp,TMPFILE_F1,chn);
	fdr = open(trkfile,O_RDONLY|O_BINARY);
	while( (size=read(fdr,copymem,32000))!=NULL ){
		write( fdw,copymem,size );
	}
	close(fdr);
	close(fdw);
	free_memory(copymem);
}

//---------------------------------------------------- マップファイル作成 -----
void makemap( char *mapfilename,char *midfilename, int filech[] )
{
	int i;
	FILE *fpw;
	
	
	printf( "%s:\n", mapfilename );
	
	if( (fpw=fopen(mapfilename,"w"))==NULL )
	{
		printf("Can\'t make map file.\n");
		mcv_exit(EOF);
	}
	fprintf( fpw,
		"-- mcv.exe version %1d.%02d%c MIDI mapfile of \'%s\' --\n\n",
		version_int,
		version_real,
		version_char,
		midfilename
	);
	
	for( i=0; i<32; i++)
	{

		if( filech[i]==EOF ) continue;
		
		fprintf( fpw,"Track(%2d) : ", i );
		
		if( filech[i]>=0 && filech[i]<16 )
		{
			fprintf( fpw,"MIDI ch.(%2d) ; ", filech[i] );
		}
		else if( filech[i]==256 )
		{
			fprintf( fpw,"Conductor    ; " );
		}
		fprintf( fpw,"\"%s\"\n", trackname[i] );
	}
	fclose(fpw);
}
