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
int aopt=0;

word set_chain(void)
{
	PLAYINFO	pp;
	char *infobuf;
	if( (infobuf = ddn_keep_highmemory(sizeof(PLAYINFO)+10))==NULL ){
//		puts("メモリーが足りません。");
		exit(EOF);
	}
	if( (musicbuf = ddn_keep_highmemory(MFXDDN_MAXMUDSIZE))==NULL ){
//		puts("メモリーが足りません。");
		exit(EOF);
	}
	strcpy(pp.mipid,id);
	pp.musicadr = FP_SEG(musicbuf);
	memcpy( infobuf,&pp,sizeof(PLAYINFO) );

	ddn_stay_memory( infobuf  );
	ddn_stay_memory( musicbuf );
	mfxddn_add_chain_address(infobuf );
	mfxddn_add_chain_address(musicbuf);
	if( aopt==1 )
	{
		printf("Memory was assigned (%ldbytes)\n",MFXDDN_MAXMUDSIZE);
	}
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
//			puts("--- 演奏バッファを確保・常駐しました ---");
			infoseg = set_chain();
			break;
		}
		buf = MK_FP(infoseg,0);
		if( strcmp(buf,id)==NULL ){
//			puts("--- すでに演奏バッファは確保されています ---");
			pp       = MK_FP( infoseg , 0  );
			musicbuf = MK_FP(pp->musicadr,0);
			mfxddn_del_chain_address((void far *)pp);
			mfxddn_del_chain_address((void far *)musicbuf);
			ddn_free_memory((void far *)pp);
			ddn_free_memory((void far *)musicbuf);
			infoseg  = set_chain();
			break;
		}
	}
	pp       = MK_FP( infoseg , 0  );
	musicbuf = MK_FP(pp->musicadr,0);
	mfxddn_change_musicbuffer(musicbuf);
}

void main(int argc,char **argv)
{
	char buf[256];
	int fl_sw;
	FILE *fpr;

	if( argc<=1 )return;

	MFXDDN_MAXMUDSIZE = 1L;
	if( mfxddn_bgm_init3(musicbuf)==EOF ){
		puts("Not installed MFXDRV/DDN");
		exit(EOF);
	}
	
	if( !stricmp( *(argv+1),"/s" ) ){
		mfxddn_bgm_stop();
		exit(NULL);
	}
	if( !stricmp( *(argv+1),"/p" ) ){
		mfxddn_bgm_pause();
		exit(NULL);
	}
	if( !stricmp( *(argv+1),"/c" ) ){
		mfxddn_bgm_continue();
		exit(NULL);
	}
	if( !stricmp( *(argv+1),"/f" ) ){
		mfxddn_bgm_fadeout(4);
		exit(NULL);
	}
	if( argc>2 )
	{
		if( !stricmp( *(argv+2),"debug") )aopt = 1;
	}
	if( !stricmp( *(argv+1),"/a" ) ){
		MFXDDN_MAXMUDSIZE = 51200L;
	}
	else
	{
		if( (fpr=fopen(argv[1],"rb"))==NULL )exit(1);
		fseek(fpr,0,SEEK_END);
		MFXDDN_MAXMUDSIZE = ftell(fpr);
		fclose(fpr);
	}
	chain_check();			// チェインバッファをチェックする
	mfxddn_bgm_play(argv[1]);
	exit(NULL);
}
