comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// 常駐チェック
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code
NULL		equ		0
EOF			equ		-1

;------------------------------------------------------------------------------
; MFXDDN常駐チェック
mfxddn_install_check	proc
			public	mfxddn_install_check
			push	ds
			push	es
			push	si
			push	di
			mov		ax,cs
			mov		ds,ax
			mov		ah,35h
			mov		al,DDNVECT
			int		21h
			mov		di,bx
			add		di,2
			mov		si,offset ddn_id
			mov		cx,9
			cld
			rep		cmpsb
			pop		di
			pop		si
			pop		es
			pop		ds
			jz		mic_installed
	mic_not_installed:
			mfxddn_errset	0
			mov		ax,EOF
			ret
	mic_installed:
			mfxddn_errset	8
			mov		ax,NULL
			ret
mfxddn_install_check	endp

ddn_id		db		'MFXkernel'

			end
