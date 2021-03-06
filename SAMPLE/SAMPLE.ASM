;==============================================================================
; MFXDDN専用 driver
;						れべるめーたぁにゃの。
;  copyright (c) 1993 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
			dosseg
			jumps
			.186
			.model	tiny

include		..\kernel\ddn.inc
include		..\kernel\stdio.inc
include		..\kernel\option.inc

level		equ		4

			.code
			org		100h
start:
			jmp		near ptr com_start

;------------------------------------------------------------------------------
; ドライバーステータステーブル ddn.inc に準拠
;
org	DRVTYPE	
				dtype		dw	ETC_DEVICE
org	DRVID					;	'----･----+----･',--h
				did			db	'れべるめーた98 ',00h
org	DRVINIT
				dinit		dw	offset driver_init
org	DRVEND
				dend		dw	offset dummy_func
org	DRVPLAY
				dplay		dw	offset dummy_func
org	DRVSTOP
				dstop		dw	offset dummy_func
org	DRVINT
				dint		dw	offset dummy_func
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
				dw			?
;------------------------------------------------------------------------------

.data
dinstmsg	db	'[32mPC98[33m Level meter display driver[m version 0.01β(test)',CR
			db	'copyright (c) 1994 ABA / T.Kobayashi and Interfair '
			db	' all rights reserved,',CR,'$'
dusemsg		db	'レベルメーターを表示しましゅの。$'
.code

;------------------------------------------------------------------------------
;ＤＯＳ割り込み時に表示するメッセージ
com_start	proc
			mov		ax,cs
			mov		ds,ax
			_puts	'Usage : mld.com level.xdv'
			_exit	NULL
com_start	endp

;------------------------------------------------------------------------------
;なんもしない(DDN)
dummy_func	proc	far
			ret
dummy_func	endp

;------------------------------------------------------------------------------
;常駐時に実行するドライバー初期化
driver_init	proc	far
			push	cs
			pop		ds

			option	'io',NO_PARAM,nai,era
			_puts	'認識できましたあ'
			mov		ax,1
			ret
	nai:
			_puts	'ない、と認識されましたあ'
			mov		ax,1
			ret
	era:
			_puts	'えらー、と認識されましたぁ'
			mov		ax,1
			ret
driver_init	endp


			end		start
