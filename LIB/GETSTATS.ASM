comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN ���䃉�C�u����
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// ���t�X�e�[�^�X�擾�e��
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

; ���t�󋵂̎擾
mfxddn_get_playstatus	proc
		public	mfxddn_get_playstatus
		mov		ah,0ah
		int		DDNVECT
		mfxddn_errset	8
		ret
mfxddn_get_playstatus	endp

; �^�C���x�[�X�̎擾
mfxddn_get_timebase	proc
		public	mfxddn_get_timebase
		call	mfxddn_get_playstatus
		mov		ax,bx
		ret
mfxddn_get_timebase	endp

; �e���|�̎擾
mfxddn_get_tempo	proc
		public	mfxddn_get_tempo
		call	mfxddn_get_playstatus
		mov		ax,cx
		ret
mfxddn_get_tempo	endp

; �}�X�^�[�{�����[���̎擾
mfxddn_get_mastervolume	proc
		public	mfxddn_get_mastervolume
		call	mfxddn_get_playstatus
		mov		ax,dx
		ret
mfxddn_get_mastervolume	endp

end
