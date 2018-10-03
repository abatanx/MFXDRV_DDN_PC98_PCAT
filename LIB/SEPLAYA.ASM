comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN êßå‰ÉâÉCÉuÉâÉä
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// å¯â âπî≠ê∫
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

mfxddn_se_play_local	proc	buffer:dword,chn,trk,drv:word
		public	mfxddn_se_play_local
		cmp		MFXDDN_Initialize,EOF
		jnz		main
		mfxddn_errset	0
		mov		ax,EOF
		ret
	main:
		push	es
		mov		bx,word ptr buffer
		mov		es,word ptr buffer+2
		mov		ah,20h
		mov		al,byte ptr trk
		mov		ch,byte ptr chn
		mov		cl,byte ptr drv
		int		DDNVECT
		pop		es
		mfxddn_errset	8
		mov		ax,NULL
		ret
mfxddn_se_play_local	endp

end
