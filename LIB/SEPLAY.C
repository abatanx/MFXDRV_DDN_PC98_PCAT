/*
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
*/

#include	<stdio.h>
#include	"mfxddn.h"

/*
// 効果音開始
*/
int mfxddn_se_play( int no )
{
	if( MFXDDN_Initialize==EOF || no>=MAX_SEBUF ){
		mfxddn_errset(DDN_NOTINSTALLED);
		return EOF;
	}
	if( se[no].buffer==NULL ){
		mfxddn_errset(DDN_NOTINSTALLED);
		return EOF;
	}
	mfxddn_se_play_local(
		(char far *)se[no].buffer , se[no].channel , se[no].track , se[no].driver
	);
	return NULL;
}
