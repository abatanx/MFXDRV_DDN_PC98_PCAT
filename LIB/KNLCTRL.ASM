comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN ���䃉�C�u����
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// �J�[�l���{�̂̑g�ݍ��݁^���(LIB��DDN�̑g�ݍ��݁^��������患)
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
; �J�[�l���̏풓
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
; �J�[�l���̉��
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