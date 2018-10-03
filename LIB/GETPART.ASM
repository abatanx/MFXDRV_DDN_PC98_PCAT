comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// 演奏パート取得各種
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

; 演奏カウンターの取得
mfxddn_get_counter	proc
		public	mfxddn_get_counter
		mov		ah,0bh
		int		DDNVECT
		mfxddn_errset	8
		ret
mfxddn_get_counter	endp

; 演奏小節の取得
mfxddn_get_mean	proc
		public	mfxddn_get_mean
		mov		ah,0ch
		int		DDNVECT
		mfxddn_errset	8
		ret
mfxddn_get_mean	endp

; 演奏小節内のtickの取得
mfxddn_get_mean_counter	proc
		public	mfxddn_get_mean_counter
		mov		ah,0ch
		int		DDNVECT
		mfxddn_errset	8
		mov		ax,dx
		ret
mfxddn_get_mean_counter	endp

end

