comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN ���䃉�C�u����
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// �g�p�\�`�����l�����擾(�A�Z���u����)
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

mfxddn_get_canuse_channel_local	proc	buffer:dword
		public	mfxddn_get_canuse_channel_local
		cmp		MFXDDN_Initialize,EOF
		jnz		main
		mfxddn_errset	0
		mov		ax,NULL
		ret
	main:
		push	es
		mov		bx,word ptr buffer
		mov		es,word ptr buffer+2
		mov		ah,04h
		int		DDNVECT
		pop		es
		mov		al,ah
		xor		ah,ah
		mfxddn_errset	8
		ret
mfxddn_get_canuse_channel_local	endp

end