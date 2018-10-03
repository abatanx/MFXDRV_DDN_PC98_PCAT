comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN êßå‰ÉâÉCÉuÉâÉä
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// (DCM-Stating Initalize and Ending Initialize)
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

mfxddn_dcm_init	proc	no:word
		public	mfxddn_dcm_init
		cmp		MFXDDN_Initialize,EOF
		jnz		main_dcm_init
		mfxddn_errset	0
		mov		ax,EOF
		ret
	main_dcm_init:
		mov		ah,17h
		mov		dl,byte ptr no
		int		DDNVECT
		mfxddn_errset	8
		mov		ax,NULL
		ret
mfxddn_dcm_init	endp

mfxddn_dcm_end	proc	no:word
		public	mfxddn_dcm_end
		cmp		MFXDDN_Initialize,EOF
		jnz		main_dcm_end
		mfxddn_errset	0
		mov		ax,NULL
		ret
	main_dcm_end:
		mov		ah,19h
		mov		dl,byte ptr no
		int		DDNVECT
		mfxddn_errset	8
		mov		ax,EOF
		ret
mfxddn_dcm_end	endp

end
