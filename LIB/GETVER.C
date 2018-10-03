/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
*/

#include	<stdio.h>
#include	"mfxddn.h"

/*
// バージョン取得
*/
int mfxddn_get_driver_version(char *drvid)
{
	char buf[256];
	int ver,ver_int,ver_real;
	
	if( MFXDDN_Initialize==EOF ){
		mfxddn_errset(DDN_NOTINSTALLED);
		return EOF;
	}
	
	mfxddn_add_space( buf,drvid );
	ver = mfxddn_get_driver_version_local((char far *)drvid);
	ver_int  = (int)(ver >>     8);
	ver_real = (int)(ver & 0x00ff);
	ver = ver_int*100+ver_real;
	return ver;
}
