;==============================================================================
; MFXDDN sound driver module
;						YAMAHA YM2608 FM(OPNA) driver
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
include		usertool.inc
include		opna.inc
include		opnafreq.inc
include		opnavib.inc

jptable		dw	offset ecm_set_sound
			dw	offset ecm_set_revisionflag
			dw	offset ecm_write_opnreg
ECMFUNCMAX	=	3

ecmtype		db	?

;---------------------------- ddn func proc.(00) ECM
opn_ecm		proc	far
			cmp		es:[bx]  ,word ptr DRVIDNUM		; OPN.XDV�ɑ΂��Ă�ECM��?
			jz		ecm_pass1
			ret
	ecm_pass1:
			mov		al,es:[bx+2]
			mov		[ecmtype],al
	ecm_go:
			mov		al,es:[bx+5]
			add		bx,6
			
			xor		ah,ah
			cmp		ax,ECMFUNCMAX
			jnb		oe_e

			shl		ax,1
			add		ax,offset jptable
			mov		si,ax
			call	[si]
	oe_e:
			ret
opn_ecm		endp

;���F�o�^ =============================
ecm_set_sound	proc
			cmp		[soundtblmax],MAXSOUND
			jb		set_sound_ok
			ret
	set_sound_ok:
			mov		ax,type OPNTONE
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

;���ʕ␳�t���O =======================
ecm_set_revisionflag	proc
			cmp		es:[bx],byte ptr 00h
			jz		esr_false
			mov		[volumerevision],TRUE
			ret
	esr_false:
			mov		[volumerevision],FALSE
			ret
ecm_set_revisionflag	endp

;���W�X�^�������� =====================
ecm_write_opnreg	proc
			cmp		[ecmtype],00h
			jz		ewo_end
			mov		ah,es:[bx]
			mov		al,es:[bx+1]
			push	bx
			mov		bx,ax
			call	write_opnareg
			pop		bx
			add		bx,2
	ewo_end:
			ret
ecm_write_opnreg	endp

;---------------------------- ddn func proc.(01) �m�[�g�I�t
;	ch		opn�`�����l��
;	bh		�m�[�g�i���o�[
;
opn_note_off	proc	far
			xor		ax,ax
			mov		al,ch
			mov		si,ax
			cmp		[notestatus+si],bh
			jnz		on_off_end
			mov		[notestatus+si],0
			
			mov		bh,28h
			mov		bl,ch
			and		bl,0fh
			or		bl,00000100b
			call	write_opnreg
	on_off_end:
			ret
opn_note_off	endp

;---------------------------- ddn func proc.(02) �m�[�g�I��
;	ch		opn�`�����l��
;	bh		�m�[�g�i���o�[
;	bl		�x���V�e�B�[
;
opn_note_on	proc	far
			xchg	ax,bx
			xor		bx,bx
			mov		bl,ch
			mov		[bx+notestatus],ah
			mov		[bx+velo_buf],al
			xchg	ax,bx

			xor		ax,ax
			mov		al,bh
			mov		cl,12
			div		cl
			mov		dl,al					; dl < Block
			sub		dl,1					; ah < Note
			jnb		opn_non_ok
			xor		dl,dl
	opn_non_ok:
			xor		bx,bx
			mov		bl,ah
			shl		bx,1
			mov		ax,[bx+opnfreq]			; ax < Fnum
			
			mov		bh,YM2203_FNUM2
			add		bh,ch
			mov		bl,ah
			shl		dl,3
			or		bl,dl
			and		bl,00111111b
			mov		ah,bl					; �ۑ�
			call	write_opnareg

			mov		bh,YM2203_FNUM1
			add		bh,ch
			mov		bl,al
			call	write_opnareg

			xor		bx,bx
			mov		bl,ch
			mov		[bx+fnumber2],ah
			mov		[bx+fnumber1],al

			mov		bh,28h
			mov		bl,ch
			and		bl,0fh
			or		bl,00000100b
			call	write_opnreg

			mov		bh,28h
			mov		bl,ch
			or		bl,11110100b
			call	write_opnreg

			mov		al,type MODTABLE
			mul		ch
			mov		bx,ax
			add		bx,offset lfo
			cmp		[bx].mod_flag,MOD_NOACTIVE
			jz		opn_non_noactive_mod
			mov		[bx].mod_flag,MOD_STANDBY
	opn_non_noactive_mod:
			mov		ah,ch
			call	set_volume			; velocity

			ret
opn_note_on	endp

;---------------------------- ddn func proc.(03) �|���t�H�j�b�N�L�[�v���b�V���[
;	ch		opn�`�����l��
;	bh		�m�[�g�i���o�[
;	bl		�v���b�V���[�l
;
opn_poly_keypress	proc	far
			ret
opn_poly_keypress	endp

;---------------------------- ddn func proc.(04) �o���N�Z���N�g
;	ch		opn�`�����l��
;	bx		�o���N�i���o�[
;
opn_bank_select	proc	far
			ret
opn_bank_select	endp

;---------------------------- ddn func proc.(05) ���W�����[�V����
;	ch		opn�`�����l��
;	bh		���W�����[�V�����f�v�X
;
opn_modulation	proc	far
			mov		al,type MODTABLE
			mul		ch
			add		ax,offset lfo
			mov		si,ax
			mov		[si].mod_depth,bh
			ret
opn_modulation	endp

;---------------------------- ddn func proc.(06) �|���^�����g�^�C��
;	ch		opn�`�����l��
;	bh		�|���^�����g�^�C��
;
opn_pol_time	proc	far
			ret
opn_pol_time	endp

;---------------------------- ddn func proc.(07) �f�[�^�G���g���[
;	ch		opn�`�����l��
;	bx		RPN/NRPN�̃p�����[�^�ɑ΂���l
;
opn_data_entry	proc	far
			ret
opn_data_entry	endp

;---------------------------- ddn func proc.(08) �{�����[��
;	ch		opn�`�����l��
;	bh		�{�����[��
;
opn_volume		proc	far
			mov		al,bh
			xor		bx,bx
			mov		bl,ch
			mov		[bx+volume_buf],al
			
			mov		ah,ch
			call	set_volume
			ret
opn_volume	endp

;---------------------------- ddn func proc.(09) �p���|�b�g
;	ch		opn�`�����l��
;	bh		�p���|�b�g
;
opn_panpot		proc	far
			ret
opn_panpot		endp

;---------------------------- ddn func proc.(0a) �G�N�X�v���b�V����
;	ch		opn�`�����l��
;	bh		�G�N�X�v���b�V����
;
opn_expression	proc	far
			mov		al,bh
			xor		bx,bx
			mov		bl,ch
			mov		[bx+exp_buf],al
			
			mov		ah,ch
			call	set_volume
			ret
opn_expression	endp

;---------------------------- ddn func proc.(0b) �z�[���h�P
;	ch		opn�`�����l��
;	bh		�z�[���h�R���g���[���l
;
opn_hold1		proc	far
			ret
opn_hold1		endp

;---------------------------- ddn func proc.(0c) �|���^�����g
;	ch		opn�`�����l��
;	bh		�|���^�����g�R���g���[���l
;
opn_poltament	proc	far
			ret
opn_poltament	endp

;---------------------------- ddn func proc.(0d) �\�X�e�k�[�g
;	ch		opn�`�����l��
;	bh		�\�X�e�k�[�g�R���g���[���l
;
opn_sostenuto	proc	far
			ret
opn_sostenuto	endp

;---------------------------- ddn func proc.(0e) �\�t�g
;	ch		opn�`�����l��
;	bh		�\�t�g�R���g���[���l
;
opn_soft		proc	far
			ret
opn_soft		endp

;---------------------------- ddn func proc.(0f) �|���^�����g�R���g���[��
;	ch		opn�`�����l��
;	bh		�\�[�X�m�[�g�i���o�[
;
opn_pol_ctrl	proc	far
			ret
opn_pol_ctrl	endp

;---------------------------- ddn func proc.(10) �ėpeffect1(��ް�޾�������)
;	ch		opn�`�����l��
;	bh		�R���g���[���l
;
opn_effect1		proc	far
			ret
opn_effect1		endp

;---------------------------- ddn func proc.(11) �ėpeffect3(��׽��������)
;	ch		opn�`�����l��
;	bh		�R���g���[���l
;
opn_effect3		proc	far
			ret
opn_effect3		endp

;---------------------------- ddn func proc.(12) NRPN
;	ch		opn�`�����l��
;	bh		mm,ll�I�� 0:mm 1:ll
;	bl		�f�[�^
opn_nrpn		proc	far
			ret
opn_nrpn		endp

;---------------------------- ddn func proc.(13) RPN
;	ch		opn�`�����l��
;	bh		mm,ll�I�� 0:mm 1:ll
;	bl		�f�[�^
opn_rpn			proc	far
			ret
opn_rpn			endp

;---------------------------- ddn func proc.(14) �v���O�����`�F���W
;	ch		opn�`�����l��
;	bh		���F�ԍ�
;
opn_prog_chg	proc	far
			mov		ah,ch
			mov		al,bh
			call	set_voice
			ret
opn_prog_chg	endp

;---------------------------- ddn func proc.(15) �`�����l���v���b�V���[
;	ch		opn�`�����l��
;	bh		�`�����l���v���b�V���[�l
;
opn_ch_presser	proc	far
			ret
opn_ch_presser	endp

;---------------------------- ddn func proc.(16) �s�b�`�x���h�����W
;	ch		opn�`�����l��
;	bx		�s�b�`�x���h�l
;
opn_pitchbend	proc	far
			ret
opn_pitchbend	endp

;---------------------------- ddn func proc.(17) �I�[���T�E���h�I�t
;	ch		opn�`�����l��
;
opn_all_soundoff	proc	far
			xor		bx,bx
			mov		bl,ch
			mov		[notestatus+bx],0
			mov		ah,ch
			call	init_opnsound
			ret
opn_all_soundoff	endp

;---------------------------- ddn func proc.(18) �I�[�����Z�b�g�R���g���[���[
;	ch		opn�`�����l��
;
opn_all_resetctrler	proc	far
			xor		bx,bx
			mov		bl,ch
			mov		[bx+notestatus],0
			mov		[bx+volume_buf],100
			mov		[bx+exp_buf],127
			mov		[bx+velo_buf],0
			mov		ah,ch
			call	init_opnsound
			ret
opn_all_resetctrler	endp

;---------------------------- ddn func proc.(19) �I�[���m�[�g�I�t
;	ch		opn�`�����l��
;
opn_all_noteoff	proc	far
			xor		bx,bx
			mov		bl,ch
			mov		[notestatus+bx],0
			mov		ah,ch
			call	init_opnsound
			ret
opn_all_noteoff	endp

;---------------------------- ddn func proc.(1a) OMNI OFF
;	ch		opn�`�����l��
;
opn_omni_off	proc	far
			ret
opn_omni_off	endp

;---------------------------- ddn func proc.(1b) OMNI ON
;	ch		opn�`�����l��
;
opn_omni_on		proc	far
			ret
opn_omni_on		endp

;---------------------------- ddn func proc.(1c) MONO
;	ch		opn�`�����l��
;	bh		MONO��
;
opn_mono		proc	far
			ret
opn_mono		endp

;---------------------------- ddn func proc.(1d) POLY
;	ch		opn�`�����l��
;
opn_poly		proc	far
			ret
opn_poly		endp

;---------------------------- ddn func proc.(1e) �A�N�e�B�u�Z���V���O
;
opn_active_sence	proc	far
			ret
opn_active_sence	endp

;---------------------------- ddn func proc.(1f) �G�N�X�N���[�V�u���b�Z�[�W
;	es:bx	�G�N�X�N���[�V�u�f�[�^��
;	cx		����
;
opn_exclusive	proc	far
			ret
opn_exclusive	endp

;---------------------------- ddn func proc.(20) �r�u���[�g�ݒ�
;	cx		���F�ԍ�
;	bh		�r�u���[�g���[�g
;	bl		�r�u���[�g�f�v�X
;	dh		�r�u���[�g�f�B���C
;
opn_vibrato		proc	far
			ret
opn_vibrato		endp

;---------------------------- ddn func proc.(21) �}�X�^�[�{�����[��
;	bh		�}�X�^�[�{�����[���l
;
opn_master_volume	proc	far
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
			mov		dh,[bx+fnumber2]
			mov		dl,[bx+fnumber1]
			add		dx,ax

			mov		bh,YM2203_FNUM2
			add		bh,ch
			mov		bl,dh
			call	write_opnareg

			mov		bh,YM2203_FNUM1
			add		bh,ch
			mov		bl,dl
			call	write_opnareg
			ret

int_modulation	endp

			end

