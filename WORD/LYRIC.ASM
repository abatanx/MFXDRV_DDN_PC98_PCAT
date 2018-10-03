;==============================================================================
; MFXDDN��p driver
;						��[�ǂՂ낹�����B
;  copyright (c) 1993 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================

			jumps
			.186
			.model	tiny
			.code

LASTLINE	equ		0

include		..\kernel\ddn.inc
include		..\kernel\stdio.inc

			org		100h
start:
			jmp		near ptr com_start

;------------------------------------------------------------------------------
; �h���C�o�[�X�e�[�^�X�e�[�u�� ddn.inc �ɏ���
;
DRVID_NUMBER	equ			0001h				; DRVID-Number
org	DRVTYPE	
				dtype		dw	ETC_DEVICE
org	DRVID					;	'----�----+----�',--h
				did			db	'LYRIC          ',00h
org	DRVINIT
				dinit		dw	offset driver_init
org	DRVEND
				dend		dw	NULL
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
				dverreal	db	0
org	DRVINSTMSG
				dw			offset dinstmsg
org	DRVUSEMSG
				dw			offset dusemsg
org	DRVFUNC
;----------------- controll ---------------- no ----- comment -----------------
				dw	offset word_controller	;00h	ECM�@�\
;------------------------------------------------------------------------------

LOCATION	dw	0h						; �ŏ��A����
COLOR		db	0e1h					; �ŏ��A��

.data
dinstmsg	db	'[32mPC98[33m Lyric data display driver[m version 1.00',CR
			db	'copyright (c) 1994 ABA / T.Kobayashi and Interfair '
			db	'All Rights Reserved.',CR,'$'
dusemsg		db	'�̎���\���ł��܂�!$'

.code

;------------------------------------------------------------------------------
;�c�n�r���荞�ݎ��ɕ\�����郁�b�Z�[�W
com_start	proc
			mov		ax,cs
			mov		ds,ax
			_puts	'Usage : mld.exe word.xdv'
			_exit	NULL
com_start	endp
;------------------------------------------------------------------------------
;�풓���Ɏ��s����h���C�o�[������
driver_init	proc	far
			mov		ax,1
			ret
driver_init	endp

;------------------------------------------------------------------------------
;���[�h�R���g���[���[
word_controller	proc	far
			cmp		es:[bx],word ptr DRVID_NUMBER
			jz		wc_main
			ret
	wc_main:
			mov		ax,es
			mov		ds,ax
			mov		si,bx
			mov		dx,[si+3]			; dx: CTRLID+�����񒷂�

			add		si,5				; CTRLID+DATA�̍ŏ���ADR
			mov		bx,si
			add		bx,dx				; CTRLID+DATA�̍Ō��ADR
			dec		dx

			cld
			lodsb

	;CTRL-ID�`�F�b�N
			cmp		al,00h				; �����\��
			jz		put_strings
			cmp		al,01h				; �F�ύX
			jz		chg_color
			cmp		al,02h				; �ꏊ�ύX
			jz		chg_location
			cmp		al,03h				; ��ʏ���
			jz		clr_display
	wc_end:
			ret
word_controller	endp

;------------------------------------------------------------------------------
; ������\��
put_strings	proc	;�ŉ��ʍs��ʂ̏���
			cld
			mov		ax,0a000h
			mov		es,ax
			mov		di,cs:[LOCATION]	; �ŉ���
			xor		ax,ax
			mov		cx,dx
			rep		stosw

			mov		ax,0a200h
			mov		es,ax
			mov		di,cs:[LOCATION]	; �ŉ���
			xor		ax,ax
			mov		al,cs:[COLOR]		; �F
			mov		cx,dx
			rep		stosw

			mov		ax,0a000h
			mov		es,ax
			mov		di,cs:[LOCATION]	; �ŉ���

			shl		dx,1
			add		cs:[LOCATION],dx
;��͊J�n
pstr_next:
			cmp		si,bx
			jnb		wc_end				; �I��
;sjis�`�F�b�N
			lodsb
			cmp		al,081h
			jb		pstr_sjis_normal
			cmp		al,09fh
			jbe		pstr_sjis_comvert
			cmp		al,0e0h
			jb		pstr_sjis_normal
			cmp		al,0fdh
			jbe		pstr_sjis_comvert
	pstr_sjis_normal:
			xor		ah,ah
			stosw
			jmp		pstr_next
	pstr_sjis_comvert:
			mov		ah,al
			lodsb						; ax=SJIS
			cmp		ah,0a0h
			jnb		pstr_sjis_1
			sub		ah,71h
			jmp		pstr_sjis_1
		pstr_sjis_0:
			sub		ah,0b1h
		pstr_sjis_1:
			shl		ah,1
			inc		ah
			cmp		al,80h
			jb		pstr_sjis_2
			dec		al
		pstr_sjis_2:
			cmp		al,09eh
			jnb		pstr_sjis_3
			sub		al,1fh
			jmp		pstr_sjis_end
		pstr_sjis_3:
			sub		al,7dh
			inc		ah
		pstr_sjis_end:

			xchg	ah,al
			mov		dx,ax
			sub		al,20h
			stosw
			mov		ax,dx
			sub		al,20h
			add		ah,80h
			stosw
			jmp		pstr_next
put_strings	endp

;------------------------------------------------------------------------------
; �F�ύX
chg_color	proc
			lodsb
			mov		cs:[COLOR],al
			jmp		wc_end
chg_color	endp
;------------------------------------------------------------------------------
; �ꏊ�ύX
chg_location	proc
			xor		bx,bx
			lodsb
			shl		al,1
			mov		bl,al
			lodsb
			mov		dl,160
			mul		dl
			add		ax,bx
			mov		cs:[LOCATION],ax
			jmp		wc_end
chg_location	endp
;------------------------------------------------------------------------------
; ��ʏ���
clr_display	proc
			mov		ax,0a000h
			mov		es,ax
			xor		di,di
			mov		cx,80*24
			xor		ax,ax
			rep		stosw

			mov		ax,0a200h
			mov		es,ax
			xor		di,di
			mov		cx,80*24
			mov		ax,0e1h
			rep		stosw
			jmp		wc_end
clr_display	endp

			end		start
