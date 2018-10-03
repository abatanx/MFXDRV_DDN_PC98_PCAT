;==============================================================================
; MFXDDN sound driver module
;							beep driver for 98
;  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
			jumps
			.186
			.model	tiny
			.code

version		equ		'0.90'

include		stdio.inc
include		ddn.inc
include		option.inc
include		usertool.inc

include		beep.inc
include		beepfunc.inc

extrn		beep_note_init:near

			org		100h
start:
			jmp		short com_start

;------------------------------------------------------------------------------
; �h���C�o�[�X�e�[�^�X�e�[�u�� ddn.inc �ɏ���
;
org	DRVTYPE	
				dtype		dw	NORMAL_DEVICE
org	DRVID
				did			db	'BEEP           ',00h
org	DRVINIT
				dinit		dw	offset driver_init
org	DRVEND
				dend		dw	offset driver_end
org	DRVPLAY
				dplay		dw	offset driver_play
org	DRVSTOP
				dstop		dw	offset driver_stop
org	DRVINT
				dint		dw	offset driver_timer_interrupt
org	DRVCH
				dch			db	1
org	DRVUSECH
				dusech		db	1
org	DRVVERINT
				dverint		db	0
org	DRVVERREAL
				dverreal	db	90
org	DRVINSTMSG
				dw			offset dinstmsg
org	DRVUSEMSG
				dw			offset dusemsg
org	DRVFUNC	
;----------------- controll ---------------------------------------------------
				dw			NULL
				dw			offset beep_note_off
				dw			offset beep_note_on
				dw			offset beep_poly_keypress
				dw			offset beep_bank_select
				dw			offset beep_modulation
				dw			offset beep_pol_time
				dw			offset beep_data_entry
				dw			offset beep_volume
				dw			offset beep_panpot
				dw			offset beep_expression
				dw			offset beep_hold1
				dw			offset beep_poltament
				dw			offset beep_sostenuto
				dw			offset beep_soft
				dw			offset beep_pol_ctrl
				dw			offset beep_effect1
				dw			offset beep_effect3
				dw			offset beep_nrpn
				dw			offset beep_rpn	
				dw			offset beep_prog_chg
				dw			offset beep_ch_presser
				dw			offset beep_pitchbend
				dw			offset beep_all_soundoff
				dw			offset beep_all_resetctrler
				dw			offset beep_all_noteoff
				dw			offset beep_omni_off
				dw			offset beep_omni_on
				dw			offset beep_mono
				dw			offset beep_poly
				dw			offset beep_active_sence
				dw			offset beep_exclusive
				dw			offset beep_vibrato
				dw			offset beep_master_volume
;------------------------------------------------------------------------------
.data
dinstmsg	db	'[32mPC98[33m BEEP sound driver[m version ',version,CR
			db	'copyright (c) 1993 ABA / T.Kobayashi and Interfair '
			db	'All Rights Reserved.',CR,'$'
dusemsg		db	'BEEP�����ŉ��t�\�������! '
			db	'SingleMode['
dusemsg_single	db	'x'
			db	']$'

				even

CPUCLOCK	dw		?				; CPU����N���b�N
single		dw		FALSE			; �P�������[�h
public		CPUCLOCK,single

.code
;------------------------------------------------------------------------------
;�펞���荞�ݕ���
driver_timer_interrupt	proc	far
extrn		note_out:near
			call	note_out
			ret
driver_timer_interrupt	endp

;------------------------------------------------------------------------------
;�t�@���N�V�����G���[
beep_func_error	proc	far
			ret
beep_func_error	endp

;------------------------------------------------------------------------------
;�c�n�r���荞�ݎ��ɕ\�����郁�b�Z�[�W
com_start	proc
			mov		ax,cs
			mov		ds,ax
			_print	dinstmsg
			_print	usage
.data
usage		db	'Usage  ; ',CR
			db	'         mld.exe beep.xdv [option...]',CR
optionlist	db	'Option ; ',CR
			db	'         /ch=x     �����Ɏg�p�ł���`�����l���� x�ɂ��܂�(DEF:1)',CR
			db	'         /id=xxxx  DRIVER-ID ��ύX���܂�(DEF:BEEP)',CR
			db	'         /s        �P�������[�h',CR
			db	'         /?        �I�v�V������\�����܂�',CR
			db	CR
			db	'$'
.code
			_exit	NULL
com_start	endp

;------------------------------------------------------------------------------
;�h���C�o�[����I��������
driver_end	proc	far			; DDN �ďo�Ȃ̂� FAR CALL
			call	beep_init
			ret
driver_end	endp

;------------------------------------------------------------------------------
;�풓���Ɏ��s����h���C�o�[������
driver_init	proc	far
			push	es
			xor		ax,ax
			mov		es,ax
			mov		al,es:[501h]			; CLOCK mode
			test	es:[500h],byte ptr 1
			pop		es
			jnz		beep_canuse
			xor		ax,ax
			ret
	beep_canuse:
			test	al,80h					; CLOCK check
			jnz		di_8mhz
	di_10mhz:
			mov		[CPUCLOCK],_10MHZ
			jmp		di_ok
	di_8mhz:
			mov		[CPUCLOCK],_8MHZ
	di_ok:
			call	beep_note_init
			call	beep_init

;���I�v�V�����̂��������` =============================
;�� USAGE
			option	'?',NO_PARAM,@@1,error_opt
			_print	usage
			mov		ax,NULL
			ret

;�� /ID �I�v�V�����̃`�F�b�N�Ł[�[���B----------------
	@@1:
			option	'id',STR_PARAM,@@2,error_opt
			push	ds
			mov		ax,es
			mov		ds,ax
			mov		ax,cs
			mov		es,ax
			mov		si,bx
			mov		di,offset did

			mov		cx,15
			cld
			mov		al,' '
			rep		stosb
			
			mov		di,offset did
			mov		cx,15
	@@1loop:
			lodsb
			or		al,al
			jz		@@1end
			stosb
			loop	@@1loop
	@@1end:
			pop		ds
			_puts	'DRIVER-ID ��ύX���܂����B'

;�� /CH �I�v�V�����̃`�F�b�N�Ł[�[���B----------------
	@@2:
			option	'ch',VALUE_PARAM,@@3,error_opt
			mov		[dch]   ,al
			mov		[dusech],al
			_puts	'�g�p�\�`�����l������ύX���܂����B'

;�� /S �I�v�V�����̃`�F�b�N�Ł[�[���B----------------
	@@3:
			option	's',NO_PARAM,@@4,error_opt
			mov		[single],TRUE
			_puts	'�P�������[�h�ɐݒ肵�܂����B'
			mov		[dch],1
			mov		[dusech],1
			mov		[dusemsg_single],'o'
			jmp		@@4

;�� �I�v�V��������[�[�[�[�[�[       ----------------
	error_opt:
			_print	optionlist

	@@4:
			xor		ax,ax
			mov		al,[dch]
			ret
driver_init	endp

;------------------------------------------------------------------------------
;���t�J�n���Ɏ��s����Ƃ�
driver_play	proc	far			; DDN�ďo�Ȃ̂� FAR CALL
			call	beep_note_init
			call	beep_init
			ret
driver_play	endp

;------------------------------------------------------------------------------
;���t�I�����Ɏ��s����Ƃ�
driver_stop	proc	far			; DDN�ďo�Ȃ̂� FAR CALL
			call	beep_note_init
			call	beep_init
			ret
driver_stop	endp

;------------------------------------------------------------------------------
;BEEP������
beep_init	proc
			beep_off
			push	ds
			push	cs
			pop		ds
			cmp		[CPUCLOCK],_8MHZ
			jz		bi_8mhz
	bi_10mhz:
			mov		ax,1229
			jmp		bi_set
	bi_8mhz:
			mov		ax,998
	bi_set:
			beep_set
			pop		ds
			ret
beep_init	endp

			end		start

revision	version		comment
1.1			0.01		�Ƃ肠��������
1.2			0.02		8MHz���[�h�ǉ��B/ID /? �I�v�V�����ǉ��B
