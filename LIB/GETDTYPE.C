/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
*/

#include	<stdio.h>
#include	"mfxddn.h"

/*
// ドライバータイプの取得
*/
int mfxddn_get_driver_type(char *drvid)
{
	char buf[256];

	if( MFXDDN_Initialize==EOF ){
		mfxddn_errset(DDN_NOTINSTALLED);
		return EOF;
	}
	mfxddn_add_space( buf,drvid );
	return mfxddn_get_driver_type_local((char far *)drvid);
}

