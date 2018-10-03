comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// チェインバッファの削除
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

mfxddn_del_chain_address	proc	buffer:dword
		public	mfxddn_del_chain_address
		cmp		MFXDDN_Initialize,EOF
		jnz		main
		mfxddn_errset	0
		mov		ax,EOF
		ret
	main:
		push	es
		mov		es,word ptr buffer+2
		mov		ah,38h
		int		DDNVECT
		pop		es
		mfxddn_errset	8
		mov		ax,NULL
		ret
mfxddn_del_chain_address	endp

end
