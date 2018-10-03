;==============================================================================
; MFXDDN sound driver module
;						MIDI Interface driver for 98
;  copyright (c) 1993 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; �t�@���N�V��������
;

;��
; ���̃v���O�����͑S�� XMML rel3.00 �d�l�̒ʏ퉹���f�o�C�X���W���[���K�i��
; �����Ă��܂��B
; XMML rel.3.00 copyright (c) ABA / T.Kobayashi and Interfair 
;													all rights reserved
;��
			jumps
			.186
			.model	tiny
			.code

include		stdio.inc
include		ddn.inc
include		sbmidi.inc
include		sbmdterm.inc

extrn		MODULE:word
extrn		progchg:word
extrn		volume_buf:word
extrn		mastervol_buf:word

_ms			macro	data
			mov		al,data
			call	midi_out
			endm


;---------------------------- ddn func proc.(00) ����������
;ret@ax
;	NULL	����������
;
midi_init_midimodule	proc	far
			public	midi_init_midimodule
			xor		ax,ax
			ret
midi_init_midimodule	endp

;---------------------------- ddn func proc.(01) �m�[�g�I�t
;	ch		MIDI�`�����l��
;	bh		�m�[�g�i���o�[
;	bl		�x���V�e�B�[
;
midi_note_off	proc	far
			public	midi_note_off
			cmp		ch,09h
			jnz		mnof_main
			cmp		[progchg],TRUE
			jz		mnof_main
			ret
	mnof_main:
			or		ch,80h
			_ms		ch
			_ms		bh
			_ms		bl
			ret
midi_note_off	endp

;---------------------------- ddn func proc.(02) �m�[�g�I��
;	ch		MIDI�`�����l��
;	bh		�m�[�g�i���o�[
;	bl		�x���V�e�B�[
;
midi_note_on	proc	far
			public	midi_note_on
			cmp		ch,09h
			jnz		mnon_main
			cmp		[progchg],TRUE
			jz		mnon_main
			ret
	mnon_main:
			or		ch,90h
			_ms		ch
			_ms		bh
			_ms		bl
			ret
midi_note_on	endp

;---------------------------- ddn func proc.(03) �|���t�H�j�b�N�L�[�v���b�V���[
;	ch		MIDI�`�����l��
;	bh		�m�[�g�i���o�[
;	bl		�v���b�V���[�l
;
midi_poly_keypress	proc	far
			public	midi_poly_keypress
			or		ch,0a0h
			_ms		ch
			_ms		bh
			_ms		bl
			ret
midi_poly_keypress	endp

;---------------------------- ddn func proc.(04) �o���N�Z���N�g
;	ch		MIDI�`�����l��
;	bx		�o���N�i���o�[
;
midi_bank_select	proc	far
			public	midi_bank_select
			or		ch,0b0h
			_ms		ch
			_ms		00h
			_ms		bh
			_ms		ch
			_ms		20h
			_ms		bl
			ret
midi_bank_select	endp

;---------------------------- ddn func proc.(05) ���W�����[�V����
;	ch		MIDI�`�����l��
;	bh		���W�����[�V�����f�v�X
;
midi_modulation	proc	far
			public	midi_modulation
			cmp		[progchg],TRUE
			jz		mmod_main
			ret
	mmod_main:
			or		ch,0b0h
			_ms		ch
			_ms		01h
			_ms		bh
			ret
midi_modulation	endp

;---------------------------- ddn func proc.(06) �|���^�����g�^�C��
;	ch		MIDI�`�����l��
;	bh		�|���^�����g�^�C��
;
midi_pol_time	proc	far
			public	midi_pol_time
			or		ch,0b0h
			_ms		ch
			_ms		05h
			_ms		bh
			ret
midi_pol_time	endp

;---------------------------- ddn func proc.(07) �f�[�^�G���g���[
;	ch		MIDI�`�����l��
;	bx		RPN/NRPN�̃p�����[�^�ɑ΂���l
;
midi_data_entry	proc	far
			public	midi_data_entry
			cmp		[progchg],TRUE
			jz		mdatae_main
			ret
	mdatae_main:

			or		ch,0b0h
			_ms		ch
			or		bh,bh
			jnz		midi_entry_ll
	midi_entry_mm:
			_ms		06h
			_ms		bl
			ret
	midi_entry_ll:
			_ms		26h
			_ms		bl
			ret
midi_data_entry	endp

;---------------------------- ddn func proc.(08) �{�����[��
;	ch		MIDI�`�����l��
;	bh		�{�����[��
;
midi_volume		proc	far
			public	midi_volume
			push	bx
			push	cx
			mov		al,bh
			xor		ah,ah
			mov		bl,ch
			xor		bh,bh
			shl		bx,1
			mov		[bx+volume_buf],ax
			pop		cx
			pop		bx

;			cmp		[MODULE],GS_MODULE
;			jz		gs_midivol
;			mov		ax,[mastervol_buf]
;			mul		bh
;			shr		ax,7
;			mov		bh,al

	gs_midivol:
			or		ch,0b0h
			_ms		ch
			_ms		07h
			_ms		bh
			ret
midi_volume	endp

;---------------------------- ddn func proc.(09) �p���|�b�g
;	ch		MIDI�`�����l��
;	bh		�p���|�b�g
;
midi_panpot		proc	far
			public	midi_panpot
			or		ch,0b0h
			_ms		ch
			_ms		0ah
			_ms		bh
			ret
midi_panpot		endp

;---------------------------- ddn func proc.(0a) �G�N�X�v���b�V����
;	ch		MIDI�`�����l��
;	bh		�G�N�X�v���b�V����
;
midi_expression	proc	far
			public	midi_expression
			or		ch,0b0h
			_ms		ch
			_ms		0bh
			_ms		bh
			ret
midi_expression	endp

;---------------------------- ddn func proc.(0b) �z�[���h�P
;	ch		MIDI�`�����l��
;	bh		�z�[���h�R���g���[���l
;
midi_hold1		proc	far
			public	midi_hold1
			or		ch,0b0h
			_ms		ch
			_ms		40h
			_ms		bh
			ret
midi_hold1		endp

;---------------------------- ddn func proc.(0c) �|���^�����g
;	ch		MIDI�`�����l��
;	bh		�|���^�����g�R���g���[���l
;
midi_poltament	proc	far
			public	midi_poltament
			cmp		[progchg],TRUE
			jz		mpolt_main
			ret
	mpolt_main:
	
			or		ch,0b0h
			_ms		ch
			_ms		41h
			_ms		bh
			ret
midi_poltament	endp

;---------------------------- ddn func proc.(0d) �\�X�e�k�[�g
;	ch		MIDI�`�����l��
;	bh		�\�X�e�k�[�g�R���g���[���l
;
midi_sostenuto	proc	far
			public	midi_sostenuto
			or		ch,0b0h
			_ms		ch
			_ms		42h
			_ms		bh
			ret
midi_sostenuto	endp

;---------------------------- ddn func proc.(0e) �\�t�g
;	ch		MIDI�`�����l��
;	bh		�\�t�g�R���g���[���l
;
midi_soft		proc	far
			public	midi_soft
			or		ch,0b0h
			_ms		ch
			_ms		43h
			_ms		bh
			ret
midi_soft		endp

;---------------------------- ddn func proc.(0f) �|���^�����g�R���g���[��
;	ch		MIDI�`�����l��
;	bh		�\�[�X�m�[�g�i���o�[
;
midi_pol_ctrl	proc	far
			public	midi_pol_ctrl
			or		ch,0b0h
			_ms		ch
			_ms		54h
			_ms		bh
			ret
midi_pol_ctrl	endp

;---------------------------- ddn func proc.(10) �ėpeffect1(��ް�޾�������)
;	ch		MIDI�`�����l��
;	bh		�R���g���[���l
;
midi_effect1		proc	far
			public	midi_effect1
			or		ch,0b0h
			_ms		ch
			_ms		5bh
			_ms		bh
			ret
midi_effect1		endp

;---------------------------- ddn func proc.(11) �ėpeffect3(��׽��������)
;	ch		MIDI�`�����l��
;	bh		�R���g���[���l
;
midi_effect3		proc	far
			public	midi_effect3
			or		ch,0b0h
			_ms		ch
			_ms		5dh
			_ms		bh
			ret
midi_effect3		endp

;---------------------------- ddn func proc.(12) NRPN
;	ch		MIDI�`�����l��
;	bh		mm,ll�I�� 0:mm 1:ll
;	bl		�f�[�^
midi_nrpn		proc	far
			public	midi_nrpn
			or		ch,0b0h
			mov		cl,63h
			sub		cl,bh
			_ms		ch
			_ms		cl
			_ms		bl
			ret
midi_nrpn		endp

;---------------------------- ddn func proc.(13) RPN
;	ch		MIDI�`�����l��
;	bh		mm,ll�I�� 0:mm 1:ll
;	bl		�f�[�^
midi_rpn			proc	far
			public	midi_rpn
			or		ch,0b0h
			mov		cl,65h
			sub		cl,bh
			_ms		ch
			_ms		cl
			_ms		bl
			ret
midi_rpn			endp

;---------------------------- ddn func proc.(14) �v���O�����`�F���W
;	ch		MIDI�`�����l��
;	bh		���F�ԍ�
;
midi_prog_chg	proc	far
			public	midi_prog_chg
			cmp		[progchg],FALSE
			jz		mpc_exit
			or		ch,0c0h
			_ms		ch
			_ms		bh
	mpc_exit:
			ret
midi_prog_chg	endp

;---------------------------- ddn func proc.(15) �`�����l���v���b�V���[
;	ch		MIDI�`�����l��
;	bh		�`�����l���v���b�V���[�l
;
midi_ch_presser	proc	far
			public	midi_ch_presser
			or		ch,0d0h
			_ms		ch
			_ms		bh
			ret
midi_ch_presser	endp

;---------------------------- ddn func proc.(16) �s�b�`�x���h�����W
;	ch		MIDI�`�����l��
;	bx		�s�b�`�x���h�l
;
midi_pitchbend	proc	far
			public	midi_pitchbend
			add		bx,8192		; �␳^^;;
			shl		bl,1		; 1������ + cy=?
			rcl		bh,1		; cy �� �J��グ
			shr		bl,1		; 1�������̂�߂�

			or		ch,0e0h
			_ms		ch
			_ms		bl
			_ms		bh
			ret
midi_pitchbend	endp

;---------------------------- ddn func proc.(17) �I�[���T�E���h�I�t
;	ch		MIDI�`�����l��
;
midi_all_soundoff	proc	far
			public	midi_all_soundoff
			or		ch,0b0h
			_ms		ch
			_ms		78h
			_ms		00h
			ret
midi_all_soundoff	endp

;---------------------------- ddn func proc.(18) �I�[�����Z�b�g�R���g���[���[
;	ch		MIDI�`�����l��
;
midi_all_resetctrler	proc	far
			public	midi_all_resetctrler
			or		ch,0b0h
			_ms		ch
			_ms		79h
			_ms		00h
			ret
midi_all_resetctrler	endp

;---------------------------- ddn func proc.(19) �I�[���m�[�g�I�t
;	ch		MIDI�`�����l��
;
midi_all_noteoff	proc	far
			public	midi_all_noteoff
			or		ch,0b0h
			_ms		ch
			_ms		7bh
			_ms		00h
			ret
midi_all_noteoff	endp

;---------------------------- ddn func proc.(1a) OMNI OFF
;	ch		MIDI�`�����l��
;
midi_omni_off	proc	far
			public	midi_omni_off
			or		ch,0b0h
			_ms		ch
			_ms		7ch
			_ms		00h
			ret
midi_omni_off	endp

;---------------------------- ddn func proc.(1b) OMNI ON
;	ch		MIDI�`�����l��
;
midi_omni_on		proc	far
			public	midi_omni_on
			or		ch,0b0h
			_ms		ch
			_ms		7dh
			_ms		00h
			ret
midi_omni_on		endp

;---------------------------- ddn func proc.(1c) MONO
;	ch		MIDI�`�����l��
;	bh		MONO��
;
midi_mono		proc	far
			public	midi_mono
			or		ch,0b0h
			_ms		ch
			_ms		7eh
			_ms		bh
			ret
midi_mono		endp

;---------------------------- ddn func proc.(1d) POLY
;	ch		MIDI�`�����l��
;
midi_poly		proc	far
			public	midi_poly
			or		ch,0b0h
			_ms		ch
			_ms		7fh
			_ms		00h
			ret
midi_poly		endp

;---------------------------- ddn func proc.(1e) �A�N�e�B�u�Z���V���O
;
midi_active_sence	proc	far
			public	midi_active_sence
			_ms		0feh
			ret
midi_active_sence	endp

;---------------------------- ddn func proc.(1f) �G�N�X�N���[�V�u���b�Z�[�W
;	es:bx	�G�N�X�N���[�V�u�f�[�^��
;	cx		����
;
midi_exclusive	proc	far
			public	midi_exclusive
			push	ds
			push	si
			mov		si,bx
			mov		bx,es
			mov		ds,bx
			cld
			_ms		0f0h
	exclusive_next:
			push	cx
			lodsb
			call	midi_out
			pop		cx
			loop	exclusive_next
			_ms		0f7h
			pop		si
			pop		ds
			ret
midi_exclusive	endp

;---------------------------- ddn func proc.(20) �r�u���[�g�ݒ�
;	cx		���F�ԍ�
;	bh		�r�u���[�g���[�g
;	bl		�r�u���[�g�f�v�X
;	dh		�r�u���[�g�f�B���C
;
midi_vibrato		proc	far
			public	midi_vibrato
			ret
midi_vibrato		endp

;---------------------------- ddn func proc.(21) �}�X�^�[�{�����[��
;	bh		�}�X�^�[�{�����[���l
;
midi_master_volume	proc	far
			public	midi_master_volume
			xor		ax,ax
			mov		al,bh
			inc		ax
			mov		[mastervol_buf],ax
			
			cmp		[MODULE],GS_MODULE
			jnz		gm
;----- GS���� mastervolueme
	gs:
			push	bx
			_ms		0f0h
			_ms		41h
			_ms		10h
			_ms		42h
			_ms		12h
			_ms		40h
			_ms		00h
			_ms		04h
			pop		bx
			push	bx
			_ms		bh
	;check sum�v�Z
	sum_ex:
			pop		bx
			mov		bl,bh
			xor		bh,bh
			add		bx,40h+00h+04h
			and		bx,127
			mov		ax,128
			sub		ax,bx
	ret:
			_ms		al
			_ms		0f7h
			ret

;----- GM���� mastervolueme(�[���I�ɂ���̂悧)
	gm:
			mov		si,offset volume_buf
			mov		cx,16
			xor		dh,dh
			cld
	gm_mastvol:
			lodsw
			mul		bh				; ax<- volume*bh
			shr		ax,7			; ax/128
			mov		dl,al
	
			mov		al,dh
			or		al,0b0h
			call	midi_out
			mov		al,07h
			call	midi_out
			mov		al,dl
			call	midi_out
			inc		dh
			loop	gm_mastvol

			ret
midi_master_volume	endp

			end

