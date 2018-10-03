comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN êßå‰ÉâÉCÉuÉâÉä
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// (DCM-Volume and Expression)
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

mfxddn_dcm_volume	proc	drvno,channel,vol:word
		public	mfxddn_dcm_volume
		cmp		MFXDDN_Initialize,EOF
		jnz		main_dcm_volume
		mfxddn_errset	0
		mov		ax,NULL
		ret
	main_dcm_volume:
		mov		ah,18h
		mov		al,08h
		mov		dl,byte ptr drvno
		mov		ch,byte ptr channel
		mov		bh,byte ptr vol
		int		DDNVECT
		mfxddn_errset	8
		mov		ax,NULL
		ret
mfxddn_dcm_volume	endp

mfxddn_dcm_expression	proc	drvno,channel,exp:word
		public	mfxddn_dcm_expression
		cmp		MFXDDN_Initialize,EOF
		jnz		main_dcm_expression
		mfxddn_errset	0
		mov		ax,EOF
		ret
	main_dcm_expression:
		mov		ah,18h
		mov		al,0ah
		mov		dl,byte ptr drvno
		mov		ch,byte ptr channel
		mov		bh,byte ptr exp
		int		DDNVECT
		mfxddn_errset	8
		mov		ax,NULL
		ret
mfxddn_dcm_expression	endp

end
