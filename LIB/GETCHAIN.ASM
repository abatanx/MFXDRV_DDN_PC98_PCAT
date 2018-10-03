comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// チェインバッファ先頭アドレスの取得
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

mfxddn_get_chain_address	proc
		public	mfxddn_get_chain_address
		cmp		MFXDDN_Initialize,EOF
		jnz		main
		mfxddn_errset	0
		xor		dx,dx
		xor		ax,ax
		ret
	main:
		push	es
		mov		ah,36h
		int		DDNVECT
		mov		ax,bx
		mov		dx,es
		pop		es
		mfxddn_errset	8
		ret
mfxddn_get_chain_address	endp

end
