comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// ワーク取得
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

mfxddn_get_work	proc	track,workno:word
		public	mfxddn_get_work
		mov		bh,byte ptr track
		mov		bl,byte ptr workno
		mov		ah,06h
		int		DDNVECT
		mfxddn_errset	8
		ret
mfxddn_get_work	endp

end
