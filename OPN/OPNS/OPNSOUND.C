#include	<stdio.h>
#include	<string.h>
#include	<alloc.h>
#include	<dos.h>
#include	<dir.h>
#include	<mem.h>
#include	<conio.h>
#include	<crtbios.h>
#undef		text_end()
#include	<master.h>
#include	<mylib.h>
#include	<game.h>
#include	<mfxddn.h>
#include	"opnsound.h"
#include	"sound.h"

#define		MAIN_WINDOW		0
#define		SUB_WINDOW		1
#define		DRVIDNUM		0x0008
#define		DEVICENAME		"OPN"
#define		YES				1
#define		NO				0

char *ntcode[]={
	"C","C#|Db","D","D#|Eb","E","F","F#|Gb","G","G#|Ab","A","A#|Bb","B"
};
int tf[4]={ 0,2,1,3 };

int 
	sx[9]     = { 9, 13, 17, 21, 25, 29, 33, 37, 41 },
	sy[5]     = { 3,  5,  6,  7,  8 },
	max_value[5][9] = {
		{ 255,255, 99,255, 99,255,  7,  7, 63 },
		{  31, 31, 31, 15, 15,127,  3, 15,  7 },
		{  31, 31, 31, 15, 15,127,  3, 15,  7 },
		{  31, 31, 31, 15, 15,127,  3, 15,  7 },
		{  31, 31, 31, 15, 15,127,  3, 15,  7 } },
	min_value[5][9] = {
		{   0,  0,  0,  0,  0,  0,  0,  0,  0 },
		{   0,  0,  0,  0,  0,  0,  0,  0,  0 },
		{   0,  0,  0,  0,  0,  0,  0,  0,  0 },
		{   0,  0,  0,  0,  0,  0,  0,  0,  0 },
		{   0,  0,  0,  0,  0,  0,  0,  0,  0 } };
	
typedef struct {
	int		data[5][9];
} INPARAM;

OPNDATA		opndata[256];

void set_screen(void);
void init_opndata(void);
void savetoinner(int,INPARAM *);
void innertosave(int,INPARAM);
void put_parameter( int,INPARAM );
void load(char *);
void save(void);
void edit(void);

int mididrv,miditbl;
char *soundlist[256];

int main(int argc,char **argv)
{
	int i,ext,num;
	char filename[256],dr[MAXDRIVE],di[MAXDIR],fi[MAXFILE],ex[MAXEXT],
		sndfile[256],buf[255];
	FILE *fpr;
	
	strcpy( filename,"" );
	ext = FALSE;
	
	for( i=1; i<argc; i++)
	{
		if( *argv[i]=='/' || *argv[i]=='-' )
		{
			switch( *(argv[i]+1) )
			{
				case 'x':case 'X':			// 外部に頼る
					ext = TRUE;
					break;
			}
		}
		else
		{
			strncpy(filename,argv[i],255);
		}
	}
	if( ext==FALSE )
	{
		printf("%s\n",argv[0]);
		fl_file(argv[0]);
	}

	mididrv = FALSE;

	puts("[OPN] sound editor version 1.00");
	puts("copyright (c) 1994 Interfair all rights reserved.");

	if( (fpr=fopen("opnsound.snd","r"))==NULL )
	{
		clearerr(fpr);
		fnsplit( argv[0],dr,di,fi,ex );
		fnmerge( sndfile,dr,di,"opnsound",".snd");
		if( (fpr=fopen(sndfile,"r"))==NULL )
		{
			printf(
				"Could not open \'%s\'\n"
				"Use a default series of sound-name lists.\n",
				sndfile
			);
			clearerr(fpr);
			for( i=0  ; i<=127 ; i++)
				soundlist[i] = default_soundlist[i];
			for( i=128; i<=255 ; i++)
				soundlist[i] = "-- No inst --";
			goto follow;
		}
	}
	for( i=0; i<=255 ; i++)
		soundlist[i] = "-- No inst --";
	while( fgets(buf,255,fpr)!=NULL )
	{
		if( buf[0]<' ' )continue;
		sscanf(buf,"%d%s\n",&num,buf);
		printf("%4d",num,buf);
		if( buf[0]==NULL )break;
		if( !(soundlist[num]=malloc(strlen(buf)+1)) )
		{
			printf("Fatal error: Not enough to memory.\n");
			exit(1);
		}
		strcpy( soundlist[num],buf );
	}
	fclose(fpr);
	printf(" loaded.\n");
follow:

/*
	if( mfxddn_install_kernel()==EOF )
	{
		printf("fatal error: could not install MFXDRV/DDN \n");
		return 1;
	}
*/
	if( mfxddn_bgm_init()==EOF )
	{
		printf("fatal error: MFXDRV/DDN is broken.\n");
/*
		mfxddn_remove_kernel();
*/
		return 1;
	}
	if( mfxddn_load_driver_filelink(DEVICENAME".xdv","",XDVTITLE_ON)==EOF )
	{
		printf("fatal error: Could not install driver.\n");
/*
		mfxddn_remove_kernel();
*/
		return 1;
	}
	if( mfxddn_load_driver_filelink("midi.xdv","",XDVTITLE_ON)!=EOF )
	{
		printf("Can use MIDI driver.\n");
		mididrv = TRUE;
		if( (miditbl = mfxddn_get_driver_table("MIDI"))==EOF )
		{
			printf("fatal error: MIDI.XDV's ID is different from the original ID.\n");
/*
			mfxddn_remove_kernel();
*/
			return 1;
		}
		mfxddn_dcm_init(miditbl);
		mfxddn_dcm_volume(miditbl,0,127);
		mfxddn_dcm_expression(miditbl,0,127);
	}
	printf("\x1b[>1h\x1b[>5l");
	
	key_beep(BEEPOFF);
	key_start();
	
	set_screen();
	init_opndata();
	if( *filename!=NULL )load(filename);
	
	edit();
	
	key_end();
	key_beep(BEEPON);
	
	printf("\x1b[>1l\x1b[>5l\x1b[2J");
/*
	mfxddn_remove_kernel();
*/
	return NULL;
}

/* --- データ初期化 --- */
void init_opndata(void)
{
	int i,j;
	for( i=0; i<256; i++)
	{
		opndata[i].MOD_DELAY   = 0;
		opndata[i].MOD_SPEED   = 0;
		opndata[i].FBALG       = 0;

		for( j=0; j<4; j++)
		{
			opndata[i].DTML[tf[j]] = 0;
			opndata[i].TL  [tf[j]] = 0;
			opndata[i].KSAR[tf[j]] = 0;
			opndata[i].DR  [tf[j]] = 0;
			opndata[i].SR  [tf[j]] = 0;
			opndata[i].SLRR[tf[j]] = 0;
		}
	}
}

/* --- セーブparam -> 内部param --- */
void savetoinner(int no,INPARAM *param)
{
	int i;
	
	param->data[0][0] = no;
	param->data[0][1] = opndata[no].MOD_DELAY / 100;
	param->data[0][2] = opndata[no].MOD_DELAY % 100;
	param->data[0][3] = opndata[no].MOD_SPEED / 100;
	param->data[0][4] = opndata[no].MOD_SPEED % 100;
	param->data[0][5] = 0;
	param->data[0][6] = opndata[no].FBALG &  0x7;
	param->data[0][7] = opndata[no].FBALG >> 3;
	param->data[0][8] = opndata[no].FBALG;
	
	for( i=0; i<4; i++)
	{
		param->data[i+1][0] = opndata[no].KSAR[tf[i]] & 0x1f;
		param->data[i+1][1] = opndata[no].DR  [tf[i]];
		param->data[i+1][2] = opndata[no].SR  [tf[i]];
		param->data[i+1][3] = opndata[no].SLRR[tf[i]] & 0x0f;
		param->data[i+1][4] = opndata[no].SLRR[tf[i]] >> 4;
		param->data[i+1][5] = opndata[no].TL  [tf[i]];
		param->data[i+1][6] = opndata[no].KSAR[tf[i]] >> 6;
		param->data[i+1][7] = opndata[no].DTML[tf[i]] & 0x0f;
		param->data[i+1][8] = opndata[no].DTML[tf[i]] >> 4;
	}
}

/* --- 内部param -> セーブparam --- */
void innertosave(int no,INPARAM param)
{
	int i;

	opndata[no].MOD_DELAY   = param.data[0][2]+param.data[0][1]*100;
	opndata[no].MOD_SPEED   = param.data[0][4]+param.data[0][3]*100;
	opndata[no].FBALG       = param.data[0][8];
	
	for( i=0; i<4; i++)
	{
		opndata[no].KSAR[tf[i]] = param.data[i+1][0] | (param.data[i+1][6]<<6);
		opndata[no].DR  [tf[i]] = param.data[i+1][1];
		opndata[no].SR  [tf[i]] = param.data[i+1][2];
		opndata[no].SLRR[tf[i]] = param.data[i+1][3] | (param.data[i+1][4]<<4);
		opndata[no].TL  [tf[i]] = param.data[i+1][5];
		opndata[no].DTML[tf[i]] = param.data[i+1][7] | (param.data[i+1][8]<<4);
	}
}

/* --- 画面の作成 --- */
void set_screen(void)
{
	int i;
	clrscr();
	
	textcolor( T_GREEN );
	locate( 4,1  );		cputs("Main Window  [               ]");
	locate( 4,12 );		cputs("Sub  Window  [               ]");
	
	for( i=0; i<=1; i++)
	{
		textcolor( T_YELLOW );
		locate( 4,2+i*11 );
			cputs("Bank No_ Delay__ Speed__ --- Alg Fb_ A&F ");
		locate( 9,4+i*11 );
			cputs("AR_ DR_ SR_ RR_ SL_ TL_ KS_ Ml_ Dt_ ");

		textcolor( T_CYAN );
		locate( 4,5+i*11 );	cputs("OP1");
		locate( 4,6+i*11 );	cputs("OP2");
		locate( 4,7+i*11 );	cputs("OP3");
		locate( 4,8+i*11 );	cputs("OP4");
	}
	
/*
	textcolor( T_RED );
	for( i=0; i<=24; i++)
	{
		locate( 46,i );
		cputs("∥");
	}
	textcolor( T_WHITE );
*/
	
	locate( 49,1 );		cputs("=========== コマンド =========");
	locate( 49,2 );		cputs("W)セーブ      I)MAIN  →  SUB ");
	locate( 49,3 );		cputs("R)ロード      O)MAIN  ←  SUB ");
	locate( 49,4 );		cputs("              P)MAIN ←→ SUB ");
	locate( 49,5 );		cputs("\\)SHELL       @)鍵盤Octave変更");
	locate( 49,6 );		cputs("B)Bank を変更する");
	locate( 49,7 );		cputs("OPN  TEST) cvbnm,./ fgjkl");
	if(mididrv==TRUE )
	{
	locate( 49,8 );		cputs("MIDI TEST) CVBNM<>? FGJKL");
	}
	locate( 49,9 );		cputs("ESC)終了");
	locate( 49,10);		cputs("============ 操作 ============");
	locate( 49,11);		cputs("カーソルキー ) カーソルの移動 ");
	locate( 49,12);		cputs("ROLLUP/DOWN  ) 数値 +1 / -1   ");
	locate( 49,13);		cputs("[ , ]        ) 音色 +1 / -1   ");
	locate( 49,14);		cputs("数値キー,-   ) 数値の直接入力 ");
	locate( 49,15);		cputs("=== OPN algorithm diagram. ===");
	
}

/* --- パラメータ表示 --- */
void put_parameter( int window,INPARAM param )
{
	int i,j;
	
	locate( 18,1+window*11 );
	textcolor  (T_CYAN);
	if( param.data[0][0]>=0 && param.data[0][0]<=255 )
		cprintf( "%-15s",soundlist[param.data[0][0]] );
	else
		cputs  ( "--- No Inst ---" );
	
	textcolor  (T_WHITE);
	textreverse(REVERSE);
	for( i=0; i<5; i++)
	{
		for( j=0; j<9; j++)
		{
			locate( sx[j],sy[i]+window*11 );
			cprintf( "%3d",(int)param.data[i][j] );
		}
	}
	textreverse(NOREVERSE);
	textcolor  (T_GREEN);
	for( i=0; i<=6; i++)
	{
		locate(49,i+16);
		cputs( algomap[param.data[0][6]][i] );
	}
	textcolor(T_WHITE);
}

/* --- 数値の入力 --- */
int str_numinput( int x,int y,unsigned _1st_key_code,int *retc,unsigned *kcc )
{
	char buf[4];
	unsigned key_code;
	int ix;
	
	ix = 0;
	buf[ix++] = (char)_1st_key_code;
	buf[ix  ] = NULL;
	
	do {
		textreverse( REVERSE  );
		textcolor  ( T_GREEN  );
			locate( sx[x],sy[y] );
			cprintf( "%3s",buf );
			locate( sx[x]+3-ix,sy[y] );
		textreverse( NOREVERSE  );
		textcolor  ( T_WHITE );
		
		key_code = key_wait();

		switch( key_code )
		{
		case K_BS   :
		case K_DEL  :
			buf[ix] = '\0';
			ix--;
			if( ix<=0 )return EOF;
			break;

		case K_ESC  :
			return EOF;
		
		case K_CR   :
		case K_LEFT :
		case K_RIGHT:
		case K_UP   :
		case K_DOWN :
			*kcc  = key_code;
			*retc = valtonum(buf);
			if( *retc>max_value[y][x] )*retc = max_value[y][x];
			if( *retc<min_value[y][x] )*retc = min_value[y][x];
			return NULL;
		
		default:
			if( key_code>='0' && key_code<='9' && ix<3 )
			{
				buf[ix++] = (char)key_code;
				buf[ix  ] = NULL;
			}
			break;
		}
	}
	while(1);
}

/* --- 文字列の入力 --- */
int str_input( int x,int y,char *buf,int max )
{
	int ix;
	unsigned key_num;
	
	ix = 0;

	*buf = '\0';

	while(1)
	{
		locate( x+ix,y );
		key_num = key_wait();

		switch( key_num )
		{
		case K_ESC:
			return EOF;
		case K_CR:
			return NULL;
		case K_BS:
			if( ix>0 )
			{
				*(buf+--ix) = '\0';
			}
			locate( x+ix,y );
			cputs(" ");
			break;
		default:
			if( ix<max )
			{
				*(buf+ix++) = (char)key_num;
				*(buf+ix  ) = NULL;
				cprintf("%c",key_num);
			}
			break;
		}
	}
}

/* --- セーブ --- */
void save(void)
{
	FILE *fpw;
	int i;
	long l;
	char buf[256],dr[MAXDRIVE],di[MAXDIR],fi[MAXFILE],ex[MAXEXT];
	char fname[MAXPATH];

	locate( 3,21 );
	textcolor( T_YELLOW );
	cputs("SAVE FILENAME(.sbj) : ");
	str_input( 25,21,buf,30 );
	fnsplit( buf,dr,di,fi,ex );
	fnmerge( fname,dr,di,fi,".sbj" );

	locate( 3,22 );
	textcolor( T_RED );
	cputs("セーブ中...");

	if( (fpw=fopen(fname,"wb"))==NULL )
	{
		locate( 3,22 );
		cputs("ファイルが作成できません!!");
		clearerr(fpw);
		return;
	}
	fprintf( fpw,
		"XMML3.00 sound object - OPN sound Editor opnsound.exe version 1.00\n"
		"copyright (c) 1994 by Interfair all rights reserved.\n\x1a%c",0
	);
	fwrite( "OPN",4,1,fpw );
	
	putw( DRVIDNUM,fpw );		/* DRVID-Number */
	putc( 0x00,fpw );			/* DriverType   */
	
	l = sizeof(OPNDATA);
	for( i=0; i<256; i++)
	{
		putw( 0,fpw );
		putc( i,fpw );
		fwrite( &l,sizeof(long),1,fpw );
		fwrite( &opndata[i],sizeof(OPNDATA),1,fpw );
	}
	putw(0xffff,fpw);
	fclose( fpw );
}

/* --- ロード --- */
void load(char *filename)
{
	FILE *fpr;
	int i,a,b;
	long l;
	char buf[256],dr[MAXDRIVE],di[MAXDIR],fi[MAXFILE],ex[MAXEXT];
	char fname[MAXPATH];

	if( *filename==NULL )
	{
		locate( 3,21 );
		textcolor( T_YELLOW );
		cputs("LOAD FILENAME(.sbj) : ");
		str_input( 25,21,buf,30 );
	}
	else
	{
		strncpy(buf,filename,255);
	}
	fnsplit( buf,dr,di,fi,ex );
	fnmerge( fname,dr,di,fi,".sbj" );

	locate( 3,22 );
	textcolor( T_RED );
	cputs("ロード中...");

	if( (fpr=fopen(fname,"rb"))==NULL )
	{
		locate( 3,22 );
		cputs("ファイルが見つかりません!!");
		clearerr(fpr);
		return;
	}
	fread( buf,21,1,fpr );
	if( strncmp(buf,"XMML3.00 sound object",21)!=NULL )
	{
		locate( 3,22 );
		cputs("Sound object ではありません!!");
		fclose(fpr);
		return;
	}
	while( fgetc(fpr)!=NULL );
	fread( buf,4,1,fpr );
	a = getw(fpr);
	b = getc(fpr);
	
	if( strncmp(buf,"OPN",4)!=NULL || a!=DRVIDNUM || b!=0x00 )
	{
		locate( 3,22 );
		cputs("違う音源の sound objectです!!");
		fclose(fpr);
		return;
	}

	while( (unsigned)getw(fpr)!=0xffff )
	{
		b = fgetc(fpr);
		fread( &l,sizeof(long),1,fpr );
		fread( &opndata[b],l,1,fpr );
	}
	fclose( fpr );
}

/* play */
void play(OPNDATA dat,int nt,int prog,int shift)
{
	int drvno,a,usemidi=FALSE;
	unsigned i;
	
	struct ecmtable{
		word drvidnum;
		byte drvtype ;
		word length;
		byte cntroll;			// 0x00は、音色定義
		word bank;
		byte no;
		OPNDATA data;
	} ecmparam;
	
	ecmparam.drvidnum = DRVIDNUM;
	ecmparam.drvtype  = 0x00;
	ecmparam.length   = sizeof(OPNDATA)+4;

	ecmparam.cntroll  = 0x00;
	ecmparam.bank     = 0x0000;
	ecmparam.no       = 0;
	ecmparam.data     = dat;

	if( shift==1 && mididrv==TRUE )
	{
		
		mfxddn_dcm_progchange(miditbl,0,prog);
		usemidi = TRUE;
		drvno = miditbl;
	}
	else 
	{
		if( (drvno=mfxddn_get_driver_table(DEVICENAME))==EOF )
		{
			locate(3,22);
			cputs("OPN.XDVが組み込まれていません。");
			return;
		}
		if( mfxddn_dcm_init(drvno)==EOF )
		{
			locate(3,22);
			cputs("OPN.XDVが使用不能です。");
			return;
		}
		locate(3,22);
		mfxddn_dcm_ecm(drvno,&ecmparam);
		mfxddn_dcm_progchange(drvno,0,  0);
		mfxddn_dcm_volume    (drvno,0,127);
		mfxddn_dcm_expression(drvno,0,127);
	}
	mfxddn_dcm_noteon(drvno,0,nt,127);

	locate( 3,21 );
	textcolor( T_WHITE );
	printf("O%1d %-2s",nt/12,ntcode[nt%12]);

	do
	{
		a = key_sense(0x04)|key_sense(0x05)|key_sense(0x06);
		for( i=0; i<10000; i++)outportb(0x5f,0);
		a|= key_sense(0x04)|key_sense(0x05)|key_sense(0x06);
	}
	while( a );
	mfxddn_dcm_noteoff(drvno,0,nt);
	locate( 3,21 );
	cputs("                    ");

//	if( usemidi==FALSE )mfxddn_dcm_end(drvno);
	while( key_scan()!=0xffff );
}

int yn(void)
{
	int c;
	textcolor(T_WHITE);
	cputs("(Y/[N]) ");
	while(1)
	{
		c = getch();
		if( c=='y'||c=='Y' )return YES;
		if( c=='n'||c=='N'||c==0x0d )return NO;
	}
}

void rewrite(INPARAM main,INPARAM sub)
{
	set_screen();
	put_parameter( MAIN_WINDOW,main );
	put_parameter( SUB_WINDOW ,sub  );
}
/* --- Editor --- */
void edit(void)
{
	INPARAM main,sub,tmp;
	int x,y,num,no,nt,a,oct=4;
	unsigned key_code,key_code_next;
	char buf[256];
	
	savetoinner( 0, &main );
	savetoinner( 0, &sub  );
	
	put_parameter( MAIN_WINDOW,main );
	put_parameter( SUB_WINDOW ,sub  );
	
	x  = 0;
	y  = 0;
	no = 0;
	
	key_code_next = NULL;
	
	while(1)
	{
		if( main.data[0][0]!=no )
		{
			innertosave( no,main  );
			no = main.data[0][0];
			savetoinner( no,&main );
		}
	
		put_parameter( MAIN_WINDOW,main );
		
		locate( sx[x],sy[y] );
		if( !key_code_next )key_code = key_wait();
		else				key_code = key_code_next;
		
		key_code_next = NULL;
		
		x+= (	((key_code==K_LEFT  && x>0) ? -1 : 0 ) 
			   +((key_code==K_RIGHT && x<8) ?  1 : 0 ) );
		y+= (	((key_code==K_UP    && y>0) ? -1 : 0 ) 
			   +((key_code==K_DOWN  && y<4) ?  1 : 0 ) );
		
		if( key_code==K_ESC )
		{
			locate( 3,21 );
			textcolor(T_RED);
			cputs("QUIT OK? ");
			if( yn()==YES )break;
			rewrite(main,sub);
		}

		switch( key_code )
		{
		case K_ROLLUP	:	
			if( max_value[y][x]>main.data[y][x] )main.data[y][x]++;
			break;

		case K_ROLLDOWN	:	
			if( min_value[y][x]<main.data[y][x] )main.data[y][x]--;
			break;
		
		case '[':
			if( main.data[0][0]>0   )main.data[0][0]--;
			break;

		case ']':
			if( main.data[0][0]<255 )main.data[0][0]++;
			break;
		
		case 'I':case 'i':
			innertosave( no,main  );
			locate( 3,21 );
			textcolor( T_GREEN );
			cputs("MAIN を SUB にコピーしてもよろしいですか? ");
			if( yn()==YES )sub=main;
			main.data[0][0] = no;
			innertosave( no,main  );
			rewrite(main,sub);
			savetoinner( no,&main );
			break;

		case 'O':case 'o':
			innertosave( no,main  );
			locate( 3,21 );
			textcolor( T_CYAN );
			cputs("SUB を MAIN にコピーしてもよろしいですか? ");
			if( yn()==YES )main=sub;
			main.data[0][0] = no;
			innertosave( no,main  );
			rewrite(main,sub);
			savetoinner( no,&main );
			break;

		case 'P':case 'p':
			innertosave( no,main  );
			locate( 3,21 );
			textcolor( T_WHITE );
			cputs("MAIN と SUB を入れ替えてもよろしいですか? ");
			if( yn()==YES ){
				tmp =main;
				main=sub;
				sub =tmp;
			}
			main.data[0][0] = no;
			innertosave( no,main  );
			rewrite(main,sub);
			savetoinner( no,&main );
			break;

		case '\\':
			clrscr();
			printf("\x1b[>1l\x1b[>5l\x1b[2J");
			printf("EXIT で、opnsound.exe に復帰します。\n");
			system("command.com");
			printf("\x1b[>1h\x1b[>5l");
			clrscr();
			set_screen();
			put_parameter( MAIN_WINDOW,main );
			put_parameter( SUB_WINDOW ,sub  );
			break;
		
		case 'W':case 'w':
			innertosave( no,main  );
			save();
			rewrite(main,sub);
			break;
		
		case 'R':case 'r':
			innertosave( no,main  );
			load("");
			rewrite(main,sub);
			savetoinner( no,&main );
			break;

		case '@':
			innertosave( no,main  );
			locate( 3,21 );
			textcolor( T_YELLOW );
			cputs("Octave(0..8) : ");
			str_input( 17,21,buf,30 );
			cut_space(buf);
			if( buf[0]!=NULL )
			{
				a=valtonum(buf);
				if( a>=0 && a<=8 )oct=a;
			}
			rewrite(main,sub);
			savetoinner( no,&main );
			break;

			case 'f':case 'g':		case 'j':case 'k':case 'l':
		case 'c':case 'v':case 'b':case 'n':case 'm':case ',':case '.':case '/':
			switch(key_code)
			{
				case 'c':nt = 0;break;
				case 'f':nt = 1;break;
				case 'v':nt = 2;break;
				case 'g':nt = 3;break;
				case 'b':nt = 4;break;
				case 'n':nt = 5;break;
				case 'j':nt = 6;break;
				case 'm':nt = 7;break;
				case 'k':nt = 8;break;
				case ',':nt = 9;break;
				case 'l':nt =10;break;
				case '.':nt =11;break;
				case '/':nt =12;break;
			}
			innertosave( no,main );
			play(opndata[no],oct*12+nt,no,0);
			break;
		
			case 'F':case 'G':		case 'J':case 'K':case 'L':
		case 'C':case 'V':case 'B':case 'N':case 'M':case '<':case '>':case '?':
			switch(key_code)
			{
				case 'C':nt = 0;break;
				case 'F':nt = 1;break;
				case 'V':nt = 2;break;
				case 'G':nt = 3;break;
				case 'B':nt = 4;break;
				case 'N':nt = 5;break;
				case 'J':nt = 6;break;
				case 'M':nt = 7;break;
				case 'K':nt = 8;break;
				case '<':nt = 9;break;
				case 'L':nt =10;break;
				case '>':nt =11;break;
				case '?':nt =12;break;
			}
			innertosave( no,main );
			play(opndata[no],oct*12+nt,no,1);
			break;
		
		default:
			if( (key_code>='0' && key_code<='9') || key_code=='-' )
			{
				if( str_numinput( x,y,key_code,&num,&key_code_next )==NULL )
				{
					main.data[y][x] = num;
				}
			}
			break;
		}

		main.data[0][8] = main.data[0][6] | (main.data[0][7]<<3);
	
	}
}
