/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//--------------------------------------------------------------------------*/
//
// Filelink 対応版
//

#include	"mfxddn.h"
#undef		CONFIG_FILELINK
#define		CONFIG_FILELINK		TRUE
#include	"seload.c"
