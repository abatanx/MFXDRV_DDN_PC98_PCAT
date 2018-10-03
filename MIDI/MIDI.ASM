;==============================================================================
; MFXDDN sound driver module
;						MIDI Interface driver for 98
;  copyright (c) 1993 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
			jumps
			.186
			.model	tiny
			.code

include		stdio.inc
include		ddn.inc
include		option.inc
include		usertool.inc

MPU_SYSIO	equ		TRUE
public		MPU_STATUS,MPU_COMMAND,MPU_DATA
include		midi.inc
include		miditerm.inc
include		midifunc.inc


			org		100h
start:
			jmp		short com_start

disenable	equ		0
enable		equ		1

rs232c		=		disenable

;------------------------------------------------------------------------------
; �h���C�o�[�X�e�[�^�X�e�[�u�� ddn.inc �ɏ���
;
org	DRVTYPE	
				dtype		dw	NORMAL_DEVICE
org	DRVID
				did			db	'MIDI           ',00h
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
				dch			db	16
org	DRVUSECH
				dusech		db	16
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
				dw			offset NULL
				dw			offset midi_note_off
				dw			offset midi_note_on
				dw			offset midi_poly_keypress
				dw			offset midi_bank_select
				dw			offset midi_modulation
				dw			offset midi_pol_time
				dw			offset midi_data_entry
				dw			offset midi_volume
				dw			offset midi_panpot
				dw			offset midi_expression
				dw			offset midi_hold1
				dw			offset midi_poltament
				dw			offset midi_sostenuto
				dw			offset midi_soft
				dw			offset midi_pol_ctrl
				dw			offset midi_effect1
				dw			offset midi_effect3
				dw			offset midi_nrpn
				dw			offset midi_rpn	
				dw			offset midi_prog_chg
				dw			offset midi_ch_presser
				dw			offset midi_pitchbend
				dw			offset midi_all_soundoff
				dw			offset midi_all_resetctrler
				dw			offset midi_all_noteoff
				dw			offset midi_omni_off
				dw			offset midi_omni_on
				dw			offset midi_mono
				dw			offset midi_poly
				dw			offset midi_active_sence
				dw			offset midi_exclusive
				dw			offset midi_vibrato
				dw			offset midi_master_volume
;------------------------------------------------------------------------------
.data
dinstmsg	db	'[32mPC98[36m MIDI interface driver(MPU/RS232C) for GS/GM module [mversion '
			db	'0'+ver_int,'.','0'+ver_real/10,'0'+ver_real mod 10,ver_char,CR
			db	'copyright (c) 1993-94 ABA / T.Kobayashi and Interfair'
			db	' All Rights Reserved.',CR,'$'
dusemsg		db	'MIDI �ŉ��t�\�ł� MIDI.XDV ver.'
			db	'0'+ver_int,'.','0'+ver_real/10,'0'+ver_real mod 10,ver_char,CR
			db	'$'

					even
INTERFACE			dw	?
MODULE				dw	?

rs232c_interrupt	label	dword
rs232c_ofs			dw	?
rs232c_seg			dw	?

mpu_interrupt		label	dword
mpu_ofs				dw	?
mpu_seg				dw	?

MPU_STATUS			dw		0e0d2h		; MPU��I/O�A�h���X
MPU_COMMAND			dw		0e0d2h
MPU_DATA			dw		0e0d0h
MPU_INT				dw		0eh			; �f�t�H���g INT �x�N�^
MPU_INTEOI			dw		26h			; MPU-EOI

; �l�h�c�h���t�f�[�^�o�b�t�@
if	MIDI_BUFFERING	EQ	TRUE
				even
midi_databuf	db	datasiz dup(?)			; �f�[�^�o�b�t�@

				even
midi_datalen	dw	?						; ���݂̃f�[�^��
midi_dataadr	dw	?						; ���݂̃f�[�^�A�h���X
midi_datawrt	dw	?						; �������݃f�[�^�A�h���X

public			midi_databuf
public			midi_datalen
public			midi_dataadr
public			midi_datawrt
endif

progchg			dw	TRUE					; �v���O�����`�F���W�t���O
public			progchg
volume_buf		dw	16 dup(?)				; �{�����[���o�b�t�@
mastervol_buf	dw	?						; master�{�����[���o�b�t�@
public			volume_buf
public			mastervol_buf
public			INTERFACE,MODULE

.code
;------------------------------------------------------------------------------
; EOI ���s
put_eoi		proc
			pushf
			push	ax
			cli
			mov		al,byte ptr cs:[MPU_INTEOI]
			out		00h,al
			out		5fh,al
			out		5fh,al
			pop		ax
			popf
			ret
put_eoi		endp

;------------------------------------------------------------------------------
;MPU Interrupt
mpu_interrupt_prg	proc
			call	put_eoi
			iret
mpu_interrupt_prg	endp

;------------------------------------------------------------------------------
;�펞���荞�ݕ���
driver_timer_interrupt	proc	far
	if MIDI_BUFFERING EQ TRUE
			call	midi_send
	endif
			ret
driver_timer_interrupt	endp

;------------------------------------------------------------------------------
;�c�n�r���荞�ݎ��ɕ\�����郁�b�Z�[�W
com_start	proc
			mov		ax,cs
			mov		ds,ax
			_print	dinstmsg
			_print	usage
.data
usage		db	'Usage  ; ',CR
			db	'         mld.exe midi.xdv [option...]',CR
optionlist	db	'Option ; ',CR
			db	'         /mpu      MPU   ���g�p���܂�',CR
			db	'         /rs       RS232C���g�p���܂�',CR
			db	'         /gs       GS�������g�p���܂�',CR
			db	'         /gm       GM�������g�p���܂�',CR
			db	'         /io=xxxxH MPU ��I/O�A�h���X���w�肵�܂�(DEF:E0D0H)',CR
			db	'         /int=xxH  MPU ��INT�x�N�^���w�肵�܂�  (DEF:02H)',CR
			db	'         /id=xxxx  DRIVER-ID ��ύX���܂�(DEF:MIDI)',CR
			db	'         /p        Piano ���t���[�h',CR
			db	'         /?        �I�v�V������\�����܂�',CR
			db	CR
			db	'$'
.code
			_exit	NULL
com_start	endp

;------------------------------------------------------------------------------
;�h���C�o�[����I��������
driver_end	proc	far			; DDN �ďo�Ȃ̂� FAR CALL
			push	ds
			push	dx
			mov		ax,cs
			mov		ds,ax
			cmp		[INTERFACE],RS232C_INTERFACE
			jz		de_end

			mov		al,0ffh
			call	send_mpucmd
			
			pushf
			cli
			mov		ah,25h
			mov		al,byte ptr [MPU_INT]
			mov		dx,cs:[mpu_ofs]
			mov		ds,cs:[mpu_seg]
			int		21h
			popf
			
	de_end:
			pop		dx
			pop		ds
			ret
driver_end	endp

;------------------------------------------------------------------------------
;�풓���Ɏ��s����h���C�o�[������
driver_init	proc	far
	; �f�[�^�o�b�t�@�̏�����
			call	init_databuf

;���I�v�V�����̂��������` =============================
;�� USAGE
			option	'?',NO_PARAM,@@p,error_opt
			_print	usage
			mov		ax,NULL
			ret

;�� /P �I�v�V�����̃`�F�b�N�Ł[�[���B----------
	@@p:
			option	'p',NO_PARAM,@@int,error_opt
			mov		[progchg],FALSE
			_puts	'���ׂ� Piano �ŉ��t���܂��B'

;�� /INT �I�v�V�����̃`�F�b�N�Ł[�[���B----------
	@@int:
			option	'int',VALUE_PARAM,@@io,error_opt
			cmp		ax,3
			jb		@@int_param_ok
			_puts	'INT�̃p�����[�^���Ⴂ�܂��B'
			jmp		error_opt
			
	@@int_param_ok:
			cmp		ax,0
			jnz		@@int_int1
			mov		ax,0bh
			mov		bx,23h
			jmp		@@int_set
		@@int_int1:
			cmp		ax,1
			jnz		@@int_int2
			mov		ax,0dh
			mov		bx,25h
			jmp		@@int_set
		@@int_int2:
			mov		ax,0eh
			mov		bx,26h
		@@int_set:
			mov		[MPU_INT   ],ax
			mov		[MPU_INTEOI],bx
			_puts	'MPU �� ���荞�݃��x����ύX���܂����B'

;�� /IO:xxxxH �I�v�V�����̃`�F�b�N�Ł[�[���B----------
	@@io:
			option	'io',VALUE_PARAM,@@id,error_opt
			mov		[MPU_DATA],ax
			add		ax,2
			mov		[MPU_STATUS],ax
			mov		[MPU_COMMAND],ax
			_puts	'MPU �� I/O �A�h���X��ύX���܂����B'

;�� /ID �I�v�V�����̃`�F�b�N�Ł[�[���B----------------
	@@id:
			option	'id',STR_PARAM,@@gm,error_opt
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

; �� /GM�I�v�V�����`�F�b�N
	@@gm:
			option	'gm',NO_PARAM,@@gs,error_opt
			mov		[MODULE],GM_MODULE
			_puts	'GM�������g�p���܂��B'
			jmp		@@mpu

; �� /GS�I�v�V�����`�F�b�N ---------------------------
	@@gs:
			option	'gs',NO_PARAM,@@notgmgs,error_opt
	set_gs:
			mov		[MODULE],GS_MODULE
			_puts	'GS�������g�p���܂��B'
			jmp		@@mpu

; �� /GS , /GM �I�v�V�����w��Ȃ�
	@@notgmgs:
			jmp		set_gs

;�� /MPU�I�v�V�����̃`�F�b�N�Ł[�[���B----------------
	@@mpu:
			option	'mpu',NO_PARAM,@@rs,error_opt
			jmp		mpu_int

;�� /RS �I�v�V�����̃`�F�b�N�Ł[�[���B----------------
	@@rs:
			option	'rs',NO_PARAM,@@etc,error_opt
			jmp		rs_int
; ���̑��`
	@@etc:
			jmp		normal_check_interface

;�� �I�v�V��������[�[�[�[�[�[       ----------------
	error_opt:
			_print	optionlist

	; MPU98-II �Ƃ��̃{�[�h���������Ă邩�`�F�b�N����̂���
	normal_check_interface:
	mpu_int:
			call	check_mpu_interface
			or		ax,ax
			jnz		mpu_cant_find
			_put	'MPU401�݊�'
			mov		bx,MPU_INTERFACE
			jmp		midi_ok

	; MPU���G���[�Ȃ̂ˁ`�B232C�ɂ͂₪���
	mpu_cant_find:
	rs_int:
			call	check_rs232c_interface
			or		ax,ax
			jnz		cant_use_midi
			_put	'RS-232C '
			mov		bx,RS232C_INTERFACE
			jmp		midi_ok

	cant_use_midi:
	; ���H����Ȃ��B
			_puts	'RS-232C �� MIDI�������ڑ�����Ă��܂���B'
			mov		ax,0
			ret
	
midi_ok:
			push	cs
			pop		ds
			mov		[INTERFACE],bx
			_puts	'Interface ���g�p���܂��B'
			cmp		[INTERFACE],RS232C_INTERFACE
			jz		di_end
			_put	'MPU I/O port ['
			puthex_16reg	[MPU_DATA]
			_put	'h/'
			puthex_16reg	[MPU_COMMAND]
			_puts	'h]'
			
			_put	'MPU Interrupt level ['
			cmp		[MPU_INT],0bh
			jnz		not_ir0
			_put	'IR3(INT0)'
			jmp		mo_nex
	not_ir0:
			cmp		[MPU_INT],0dh
			jnz		not_ir1
			_put	'IR5(INT1)'
			jmp		mo_nex
	not_ir1:
			_put	'IR6(INT2)'
	mo_nex:
			_puts	']'

			pushf
			cli
			mov		ah,35h
			mov		al,byte ptr [MPU_INT]
			int		21h
			mov		[mpu_ofs],bx
			mov		[mpu_seg],es
			
			mov		ah,25h
			mov		al,byte ptr [MPU_INT]
			mov		dx,offset mpu_interrupt_prg
			int		21h
			popf
			
	di_end:
			mov		ax,16
			ret
driver_init	endp

;------------------------------------------------------------------------------
;���t�J�n���Ɏ��s����Ƃ�
driver_play	proc	far			; DDN�ďo�Ȃ̂� FAR CALL
			push	ds
			push	si
			mov		ax,cs
			mov		ds,ax
			call	init_databuf
			cmp		[MODULE],GM_MODULE
			jz		dp_gm_buf
			mov		si,offset gs_initialize
			jmp		gp_send_start
	dp_gm_buf:
			mov		si,offset gm_initialize
	gp_send_start:
			call	send_initialize
			mov		si,offset global_initialize
			call	send_initialize
			pop		si
			pop		ds
			ret
	.data
gs_initialize:
			db	0f0h, 41h, 10h, 42h, 12h, 40h, 00h, 7fh, 00h, 41h,0f7h	; GS ON
			db	0feh, 0feh
gm_initialize:
			db	0f0h, 7eh, 7fh, 09h, 01h, 0f7h							; GM ON
			db	0feh, 0feh
global_initialize:
			db	0b0h, 7bh, 00h,0b0h, 78h, 00h,0b0h, 79h, 00h
			db	0b1h, 7bh, 00h,0b1h, 78h, 00h,0b1h, 79h, 00h
			db	0b2h, 7bh, 00h,0b2h, 78h, 00h,0b2h, 79h, 00h
			db	0b3h, 7bh, 00h,0b3h, 78h, 00h,0b3h, 79h, 00h
			db	0b4h, 7bh, 00h,0b4h, 78h, 00h,0b4h, 79h, 00h
			db	0b5h, 7bh, 00h,0b5h, 78h, 00h,0b5h, 79h, 00h
			db	0b6h, 7bh, 00h,0b6h, 78h, 00h,0b6h, 79h, 00h
			db	0b7h, 7bh, 00h,0b7h, 78h, 00h,0b7h, 79h, 00h
			db	0b8h, 7bh, 00h,0b8h, 78h, 00h,0b8h, 79h, 00h
			db	0b9h, 7bh, 00h,0b9h, 78h, 00h,0b9h, 79h, 00h
			db	0bah, 7bh, 00h,0bah, 78h, 00h,0bah, 79h, 00h
			db	0bbh, 7bh, 00h,0bbh, 78h, 00h,0bbh, 79h, 00h
			db	0bch, 7bh, 00h,0bch, 78h, 00h,0bch, 79h, 00h
			db	0bdh, 7bh, 00h,0bdh, 78h, 00h,0bdh, 79h, 00h
			db	0beh, 7bh, 00h,0beh, 78h, 00h,0beh, 79h, 00h
			db	0bfh, 7bh, 00h,0bfh, 78h, 00h,0bfh, 79h, 00h
			db	0ffh
	.code
driver_play	endp

;------------------------------------------------------------------------------
;���t�I�����Ɏ��s����Ƃ�
driver_stop	proc	far			; DDN�ďo�Ȃ̂� FAR CALL
			push	ds
			push	si
			mov		ax,cs
			mov		ds,ax
			call	init_databuf
			mov		si,offset global_initialize
			call	send_initialize
			pop		si
			pop		ds
			ret
driver_stop	endp

;------------------------------------------------------------------------------
;��̃f�[�^�����育��o�͂���Ƃ�
send_initialize		proc
			cld
	si_next_ent:
			lodsb
			cmp		al,0ffh
			jz		si_exit
			cmp		al,0feh
			jz		si_wait_x
			call	midi_out
			jmp		si_next_ent
	si_wait_x:
			mov		cx,10000
	si_wait:
			out		5fh,al
			out		5fh,al
			out		5fh,al
			out		5fh,al
			out		5fh,al
			loop	si_wait
			jmp		si_next_ent
	si_exit:
			call	midi_send
			ret
send_initialize		endp

;================================================================== procedure =
;------------------------------------------------------------------------------
; MPU98-II �Ƃ��A���̌݊��{�[�h���������Ă���ANULL ��������
send_mpucmd	proc
			push	ax
			mov		cx,32767
	smx_DRR_wait:
			mov		dx,[MPU_STATUS]
			in		al,dx
			test	al,DRR
			jz		smx_DRR_ok
			out		5fh,al			; wait
			out		5fh,al			; wait
			loop	smx_DRR_wait
			pop		ax
			jmp		smx_timeout
	smx_DRR_ok:
			pop		ax
			mov		dx,[MPU_COMMAND]
			out		dx,al
				rept	5
				out		5fh,al
				endm
	
	smx_get_ACK:
			mov		cx,32767
	smx_DSR_wait:
			mov		dx,[MPU_STATUS]
			in		al,dx
			test	al,DSR
			jz		smx_DSR_ok
			out		5fh,al
			out		5fh,al
			loop	smx_DSR_wait
			jmp		smx_timeout
	smx_DSR_ok:
			mov		dx,[MPU_DATA]
			in		al,dx
			cmp		al,MPU_ACK
			jz		smx_ACK_ok
			int		MPU_INTERRUPT
			jmp		smx_get_ACK
	smx_ACK_ok:
			out		5fh,al
			out		5fh,al
			out		5fh,al
			clc
			ret
	smx_timeout:
			stc
			ret
send_mpucmd	endp

check_mpu_interface	proc
			pushf
			mov		cx,16384
mpu_board_check:
			mov		dx,[MPU_STATUS]
			in		al,dx
			test	al,DRR
			jz		mpu_interface_ok
			mov		dx,[MPU_DATA]
			in		al,dx
			out		5fh,al
			out		5fh,al
			loop	mpu_board_check
			jmp		mpu_timeout

	mpu_interface_ok:

	;MPU�����Z�b�g����
			mov		al,0ffh
			call	send_mpucmd
			jb		mpu_timeout
	;UART����
			mov		al,03fh
			call	send_mpucmd

			mov		ax,NULL
			popf
			ret

	;---- MPU �^�C���A�E�g
mpu_timeout:
			mov		ax,EOF
			popf
			ret

check_mpu_interface	endp

;------------------------------------------------------------------------------
; RS-232C �� MIDI �ł��邩�A�`�F�b�N����B�ł���Ȃ�ANULL ��������
check_rs232c_interface	proc
			pushf
			cli
			in		al, 35h
			out		5fh,al
			out		5fh,al
			out		5fh,al
			and		al,0f8h					;����M���荞�݋֎~
			out		35h, al
			
;�ʐM���x��ݒ肷��
			push	es
			xor		ax,ax
			mov		es,ax
			mov		al,es:[0501h]
			pop		es
			_put	'RS-232C �ʐM���x��'
			test	al,80h
			jz		CLOCK10
	CLOCK8:
			;8MHz�N���b�N(1.9968MHz)  ������ (31.20KHz) == 4
			_put	'8MHz�n(31.20KHz)'
			mov		dx,4
			push	dx
			jmp		CLSET_OK
	CLOCK10:
			;10MHz�N���b�N(2.4576MHz) ������ (30.72KHz) == 5
			_put	'10MHz�n(30.72MHz)'
			mov		dx,5
			push	dx
	CLSET_OK:
			_puts	'�ɐݒ肵�܂����B'
			pop		dx
			mov		al, 0b6h
			out		77h, al					;mode 3
			out		5fh,al
			out		5fh,al
			mov		al, dl
			out		75h, al
			out		5fh,al
			out		5fh,al
			mov		al, dh
			out		75h, al
			out		5fh,al
			out		5fh,al
;8251���[�h�ݒ�
			xor		al,al
			out		32h,al					;dummy command
			call	rs_wait
			out		32h,al
			call	rs_wait
			out		32h,al
			call	rs_wait
			
			mov		al, 40h
			out		32h, al
			call	rs_wait

			mov		al, 01001110B
			out		32h, al
			call	rs_wait
			
;ER/RS�M�� ON
			mov		al, 37h
			out		32h, al
			call	rs_wait
			
; �_�~�[�f�^���o�͂��āA232C�ڑ���Ԃ����߂��̂��I�I
; ���ł�����Aall reset controller ���o�͂��܂����B
			mov		cx,16
	check_232c_enabled:
			mov		al,0b0h
			mov		dl,cl
			dec		dl
			or		al,dl
			call	send_rsmidi
			jb		rs232c_nodevice
			mov		al,79h
			call	send_rsmidi
			jb		rs232c_nodevice
			mov		al,00h
			call	send_rsmidi
			jb		rs232c_nodevice
			loop	check_232c_enabled
			mov		ax,NULL				; �����A�悩�����B
			popf
			ret
	rs232c_nodevice:
			mov		ax,EOF				; �Ȃ����I�����������������B
			popf
			ret

	rs_wait:							; RS-232C �̂������ƂȂ̂ł�
			push	cx
			mov		cx,256
			loop	$
			pop		cx
			ret

	send_rsmidi:						; RS232C �ɏo�͂��Ă݂�
			push	cx
			push	dx
			mov		dl,al
			mov		cx,16000
		s_rs232c:						; �Ȃɂ��Ȃ����ĂȂ����B
			in		al,32h				; ������� RS-MIDI��z�肾!�I!�I!�I
			test	al,1
			jnz		rs232c_send_complete
			out		5fh,al
			out		5fh,al
			loop	s_rs232c
			pop		dx
			pop		cx
			stc
			ret							; �o�͎��s�I�I
	
	rs232c_send_complete:
			mov		al,dl
			out		30h,al
			call	rs_wait
			pop		dx
			pop		cx
			clc
			ret							; ���[�ӁB

check_rs232c_interface	endp
			end		start

revision	version		comment
1.1			0.90B		�Ƃ肠��������
1.2			0.91B		�t�F�[�h�A�E�g�n�̃o�O��ގ�
1.3			0.92		�������n����bugfix�A/id�I�v�V�����̕ύX�B
						/rs�I�v�V�����̕s��Ώ��B
1.4			0.96		MIDI�@���MIDI-IN�ɐڑ����Ă���Ƃ��ɒ�~���Ă���
						BUG��FIX�����Ǝv���B
