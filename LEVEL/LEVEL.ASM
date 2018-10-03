;==============================================================================
; MFXDDN��p driver
;						��ׂ�߁[�����ɂ�́B
;  copyright (c) 1993 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================

			jumps
			.186
			.model	tiny
			.code

include		..\kernel\ddn.inc
include		..\kernel\stdio.inc
level		equ		4

			org		100h
start:
			jmp		near ptr com_start

;------------------------------------------------------------------------------
; �h���C�o�[�X�e�[�^�X�e�[�u�� ddn.inc �ɏ���
;
org	DRVTYPE	
				dtype		dw	ETC_DEVICE
org	DRVID					;	'----�----+----�',--h
				did			db	'��ׂ�߁[��98 ',00h
org	DRVINIT
				dinit		dw	offset driver_init
org	DRVEND
				dend		dw	offset dummy_func
org	DRVPLAY
				dplay		dw	offset level_start
org	DRVSTOP
				dstop		dw	offset level_stop
org	DRVINT
				dint		dw	offset level_counting
org	DRVCH
				dch			db	?
org	DRVUSECH
				dusech		db	?
org	DRVVERINT
				dverint		db	1
org	DRVVERREAL
				dverreal	db	0
org	DRVINSTMSG
				dw			offset dinstmsg
org	DRVUSEMSG
				dw			offset dusemsg
org	DRVFUNC
;----------------- controll ---------------- no ----- comment -----------------
				dw			NULL
;------------------------------------------------------------------------------

.data
dinstmsg	db	'[32mPC98[33m Level meter display driver[m version 0.01��(test)',CR
			db	'copyright (c) 1994 ABA / T.Kobayashi and Interfair '
			db	'All Rights Reserved.',CR,'$'
dusemsg		db	'���x�����[�^�[��\�����܂���́B$'
.code

;------------------------------------------------------------------------------
;�c�n�r���荞�ݎ��ɕ\�����郁�b�Z�[�W
com_start	proc
			mov		ax,cs
			mov		ds,ax
			_puts	'Usage : mld.com level.xdv'
			_exit	NULL
com_start	endp

;------------------------------------------------------------------------------
;�Ȃ�����Ȃ�(DDN)
dummy_func	proc	far
			nop
			nop
			nop
			ret
dummy_func	endp

;------------------------------------------------------------------------------
;�풓���Ɏ��s����h���C�o�[������
driver_init	proc	far
			mov		ax,1
			ret
driver_init	endp

;------------------------------------------------------------------------------
;�ŏ�
level_start	proc	far
extrn		counter:word
extrn		velo   :byte
extrn		enable :byte

			mov		ax,cs
			mov		ds,ax
			mov		es,ax
			mov		cx,32
			mov		di,offset counter
			rep		stosw
			mov		cx,32
			mov		di,offset velo
			rep		stosb
			mov		[enable],0
			ret
level_start	endp

;------------------------------------------------------------------------------
;�Ō�
level_stop	proc	far
			ret
level_stop	endp

;------------------------------------------------------------------------------
;�펞���荞�ݕ�
level_counting	proc	far
extrn		_level_meter:near
			pusha
			push	ds
			push	es
			mov		ax,cs
			mov		ds,ax
			mov		es,ax
			call	_level_meter
			pop		es
			pop		ds
			popa
			ret
level_counting	endp

			end		start
