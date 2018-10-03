comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN êßå‰ÉâÉCÉuÉâÉä
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// (DCM-ECM system)
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

mfxddn_dcm_ecm	proc	drvno:word,ecm:dword
		public	mfxddn_dcm_ecm
		cmp		MFXDDN_Initialize,EOF
		jnz		main
		mfxddn_errset	0
		mov		ax,EOF
		ret
	main:
		push	es
		mov		ah,18h
		mov		al,0
		mov		dl,byte ptr drvno
		mov		bx,word ptr ecm
		mov		es,word ptr ecm+2
		int		DDNVECT
		pop		es
		mfxddn_errset	8
		mov		ax,NULL
		ret
mfxddn_dcm_ecm	endp

end
