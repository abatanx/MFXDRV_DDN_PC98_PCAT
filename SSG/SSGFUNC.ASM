;==============================================================================
; MFXDDN sound driver module
;						YAMAHA YM2203 SSG driver
;  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
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
include		ssg.inc
include		ssgfreq.inc
include		usertool.inc
include		ssgvib.inc

extrn		set_voice :near
extrn		set_volume:near
extrn		write_opnreg:near
extrn		volume_buf:word
extrn		exp_buf:word
extrn		velo_buf:word
extrn		mastervol:word
extrn		soundtbl:SSGTONE
extrn		soundtblmax:word
extrn		notestatus:byte
extrn		ssg_tone_reset:near
extrn		fnumber:word,lfo:MODTABLE

;---------------------------- ddn func proc.(00) ECM
ssg_ecm		proc	far
			public	ssg_ecm
			push	cs
			pop		ds
			
			cmp		es:[bx]  ,word ptr DRVIDNUM		; OPN.XDV�ɑ΂��Ă�ECM��?
			jz		ecm_pass1
			ret
	ecm_pass1:
			cmp		es:[bx+2],byte ptr 00h			; �����h���C�o��?
			jz		ecm_go
			ret
	ecm_go:
			mov		al,es:[bx+5]
			cmp		al,00h					; ���F�o�^��!
			jz		ecm_set_sound
			mov		al,es:[bx+5]
			cmp		al,02h					; ���W�X�^�������݂�!
			jz		ecm_set_sound
			ret
ssg_ecm		endp

;���F�o�^ ==============
ecm_set_sound	proc	far
			add		bx,6
			cmp		[soundtblmax],MAXSOUND
			jb		set_sound_ok
			ret
	set_sound_ok:
			mov		ax,type SSGTONE
			mul		[soundtblmax]
			mov		si,ax
			add		si,offset soundtbl
			mov		ax,es:[bx]
			mov		[si].banknum,ax
			mov		al,es:[bx+2]
			mov		[si].no     ,al
			add		bx,3
			mov		[si].datofs,bx
			mov		[si].datseg,es
			inc		[soundtblmax]
			ret
ecm_set_sound	endp

;���W�X�^�������� =====================
ecm_write_opnreg	proc
			mov		ah,es:[bx]
			mov		al,es:[bx+1]
			push	bx
			mov		bx,ax
			call	write_opnreg
			pop		bx
			add		bx,2
			ret
ecm_write_opnreg	endp

;---------------------------- ddn func proc.(01) �m�[�g�I�t
;	ch		opn�`�����l��
;	bh		�m�[�g�i���o�[
;
ssg_note_off	proc	far
			public	ssg_note_off
			xor		ax,ax
			mov		al,ch
			mov		si,ax
			cmp		[notestatus+si],bh
			jnz		on_off_end
			mov		[notestatus+si],0
			
			mov		bx,0800h
			add		bh,ch
			call	write_opnreg
	on_off_end:
			ret
ssg_note_off	endp

;---------------------------- ddn func proc.(02) �m�[�g�I��
;	ch		opn�`�����l��
;	bh		�m�[�g�i���o�[
;	bl		�x���V�e�B�[
;
ssg_note_on	proc	far
			public	ssg_note_on

			xor		ax,ax
			mov		al,ch
			mov		si,ax
			mov		[si+notestatus],bh
			shl		si,1
			mov		byte ptr [si+velo_buf],bl	; Velocity�o�^

			mov		bl,bh
			xor		bh,bh
			shl		bx,1
			mov		ax,[ssgfreq+bx]
			mov		[si+fnumber],ax

			mov		bh,ch
			shl		bh,1						; FREQ���V�X�^(LOW)
			mov		bl,al
			call	write_opnreg
			inc		bh							; FREQ���W�X�^(HIGH)
			mov		bl,ah
			call	write_opnreg

			mov		ah,ch
			call	ssg_tone_reset

			mov		al,type MODTABLE
			mul		ch
			mov		bx,ax
			add		bx,offset lfo
			cmp		[bx].mod_flag,MOD_NOACTIVE
			jz		ssg_non_noactive_mod
			mov		[bx].mod_flag,MOD_STANDBY
	ssg_non_noactive_mod:

			mov		ah,ch
			call	set_volume			; velocity

			ret
ssg_note_on	endp

;---------------------------- ddn func proc.(03) �|���t�H�j�b�N�L�[�v���b�V���[
;	ch		ssg�`�����l��
;	bh		�m�[�g�i���o�[
;	bl		�v���b�V���[�l
;
ssg_poly_keypress	proc	far
			public	ssg_poly_keypress
			ret
ssg_poly_keypress	endp

;---------------------------- ddn func proc.(04) �o���N�Z���N�g
;	ch		opn�`�����l��
;	bx		�o���N�i���o�[
;
ssg_bank_select	proc	far
			public	ssg_bank_select
			ret
ssg_bank_select	endp

;---------------------------- ddn func proc.(05) ���W�����[�V����
;	ch		ssg�`�����l��
;	bh		���W�����[�V�����f�v�X
;
ssg_modulation	proc	far
			public	ssg_modulation
			mov		al,type MODTABLE
			mul		ch
			add		ax,offset lfo
			mov		si,ax
			mov		[si].mod_depth,bh
			ret
			ret
ssg_modulation	endp

;---------------------------- ddn func proc.(06) �|���^�����g�^�C��
;	ch		ssg�`�����l��
;	bh		�|���^�����g�^�C��
;
ssg_pol_time	proc	far
			public	ssg_pol_time
			ret
ssg_pol_time	endp

;---------------------------- ddn func proc.(07) �f�[�^�G���g���[
;	ch		ssg�`�����l��
;	bx		RPN/NRPN�̃p�����[�^�ɑ΂���l
;
ssg_data_entry	proc	far
			public	ssg_data_entry
			ret
ssg_data_entry	endp

;---------------------------- ddn func proc.(08) �{�����[��
;	ch		ssg�`�����l��
;	bh		�{�����[��
;
ssg_volume		proc	far
			public	ssg_volume
			xor		ax,ax
			mov		al,bh
			xor		bx,bx
			mov		bl,ch
			shl		bx,1
			mov		[volume_buf+bx],ax
			
			mov		ah,ch
			call	set_volume
			ret
ssg_volume	endp

;---------------------------- ddn func proc.(09) �p���|�b�g
;	ch		ssg�`�����l��
;	bh		�p���|�b�g
;
ssg_panpot		proc	far
			public	ssg_panpot
			ret
ssg_panpot		endp

;---------------------------- ddn func proc.(0a) �G�N�X�v���b�V����
;	ch		ssg�`�����l��
;	bh		�G�N�X�v���b�V����
;
ssg_expression	proc	far
			public	ssg_expression
			xor		ax,ax
			mov		al,bh
			xor		bx,bx
			mov		bl,ch
			shl		bx,1
			mov		[exp_buf+bx],ax
			
			mov		ah,ch
			call	set_volume
			ret
ssg_expression	endp

;---------------------------- ddn func proc.(0b) �z�[���h�P
;	ch		ssg�`�����l��
;	bh		�z�[���h�R���g���[���l
;
ssg_hold1		proc	far
			public	ssg_hold1
			ret
ssg_hold1		endp

;---------------------------- ddn func proc.(0c) �|���^�����g
;	ch		ssg�`�����l��
;	bh		�|���^�����g�R���g���[���l
;
ssg_poltament	proc	far
			public	ssg_poltament
			ret
ssg_poltament	endp

;---------------------------- ddn func proc.(0d) �\�X�e�k�[�g
;	ch		ssg�`�����l��
;	bh		�\�X�e�k�[�g�R���g���[���l
;
ssg_sostenuto	proc	far
			public	ssg_sostenuto
			ret
ssg_sostenuto	endp

;---------------------------- ddn func proc.(0e) �\�t�g
;	ch		ssg�`�����l��
;	bh		�\�t�g�R���g���[���l
;
ssg_soft		proc	far
			public	ssg_soft
			ret
ssg_soft		endp

;---------------------------- ddn func proc.(0f) �|���^�����g�R���g���[��
;	ch		ssg�`�����l��
;	bh		�\�[�X�m�[�g�i���o�[
;
ssg_pol_ctrl	proc	far
			public	ssg_pol_ctrl
			ret
ssg_pol_ctrl	endp

;---------------------------- ddn func proc.(10) �ėpeffect1(��ް�޾�������)
;	ch		ssg�`�����l��
;	bh		�R���g���[���l
;
ssg_effect1		proc	far
			public	ssg_effect1
			ret
ssg_effect1		endp

;---------------------------- ddn func proc.(11) �ėpeffect3(��׽��������)
;	ch		ssg�`�����l��
;	bh		�R���g���[���l
;
ssg_effect3		proc	far
			public	ssg_effect3
			ret
ssg_effect3		endp

;---------------------------- ddn func proc.(12) NRPN
;	ch		ssg�`�����l��
;	bh		mm,ll�I�� 0:mm 1:ll
;	bl		�f�[�^
ssg_nrpn		proc	far
			public	ssg_nrpn
			ret
ssg_nrpn		endp

;---------------------------- ddn func proc.(13) RPN
;	ch		ssg�`�����l��
;	bh		mm,ll�I�� 0:mm 1:ll
;	bl		�f�[�^
ssg_rpn			proc	far
			public	ssg_rpn
			ret
ssg_rpn			endp

;---------------------------- ddn func proc.(14) �v���O�����`�F���W
;	ch		ssg�`�����l��
;	bh		���F�ԍ�
;
ssg_prog_chg	proc	far
			public	ssg_prog_chg
			mov		ah,ch
			mov		al,bh
			call	set_voice
			ret
ssg_prog_chg	endp

;---------------------------- ddn func proc.(15) �`�����l���v���b�V���[
;	ch		ssg�`�����l��
;	bh		�`�����l���v���b�V���[�l
;
ssg_ch_presser	proc	far
			public	ssg_ch_presser
			ret
ssg_ch_presser	endp

;---------------------------- ddn func proc.(16) �s�b�`�x���h�����W
;	ch		ssg�`�����l��
;	bx		�s�b�`�x���h�l
;
ssg_pitchbend	proc	far
			public	ssg_pitchbend
			ret
ssg_pitchbend	endp

;---------------------------- ddn func proc.(17) �I�[���T�E���h�I�t
;	ch		ssg�`�����l��
;
ssg_all_soundoff	proc	far
			public	ssg_all_soundoff
			ret
ssg_all_soundoff	endp

;---------------------------- ddn func proc.(18) �I�[�����Z�b�g�R���g���[���[
;	ch		ssg�`�����l��
;
ssg_all_resetctrler	proc	far
			public	ssg_all_resetctrler
			ret
ssg_all_resetctrler	endp

;---------------------------- ddn func proc.(19) �I�[���m�[�g�I�t
;	ch		ssg�`�����l��
;
ssg_all_noteoff	proc	far
			public	ssg_all_noteoff
			ret
ssg_all_noteoff	endp

;---------------------------- ddn func proc.(1a) OMNI OFF
;	ch		ssg�`�����l��
;
ssg_omni_off	proc	far
			public	ssg_omni_off
			ret
ssg_omni_off	endp

;---------------------------- ddn func proc.(1b) OMNI ON
;	ch		ssg�`�����l��
;
ssg_omni_on		proc	far
			public	ssg_omni_on
			ret
ssg_omni_on		endp

;---------------------------- ddn func proc.(1c) MONO
;	ch		ssg�`�����l��
;	bh		MONO��
;
ssg_mono		proc	far
			public	ssg_mono
			ret
ssg_mono		endp

;---------------------------- ddn func proc.(1d) POLY
;	ch		ssg�`�����l��
;
ssg_poly		proc	far
			public	ssg_poly
			ret
ssg_poly		endp

;---------------------------- ddn func proc.(1e) �A�N�e�B�u�Z���V���O
;
ssg_active_sence	proc	far
			public	ssg_active_sence
			ret
ssg_active_sence	endp

;---------------------------- ddn func proc.(1f) �G�N�X�N���[�V�u���b�Z�[�W
;	es:bx	�G�N�X�N���[�V�u�f�[�^��
;	cx		����
;
ssg_exclusive	proc	far
			public	ssg_exclusive
			ret
ssg_exclusive	endp

;---------------------------- ddn func proc.(20) �r�u���[�g�ݒ�
;	cx		���F�ԍ�
;	bh		�r�u���[�g���[�g
;	bl		�r�u���[�g�f�v�X
;	dh		�r�u���[�g�f�B���C
;
ssg_vibrato		proc	far
			public	ssg_vibrato
			ret
ssg_vibrato		endp

;---------------------------- ddn func proc.(21) �}�X�^�[�{�����[��
;	bh		�}�X�^�[�{�����[���l
;
ssg_master_volume	proc	far
			public	ssg_master_volume
			mov		byte ptr [mastervol],bh
			mov		ah,0
			call	set_volume
			mov		ah,1
			call	set_volume
			mov		ah,2
			call	set_volume
			ret
ssg_master_volume	endp

;---------------------------- ddn func proc.(21) �}�X�^�[�{�����[��
;	bh		�}�X�^�[�{�����[���l
;
opn_master_volume	proc	far
			public	opn_master_volume
			mov		byte ptr [mastervol],bh
			mov		ah,0
			call	set_volume
			mov		ah,1
			call	set_volume
			mov		ah,2
			call	set_volume
			ret
opn_master_volume	endp

;------------------------------------------------------------------
; Amplitude Modulation(Tremolo)
;
int_modulation	proc
			public	int_modulation
			mov		cx,3
			mov		bx,offset lfo
			xor		dh,dh
	modnext:
			push	cx
			push	bx
			push	dx
			mov		ch,dh
			call	modulation_main
			pop		dx
			pop		bx
			pop		cx
			inc		dh
			add		bx,type MODTABLE
			loop	modnext
			ret

	modulation_main:
			mov		al,[bx].mod_flag
			cmp		al,MOD_STANDBY
			jz		mod_standby_proc
			cmp		al,MOD_SYNC
			jz		mod_sync_proc
			cmp		al,MOD_MAIN
			jz		mod_main_proc
			ret

;----- Standby
	mod_standby_proc:
			mov		[bx].mod_flag,MOD_SYNC
			mov		ax,[bx].mod_sync
			mov		[bx].mod_sync_cnt,ax
			mov		[bx].mod_trace,0
			ret
;----- ModSync
	mod_sync_proc:
			dec		[bx].mod_sync_cnt
			jnz		mod_sync_until
			mov		[bx].mod_flag,MOD_MAIN
	mod_sync_until:
			ret
;----- ModMain
	mod_main_proc:
			mov		ax,[bx].mod_speed
			add		[bx].mod_trace,ax
			jnb		mod_main_normal
			xor		ax,ax
			jmp		mod_main_start
	mod_main_normal:
			mov		ax,[bx].mod_trace
	mod_main_start:
			mov		al,ah
			xor		ah,ah
			mov		si,ax
			mov		al,[lfo_sin_function+si]
			mov		ah,[bx].mod_depth
			imul	ah						; ax �ɁA�����l
			cwd
			mov		si,400					; ���x(100�ȏ�)
			idiv	si						; ax �ɁA���ۂ̑����l
			
			xor		bx,bx
			mov		bl,ch
			shl		bx,1
			mov		dx,[fnumber+bx]
			add		dx,ax

			add		bh,ch
			shl		bh,1
			mov		bl,dl
			call	write_opnreg

			inc		bh
			mov		bl,dh
			call	write_opnreg
			ret

int_modulation	endp

			end

