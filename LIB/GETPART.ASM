comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN ���䃉�C�u����
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// ���t�p�[�g�擾�e��
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

; ���t�J�E���^�[�̎擾
mfxddn_get_counter	proc
		public	mfxddn_get_counter
		mov		ah,0bh
		int		DDNVECT
		mfxddn_errset	8
		ret
mfxddn_get_counter	endp

; ���t���߂̎擾
mfxddn_get_mean	proc
		public	mfxddn_get_mean
		mov		ah,0ch
		int		DDNVECT
		mfxddn_errset	8
		ret
mfxddn_get_mean	endp

; ���t���ߓ���tick�̎擾
mfxddn_get_mean_counter	proc
		public	mfxddn_get_mean_counter
		mov		ah,0ch
		int		DDNVECT
		mfxddn_errset	8
		mov		ax,dx
		ret
mfxddn_get_mean_counter	endp

end

