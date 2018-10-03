//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 Stay Resident type BGM Player.
//                          MiP(tm) version 2.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------

#include	<stdio.h>
#include	<string.h>
#include	<dir.h>
#include	<dos.h>
#include	<mfxddn.h>
#include	<fl.h>

#define		STAY		1
#define		NOTSTAY		2
#define		SCRL		10

#define		version		"1.20"
#define		id			"MipPlayer"

typedef		struct {
	char mipid[10];
	word musicadr;
} PLAYINFO;

char	*musicbuf;

void fl_menu(void)
{
	int y,yy,i,c,flag[256];
	MUD_MUSICINFO info[256];

	printf("FILELINKファイル読み込み中...\n");
	for( i=0; i<FILELINK_use_switch && i<256 ; i++)
	{
		if( mfxddn_alloc_musicinfo(&info[i]) )
		{
			printf("メモリが足りません。\n");
			exit(1);
		}
		flag[i] = 
			mfxddn_get_musicinfo_filelink(file_info[i].finf.fname,&info[i]);
		if( flag[i]==EOF )
		{
			info[i].title[0] = NULL;
			info[i].composer[0] = NULL;
			info[i].arranger[0] = NULL;
			info[i].lyric[0] = NULL;
			info[i].artist[0] = NULL;
			info[i].copyright[0] = NULL;
			info[i].memo[0] = NULL;
			info[i].linker[0] = NULL;
			
			printf("\r%s readed",file_info[i].finf.fname);
			
		}
	}

	printf("\x1b[2J");
	printf("\x1b[32m FILELINK(Format2)ファイラモード \x1b[m Version 0.10\n");
	printf("p,8:UP n,2:DOWN q:QUIT RET:PLAY \n\n");
	
	printf("No Filename_____ Ver__ Title___\n");
	printf(
		"\x1b[15;1H""----------""----------""----------""- Music In"
		"fomation -""----------""----------""----------"
	);

	y  = 0;
	yy = 0;

	for(;;)
	{
		printf("\x1b[5;1H");
		for( i=y; i<y+SCRL; i++)
		{
			if( i>=FILELINK_use_switch )
			{
				printf("\x1b[0K\n");
				continue;
			}
			printf(
				"%2d %-13s ",
				i+1,file_info[i].finf.fname
			);
			if( flag[i]==EOF )
			{
				printf("*\x1b[0K\n");
			}
			else
			{
				printf(
					"%1d.%02d%c %-30s\n",
					info[i].ver_int ,info[i].ver_float, info[i].ver_char,
					info[i].title
				);
			}
		}
		for(;;)
		{
			printf(
				"\x1b[%d;1H"
				"\x1b[7m%2d %-13s\x1b[m",
				yy+5,
				y+yy+1,file_info[y+yy].finf.fname);
			printf(
				"\x1b[16;1H"
				"     title \x1b[0K%s\n"
				"  composer \x1b[0K%s\n"
				"  arranger \x1b[0K%s\n"
				"    lyrics \x1b[0K%s\n"
				"    artist \x1b[0K%s\n"
				" copyright \x1b[0K%s\n"
				"    system \x1b[0K%s\n",
				info[y+yy].title, info[y+yy].composer,
				info[y+yy].arranger,  info[y+yy].lyric, info[y+yy].artist,
				info[y+yy].copyright, info[y+yy].linker
			);
			c = getch();
			printf(
				"\x1b[%d;1H%2d %-13s",
				yy+5,
				y+yy+1,file_info[y+yy].finf.fname);
			switch( c )
			{
				case 'q':case 0x1b:
					printf("\x1b[2J");
					return;
				case 0x0d:
					if( flag[y+yy]!=EOF )
					{
						mfxddn_bgm_play_filelink(file_info[y+yy].finf.fname);
					}
					break;
				case 's':
					mfxddn_bgm_stop();
					break;
				case '2':case 'n':
					yy++;
					break;
				case '8':case 'p':
					yy--;
					break;
			}
			if( y+yy>=FILELINK_use_switch )
			{
				yy--;
			}
			else if(y+yy<0 )
			{
				yy++;
			}
			if( yy>=SCRL )
			{
				yy = 0;
				y += SCRL;
				break;
			}
			else if( yy<0 )
			{
				yy = SCRL-1;
				y -= SCRL;
				break;
			}
		}
	}
}

word set_chain(void)
{
	PLAYINFO	pp;
	char *infobuf;
	strcpy(pp.mipid,id);
	pp.musicadr = FP_SEG(musicbuf);
	if( (infobuf = ddn_keep_highmemory(sizeof(PLAYINFO)+10))==NULL ){
		puts("メモリーが足りません。");
		exit(EOF);
	}
	memcpy( infobuf,&pp,sizeof(PLAYINFO) );

	ddn_stay_memory( infobuf  );
	ddn_stay_memory( musicbuf );
	mfxddn_add_chain_address(infobuf );
	mfxddn_add_chain_address(musicbuf);
	return(FP_SEG(infobuf));
}

void chain_check(void)
{
	byte *chain,*buf;
	word infoseg;
	PLAYINFO *pp;
	chain = mfxddn_get_chain_address();
	chain+= 10;
	for(;;){
		infoseg = *chain + 256 * *(chain+1);
		chain  += 2;
		if( infoseg==0 ){
			puts("--- 演奏バッファを確保・常駐しました ---");
			infoseg = set_chain();
			break;
		}
		buf = MK_FP(infoseg,0);
		if( strcmp(buf,id)==NULL ){
			puts("--- すでに演奏バッファは確保されています ---");
			break;
		}
	}
	pp       = MK_FP( infoseg , 0  );
	musicbuf = MK_FP(pp->musicadr,0);
	mfxddn_change_musicbuffer(musicbuf);
}

void main(int argc,char **argv)
{
	char mfile[MAXPATH],dr[MAXDRIVE],di[MAXDIR],fi[MAXFILE],ex[MAXEXT];
	char buf[256];
	int fl_sw;
	FILE *fpr;

	MFXDDN_MAXMUDSIZE = 100000L;
	printf(
		"\x1b[32mMFXDRV/DDN専用 B.G.M. player \x1b[33mMIP\x1b[m"
		" version %s\n"
		"copyright (c) 1994 by ABA / T.kobayashi and Interfair all rights reserved.\n",
		version
	);
	if( argc<=1 ){
		puts(
			"usage  ; mip [filename | </|-[option]>]\n"
			"option ; /f  フェードアウト\n"
			"         /p  一時停止\n"
			"         /c  一時停止再開\n"
			"         /s  演奏終了\n"
		);
		exit(EOF);
	}
	if( (musicbuf = ddn_keep_highmemory(MFXDDN_MAXMUDSIZE))==NULL ){
		puts("メモリーが足りません。");
		exit(EOF);
	}
	if( mfxddn_bgm_init2(musicbuf)==EOF ){
		puts("MFXDRV/DDN(XMML3.00)が常駐していません。");
		exit(EOF);
	}
	
	if( !stricmp( *(argv+1),"/s" ) ){
		puts("★演奏を停止します。");
		mfxddn_bgm_stop();
		exit(NULL);
	}
	if( !stricmp( *(argv+1),"/p" ) ){
		puts("★演奏を一時停止します。");
		mfxddn_bgm_pause();
		exit(NULL);
	}
	if( !stricmp( *(argv+1),"/c" ) ){
		puts("★演奏を再開します。");
		mfxddn_bgm_continue();
		exit(NULL);
	}
	if( !stricmp( *(argv+1),"/f" ) ){
		puts("★演奏をフェードアウト終了します。");
		mfxddn_bgm_fadeout(4);
		exit(NULL);
	}
	
	fnsplit( *(argv+1),dr,di,fi,ex );
	if( !strcmp(ex,"") )
		fnmerge( mfile,dr,di,fi,".mud" );
	else
		strcpy( mfile,*(argv+1) );

	printf ( "%s:\n",mfile );

	mfxddn_bgm_stop();
	chain_check();			// チェインバッファをチェックする

	if( fl_file(mfile)!=EOF )fl_menu();
	else
	{
		fl_switch(EOF);
		if( mfxddn_bgm_play(mfile)==EOF ){
			puts( mfxddn_errmsg() );
			exit(1);
		}
		puts("★演奏を開始します");
		printf(
			"\n[ MUD ファイル情報 ] 作成日時 %02d/%02d/%02d %02d:%02d:%02d\n"
			"  mud format version : %1d.%02d%c\n",
			mud.da_year , mud.da_month  ,mud.da_day  ,
			mud.ti_hour , mud.ti_min    ,mud.  ti_sec,
			mud.ver_int , mud.ver_float ,mud.ver_char
		);
		printf(
			"               title : %s\n"
			"            composer : %s\n"
			"            arranger : %s\n"
			"               lyric : %s\n"
			"              artist : %s\n"
			"           copyright : %s\n"
			"[memo]\n"
			"%s\n",
			mud.title   , mud.composer  ,mud.arranger,
			mud.lyric   , mud.artist    , mud.copyright,
			mud.memo
		);
	}
	exit(0);
}
