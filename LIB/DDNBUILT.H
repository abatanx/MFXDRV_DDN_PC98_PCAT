/*---------------------------------------------------------------------------
   MFXDDN the XMML ver.3.00 MFXDRV/DDN ドライバー制御ライブラリ
                             MFXDDN.H version 1.00
  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
  *BUILT専属 Header file
-----------------------------------------------------------------------------*/

#ifndef		__DDNBUILT_H__
#define		__DDNBUILT_H__

#ifndef		MK_FP
# define MK_FP(s,o)	((void far *)(((unsigned long)(s) << 16)+(unsigned)(o)))
#endif

#define		wset(a,b)	((unsigned)((unsigned)(b)*256+(unsigned)(a)))

/*-- Borland bc or tcc --*/
#ifdef	C_TC
#define	__DDN_BUILTING_COMPILER__	"TC"
#endif

/*-- Borland bc or tcc --*/
#ifdef	C_BC
#define	__DDN_BUILTING_COMPILER__	"BC"
#endif

/*-- msc --*/
#ifdef	C_MSC
#define	__DDN_BUILTING_COMPILER__	"MSC"
#endif

/*-- etc --*/
/*
#ifndef		__DDN_BUILTING_COMPILER__
# define	__DDN_BUILTING_COMPILER__	"?"
#endif
*/

#endif
