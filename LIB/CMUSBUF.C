/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// 演奏バッファ変更
*/

#include	<stdio.h>
#include	"mfxddn.h"

/*
// 演奏バッファ変更
*/
void mfxddn_change_musicbuffer(char far *buffer)
{
	mfxddn_musicbuffer = buffer;
}
