comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// フェードアウト終了
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

mfxddn_bgm_fadeout	proc	speed:word
		public	mfxddn_bgm_fadeout
		cmp		MFXDDN_Initialize,EOF
		jnz		main
		mfxddn_errset	0
		mov		ax,EOF
		ret
	main:
		mov		ah,14h
		mov		bx,speed
		int		DDNVECT
		mfxddn_errset	8
		mov		ax,NULL
		ret
mfxddn_bgm_fadeout	endp

end
