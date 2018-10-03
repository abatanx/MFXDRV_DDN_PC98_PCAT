/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//--------------------------------------------------------------------------*/
//
// master.lib file control対応版
//

/*
// MUDファイルのロード／演奏開始
*/

#include	<stdio.h>
#include	<dos.h>
#include	<master.h>
#include	"mfxddn.h"
#undef		CONFIG_MTLIB
#define		CONFIG_MTLIB		TRUE

#define		__DDN_LOADHEADER__

#define		fgetc(a)		file_getc()
#define		 getw(a)		file_getw()
#define		fclose(a)		file_close()
#define		fread(a,b,c,d)	file_read(a,(b)*(c))
#define		ftell(a)		file_tell()
#define		clearerr(a)		
#define		fseek(a,b,c)	file_seek(b,c)
#undef		SEEK_SET
#undef		SEEK_CUR
#undef		SEEK_END
#define		SEEK_SET	0
#define		SEEK_CUR	1
#define		SEEK_END	2

#include	"bgmlplay.c"

