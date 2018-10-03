comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// ドライバ名の取得
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

mfxddn_get_driver_name	proc	number:word
		public	mfxddn_get_driver_name
		cmp		MFXDDN_Initialize,EOF
		jnz		main
		mfxddn_errset	0
		xor		ax,ax
		ret
	main:
		mfxddn_errset	9
		push	es
		mov		ah,03h
		mov		al,byte ptr number
		int		DDNVECT
		or		ax,ax
		jz		success
		xor		ax,ax
		xor		dx,dx
		jmp		exit
	success:
		mov		ax,bx
		mov		dx,es
		mfxddn_errset	8
	exit:
		pop		es
		ret
mfxddn_get_driver_name	endp

end
