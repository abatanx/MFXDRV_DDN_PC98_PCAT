;==============================================================================
; MFXDDN sound driver module
;						YAMAHA YM2608 FM(OPNA) driver
;  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
			jumps
			.186
			.model	tiny
			.code

include		stdio.inc
include		ddn.inc
include		option.inc
include		usertool.inc
include		opna.inc

			.code
			assume	cs:@code,ds:@code
			org		100h
start:
			jmp		near ptr com_start

;------------------------------------------------------------------------------
; �h���C�o�[�X�e�[�^�X�e�[�u�� ddn.inc �ɏ���
;
org	DRVTYPE	
				dtype		dw	NORMAL_DEVICE
org	DRVID
				did			db	'OPNA           ',00h
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
				dch			db	3
org	DRVUSECH
				dusech		db	3
org	DRVVERINT
				dverint		db	ver_int
org	DRVVERREAL
				dverreal	db	ver_real
org	DRVINSTMSG
				dw			offset dinstmsg
org	DRVUSEMSG
				dw			offset dusemsg
org	DRVFUNC	
;----------------- controll ---------------------------------------------------
				dw			offset opn_ecm
				dw			offset opn_note_off
				dw			offset opn_note_on
				dw			offset opn_poly_keypress
				dw			offset opn_bank_select
				dw			offset opn_modulation
				dw			offset opn_pol_time
				dw			offset opn_data_entry
				dw			offset opn_volume
				dw			offset opn_panpot
				dw			offset opn_expression
				dw			offset opn_hold1
				dw			offset opn_poltament
				dw			offset opn_sostenuto
				dw			offset opn_soft
				dw			offset opn_pol_ctrl
				dw			offset opn_effect1
				dw			offset opn_effect3
				dw			offset opn_nrpn
				dw			offset opn_rpn	
				dw			offset opn_prog_chg
				dw			offset opn_ch_presser
				dw			offset opn_pitchbend
				dw			offset opn_all_soundoff
				dw			offset opn_all_resetctrler
				dw			offset opn_all_noteoff
				dw			offset opn_omni_off
				dw			offset opn_omni_on
				dw			offset opn_mono
				dw			offset opn_poly
				dw			offset opn_active_sence
				dw			offset opn_exclusive
				dw			offset opn_vibrato
				dw			offset opn_master_volume
;------------------------------------------------------------------------------
				even
.data

even
volume_buf		db		3 dup(?)
exp_buf			db		3 dup(?)
velo_buf		db		3 dup(?)
notestatus		db		3 dup(?)
mastervol		db		?
volumerevision	db		?
fnumber1		db		3 dup(?)
fnumber2		db		3 dup(?)
lfo			MODTABLE	3 dup(?)
OPNAPORT1		dw		?
OPNAPORT2		dw		?
OPNPORT1		dw		?
OPNPORT2		dw		?

even
soundtblmax		dw			?
soundtbl		OPNTONE		MAXSOUND dup(?)

dinstmsg	db	'[32mPC98[36m YAMAHA YM2608(OPNA) driver[m version '
			db	'0'+ver_int,'.','0'+ver_real/10,'0'+ver_real mod 10,ver_char,CR
			db	'copyright (c) 1994 ABA / T.Kobayashi and Interfair '
			db	'All Rights Reserved.',CR,'$'
dusemsg		db	'OPNA �ŉ��t�\�ł� OPNA.XDV ver.'
			db	'0'+ver_int,'.','0'+ver_real/10,'0'+ver_real mod 10,ver_char,CR
			db	'$'

.code

;------------------------------------------------------------------------------
;�펞���荞�ݕ���
driver_timer_interrupt	proc	far
			call	int_modulation
			ret
driver_timer_interrupt	endp

;------------------------------------------------------------------------------
;�t�@���N�V�����G���[
opn_func_error	proc	far
			ret
opn_func_error	endp

;------------------------------------------------------------------------------
;�h���C�o�[����I��������
driver_end	proc	far				; MLD �Ăяo���� FAR ����B
			mov		ah,0
			call	init_opnsound
			mov		ah,1
			call	init_opnsound
			mov		ah,2
			call	init_opnsound

			mov		bh,29h
			mov		bl,03h
			call	write_opnreg

			mov		dx,0a460h
			mov		al,0
			out		dx,al

			ret
driver_end	endp

;------------------------------------------------------------------------------
;�풓���Ɏ��s����h���C�o�[������
driver_init	proc	far				; MLD �Ăяo���� FAR ����B
			mov		ax,cs
			mov		ds,ax

			mov		OPNPORT1,188h
			mov		OPNPORT2,18ah
			mov		OPNAPORT1,18ch
			mov		OPNAPORT2,18eh

;�I�v�V�����`�F�b�N=====
; /io=xxxxh
			option	'io',VALUE_PARAM,@fast1,error_opt
			mov		OPNPORT1,ax
			add		ax,2
			mov		OPNPORT2,ax
; /io2=xxxxh
	@fast1:
			option	'io2',VALUE_PARAM,@fast2,error_opt
			mov		OPNAPORT1,ax
			add		ax,2
			mov		OPNAPORT2,ax
; /id=xxxx
	@fast2:
			option	'id',STR_PARAM,@fast,error_opt
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
	@@2loop:
			lodsb
			or		al,al
			jz		@@2end
			stosb
			loop	@@2loop
	@@2end:
			pop		ds
			_puts	'DRIVER-ID ��ύX���܂����B'
			jmp		@fast

	error_opt:
			_puts	'�p�����[�^���Ⴂ�܂��B'
	@fast:
			call	check_opn		; OPN�`�F�b�N
			jb		not_stay_opna	; OPNA�Ȃ��B���[�B

			mov		bh,0ffh
			call	read_opnreg
			cmp		al,1
			jnz		not_stay_opna

			mov		dx,0a460h
			mov		al,1
			out		dx,al

			mov		bh,29h
			mov		bl,83h
			call	write_opnreg

			mov		ah,0
			call	init_opnsound	; OPN������
			mov		ah,1
			call	init_opnsound	; OPN������
			mov		ah,2
			call	init_opnsound	; OPN������
			jb		not_stay_opna

			_put	'YM2608(YM2203�݊���) I/O port ['
			puthex_16reg	OPNPORT1
			_put	'h/'
			puthex_16reg	OPNPORT2
			_puts	'h]'
			_put	'YM2608(OPN�g����)    I/O port ['
			puthex_16reg	OPNAPORT1
			_put	'h/'
			puthex_16reg	OPNAPORT2
			_puts	'h] ���g�p���܂��B'

			mov		ax,3			; 3 Channel
			ret
	not_stay_opna:
			mov		ax,0
			ret
driver_init	endp

;OPN�̃`�F�b�N
check_opn	proc
			mov		cx,10000		; 1���񂿂������`
	lp_co:
			mov		dx,OPNPORT1
			in		al,dx
			cmp		al,0ffh
			jnz		stay_opn
			loop	lp_co
			stc
			ret
	stay_opn:
			clc
			ret
check_opn	endp

;------------------------------------------------------------------------------
;���t�J�n���Ɏ��s����Ƃ�
driver_play	proc	far			; DDN�ďo�� FAR ����
			mov		ah,0
			call	init_opnsound
			mov		ah,1
			call	init_opnsound
			mov		ah,2
			call	init_opnsound
			call	init_opnbuf
			ret
driver_play	endp

;------------------------------------------------------------------------------
;���t�I�����Ɏ��s����Ƃ�
driver_stop	proc	far			; DDN�ďo�� FAR ����
			mov		ah,0
			call	init_opnsound
			mov		ah,1
			call	init_opnsound
			mov		ah,2
			call	init_opnsound
			ret
driver_stop	endp

;------------------------------------------------------------------------------
;�c�n�r����̎��s���ɕ\�����郁�b�Z�[�W
com_start	proc
			mov		ax,cs
			mov		ds,ax
			_print	dinstmsg
			_print	usage
.data
usage		db	'Usage  ; ',CR
			db	'         mld.exe opn.xdv [option...]',CR
optionlist	db	'Option ; ',CR
			db	'         /io =xxxxH YM2203�T�E���h�{�[�h��I/O�A�h���X�w��(DEF:188h)',CR
			db	'         /io2=xxxxH YM2608�T�E���h�|�[�g��I/O�A�h���X�w��(DEF:18ch)',CR
			db	'         /id=xxxx   DRIVER-ID�ύX(DEF:OPNA)',CR
			db	CR
			db	'$'
.code
			_exit	NULL
com_start	endp

			end		start
