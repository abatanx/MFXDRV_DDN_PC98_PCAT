;==============================================================================
; MFXDDN timer driver module
;							Interval timer driver 98
;  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
			jumps
			dosseg
			.186
			.model	tiny
			.code

include		stdio.inc
include		ddn.inc

TM_OPTIMIZE			=		25				; ���x
											; 10/n(ms) �Ŋ��荞��
LOCAL_STACKSIZE		=		512				; Local Stack size
			org		100h
start:
			jmp		short com_start

;------------------------------------------------------------------------------
; �h���C�o�[�X�e�[�^�X�e�[�u�� ddn.inc �ɏ���
;
DRVIDNUM		equ			1002h
org	DRVTYPE	
				dtype		dw	TIMER_DEVICE
org	DRVID					;	'----�----+----�',--h
				did			db	'OPNTIMER98     ',00h
org	DRVINIT
				dinit		dw	offset driver_init
org	DRVEND
				dend		dw	offset driver_end
org	DRVPLAY
				dplay		dw	NULL
org	DRVSTOP
				dstop		dw	NULL
org	DRVINT
				dint		dw	NULL
org	DRVCH
				dch			db	?
org	DRVUSECH
				dusech		db	?
org	DRVVERINT
				dverint		db	1
org	DRVVERREAL
				dverreal	db	10
org	DRVINSTMSG
				dw			offset dinstmsg
org	DRVUSEMSG
				dw			offset dusemsg
org	DRVFUNC
;----------------- controll ---------------- no ----- comment -----------------
				dw	offset NULL				; 0h	ECM�@�\
				dw	offset init_timer		; 1h	�^�C�}�[������
				dw	offset set_tempo		; 2h	�e���|�̐ݒ�
				dw	offset timer_start		; 3h	�^�C�}�[�n��
				dw	offset timer_stop		; 4h	�^�C�}�[��~
				dw	offset set_timebase		; 5h	�^�C���x�[�X�ݒ�
;------------------------------------------------------------------------------
.data
; ���[�J���X�^�b�N�G���A
			even
local_sp_old	dw	?
local_ss_old	dw	?
local_stack_buf	dw	LOCAL_STACKSIZE dup(?)
local_stack		label	word

			even
OPN_ADR		dw		188h				; OPN�A�h���X I/O
OPN_DATA	dw		18ah				; OPN�f�[�^   I/O
OPN_VECT	db		?
OPN_MASK	db		?

TIMERINT	equ		1024-470/TM_OPTIMIZE

SPEED		dw		?					; ���荞�݊Ԋu( 0.1msec )
TEMPO		dw		?					; �e���|�v�Z����
TEMPO_CNT	dw		?					; �e���|�J�E���^�[
TIMEBASE	dw		1					; �^�C���x�[�X

ddn_interrupt		label	dword		; �펞���荞�݃W�����v��
ddn_interrupt_ofs	dw	?
ddn_interrupt_seg	dw	?

timer_vector		label	dword		; ���Ƃ̃^�C�}���荞��
timer_ofs			dw		0
timer_seg			dw		0

timer_switch		db		0			; �^�C�}�[���(ON/OFF)

timer_reint			dw		FALSE		; �^�C�}�[���荞�ݍē��`�F�b�N
timer_reint_all		dw		FALSE

dinstmsg	db	'[32mPC98[33m YAMAHA YM2203 Timer(A) Driver [mversion 1.00',CR
			db	'copyright (c) 1994 ABA / T.Kobayashi and Interfair'
			db	' All Rights Reserved.',CR,'$'
dusemsg		db	'OPN TimerA ���g�p���ĉ��t���܂��B$'


.code

;------------------------------------------------------------------------------
;�c�n�r���荞�ݎ��ɕ\�����郁�b�Z�[�W
com_start	proc
			mov		ax,cs
			mov		ds,ax
			_puts	'Usage : mld.exe opntimer.xdv'
			_exit	NULL
com_start	endp

;------------------------------------------------------------------------------
;�^�C�}�[���荞��PIC ����(�J�n)
timer_on	proc
			pushf
			push	ax
			push	bx
			cli

			cmp		cs:[OPN_VECT],8
			jnz		tmon_sub
	tmon_main:
			in		al,02h
			mov		ah,cs:[OPN_MASK]
			not		ah
			and		al,ah
			out		5fh,al
			out		5fh,al
			out		5fh,al
			out		5fh,al
			out		02h,al
			jmp		tmon_exit
	tmon_sub:
			in		al,0ah
			mov		ah,cs:[OPN_MASK]
			not		ah
			and		al,ah
			out		5fh,al
			out		5fh,al
			out		5fh,al
			out		5fh,al
			out		0ah,al
	tmon_exit:
			pop		bx
			pop		ax
			popf
			ret
timer_on	endp

;------------------------------------------------------------------------------
;�^�C�}�[���荞��PIC ����(�֎~)
timer_off	proc
			pushf
			push	ax
			cli

			cmp		cs:[OPN_VECT],8
			jnz		tmoff_sub
	tmoff_main:
			in		al,02h
			mov		ah,cs:[OPN_MASK]
			or		al,ah
			out		5fh,al
			out		5fh,al
			out		5fh,al
			out		5fh,al
			out		02h,al
			jmp		tmoff_exit
	tmoff_sub:
			in		al,0ah
			mov		ah,cs:[OPN_MASK]
			or		al,ah
			out		5fh,al
			out		5fh,al
			out		5fh,al
			out		5fh,al
			out		0ah,al
	tmoff_exit:
			pop		ax
			popf
			ret
timer_off	endp

;------------------------------------------------------------------------------
; EOI ���s
put_eoi		proc
			pushf
			push	ax
			cli

			cmp		cs:[OPN_VECT],8
			jnz		eoi_sub
	eoi_main:
			out		5fh,al
			out		5fh,al
			out		5fh,al
			out		5fh,al
			mov		al,20h
			out		00h,al
			jmp		eoi_exit
	eoi_sub:
			out		5fh,al
			out		5fh,al
			out		5fh,al
			out		5fh,al
			mov		al,20h
			out		08h,al
	eoi_exit:
			pop		ax
			popf
			ret
put_eoi		endp

;------------------------------------------------------------------------------
;�풓���Ɏ��s����h���C�o�[������
driver_init	proc	far
			pushf
			cli
			call	check_opn
			jnb		di_next
			_puts	'�T�E���h�{�[�h�����ڂ���Ă��܂���B'
			jmp		di_exit
	di_next:
			_put	'OPN���荞��(TIMER-A)�� '

			mov		dx,[OPN_ADR]
	di_opnwait:
			in		al,dx
			test	al,80h
			jnz		di_opnwait

			mov		al,0eh
			out		dx,al
			out		5fh,al
			out		5fh,al
			out		5fh,al
			out		5fh,al
			mov		dx,[OPN_DATA]
			in		al,dx
			
			and		al,0c0h
	opn_int0:
			cmp		al,00h
			jnz		opn_int4
			mov		[OPN_VECT],3
			mov		[OPN_MASK],08h
			_put	'�g���o�X INT0(IR3)'
			jmp		opn_int_exit
	opn_int4:
			cmp		al,80h
			jnz		opn_int5
			mov		[OPN_VECT],10
			mov		[OPN_MASK],04h
			_put	'�g���o�X INT41(IR10)'
			jmp		opn_int_exit
	opn_int5:
			cmp		al,0c0h
			jnz		opn_int6
			mov		[OPN_VECT],12
			mov		[OPN_MASK],10h
			_put	'�g���o�X INT5(IR12)'
			jmp		opn_int_exit
	opn_int6:
			mov		[OPN_VECT],13
			mov		[OPN_MASK],20h
			_put	'�g���o�X INT6(IR13)'

	opn_int_exit:
			_puts	'�Ŏg�p���܂��B'

			mov		ah,35h
			mov		al,[OPN_VECT]
			add		al,8
			int		21h

			mov		[timer_ofs],bx
			mov		[timer_seg],es
			call	timer_off
	di_exit:
			mov		[SPEED],TIMERINT
			xor		bx,bx
			mov		bl,[OPN_VECT]
			add		bl,8
			shl		bx,2
			push	ds
			xor		ax,ax
			mov		ds,ax
			mov		ds:[bx  ],offset interrupt_tmdev
			mov		ds:[bx+2],cs
			pop		ds
			mov		ax,1		; �^�C�}�[�͂P�Ƃ������ƂŁE�E�E
			popf
			ret
	
	di_error:
			xor		ax,ax
			ret
driver_init	endp

;OPN�̃`�F�b�N
check_opn	proc
			mov		cx,10000		; 1���񂿂������`
	lp_co:
			mov		dx,[OPN_ADR]
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
;�h���C�o�[����I��������
driver_end	proc	far			; DDN �ďo�Ȃ̂� FAR CALL
			pushf
			cli
			call	timer_off
			push	es
			push	bx
			xor		ax,ax
			mov		es,ax
			mov		ax,cs:[timer_ofs]
			mov		dx,cs:[timer_seg]
			or		ax,ax
			jz		de_not_vected
			xor		bx,bx
			mov		bl,cs:[OPN_VECT]
			add		bl,8
			shl		bx,2
			mov		es:[bx  ],ax
			mov		es:[bx+2],dx
	de_not_vected:
			pop		bx
			pop		es
			popf
			ret
driver_end	endp

;------------------------------------------------------------------------------
; ITVTIMER��p �C���^�[�o���^�C�}�[ IOCS
set_timer	proc
			pushf
			push	ax
			push	cx
			push	bx
			cli
			mov		cx,cs:[SPEED]

			mov		bh,24h
			mov		bl,cl
			call	write_opnreg
			mov		bh,25h
			mov		bl,ch
			call	write_opnreg
			mov		bx,2734h
			call	write_opnreg
			mov		bx,2735h
			call	write_opnreg

			pop		bx
			pop		cx
			pop		ax
			popf
			ret
set_timer	endp
;------------------------------------------------------------------------------
;���荞�ݏ���		�����܂�肱�݂ł����ɂ���̂��B
interrupt_tmdev		proc
			cmp		cs:[timer_reint_all],FALSE
			jz		it_start
			call	put_eoi
			call	set_timer
			iret
	it_start:
			cli
			mov		cs:[timer_reint_all],TRUE
			_local_on
			sti
			call	put_eoi
			dec		cs:[TEMPO_CNT]
			jnz		it_ret2
			push	bx
			push	es
			mov		bx,cs:[TEMPO]
			mov		cs:[TEMPO_CNT],bx
			cmp		cs:[timer_switch],OFF
			jz		skip_call_ddn
			call	set_timer
			call	dword ptr cs:[ddn_interrupt]		; DDN �� far call
	skip_call_ddn:
			pop		es
			pop		bx

	it_ret2:
			cli
			_local_off
			mov		cs:[timer_reint_all],FALSE
			iret
interrupt_tmdev		endp

;---------------------------- Timer Function  proc.(00) �^�C�}�[������
;	es:bx  = MFXDDN ���荞�ݐ�A�h���X
;ret@ax
;	NULL	����������
;	?		�������ł��Ȃ�����
;
init_timer	proc	far
			mov		[ddn_interrupt_ofs],bx
			mov		[ddn_interrupt_seg],es
			mov		ax,NULL
			ret
init_timer	endp

;---------------------------- Timer Function  proc.(01) �e���|�ݒ�
;	bx     = �e���|(1..65535)
;
set_tempo	proc	far
			or		bx,bx
			jz		st_error		; 0 div�`�F�b�N
			
			xor		dx,dx
			mov		ax,125*TM_OPTIMIZE
			div		bx
			cmp		dx,125*TM_OPTIMIZE/2
			cmc
			adc		ax,0
			xor		dx,dx
			mov		bx,[TIMEBASE]
			div		bx
			mov		[TEMPO],ax
	st_error:
			call	set_timer
			ret
set_tempo	endp

;---------------------------- Timer Function  proc.(02) �^�C�}�[�n��
;
timer_start	proc	far
			push	es
			call	timer_on
			call	set_timer
			mov		[timer_switch],ON
			pop		es
			ret
timer_start	endp

;---------------------------- Timer Function  proc.(03) �^�C�}�[��~
;
timer_stop	proc	far
			call	timer_off
			mov		[timer_switch],OFF
			ret
timer_stop	endp

;---------------------------- Timer Function  proc.(04) �^�C���x�[�X
;
set_timebase	proc	far
			push	cx
			push	dx

			cmp		bx,48
			jnb		stb_rec		; timebase �� 48�ȉ��������� 48�ɂ���(����)
			mov		bx,48
	stb_rec:
			xor		dx,dx
			mov		ax,bx
			mov		cx,48
			div		cx
			mov		[TIMEBASE],ax
			
			pop		dx
			pop		cx
			call	set_timer
			ret
set_timebase	endp

;------------------------------------------------------------------------------
__regwait	macro
			local	__reg_adr
	__reg_adr:
			out		5fh,al
			loop	__reg_adr
			endm
;------------------------------------------------------------------------------
; OPN ���W�X�^�Ƀf�[�^����������
;bh		���W�X�^�ԍ�
;bl		�f�[�^
;
write_opnreg		proc
			pushf
			push	ax
			push	cx
			push	dx
			cli
			mov		dx,cs:[OPN_ADR]
	opnwrt1:
			in		al,dx
			test	al,80h
			jnz		opnwrt1

			mov		cx,21/6+1
			__regwait

			mov		al,bh
			out		dx,al

			mov		cx,21/6+1
			__regwait

	opnwrt2:
			in		al,dx
			test	al,80h
			jnz		opnwrt2

			mov		cx,21/6+1
			__regwait

			mov		dx,cs:[OPN_DATA]
			mov		al,bl
			out		dx,al

			cmp		bh,0a0h
			jnb		wait_a0b6
			cmp		bh,21h
			jnb		wait_219e
			cmp		bh,11h
			jnb		wait_111d
			cmp		bh,10h
			jz		wait_10
	wait_000f:
			mov		cx,21/6+1
			jmp		wait_start
	wait_10:
			mov		cx,720/6+1
			jmp		wait_start
	wait_111d:
			mov		cx,194/6+1
			jmp		wait_start
	wait_219e:
			mov		cx,194/6+1
			jmp		wait_start
	wait_a0b6:
			mov		cx,59/6+1
	wait_start:
			__regwait

			pop		dx
			pop		cx
			pop		ax
			popf
		
			ret
write_opnreg	endp


			end		start

;
; Interval Time Base Count �� 0.1msec �̂Ƃ��A
; �e���|�� S  �^�C���x�[�X�� B �Ƃ���ƁA���荞�݊ԊuT �̎�������������B
;       60 * 1000 * 10     600000
; T =  ���������������� = ��������
;           S * B           S * B
;
; B = 48 �Ƃ���ƁA
;
;      12500
; T = ��������
;        S
;
;
; Interval Time Base Count �� 1msec �̂Ƃ��A
; �e���|�� S  �^�C���x�[�X�� B �Ƃ���ƁA���荞�݊ԊuT �̎�������������B
;       60 * 1000       60000
; T =  ������������ = ��������
;         S * B         S * B
;
; B = 48 �Ƃ���ƁA
;
;      1250
; T = ������
;        S
;

; Version Revision_ Comment_____________________________________________________
	1.00B	1.1		�Ƃ肠��������
	1.00B	1.2		TEANAN���̎w�E�ɂ��^�C�}���荞�݂̒x��������
					�܂��A���S�ɂȂ����ĂȂ����ǂˁB
	1.00B	1.3		���荞�݃x�N�^�𕜋A���ĂȂ������`!!
					�e���|���ꔭ�����`
	1.00B	1.4		���[�J���X�^�b�N��ς񂾁B���蓮�삷��悤�ɂȂ����B
	1.01	1.4.1	������ �ē��`�F�b�N������������
			1.4.2	������ �ē��`�F�b�N���Â�����
			1.4.3	���[�J���X�^�b�N�����炵�Ă݂�
	1.02	1.5		������Ɛ���������Alocalstack���炵�Ă����蓮�삷��悤��
					�Ȃ����B���������B
	1.10	1.6		���[�ށA�\������̂́A�������Ɗ֌W�������炵���B���������B
