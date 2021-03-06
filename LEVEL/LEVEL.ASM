;==============================================================================
; MFXDDN専用 driver
;						れべるめーたぁにゃの。
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
dinstmsg	db	'[32mPC98[33m Level meter display driver[m version 0.01β(test)',CR
			db	'copyright (c) 1994 ABA / T.Kobayashi and Interfair '
			db	'All Rights Reserved.',CR,'$'
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
			nop
			nop
			nop
			ret
dummy_func	endp

;------------------------------------------------------------------------------
;常駐時に実行するドライバー初期化
driver_init	proc	far
			mov		ax,1
			ret
driver_init	endp

;------------------------------------------------------------------------------
;最初
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
;最後
level_stop	proc	far
			ret
level_stop	endp

;------------------------------------------------------------------------------
;常時割り込み部
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