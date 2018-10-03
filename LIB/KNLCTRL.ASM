comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// カーネル本体の組み込み／解放(LIB化DDNの組み込み／解放部だよぅ)
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

IF	CODESIZE	EQ	c_near
extrn	mfxddn_kernel_program:near
ELSE
extrn	mfxddn_kernel_program:far
ENDIF

;----------------------------------------------------------------------------
; カーネルの常駐
;
mfxddn_install_kernel	proc
		public	mfxddn_install_kernel
		push_all
		mov		dx,'In'
		call	mfxddn_kernel_program
		mov		cs:[ax_entry],ax
		pop_all
		mov		ax,cs:[ax_entry]
		ret
mfxddn_install_kernel	endp

;----------------------------------------------------------------------------
; カーネルの解放
;
mfxddn_remove_kernel	proc
		public	mfxddn_remove_kernel
		push_all
		mov		dx,'Re'
		call	mfxddn_kernel_program
		mov		cs:[ax_entry],ax
		pop_all
		mov		ax,cs:[ax_entry]
		ret
mfxddn_remove_kernel	endp

ax_entry	dw		?

		end
