/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// エラーメッセージ系
*/
#include	<stdio.h>
#include	"mfxddn.h"

static	char *errmsg[]={
	"mfxdrv/ddn がInstallされていません。",
	"曲データのためのメモリーが足りません。",
	"曲データのファイルが見つかりません。",
	"mud ファイルではありません。",
	"mudファイルのフォーマットが違います。",
	"音源driver が Installされていません。",
	"mud ファイルが大きすぎます。",
	"演奏成功。",
	"実行成功。",
	"実行失敗。"
};

extern	int mfxddn_err;

char *mfxddn_errmsg(void)
{
	return errmsg[mfxddn_err];
}
