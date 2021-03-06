;==============================================================================
; MFXDDN timer driver module
;							早送りドライバ
;  copyright (c) 1993 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
			jumps
			.186
			.model	tiny
			.code
			org		100h

include		stdio.inc
include		ddn.inc
include		option.inc
include		usertool.inc

BEAT		equ		4

start:
			jmp		near ptr com_start

;------------------------------------------------------------------------------
; ドライバーステータステーブル ddn.inc に準拠
;
org	DRVTYPE	
				dtype		dw	ETC_DEVICE
org	DRVID					;	'----･----+----･',--h
				did			db	'FASTFORWARD    ',00h
org	DRVINIT
				dinit		dw	offset driver_init
org	DRVEND
				dend		dw	NULL
org	DRVPLAY
				dplay		dw	NULL
org	DRVSTOP
				dstop		dw	NULL
org	DRVINT
				dint		dw	offset ff_main
org	DRVCH
				dch			db	0
org	DRVUSECH
				dusech		db	0
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
dinstmsg	db	'[32mPC98[33m BGM F.F. driver[m version 1.00',CR
			db	'copyright (c) 1993 ABA / T.Kobayashi and Interfair '
			db	'All Rights Reserved.',CR,'$'
dusemsg		db	'[GRPH] キーで早送り機能が使用可能です。$'

.code

ff_tempo	dw	1280

;------------------------------------------------------------------------------
;ＤＯＳ割り込み時に表示するメッセージ
com_start	proc
			mov		ax,cs
			mov		ds,ax
			_puts	'Usage : mld.com ff.xdv'
			_exit	NULL
com_start	endp

;------------------------------------------------------------------------------
;なんもしない(FAR)
dummy_func_far	proc	far
			ret
dummy_func_far	endp

;------------------------------------------------------------------------------
;常駐時に実行するドライバー初期化
driver_init	proc	far
			mov		ax,1
			ret
driver_init	endp

;------------------------------------------------------------------------------
;早送りメイン
ff_main		proc	far
			push	ds
			push	es
			mov		ax,cs
			mov		ds,ax

			mov		ah,0ah
			int		50h
			mov		cx,ax

			mov		ax,0
			mov		es,ax
			test	es:[053ah],byte ptr 08h
			jz		ff_not_push_grph

	ff_push_grph:
			test	cx,2		; 早送り中か？
			jnz		ff_end		; 早送り中なので、skip!!
			mov		ah,15h
			mov		bx,[ff_tempo]
			int		50h			; 早送り開始〜
			jmp		ff_end
	
	ff_not_push_grph:
			test	cx,2		; 早送り中か？
			jz		ff_end		; 早送りしてないので、すきっぷ
			mov		ah,16h
			int		50h
	
	ff_end:
			pop		es
			pop		ds
			ret
ff_main		endp
			end		start
