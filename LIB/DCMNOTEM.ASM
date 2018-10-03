comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN êßå‰ÉâÉCÉuÉâÉä
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// (DCM-Noteon message)
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

mfxddn_dcm_noteon	proc	drvno,channel,note,velocity:word
		public	mfxddn_dcm_noteon
		cmp		MFXDDN_Initialize,EOF
		jnz		main
		mfxddn_errset	0
		mov		ax,EOF
		ret
	main:
		mov		ah,18h
		mov		al,02h
		mov		dl,byte ptr drvno
		mov		ch,byte ptr channel
		mov		bh,byte ptr note
		mov		bl,byte ptr velocity
		int		DDNVECT
		mfxddn_errset	8
		mov		ax,NULL
		ret
mfxddn_dcm_noteon	endp

mfxddn_dcm_noteoff	proc	drvno,channel,note:word
		public	mfxddn_dcm_noteoff
		cmp		MFXDDN_Initialize,EOF
		jnz		main2
		mfxddn_errset	0
		mov		ax,EOF
		ret
	main2:
		mov		ah,18h
		mov		al,01h
		mov		dl,byte ptr drvno
		mov		ch,byte ptr channel
		mov		bh,byte ptr note
		int		DDNVECT
		mfxddn_errset	8
		mov		ax,NULL
		ret
mfxddn_dcm_noteoff	endp

end
