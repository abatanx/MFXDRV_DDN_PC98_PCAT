comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// 演奏開始
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

mfxddn_bgm_start	proc	buffer:dword
		public	mfxddn_bgm_start
		cmp		MFXDDN_Initialize,EOF
		jnz		main
		mfxddn_errset	0
		mov		ax,EOF
		ret
	main:
		push	es
		mov		bx,word ptr buffer
		mov		es,word ptr buffer+2
		mov		ah,10h
		int		DDNVECT
		pop		es
		mfxddn_errset	7
		mov		ax,NULL
		ret
mfxddn_bgm_start	endp

end
