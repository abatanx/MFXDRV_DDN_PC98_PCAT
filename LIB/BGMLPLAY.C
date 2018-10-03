/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//--------------------------------------------------------------------------*/
//
// Filelink 対応版
//

#if	!defined(__DDN_LOADHEADER__)
#include	<stdio.h>
#include	<dos.h>
#include	"mfxddn.h"
#endif

#define		asciiz(buf)		for(i=0;(buf[i]=fgetc(fpr))!=NULL&&i<255;i++);\
							if(buf[i]!=NULL)while(fgetc(fpr)!=NULL);\
							buf[i]=NULL;

#if			CONFIG_FILELINK == TRUE
#include	"fl.h"
#endif

static		MUD_TRACK		track[32];
	
/*
// MUDファイルのロード／演奏開始
*/
#if			CONFIG_FILELINK == TRUE
int mfxddn_bgm_play_filelink(char *filename)
#else
#if			CONFIG_MTLIB	== TRUE
int mfxddn_bgm_play_mtlib(char *filename)
#else
int mfxddn_bgm_play(char *filename)
#endif
#endif
{
#if			CONFIG_MTLIB	!= TRUE
	FILE *fpr,*fpw;
#endif
	char buf[256],*xdvname;
	char far *mpt;
	int i,j,k,track_no,module,yusen,c,trn,x,xdn,mm,kp;
	long filepointer,bin_plus,base_fp,soundfp,soundsize;
	unsigned musseg;

	if( MFXDDN_Initialize!=NULL ){
		mfxddn_errset(DDN_NOTINSTALLED);
		return(EOF);
	}

	mfxddn_bgm_stop();
	bin_plus = 0L;
	
#if			CONFIG_FILELINK == TRUE
	if( (fpr=fl_open(filename,"rb"))==NULL ){
#else
#if			CONFIG_MTLIB	== TRUE
	if(   file_ropen(filename)==NULL       ){
#else
	if( (fpr=  fopen(filename,"rb"))==NULL ){
#endif
#endif
		clearerr(fpr);
		mfxddn_errset(DDN_FILENOTFOUND);
		return(EOF);
	}
#if			CONFIG_FILELINK == TRUE
	base_fp = ftell(fpr);
#else
	base_fp = 0;
#endif

	for( i=0; i<9; i++)buf[i] = fgetc(fpr);
	mud.ver_int  = (int)buf[5];
	mud.ver_float= (int)buf[6];
	mud.ver_char = (int)buf[7];

/* 識別子及び、XMMLバージョンチェック */
	if( ddn_strncmp(buf,"Mudmf",5)!=NULL ){
		fclose(fpr);
		mfxddn_errset(DDN_NOTMUDFILE);
		return(EOF);
	}
	if( buf[5]!=2 ){
		fclose(fpr);
		mfxddn_errset(DDN_VERSIONERROR);
		return(EOF);
	}
/* リンカ名＋バージョン名スキップ */
	while( fgetc(fpr)!=0x00 );
/* メタイベントスキップ           */
	asciiz( mud.title    );
	asciiz( mud.composer );
	asciiz( mud.arranger );
	asciiz( mud.lyric    );
	asciiz( mud.artist   );
	asciiz( mud.copyright);
	asciiz( mud.memo     );
/* 拡張エリアスキップ */
	fseek( fpr,12L,SEEK_CUR );
/* 作成日時 */
	mud.da_year =fgetc(fpr);	mud.da_month=fgetc(fpr);
	mud.da_day  =fgetc(fpr);
	mud.ti_hour =fgetc(fpr);	mud.ti_min  =fgetc(fpr);
	mud.ti_sec  =fgetc(fpr);
/* 音色fp/size */
	fread( &soundfp  ,sizeof(long),1,fpr );
	fread( &soundsize,sizeof(long),1,fpr );
/* 優先処理 */
	yusen = FALSE;
	while( fgetc(fpr)==0x00 ){
		for( i=0 ; (buf[i]=fgetc(fpr))!=NULL ; i++ );
		fread( &filepointer,sizeof(long),1,fpr );
		if( mfxddn_get_driver_table(buf)!=EOF ){
			fseek( fpr,filepointer+base_fp,SEEK_SET );	/* base fp は、
														  filelink使用時に
														  つかってるよぅ */
			yusen = TRUE;
			break;
		}
	}
/* 通常 */
	if( yusen==FALSE ){
		while( fgetc(fpr)!=0x00 );
		fread( &filepointer,sizeof(long),1,fpr );
		fseek( fpr,filepointer+base_fp,SEEK_SET );
	}
/* トラックロード */
	/* 全トラックの初期化 */
	for( i=0; i<32; i++){
		mud_track_work[i].flag = FALSE;
		mud_track_work[i].buffer_size = 0;
	}
	/* タイムベース読み込み */
	track_info.timebase = getw( fpr );		/* timebase */

	/* トラックファイルのヘッダー読み込み */
	trn = 0;
	/* 音色の読み込み情報設定 */
	mud_track_work[trn].flag = TRUE;
	for( i=0; i<4; i++){
		for( j=0; j<15; j++)track[trn].chain[i].module[j]=' ';
		track[trn].chain[i].module[15] = '\0';
		track[trn].chain[i].channel = (unsigned char)0;
	}
	strcpy(track[trn].chain[0].module,"*SOUND");
	track[trn].bin_fp  =soundfp;
	track[trn].bin_size=soundsize;
	track[trn].bin_comp=wset('N','C');
	track[trn].ext     =NULL;
	trn++;
	
	/* トラックの読み込み情報設定 */
	while( fgetc(fpr)!=0xff ){
		mud_track_work[trn].flag = TRUE;
		for( i=0; i<4; i++){
			for( j=0; (track[trn].chain[i].module[j]=fgetc(fpr))>=' '
				 ; j++ );
			track[trn].chain[i].channel = (unsigned char)fgetc(fpr);
			
/*			printf("%2d ",(int)track[trn].chain[i].channel);	*/
			
		}
		fread( &track[trn].bin_fp   ,sizeof(long),1,fpr );
		fread( &track[trn].bin_size ,sizeof(long),1,fpr );
		fread( &track[trn].bin_comp ,sizeof(unsigned),1,fpr );
		fread( &track[trn].ext      ,sizeof(unsigned),1,fpr );
		trn++;
/*		printf("\n");											*/
	}
	/* 演奏順位及びデータロード */
	kp = 0;
	for( i=0; i<32; i++){
/*		printf("%d:\n",i);										*/
		if( mud_track_work[i].flag==FALSE ){
			continue;
		}
		module = EOF;
		for( j=0; j<4; j++){
			if( track[i].chain[j].module[0]==NULL ){		/* OFF */
				break;
			}
			else if( ddn_strcmp(track[i].chain[j].module,"*COND")==0
				|| ddn_strcmp(track[i].chain[j].module,"*SOUND")==0 ){
				if( track[i].chain[j].module[1]=='S' )  c = 255;
				else									c = 0;
				
				xdn = EOF;
				for( mm=0; mm<16; mm++ ){
					xdvname = ddn_far2near(mfxddn_get_driver_name(mm));
					if( xdvname==NULL ){
						continue;
					}
					if( mfxddn_get_driver_type(xdvname)==0x0000 ){
						xdn = mm;
						break;
					}
				}
				if( xdn==EOF )
				{
					break;
				}
				strcpy(track[i].chain[j].module,
					ddn_far2near(mfxddn_get_driver_name(xdn)));
				track[i].chain[j].channel=(unsigned char)c;
											/* Conductor は、ごまかす(笑) */
/*				printf("COND:track[%d].chain[%d].channel=%d\n",
					i,j,(int)track[i].chain[j].channel
				);
*/
				module = j;
				break;
			}
			else if( mfxddn_get_driver_table(track[i].chain[j].module)==EOF )
			{
				continue;						/* ドライバ無し     */
			}
			else
			{
				module = j;						/* ドライバ存在した */
				break;
			}
		}
		if( module == EOF )continue;		/* OFFだった～ */
		/* メモリー確保 */
		musseg  = FP_SEG(mfxddn_musicbuffer)+(unsigned)(bin_plus/16L);
		mpt = MK_FP(musseg,0);

		mud_track_work[kp].buffer = mpt;
		bin_plus += ((long)track[i].bin_size+160);
		if( bin_plus>=MFXDDN_MAXMUDSIZE ){
			fclose(fpr);
			mfxddn_errset(DDN_MUDSIZEOVER);
			return(EOF);
		}
		mud_track_work[kp].buffer_size = (long)track[i].bin_size+32L;
		/* トラックヘッダー作成 */
		/* 音源 */
		for( j=0; j<15; j++)mud_track_work[kp].buffer[j]=' ';
		mud_track_work[kp].buffer[15]=NULL;
		j = 0;
		while( (c=track[i].chain[module].module[j])!=NULL ){
			(char)mud_track_work[kp].buffer[j] = (char)c;
			j++;
			if( j>15 )break;
		}
		/* チャンネル */
		(unsigned char)mud_track_work[kp].buffer[16] = track[i].chain[module].channel;
/*
		printf("Fin:%2d %2d\n",
			(int)mud_track_work[kp].buffer[16],
			(int)track[i].chain[module].channel
		);
*/
		/* トラックデータ読み込み */
		filepointer = ftell(fpr);			/* 現在のfp保存 */
		fseek( fpr,track[i].bin_fp+base_fp,SEEK_SET );
		if( track[i].bin_comp==wset('F','Z') )
#if		CONFIG_MTLIB == FALSE
			ddn_flz_load_fp( mud_track_work[kp].buffer+17,fpr,(long)track[i].ext );
#else
			ddn_flz_load_fp_mtlib( mud_track_work[kp].buffer+17,(long)track[i].ext );
#endif
		else
#if		__COMPACT__+__LARGE__+__HUGE__!=0
			fread( mud_track_work[kp].buffer+17,track[i].bin_size,1,fpr );
#else
			{
			long bsize;
			for( bsize=0; bsize<track[i].bin_size; bsize++)
				*(mud_track_work[kp].buffer+17+(unsigned)bsize)=fgetc(fpr);
			}
#endif
		fseek( fpr,filepointer,SEEK_SET );	/* 戻すから base_fp はいらない */
		track_info.track_address[kp] = mud_track_work[kp].buffer;
		kp++;
	}
	track_info.track_number = kp;
	fclose(fpr);
/*
#if		CONFIG_MTLIB == FALSE
	{
		char buf[256];
		int iii;
		fpw = fopen("core","wb");
		fwrite( &track_info,sizeof(MUD_TRACKINFO),1,fpw );
		fclose(fpw);
		for( iii=0; iii<(int)track_info.track_number; iii++)
		{
			sprintf(buf,"core%d",iii);
			fpw = fopen(buf,"wb");
			fwrite( track_info.track_address[iii],10000,1,fpw );
			fclose(fpw);
		}
	}
#endif
*/
	x = mfxddn_bgm_start((void far *)&track_info);
	if( x==NULL ){
		mfxddn_errset(DDN_COMPLETE);
	}
/*	printf("%d\n",x);	*/
	return x;
}

#if			CONFIG_FILELINK==FALSE && CONFIG_MTLIB==FALSE
/*
// 演奏リスタート
*/
int mfxddn_bgm_replay(void)
{
	return mfxddn_bgm_start((void far *)&track_info);
}
#endif
