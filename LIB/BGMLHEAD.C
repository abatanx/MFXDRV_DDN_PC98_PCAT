/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//--------------------------------------------------------------------------*/
//
// Filelink 対応版
//

#include	<stdio.h>
#include	"mfxddn.h"

#if			CONFIG_FILELINK == TRUE
#include	"fl.h"
#endif

#define		asciiz(buf)		for(i=0;(buf[i]=fgetc(fpr))!=NULL&&i<255;i++);buf[i]=NULL;

/*
// MUDファイルのヘッダ読み込み
*/
#if			CONFIG_FILELINK == TRUE
int mfxddn_get_musicinfo_filelink(char *filename,MUD_MUSICINFO *info)
#else
int mfxddn_get_musicinfo(char *filename,MUD_MUSICINFO *info)
#endif
{
	FILE *fpr;
	char buf[256],*xdvname;
	int i,j,k,track_no,module,yusen,c,trn,x,xdn,mm;
	long filepointer,bin_plus,base_fp,soundfp,soundsize;
	
#if			CONFIG_FILELINK == TRUE
	if( (fpr=fl_open(filename,"rb"))==NULL ){
#else
	if( (fpr=  fopen(filename,"rb"))==NULL ){
#endif
		clearerr(fpr);
		mfxddn_errset(DDN_FILENOTFOUND);
		return(EOF);
	}

	for( i=0; i<9; i++)buf[i] = fgetc(fpr);
	info->ver_int  = (int)buf[5];
	info->ver_float= (int)buf[6];
	info->ver_char = (int)buf[7];

/* 識別子及び、XMMLバージョンチェック */
	if( ddn_strncmp(buf,"Mudmf",5)!=0 ){
		fclose(fpr);
		mfxddn_errset(DDN_NOTMUDFILE);
		return(EOF);
	}
	if( buf[5]!=2 ){
		fclose(fpr);
		mfxddn_errset(DDN_VERSIONERROR);
		return(EOF);
	}
	asciiz( info->linker   );
	asciiz( info->title    );
	asciiz( info->composer );
	asciiz( info->arranger );
	asciiz( info->lyric    );
	asciiz( info->artist   );
	asciiz( info->copyright);
	asciiz( info->memo     );
/* 拡張エリアスキップ */
	fseek( fpr,12L,SEEK_CUR );
/* 作成日時 */
	info->da_year =fgetc(fpr);
	info->da_month=fgetc(fpr);
	info->da_day  =fgetc(fpr);
	info->ti_hour =fgetc(fpr);
	info->ti_min  =fgetc(fpr);
	info->ti_sec  =fgetc(fpr);
	fclose(fpr);
	return NULL;
}

#if			CONFIG_FILELINK == FALSE
/*
// MUSICINFOのメモリかくほぅぅぅぅ
*/
int mfxddn_alloc_musicinfo(MUD_MUSICINFO *info)
{
	char *mptr;
	unsigned size;
	if( (mptr=ddn_keep_highmemory((long)(MUSICINFO_TOTALSIZE)))==NULL )
		return EOF;
	info->memory   = mptr;
	info->linker   = mptr;		mptr += MUSICINFO_LINKER;
	info->title    = mptr;		mptr += MUSICINFO_TITLE;
	info->composer = mptr;		mptr += MUSICINFO_COMPOSER;
	info->arranger = mptr;		mptr += MUSICINFO_ARRANGER;
	info->lyric    = mptr;		mptr += MUSICINFO_LYRIC;
	info->artist   = mptr;		mptr += MUSICINFO_ARTIST;
	info->copyright= mptr;		mptr += MUSICINFO_COPYRIGHT;
	info->memo     = mptr;		mptr += MUSICINFO_MEMO;
	return NULL;
}
#endif
