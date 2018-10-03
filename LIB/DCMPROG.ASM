comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN êßå‰ÉâÉCÉuÉâÉä
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// (DCM-Program change)
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

mfxddn_dcm_progchange	proc	drvno,channel,progno:word
		public	mfxddn_dcm_progchange
		cmp		MFXDDN_Initialize,EOF
		jnz		main
		mfxddn_errset	0
		mov		ax,EOF
		ret
	main:
		mov		ah,18h
		mov		al,14h
		mov		dl,byte ptr drvno
		mov		ch,byte ptr channel
		mov		bh,byte ptr progno
		int		DDNVECT
		mfxddn_errset	8
		mov		ax,NULL
		ret
mfxddn_dcm_progchange	endp

end
