/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// ライブラリ初期化
*/

#include	<stdio.h>
#include	"mfxddn.h"

/*
// MFXDDNライブラリ初期化(演奏バッファは各自用意するのぉ)
// null = ok		eof = error
*/
int mfxddn_bgm_init2(char far *buffer)
{
	int i,flag;
	
	mfxddn_musicbuffer = buffer;
	
	for( i=0; i<32; i++){
		mud_track_work[i].flag    = FALSE;
		mud_track_work[i].buffer_size = 0;
	}
	flag = mfxddn_install_check();
	MFXDDN_Initialize = flag;
	if( flag==EOF )mfxddn_errset(DDN_NOTINSTALLED);
	else		   mfxddn_errset(DDN_COMPLETEEXEC);
	return flag;
}

/*
// MFXDDNライブラリ／演奏バッファ初期化
// null = ok		eof = error
*/
int mfxddn_bgm_init3(long size)
{
	char far *buffer;
	
	MFXDDN_MAXMUDSIZE = size;
	if( (buffer=ddn_keep_highmemory(MFXDDN_MAXMUDSIZE))==NULL ){
		MFXDDN_Initialize = EOF;
		mfxddn_errset(DDN_NOTENOUGHMEMORY);
		return(EOF);
	}
	return mfxddn_bgm_init2(buffer);
}

/*
// MFXDDNライブラリ／演奏バッファ初期化
// null = ok		eof = error
*/
int mfxddn_bgm_init(void)
{
	char far *buffer;
	
	if( (buffer=ddn_keep_highmemory(MFXDDN_MAXMUDSIZE))==NULL ){
		MFXDDN_Initialize = EOF;
		mfxddn_errset(DDN_NOTENOUGHMEMORY);
		return(EOF);
	}
	
	return mfxddn_bgm_init2(buffer);
}
