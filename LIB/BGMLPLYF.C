/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//--------------------------------------------------------------------------*/
//
// Filelink 対応版
//

/*
// MUDファイルのロード／演奏開始
*/

#include	<stdio.h>
#include	<dos.h>
#include	"mfxddn.h"

#undef		CONFIG_FILELINK
#define		CONFIG_FILELINK		TRUE
#include	"bgmlplay.c"
#define		__DDN_LOADHEADER__

