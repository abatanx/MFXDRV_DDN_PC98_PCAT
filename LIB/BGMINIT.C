/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN ���䃉�C�u����
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// ���C�u����������
*/

#include	<stdio.h>
#include	"mfxddn.h"

/*
// MFXDDN���C�u����������(���t�o�b�t�@�͊e���p�ӂ���̂�)
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
// MFXDDN���C�u�����^���t�o�b�t�@������
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
// MFXDDN���C�u�����^���t�o�b�t�@������
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