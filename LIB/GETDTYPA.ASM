comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// ドライバータイプの取得
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

mfxddn_get_driver_type_local	proc	buffer:dword
		public	mfxddn_get_driver_type_local
		push	es
		mov		bx,word ptr buffer
		mov		es,word ptr buffer+2
		mov		ah,07h
		int		DDNVECT
		pop		es
		mfxddn_errset	8
		ret
mfxddn_get_driver_type_local	endp

end
