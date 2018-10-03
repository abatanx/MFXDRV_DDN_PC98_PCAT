/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN êßå‰ÉâÉCÉuÉâÉä
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
*/

#include	<stdio.h>
#include	"mfxddn.h"

static char		*mfxddn_lib="(*)"
#if		__SMALL__+__TINY__!=0
		"MFXDDNS.LIB"
#elif	__MEDIUM__!=0
		"MFXDDNM.LIB"
#elif	__COMPACT__!=0
		"MFXDDN.LIB"
#elif	__LARGE__!=0
		"MFXDDNL.LIB"
#elif	__HUGE__!=0
		"MFXDDNH.LIB"
#else
		"MFXDDN(?).LIB"
#endif
		" Version " C_DDN_VERSION "(" __DDN_BUILTING_COMPILER__ ")"
		" Copyright (c) 1993-95 Interfair"
		" All Rights Reserved(" C_DDN_INNERRELEASE ")";

MUD_TRACKWORK	mud_track_work[32];
MUD_TRACKINFO	track_info;
MUD_HEADER		mud;
SE_INFO			se[MAX_SEBUF];
int				mfxddn_err;
int				MFXDDN_Initialize = EOF;
char far		*mfxddn_musicbuffer;
long			MFXDDN_MAXMUDSIZE = 65500L;
