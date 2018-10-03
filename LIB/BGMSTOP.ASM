comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN êßå‰ÉâÉCÉuÉâÉä
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// ââëtèIóπ
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

mfxddn_bgm_stop	proc
		public	mfxddn_bgm_stop
		cmp		MFXDDN_Initialize,EOF
		jnz		main
		mfxddn_errset	0
		mov		ax,EOF
		ret
	main:
		mov		ah,11h
		int		DDNVECT
		mfxddn_errset	8
		mov		ax,NULL
		ret
mfxddn_bgm_stop	endp

end
