;==============================================================================
; �����h���C�o�쐬�p�x�[�X�v���O����
; �{�v���O�����́Apublic domain software�ł��B�����R�ɂ��g���������B
;                                         based programmed by ABA / T.Kobayashi
;==============================================================================
;
; �t�@���N�V��������
;

;��
; ���̃v���O�����͑S�� XMML rel3.00(1.2) �d�l�̉����h���C�o�K�i��
; �����Ă��܂��B�efunction�Ɋւ��ẮAusl_drv.doc �������������B
; XMML rel.3.00 copyright (c) ABA / T.Kobayashi and Interfair 
;													all rights reserved
;��
			jumps
			.186
			.model	tiny
			.code

include		stdio.inc
include		ddn.inc
include		usertool.inc
include		snd.inc

;---------------------------- ddn func proc.(00) ECM
func_ecm		proc	far
			ret
func_ecm		endp
;---------------------------- ddn func proc.(01) �m�[�g�I�t
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		�m�[�g�i���o�[(0 �` 127)
;
func_note_off	proc	far
			ret
func_note_off	endp

;---------------------------- ddn func proc.(02) �m�[�g�I��
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		�m�[�g�i���o�[(0 �` 127)
;	bl		�x���V�e�B�[(0 �` 127)
;
func_note_on	proc	far
			ret
func_note_on	endp

;---------------------------- ddn func proc.(03) �|���t�H�j�b�N�L�[�v���b�V���[
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		�m�[�g�i���o�[(0 �` 127)
;	bl		�v���b�V���[�l(0 �` 127)
;
func_poly_keypress	proc	far
			ret
func_poly_keypress	endp

;---------------------------- ddn func proc.(04) �o���N�Z���N�g
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bx		�o���N�i���o�[(0 �` 0x7f7f)
;
func_bank_select	proc	far
			ret
func_bank_select	endp

;---------------------------- ddn func proc.(05) ���W�����[�V����
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		���W�����[�V�����f�v�X(0�`127)
;
func_modulation	proc	far
			ret
func_modulation	endp

;---------------------------- ddn func proc.(06) �|���^�����g�^�C��
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		�|���^�����g�^�C��(0�`127)
;
func_pol_time	proc	far
			ret
func_pol_time	endp

;---------------------------- ddn func proc.(07) �f�[�^�G���g���[
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bx		RPN/NRPN�̃p�����[�^�ɑ΂���l(0�`0x7f7f)
;
func_data_entry	proc	far
			ret
func_data_entry	endp

;---------------------------- ddn func proc.(08) �{�����[��
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		�{�����[��(0�`127)
;
func_volume		proc	far
			ret
func_volume	endp

;---------------------------- ddn func proc.(09) �p���|�b�g
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		�p���|�b�g(0�`127)
;
func_panpot		proc	far
			ret
func_panpot		endp

;---------------------------- ddn func proc.(0a) �G�N�X�v���b�V����
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		�G�N�X�v���b�V����(0�`127)
;
func_expression	proc	far
			ret
func_expression	endp

;---------------------------- ddn func proc.(0b) �z�[���h�P
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		�z�[���h�R���g���[���l(0�`127)
;
func_hold1		proc	far
			ret
func_hold1		endp

;---------------------------- ddn func proc.(0c) �|���^�����g
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		�|���^�����g�R���g���[���l(0�`127)
;
func_poltament	proc	far
			ret
func_poltament	endp

;---------------------------- ddn func proc.(0d) �\�X�e�k�[�g
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		�\�X�e�k�[�g�R���g���[���l(0�`127)
;
func_sostenuto	proc	far
			ret
func_sostenuto	endp

;---------------------------- ddn func proc.(0e) �\�t�g
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		�\�t�g�R���g���[���l(0�`127)
;
func_soft		proc	far
			ret
func_soft		endp

;---------------------------- ddn func proc.(0f) �|���^�����g�R���g���[��
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		�\�[�X�m�[�g�i���o�[(0�`127)
;
func_pol_ctrl	proc	far
			ret
func_pol_ctrl	endp

;---------------------------- ddn func proc.(10) �ėpeffect1(��ް�޾�������)
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		�R���g���[���l(0�`127)
;
func_effect1		proc	far
			ret
func_effect1		endp

;---------------------------- ddn func proc.(11) �ėpeffect3(��׽��������)
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		�R���g���[���l(0�`127)
;
func_effect3		proc	far
			ret
func_effect3		endp

;---------------------------- ddn func proc.(12) NRPN
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		mm,ll�I�� 0:mm 1:ll
;	bl		�f�[�^(0�`127)
func_nrpn		proc	far
			ret
func_nrpn		endp

;---------------------------- ddn func proc.(13) RPN
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		mm,ll�I�� 0:mm 1:ll
;	bl		�f�[�^(0�`127)
func_rpn			proc	far
			ret
func_rpn			endp

;---------------------------- ddn func proc.(14) �v���O�����`�F���W
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		���F�ԍ�(0�` 127? �`255)
;
func_prog_chg	proc	far
			ret
func_prog_chg	endp

;---------------------------- ddn func proc.(15) �`�����l���v���b�V���[
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		�`�����l���ԍ�(0 �` drvch-1)�v���b�V���[�l
;
func_ch_presser	proc	far
			ret
func_ch_presser	endp

;---------------------------- ddn func proc.(16) �s�b�`�x���h�����W
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bx		�s�b�`�x���h�l(0 �` 0x7f7f)
;
func_pitchbend	proc	far
			ret
func_pitchbend	endp

;---------------------------- ddn func proc.(17) �I�[���T�E���h�I�t
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;
func_all_soundoff	proc	far
			ret
func_all_soundoff	endp

;---------------------------- ddn func proc.(18) �I�[�����Z�b�g�R���g���[���[
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;
func_all_resetctrler	proc	far
			ret
func_all_resetctrler	endp

;---------------------------- ddn func proc.(19) �I�[���m�[�g�I�t
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;
func_all_noteoff	proc	far
			ret
func_all_noteoff	endp

;---------------------------- ddn func proc.(1a) OMNI OFF
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;
func_omni_off	proc	far
			ret
func_omni_off	endp

;---------------------------- ddn func proc.(1b) OMNI ON
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;
func_omni_on		proc	far
			ret
func_omni_on		endp

;---------------------------- ddn func proc.(1c) MONO
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;	bh		MONO��
;
func_mono		proc	far
			ret
func_mono		endp

;---------------------------- ddn func proc.(1d) POLY
;	ch		�`�����l���ԍ�(0 �` drvch-1)
;
func_poly		proc	far
			ret
func_poly		endp

;---------------------------- ddn func proc.(1e) �A�N�e�B�u�Z���V���O
;
func_active_sence	proc	far
			ret
func_active_sence	endp

;---------------------------- ddn func proc.(1f) �G�N�X�N���[�V�u���b�Z�[�W
;	es:bx	�G�N�X�N���[�V�u�f�[�^��
;	cx		����
;
func_exclusive	proc	far
			ret
func_exclusive	endp

;---------------------------- ddn func proc.(20) �r�u���[�g�ݒ�
;	cx		���F�ԍ�
;	bh		�r�u���[�g���[�g
;	bl		�r�u���[�g�f�v�X
;	dh		�r�u���[�g�f�B���C
;
func_vibrato		proc	far
			ret
func_vibrato		endp

;---------------------------- ddn func proc.(21) �}�X�^�[�{�����[��
;	bh		�}�X�^�[�{�����[���l(0�`127)
;
func_master_volume	proc	far
			ret
func_master_volume	endp

			end
