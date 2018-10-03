;==============================================================================
; MFXDDN sound driver module
;						beep Interface driver for 98
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
include		beep.inc
include		beepfreq.inc

.data
beep_note	db		100h dup(0)		; �m�[�g���
even
xnote		dw		?
xnote_tmp	dw		?
beep_hz		dw		?
steps		db		0

single_note				dw		0	; �m�[�g
single_mod_lev			dw		0	; Modulation���x��
single_mod_levdir		dw		1	; Modulation���x�������A�傫��
single_mod_nowlev		dw		0	; ���݂�Modulation���x��
single_mod_nowlevdir	dw		0	; ���݂�Modulation���x���̕���
single_mod_sync			dw		10	; Modulation-Stating Sync
single_mod_nowsync		dw		0	; ���݂�Mod.-Stating Sync counter
single_mod_switch		dw	FALSE	; Modulaiton�X�C�b�`

STEPS		=		2
.code

extrn		CPUCLOCK:word,single:word

;---------------------------- �m�[�g���̏o��
note_out	proc
			public	note_out
			mov		ax,cs
			mov		ds,ax
			cmp		[single],TRUE		; �P�������[�h
			jz		single_note_out

			dec		[steps]
			jz		note_out_start
			ret
	note_out_start:
			mov		[steps],STEPS			; 24step �œ��삾�I
			mov		si,offset beep_note
			add		si,[xnote]
			mov		cx,80h					; 0�`80h of note.
			cld
	nout_next:
			inc		[xnote]
			cmp		[xnote],80h
			jb		nout_skip_80
			mov		[xnote],0
		nout_skip_80:
			mov		si,offset beep_note
			add		si,[xnote]
			lodsb
			or		al,al
			jnz		nout_send_freq
			loop	nout_next
			mov		[xnote_tmp],0
			beep_off						; �o�̓m�[�g�Ȃ� (beep off)
			ret
	nout_send_freq:
			mov		ax,[xnote]
			cmp		[xnote_tmp],ax			; �����Ă�̂ƃ`�F�b�N
			jz		b						; �������傾���疳���`
			mov		[xnote_tmp],ax
			
			mov		dl,12
			div		dl						; al=octv ah=note
			mov		dx,ax
			xor		bx,bx
			mov		bl,dh
			shl		bx,1
			
			cmp		[CPUCLOCK],_10MHZ
			jnz		nout_8mhz
	nout_10mhz:
			mov		ax,word ptr [freq_10mhz + bx]
			jmp		nout_freq_setok
	nout_8mhz:
			mov		ax,word ptr [freq_8mhz  + bx]
	nout_freq_setok:
			mov		cl,dl
			sub		cl,1
			jnbe	a
			mov		cl,1
	a:
			dec		cl
			shr		ax,cl
			push	ax
			beep_off
			pop		ax
			beep_set
	b:
			beep_on
			ret
note_out	endp

;---------------------------- �o�b�t�@�N���A
beep_note_init	proc
			public	beep_note_init
			beep_off
			mov		al,73h
			mov		dx,3fdfh
			out		dx,al
			out		5fh,al
			out		5fh,al
			
			push	cx
			push	di
			push	es
			push	cs
			pop		es
			mov		di,offset beep_note
			cld
			mov		cx,OCTAVE*12
			xor		al,al
			rep		stosb
			mov		[xnote],0
			mov		[steps],STEPS
			
			mov		[single_note],0
			pop		es
			pop		di
			pop		cx
			ret
beep_note_init	endp

;---------------------------- �P�������[�h
single_note_out	proc
			cmp		[single_note],0
			jnz		snout_main
			ret
	snout_main:
	jmp		snout_normal

			cmp		[single_mod_lev],0
			jz		snout_normal
			cmp		[single_mod_sync],0
			jz		snout_normal
			cmp		[single_mod_switch],TRUE
			jz		snout_mod_on

			dec		[single_mod_nowsync]
			cmp		[single_mod_nowsync],0
			jnz		snout_normal
			mov		[single_mod_switch],TRUE
	
	snout_mod_on:
			mov		ax,[single_mod_nowlevdir]
			add		[single_mod_nowlev],ax
			mov		ax,[single_mod_nowlev]
			cmp		ax,[single_mod_lev]
			jz		snout_neg
			neg		ax
			cmp		ax,[single_mod_lev]
			jz		snout_neg
			jmp		snout_normal
	snout_neg:
			neg		[single_mod_nowlevdir]

	snout_normal:
			mov		ax,[single_note]
			mov		dl,12
			div		dl						; al=octv ah=note
			mov		dx,ax
			xor		bx,bx
			mov		bl,dh
			shl		bx,1

			cmp		[CPUCLOCK],_10MHZ
			jnz		snout_8mhz
	snout_10mhz:
			mov		ax,word ptr [freq_10mhz + bx]
			jmp		snout_freq_setok
	snout_8mhz:
			mov		ax,word ptr [freq_8mhz  + bx]
	snout_freq_setok:
			mov		cl,dl
			sub		cl,2
			jnbe	bn_a
			mov		cl,1
	bn_a:
			dec		cl
			shr		ax,cl
			push	ax
;			beep_off
			pop		ax
;			add		ax,[single_mod_nowlev]
;			beep_set
			beep_on
			ret
single_note_out	endp

;---------------------------- ddn func proc.(00) ����������
;ret@ax
;	NULL	����������
;
beep_init_beepmodule	proc	far
			public	beep_init_beepmodule
			beep_off
			call	beep_note_init
			xor		ax,ax
			ret
beep_init_beepmodule	endp

;---------------------------- ddn func proc.(01) �m�[�g�I�t
;	ch		beep�`�����l��
;	bh		�m�[�g�i���o�[
;	bl		�x���V�e�B�[
;
beep_note_off	proc	far
			public	beep_note_off
			push	cs
			pop		ds
			
			cmp		[single],TRUE				; �P�������[�h
			jz		bnoff_snote_off
			
			mov		bl,bh
			xor		bh,bh
			cmp		[beep_note+bx],byte ptr 0
			jz		bnoff_exit
			dec		byte ptr [beep_note+bx]
	bnoff_exit:
			ret

;�P�����I��
	bnoff_snote_off:
			mov		bl,bh
			xor		bh,bh
;			cmp		[single_note],bx
;			jz		bnoff_snote_off_exit
			mov		[single_note],0
			beep_off
	bnoff_snote_off_exit:
			ret

beep_note_off	endp

;---------------------------- ddn func proc.(02) �m�[�g�I��
;	ch		beep�`�����l��
;	bh		�m�[�g�i���o�[
;	bl		�x���V�e�B�[
;
beep_note_on	proc	far
			public	beep_note_on
;����������
			push	cs
			pop		ds
			
			cmp		[single],TRUE				; �P�������[�h
			jz		bnon_snote_on
			
			or		bl,bl
			jz		beep_note_off
			mov		bl,bh
			xor		bh,bh
			cmp		byte ptr [beep_note+bx],127
			jnb		bnon_exit
			inc		byte ptr [beep_note+bx]
	bnon_exit:
			ret

;�P����
	bnon_snote_on:
;			cmp		[single_note],0				; ������??
;			jnz		bnon_snote_on_exit			; ����ˁ[�B
			mov		ax,[single_mod_sync]
			mov		[single_mod_nowsync],ax
			mov		ax,[single_mod_levdir]
			mov		[single_mod_nowlevdir],ax
			mov		[single_mod_switch],FALSE

			mov		bl,bh
			xor		bh,bh
			mov		[single_note],bx

			mov		ax,bx
			mov		dl,12
			div		dl						; al=octv ah=note
			mov		dx,ax
			xor		bx,bx
			mov		bl,dh
			shl		bx,1

			cmp		[CPUCLOCK],_10MHZ
			jnz		bnon_8mhz
	bnon_10mhz:
			mov		ax,word ptr [freq_10mhz + bx]
			jmp		bnon_freq_setok
	bnon_8mhz:
			mov		ax,word ptr [freq_8mhz  + bx]
	bnon_freq_setok:
			mov		cl,dl
			sub		cl,2
			jnbe	bnon_a
			mov		cl,1
	bnon_a:
			dec		cl
			shr		ax,cl
			push	ax
			beep_off
			pop		ax
			beep_set
			beep_on
	bnon_snote_on_exit:
			ret
beep_note_on	endp

;---------------------------- ddn func proc.(03) �|���t�H�j�b�N�L�[�v���b�V���[
;	ch		beep�`�����l��
;	bh		�m�[�g�i���o�[
;	bl		�v���b�V���[�l
;
beep_poly_keypress	proc	far
			public	beep_poly_keypress
			ret
beep_poly_keypress	endp

;---------------------------- ddn func proc.(04) �o���N�Z���N�g
;	ch		beep�`�����l��
;	bx		�o���N�i���o�[
;
beep_bank_select	proc	far
			public	beep_bank_select
			ret
beep_bank_select	endp

;---------------------------- ddn func proc.(05) ���W�����[�V����
;	ch		beep�`�����l��
;	bh		���W�����[�V�����f�v�X
;
beep_modulation	proc	far
			public	beep_modulation
			mov		bl,bh
			xor		bh,bh
			mov		[single_mod_lev],bx
			ret
beep_modulation	endp

;---------------------------- ddn func proc.(06) �|���^�����g�^�C��
;	ch		beep�`�����l��
;	bh		�|���^�����g�^�C��
;
beep_pol_time	proc	far
			public	beep_pol_time
			ret
beep_pol_time	endp

;---------------------------- ddn func proc.(07) �f�[�^�G���g���[
;	ch		beep�`�����l��
;	bx		RPN/NRPN�̃p�����[�^�ɑ΂���l
;
beep_data_entry	proc	far
			public	beep_data_entry
			ret
beep_data_entry	endp

;---------------------------- ddn func proc.(08) �{�����[��
;	ch		beep�`�����l��
;	bh		�{�����[��
;
beep_volume		proc	far
			public	beep_volume
			ret
beep_volume	endp

;---------------------------- ddn func proc.(09) �p���|�b�g
;	ch		beep�`�����l��
;	bh		�p���|�b�g
;
beep_panpot		proc	far
			public	beep_panpot
			ret
beep_panpot		endp

;---------------------------- ddn func proc.(0a) �G�N�X�v���b�V����
;	ch		beep�`�����l��
;	bh		�G�N�X�v���b�V����
;
beep_expression	proc	far
			public	beep_expression
			ret
beep_expression	endp

;---------------------------- ddn func proc.(0b) �z�[���h�P
;	ch		beep�`�����l��
;	bh		�z�[���h�R���g���[���l
;
beep_hold1		proc	far
			public	beep_hold1
			ret
beep_hold1		endp

;---------------------------- ddn func proc.(0c) �|���^�����g
;	ch		beep�`�����l��
;	bh		�|���^�����g�R���g���[���l
;
beep_poltament	proc	far
			public	beep_poltament
			ret
beep_poltament	endp

;---------------------------- ddn func proc.(0d) �\�X�e�k�[�g
;	ch		beep�`�����l��
;	bh		�\�X�e�k�[�g�R���g���[���l
;
beep_sostenuto	proc	far
			public	beep_sostenuto
			ret
beep_sostenuto	endp

;---------------------------- ddn func proc.(0e) �\�t�g
;	ch		beep�`�����l��
;	bh		�\�t�g�R���g���[���l
;
beep_soft		proc	far
			public	beep_soft
			ret
beep_soft		endp

;---------------------------- ddn func proc.(0f) �|���^�����g�R���g���[��
;	ch		beep�`�����l��
;	bh		�\�[�X�m�[�g�i���o�[
;
beep_pol_ctrl	proc	far
			public	beep_pol_ctrl
			ret
beep_pol_ctrl	endp

;---------------------------- ddn func proc.(10) �ėpeffect1(��ް�޾�������)
;	ch		beep�`�����l��
;	bh		�R���g���[���l
;
beep_effect1		proc	far
			public	beep_effect1
			ret
beep_effect1		endp

;---------------------------- ddn func proc.(11) �ėpeffect3(��׽��������)
;	ch		beep�`�����l��
;	bh		�R���g���[���l
;
beep_effect3		proc	far
			public	beep_effect3
			ret
beep_effect3		endp

;---------------------------- ddn func proc.(12) NRPN
;	ch		beep�`�����l��
;	bh		mm,ll�I�� 0:mm 1:ll
;	bl		�f�[�^
beep_nrpn		proc	far
			public	beep_nrpn
			ret
beep_nrpn		endp

;---------------------------- ddn func proc.(13) RPN
;	ch		beep�`�����l��
;	bh		mm,ll�I�� 0:mm 1:ll
;	bl		�f�[�^
beep_rpn			proc	far
			public	beep_rpn
			ret
beep_rpn			endp

;---------------------------- ddn func proc.(14) �v���O�����`�F���W
;	ch		beep�`�����l��
;	bh		���F�ԍ�
;
beep_prog_chg	proc	far
			public	beep_prog_chg
			ret
beep_prog_chg	endp

;---------------------------- ddn func proc.(15) �`�����l���v���b�V���[
;	ch		beep�`�����l��
;	bh		�`�����l���v���b�V���[�l
;
beep_ch_presser	proc	far
			public	beep_ch_presser
			ret
beep_ch_presser	endp

;---------------------------- ddn func proc.(16) �s�b�`�x���h�����W
;	ch		beep�`�����l��
;	bx		�s�b�`�x���h�l
;
beep_pitchbend	proc	far
			public	beep_pitchbend
			ret
beep_pitchbend	endp

;---------------------------- ddn func proc.(17) �I�[���T�E���h�I�t
;	ch		beep�`�����l��
;
beep_all_soundoff	proc	far
			public	beep_all_soundoff
			call	beep_note_init
			ret
beep_all_soundoff	endp

;---------------------------- ddn func proc.(18) �I�[�����Z�b�g�R���g���[���[
;	ch		beep�`�����l��
;
beep_all_resetctrler	proc	far
			public	beep_all_resetctrler
			call	beep_note_init
			ret
beep_all_resetctrler	endp

;---------------------------- ddn func proc.(19) �I�[���m�[�g�I�t
;	ch		beep�`�����l��
;
beep_all_noteoff	proc	far
			public	beep_all_noteoff
			call	beep_note_init
			ret
beep_all_noteoff	endp

;---------------------------- ddn func proc.(1a) OMNI OFF
;	ch		beep�`�����l��
;
beep_omni_off	proc	far
			public	beep_omni_off
			ret
beep_omni_off	endp

;---------------------------- ddn func proc.(1b) OMNI ON
;	ch		beep�`�����l��
;
beep_omni_on		proc	far
			public	beep_omni_on
			ret
beep_omni_on		endp

;---------------------------- ddn func proc.(1c) MONO
;	ch		beep�`�����l��
;	bh		MONO��
;
beep_mono		proc	far
			public	beep_mono
			ret
beep_mono		endp

;---------------------------- ddn func proc.(1d) POLY
;	ch		beep�`�����l��
;
beep_poly		proc	far
			public	beep_poly
			ret
beep_poly		endp

;---------------------------- ddn func proc.(1e) �A�N�e�B�u�Z���V���O
;
beep_active_sence	proc	far
			public	beep_active_sence
			ret
beep_active_sence	endp

;---------------------------- ddn func proc.(1f) �G�N�X�N���[�V�u���b�Z�[�W
;	es:bx	�G�N�X�N���[�V�u�f�[�^��
;	cx		����
;
beep_exclusive	proc	far
			public	beep_exclusive
			ret
beep_exclusive	endp

;---------------------------- ddn func proc.(20) �r�u���[�g�ݒ�
;	cx		���F�ԍ�
;	bh		�r�u���[�g���[�g
;	bl		�r�u���[�g�f�v�X
;	dh		�r�u���[�g�f�B���C
;
beep_vibrato		proc	far
			public	beep_vibrato
			ret
beep_vibrato		endp

;---------------------------- ddn func proc.(21) �}�X�^�[�{�����[��
;	bh		�}�X�^�[�{�����[���l
;
beep_master_volume	proc	far
			public	beep_master_volume
			ret
beep_master_volume	endp

			end

