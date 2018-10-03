//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 object linker
//                          ML(tm) version 1.00
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
#include	"..\mcv\mcv.h"

#define		version_int		2
#define		version_real	43
#define		version_char	' '

#define		TMPFILE_F1		"mcvtch"
#define		TMPFILE_F2		"mcvtmp"
#define		MAX_OBJINFO		32
#define		MAX_LABEL		200
#define		MAX_DRVID		256
#define		MAX_INSTRUMENT	1024
#define		VOICE_FP		0
#define		VOICE_SIZE		1
#define		MUSIC1			50
#define		MUSIC2			100

#define		mem()		printf("	Available memory  :  %ldbytes.\n\n",coreleft())
#define		fputw(a,b)		putw(a,b)

void ml_exit( int );
void init_label(void);
void usage_out( void );
void mlink( char *a[],int,char * );
void track_link( char *,int,MFILE *fpw);
long sound_link( MFILE *fpw );
unsigned optimize(FILE *,MFILE *,long);

long fgetcount;
int fgetcbuf=EOF , option[26];
int errorflag;

enum {
	OPT_A,OPT_B,OPT_C,OPT_D,OPT_E,OPT_F,OPT_G,OPT_H,OPT_I,OPT_J,OPT_K,OPT_L,
	OPT_M,OPT_N,OPT_O,OPT_P,OPT_Q,OPT_R,OPT_S,OPT_T,OPT_U,OPT_V,OPT_W,OPT_X,
	OPT_Y,OPT_Z
} OptionSelector;

typedef struct {
	long fp;
	char objectname[MAXPATH];
	char filename[MAXPATH];
	long track_fp[32];
} OBJTABLE;
OBJTABLE objinfo[MAX_OBJINFO];
int on = 0;

typedef struct {
	long fp;
	int  type;
	long value;
	int  size;
} LABEL;

LABEL label[MAX_LABEL];
int label_no = 0;

struct {
	unsigned bank;
	byte no;
} inst_buf[MAX_INSTRUMENT];
int inst_x;

typedef struct
{
	char filename[13];
	long filesize;
	char drvid[16];
} LISHEAD;

char *drvid_name[MAX_DRVID];
char lisfile[MAXPATH];
int drvid_x;
char globalmud[MAXPATH];

char soundtmpfile[256];

void main(int argc,char **argv)
{
	char dr[MAXDRIVE],di[MAXDIR],fi[MAXFILE],ex[MAXEXT],mud[MAXPATH],mbs[MAXPATH];
	char filename[MAXPATH],*objfile[MAX_OBJINFO],wrtfile[MAXPATH];
	int filech[32],i,n=0;

	errorflag = FALSE;
	strcpy(soundtmpfile,"soundtmp.mbj");

	fnsplit( argv[0],dr,di,fi,ex );
	fnmerge( lisfile,dr,di,"sound",".lis");

	for( i=0; i<26; i++)option[ i ] = FALSE;
	drvid_x    = 0;
	inst_x     = 0;
	
	printf(
		"music driver MFXDDN XMML3.00 object linker ML version %1d.%02d%c\n"
		"copyright (c) 1993 by ABA / T.Kobayashi and Interfair "
		"All Rights Reserved.\n",
		version_int,
		version_real,
		version_char
	);
	strcpy( filename,"" );
	strcpy( globalmud,"" );
	strcpy( wrtfile,"" );
	if( argc<=1 )	usage_out();

	for( i=1; i<argc; i++){
		if( **(argv+i)!='/' && **(argv+i)!='-' ){
			if( (objfile[n]=keep_highmemory(MAXPATH))==NULL ){
				puts("Not enough memory.");
				ml_exit( EOF );
			}
			strcpy( objfile[n++],*(argv+i) );
		}
		else {
			switch( *(argv[i]+1) ){
				case 'o':case 'O':
					printf("-- 最適化を行います. --\n");
					option[OPT_O] = TRUE;
					break;
				case 'l':case 'L':
					strcpy( lisfile,argv[i]+2 );
					break;
				case 'u':case 'U':
					printf("-- 音色ライブラリをリンクしません. --\n");
					option[OPT_U] = TRUE;
					break;
				case 'w':case 'W':
					strcpy( wrtfile,argv[i]+2 );
					printf("-- 出力ファイル : %s --\n",wrtfile);
					break;
				default:
					printf("Illigal Option : -%c\n",*(*(argv+i)+1) );
					break;
			}
		}
	}
	if( !n ) usage_out();
	
	fnsplit( objfile[0] ,dr,di,fi, ex     );
	fnmerge( objfile[0] ,dr,di,fi, ".mbs" );

	if( wrtfile[0]==NULL )
	{
		fnmerge( mud        ,"","",fi, ".mud" );
		fnmerge( globalmud  ,"","",fi, ".mud" );
	}
	else
	{
		strcpy( mud      ,wrtfile );
		strcpy( globalmud,wrtfile );
	}
	for( i=1; i<n; i++){
		fnsplit( objfile[i],dr,di,fi,ex     );
		fnmerge( objfile[i],dr,di,fi,".mbj" );
	}
	
	mbufsize(60000);
	
	init_label();
	mlink( objfile,n,mud );
	ml_exit( NULL );
}

void ml_exit( int erl )
{
	char tmp[256],rfile[256],wfile[256];
	int i;
	if( errorflag==TRUE || erl!=NULL )unlink(globalmud);
	
	strcpy(tmp,getenv("TMP"));
	cut_dirmark(tmp);
	mem();
	exit( erl );
}

void spc_cut( char *str )
{
	while( *str!='\0' ){
		if( *str==' ' )*str='\0';
		str++;
	}
}

void init_label( void )
{
	int i;
	for( i=0; i<MAX_LABEL; i++)label[i].fp = EOF;
}

void set_label( MFILE *fp,int type,int size )
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
		errorflag = TRUE;
		printf("Sorry! Relocatable stack over.\n");
		ml_exit(EOF);
	}
	
	label[ label_no ].fp   = fp->fp;
	label[ label_no ].type = type;
	label[ label_no ].value= EOF;
	label[ label_no ].size = size;
	mwrite( "",size,fp );
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
		errorflag = TRUE;
		printf("Broken relocatable stack.\n");
		ml_exit(EOF);
	}
	
	label[ label_no ].type = EOF;
	label[ label_no ].value= value;
}

void write_label(char *fname)
{
	int i;
	FILE *fpw;
	
	if( (fpw=fopen(fname,"r+b"))==NULL ){
		errorflag = TRUE;
		printf("Can\'t rewrite file : %s\n",fname );
		ml_exit(EOF);
	}
	for( i=0; i<MAX_LABEL; i++){
		if( label[i].fp==EOF )continue;
		if( label[i].value==EOF )continue;
		
		fseek( fpw,label[i].fp,SEEK_SET );
		fwrite( &label[i].value,label[i].size,1,fpw );
	}
	fclose( fpw );
}

void usage_out(void)
{
	puts(
		"Syntax ;\n"
		"         ml.exe [source object] <[object] | [-|/]option...>\n"
		"Option ;\n"
		"         -o       データの最適化を行います\n"
		"         -l(file) 音色ファイルを指定する\n"
		"         -w(file) 出力ファイルを指定する\n"
		"         -u       音色ファイルをリンクしない\n"
	);
	ml_exit( NULL );
}
// ADTシステム ----------------------------------------------------------------
void makeadt_inst(unsigned bank,int no)
{
	int i;
	if( inst_x >= MAX_INSTRUMENT )
	{
		errorflag = TRUE;
		printf("Warning: Too meny kind of instrument.\n");
		return;
	}
	for( i=0; i<inst_x; i++)
		if( inst_buf[i].bank==bank && inst_buf[i].no==no )return;
	inst_buf[inst_x].bank = bank;
	inst_buf[inst_x].no   = no  ;
	inst_x++;
}
int check_inst(unsigned bank,int no)
{
	int i;
	for( i=0; i<inst_x; i++)
		if( inst_buf[i].bank==bank && inst_buf[i].no==no )return TRUE;
	return FALSE;
}

void makeadt_drvid(char *drvid)
{
	int i,flag;
	if( drvid_x >= MAX_DRVID )
	{
		errorflag = TRUE;
		printf("Warning: Too meny drvid tracks.\n");
		return;
	}
	
	for( i=0; i<drvid_x; i++)
		if( strcmp( drvid_name[i],drvid )==NULL )return;

	if( (drvid_name[drvid_x]=malloc(16))==NULL )
	{
		errorflag = TRUE;
		printf("Fatal error: Not enough to memory.\n");
		exit(EOF);
	}
	strncpy( drvid_name[drvid_x++],drvid,16 );
}
int check_drvid(char *drvid)
{
	int i;
	for( i=0; i<drvid_x; i++)
		if( !strcmp(drvid_name[i],drvid) )return TRUE;
	return FALSE;
}

//-------------------------------------------------------- トラックリンク -----
void track_link( char *objectname,int labeltype,MFILE *fpw )
{
	long fp,bfp[32],bsize[32],l;
	unsigned size;
	int i,j,k,x,uf[32],nflag,timebase,extern_flag,extern_track,extern_no[32];
	FILE *fpr,*fpr_old;
	TRACK trk;
	char extern_objectname[256];
	
	fp = fpw->fp;		// リンク前の現在の fp を保存
	set_label_value( labeltype,fp );
	
	x = EOF;
	for( i=0; i<on; i++){
		if( strcmp(objectname,objinfo[i].objectname)==NULL ){
			x = i;
			break;
		}
	}
	if( x==EOF ){
		errorflag = TRUE;
		printf("Undefined:	%s\n",objectname);
		return;
	}
	
	if( (fpr=fopen(objinfo[x].filename,"rb"))==NULL ){
		errorflag = TRUE;
		printf("Can\'t open object : %s\n",objinfo[x].filename);
		ml_exit(EOF);
	}
	fseek( fpr,objinfo[x].fp,SEEK_SET );
	fread( &timebase,sizeof(int),1,fpr );		// read  timebase
	
	mwrite( &timebase,sizeof(int),fpw );		// write timebase
	for( i=0; i<32; i++){
		uf[i]       = FALSE;
		extern_flag = FALSE;
	
		j = 0;
		if( fgetc(fpr)==0x01 ){
			while( (extern_objectname[j++]=fgetc(fpr))!=NULL );
			extern_track = fgetc(fpr);

			x = EOF;
			for( j=0; j<on; j++){
				if( strcmp(extern_objectname,objinfo[j].objectname)==NULL ){
					x = j;
					break;
				}
			}
			if( x==EOF ){
				errorflag = TRUE;
				printf("Undefined:	%s in %s\n",extern_objectname,objectname);
				return;
			}
			fpr_old     = fpr;
			extern_flag = TRUE;
			
			if( (fpr=fopen( objinfo[x].filename,"rb" ))==NULL ){
				errorflag = TRUE;
				printf("Can\'t open extern object : %s\n",objinfo[x].filename);
				ml_exit(EOF);
			}
			fseek( fpr,objinfo[x].track_fp[extern_track],SEEK_SET );
			if( fgetc(fpr)!=NULL ){
				errorflag = TRUE;
				printf("Error:	extern object %s(Track%d) called new extern object.\n",
					objinfo[x].filename,extern_track
				);
				ml_exit(EOF);
			}
		}
	
		for( j=0; j<4; j++){
			k = 0;
			while( (trk.chain[j].module[k++]=fgetc(fpr))!=NULL );
			trk.chain[j].channel = fgetc(fpr);
		}
		fread( &trk.fp      ,sizeof(long),1,fpr );
		fread( &trk.size    ,sizeof(long),1,fpr );
		fread( &trk.compless,sizeof(unsigned),1,fpr );
		fread( &trk.ext     ,sizeof(unsigned),1,fpr );
		
		nflag = 0;
		for( j=0; j<4; j++){
			spc_cut( trk.chain[j].module );
			if( strcmp(trk.chain[j].module,"OFF")==NULL ){
				strcpy( trk.chain[j].module,"" );
				nflag++;
			}
		}
								// 4channel 全部OFFだった...
		if( nflag==4 ){
			if( extern_flag == TRUE )fpr = fpr_old;
			continue;
		}

		uf[i]    = TRUE;			// トラック使用フラグ
		bfp[i]   = trk.fp  ;
		bsize[i] = trk.size;
		
		mputc( i,fpw );									// Track NO書き出し
		for( j=0; j<4; j++){
			mwrite( trk.chain[j].module,
				strlen(trk.chain[j].module)+1,fpw );	// 音源書き出し
			mputc(  trk.chain[j].channel,fpw );			// チャンネル書き出し
		}
		set_label( fpw,1000+i,sizeof(long) );			// BIN FP
		mwrite( &trk.size,4,fpw );						// BIN SIZE
		
		if( option[OPT_O]==TRUE && bsize[i]<65500 ){
			mputw( 'FZ',fpw );							// 圧縮あり
			set_label( fpw,2000+i,sizeof(unsigned) );	// 拡張
		}
		else{
			mputw( 'NC',fpw );							// 圧縮なし
			mputw( ''  ,fpw );							// 拡張
		}
		if( extern_flag == TRUE ){
			fclose( fpr );
			fpr          = fpr_old;
			extern_no[i] = x;
		}
		else 
			extern_no[i] = EOF;
	}
	mputc( 0xff,fpw );
	// Track BIN 書き出し
	for( i=0; i<32; i++){
		if( uf[i]==FALSE )continue;
		if( extern_no[i]!=EOF ){
			fpr_old = fpr;
			fpr = fopen( objinfo[extern_no[i]].filename,"rb" );
		}
		fseek( fpr,bfp[i],SEEK_SET );
		set_label_value( 1000+i,fpw->fp );
		if( option[OPT_O]==TRUE && bsize[i]<65500 ){
			printf("Track %2d Optimizing ",i);
			size = optimize( fpr,fpw,bsize[i] );
			set_label_value( 2000+i,size );
		}
		else {
			printf("Track %2d Saving ",i);
			for( l=0; l<bsize[i]; l++)mputc( fgetc(fpr),fpw );
		}
		printf("\x1b[2K\r");
		if( extern_no[i]!=EOF ){
			fclose(fpr);
			fpr = fpr_old;
		}
	}
	fclose(fpr);
}
//--------------------------------------------------------- MUDMF3.00作成 -----
void mlink( char *objectfile[],int n,char *mud )
{
	FILE *fpr,*fpr2;
	int i,j,c,t,t2,mus1,mus2,no,dr;
	long nextfp,skipbin,fp,size;
	char buf[256],*mus1_obj[100],*mus1_drv[100],mus2_obj[256],drvid[256];
	unsigned bank;
	MFILE fpw;
	TRACK trk;
	
	if( (fpr=fopen(objectfile[0],"rb"))==NULL ){
		errorflag = TRUE;
		printf("Can\'t open source object file : %s\n",
			objectfile[0] );
		ml_exit(EOF);
	}
	
	for( j=0; j<22; j++){
		buf[j] = fgetc(fpr);
	}
	buf[22] = '\0';
	if( strcmp(buf,"XMML3.00 source object")!=NULL ){
		errorflag = TRUE;
		printf( "Not source object file : %s\n",objectfile[0] );
		ml_exit(EOF);
	}
	while( fgetc(fpr)!=0x00 );
	
	if( mopen(mud,&fpw)==EOF ){
		printf("Can\'t make mud file.");
		ml_exit(EOF);
	}
	printf("%s:\n",mud);
	
	for( i=0; i<MAX_OBJINFO; i++){
		strcpy( objinfo[i].objectname,"" );
	}
	
	for( i=1; i<n; i++){
		if( (fpr2=fopen(objectfile[i],"rb"))==NULL ){
			errorflag = TRUE;
			printf("Can\'t open object file : %s\n",
				objectfile[i] );
			clearerr(fpr2);
			continue;
		}
		
		for( j=0; j<15; j++){
			buf[j] = fgetc(fpr2);
		}
		buf[15] = '\0';
		if( strcmp( buf,"XMML3.00 object" )!=NULL ){
			printf( "Not object file : %s\n",objectfile[i] );
			errorflag = TRUE;
			ml_exit(EOF);
		}
		while( fgetc(fpr2)!=NULL );
		
		while( fgetc(fpr2)==0x01 ){
// オブジェクト読み込み
			skipbin = 0;

			j = 0;
			while( (c=fgetc(fpr2))!=NULL ){
				objinfo[on].objectname[j] = c;
				j++;
			}
			objinfo[on].objectname[j] = '\0';
			strcpy( objinfo[on].filename,objectfile[i] );
			
			objinfo[on].fp = ftell(fpr2);
			fseek( fpr2,2,SEEK_CUR );		// skip timebase
			
			for( t=0; t<32; t++){
				objinfo[on].track_fp[t] = ftell(fpr2);
				if( fgetc(fpr2)==NULL ){			// Chain is own object
					for( t2=0; t2<4; t2++){			// 音源指定のスキップ
						for( dr=0; dr<16; dr++)
							if( (drvid[dr]=fgetc(fpr2))==NULL )break;
						fgetc( fpr2 );				// Channel スキップ

						makeadt_drvid(drvid);		// 辞書登録

					}
					getw(fpr2);getw(fpr2);			// BIN FP  のスキップ
					fread( &fp,sizeof(long),1,fpr2);// BIN SIZE
					skipbin += fp;
					getw(fpr2);						// 圧縮フラグ
					getw(fpr2);						// 拡張
				}
				else {								// Chain is extern one.
					while( fgetc(fpr2)!=NULL );		// extern のスキップ
					fgetc(fpr2);					// トラック番号のｽｷｯﾌﾟ
				}
			}
// リンク音色読み込み＆辞書登録
			fseek( fpr2,skipbin,SEEK_CUR );
			
			while( (bank=(unsigned)getw(fpr2))!=0xffff )
			{
				no = fgetc(fpr2);
				makeadt_inst(bank,no);
			}
			on ++;
		}
		fclose(fpr2);
	}
	
	printf("No_ Objectname__________ Filename____________\n");
	for( i=0; i<on; i++){
		printf( "%3d %-20s %-20s\n",i,objinfo[i].objectname,objinfo[i].filename );
	}
	
// MUDヘッダー書き出し
	mputs( "Mudmf",&fpw );
	mputc( version_int ,&fpw );
	mputc( version_real,&fpw );
	mputc( version_char,&fpw );
	mputc( 0x1a        ,&fpw );
	sprintf( buf,"XMML3.00 linker: ml.exe version %1d.%02d%c",
		version_int,
		version_real,
		version_char
	);
	mwrite( buf,strlen(buf)+1,&fpw );

// メタイベント書き出し	(mbs -> mud  copy only)
	for( i=0; i<7; ){
		if( (c=fgetc(fpr))==0x00 )i++;
		mputc( c,&fpw );
	}

// 拡張エリア
	for( i=0; i<12; i++)mputc( 0x00,&fpw );

// データ作成日時		(mbs -> mud  copy only)
	for( i=0; i<6;  i++)mputc( fgetc(fpr),&fpw );

// 音色fp
	set_label( &fpw,VOICE_FP  ,sizeof(long) );
	set_label( &fpw,VOICE_SIZE,sizeof(long) );

// 優先処理
	mus1 = 0;
	while( fgetc(fpr)==0x00 ){
		i = 0;
		while( (buf[i++]=fgetc(fpr))!=0x00 );
		spc_cut( buf );
		mus1_drv[mus1] = keep_highmemory(256);
		strcpy( mus1_drv[mus1],buf );

		i = 0;
		while( (buf[i++]=fgetc(fpr))!=0x00 );
		spc_cut( buf );
		mus1_obj[mus1] = keep_highmemory(256);
		strcpy( mus1_obj[mus1],buf );

		mputc( 0x00,&fpw );
		mwrite( mus1_drv[mus1],strlen(mus1_drv[mus1])+1,&fpw );

		set_label( &fpw,MUSIC1+mus1,sizeof(long) );
		mus1 ++;
	}
	mputc( 0xff,&fpw );

// 一般オブジェクト
	i = 0;
	while( (c=fgetc(fpr))!=0x00 ){
		mus2_obj[ i++ ] = c;
	}
	mus2_obj[ i ] = '\0';
	spc_cut( mus2_obj );
	mwrite( mus2_obj,strlen(mus2_obj)+1,&fpw );
	set_label( &fpw,MUSIC2,sizeof(long) );

// トラックリンク

	for( i=0; i<mus1; i++){
		track_link( mus1_obj[i],MUSIC1+i,&fpw );
	}
	track_link( mus2_obj,MUSIC2,&fpw );

// 音色
	set_label_value( VOICE_FP  ,fpw.fp);
	size = sound_link( &fpw );
	set_label_value( VOICE_SIZE,size  );
	
	mclose( &fpw );
	fclose(fpr);
	
// ラベル書き出し
	write_label(mud);
}

// FLZによるBIN圧縮
unsigned optimize(FILE *fpr,MFILE *fpw,long fsize)
{
	long size;
	unsigned cl[256],min;
	unsigned fs,p1,p2,p3,i,j,max,man,min_n,fxsize=0,roll;
	unsigned char *buf;
	int ii;
	long base;
	char *rollchr[8]={
		"｜","／","―","＼","｜","／","―","＼"
	};
	
	fprintf( stderr,"(%6ld) \x1b[>5h",fsize );
	
	roll = 0;
	fs   = (unsigned)fsize;

	if((buf=keep_highmemory(65500))==NULL){
		puts( "not enough memory!" );
		errorflag = TRUE;
		exit( EOF );
	}
	if( fs>=65500 )
	{
		puts( "Object filesize over!" );
		errorflag = TRUE;
		exit( EOF );
	}
	fread(buf,fs,1,fpr);
	
	for(i=0;i<=255;i++ )cl[i]=0;
	for(i=0;i<fs  ;i++ )cl[*(buf+i)]++;
	min=65535;
	for( ii=255 ; ii>=0 ; ii--){
		if(min > cl[ii]){
			min=cl[ii];
			min_n=ii;
		}
	}
	mputc(min_n,fpw);
	fxsize++;
	
	for(i=0;i<fs;i++){
		max=0;
		
		if( (i % 100)==NULL ){
			if( (i % 600)==NULL ){
				fputs(". \x08",stderr);
			}
			fputs( rollchr[roll++],stderr );
			fputs( "\x08\x08",stderr );
			roll = roll % 8;
		}
		for(j=0;j<=251;j++){
			base = i-256+j;
			if(base<0)continue;
			if(*(buf+base)==*(buf+i)){
				p1    = 1;
				p2    = 1;
				while( *(buf+base+p1)==*(buf+i+p1) ){
					if( base+p1 >=fs  || i+p1>=fs )break;
					if((base+p1)>=i   || p1  >=255){
						p2--;
						break;
					}
					p1++;
					p2++;
				}
				if(max < p2){
					max=p2;
					man=j;
				}
			}
		}
		if(max >=4 ){
			mputc(min_n,fpw);
			mputc(max,fpw);
			mputc(man,fpw);
			fxsize+=3;
			i+=(max-1);
		}
		else {
			if(*(buf+i)==min_n){
				mputc(min_n,fpw);
				mputc(0,fpw);
				fxsize+=2;
			}
			else {
				mputc(*(buf+i),fpw);
				fxsize++ ;
			}
		}
	}
	free_memory(buf);

	fputs( "\x1b[>5l",stderr );

	return fxsize;
}

// 音色定義トラックファイルの作成
long sound_link(MFILE *fpw)
{
	FILE *fpr;
	LISHEAD lh;
	int i,flag;
	int ecm_drvidnum,ecm_drvtype;
	unsigned bank,no;
	long fp,s,size,endfp,l,fp1,fp2;
	byte buf[256];
	
	if( option[OPT_U]==TRUE )
	{
		mputc(0xe2,fpw);			// トラック終了
		return 1;
	}

	if( (fpr=fopen(lisfile,"rb"))==NULL )
	{
		printf("--- 音色ファイルがありません ---(path : %s)\n",lisfile);
		clearerr(fpr);
		mputc(0xe2,fpw);			// トラック終了
		return 1;
	}

	fp1 = fpw->fp;

// おとかきこみ
	fread( &buf,9,1,fpr );
	if( strncmp(buf,"Lissf",5)!=NULL )
	{
		printf("Warning: 音色ライブラリではありません。\n");
		fclose(fpr);
		mputc(0xe2,fpw);			// トラック終了
		return 1;
	}
	while( fgetc(fpr)!=NULL );
	fseek( fpr,3+3+16,SEEK_CUR );

	while( fgetc(fpr)==0x01 )
	{
		fread( &lh,sizeof(LISHEAD),1,fpr );
		flag=FALSE;
		for( i=0; i<drvid_x; i++)
		{
			if( check_drvid(lh.drvid)==TRUE )
			{
				flag=TRUE;
				break;
			}
		}
		if( flag==FALSE )
		{
			fseek( fpr,lh.filesize,SEEK_CUR );
			continue;
		}
//		fp = ftell(fpr);
		printf("Sound %-16s Saving ",lh.drvid);
		
		fread( buf,21,1,fpr );
		if( strncmp(buf,"XMML3.00 sound object",21) )
		{
			printf("Warning: Sound object '%s\' is broken.\n",lh.filename);
			errorflag = TRUE;
		}
		else
		{
			while( fgetc(fpr)!=NULL );
			while( fgetc(fpr)!=NULL );			// Skip drvid
			ecm_drvidnum = getw(fpr);
			ecm_drvtype  = getc(fpr);
			while( (bank=(unsigned)getw(fpr))!=0xffff )
			{
				no  = fgetc(fpr);
				fread( &size,sizeof(long),1,fpr );
				if( check_inst(bank,no)==TRUE )
				{
					mputc( 0xe1,fpw );				/* ECM */
					mputw(ecm_drvidnum    ,fpw);
					mputc(ecm_drvtype     ,fpw);
					mputw((unsigned)size+4,fpw);
					mputc( 0x00,fpw );
					mputw( bank,fpw );
					mputc( no  ,fpw );
					
					for( s=0; s<(unsigned)size; s++)
					{
						mputc( fgetc(fpr),fpw );
					}
				}
				else
				{
					fseek( fpr,size,SEEK_CUR );
				}
			}
		}
		printf("\x1b[2K\r");
	}
	fclose(fpr);
	mputc(0xe2,fpw);			// トラック終了
	
	fp2 = fpw->fp;
	
	size = fp2-fp1;
	return size;
}
//
// log:
// version 1.00		XMML2.00 linker はしんでます^^;
// version 2.00		とりあえず、XMML3.00用に作成して完成
// version 2.10		データ最適化機能追加 (-o)
// version 2.10A	トラックの外部object参照機能追加
// version 2.20		BUG FIX
// version 2.30		マップファイルを作成するようにした
// version 2.40		音色がlinkできるようになった。
// version 2.41		音色ライブラリに登録されていた音色がリンクされないbug
//					を修正した。
// version 2.43		ファイル出力(-w)オプションを追加
