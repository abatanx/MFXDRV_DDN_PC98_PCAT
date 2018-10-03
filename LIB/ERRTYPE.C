/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// エラータイプを返す
*/

#include	<stdio.h>
#include	"mfxddn.h"

/*
// エラータイプを取得する
*/
int mfxddn_errortype(void)
{
	return mfxddn_err;
}

