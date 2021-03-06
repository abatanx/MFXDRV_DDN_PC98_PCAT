;==============================================================================
; MFXDDN timer driver module
;							Interval timer driver 98
;  copyright (c) 1993 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
			jumps
			.model	tiny
			.code
			org		100h

include		..\kernel\ddn.inc
include		..\kernel\stdio.inc
BEAT		equ		4

start:
			jmp		short com_start

;------------------------------------------------------------------------------
; ドライバーステータステーブル ddn.inc に準拠
;
org	DRVTYPE	
				dtype		dw	ETC_DEVICE
org	DRVID					;	'----･----+----･',--h
				did			db	'BEATING_DRIVER ',00h
org	DRVINIT
				dinit		dw	offset driver_init
org	DRVEND
				dend		dw	offset dummy_func
org	DRVPLAY
				dplay		dw	offset beat_start
org	DRVSTOP
				dstop		dw	offset beat_stop
org	DRVINT
				dint		dw	offset beat_counting
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

beat_steptime	dw			1
beat_count		dw			1
play_msg		dw			'>','P','L','A','Y'

.data
dinstmsg	db	'[32mPC98[33m BEAT status driver[m version 0.01β(test)',CR
			db	'copyright (c) 1993 ABA / T.Kobayashi and Interfair '
			db	'All Rights Reserved.',CR,'$'
dusemsg		db	'演奏中にぺかぺかします。$'
.code

;------------------------------------------------------------------------------
;ＤＯＳ割り込み時に表示するメッセージ
com_start	proc
			mov		ax,cs
			mov		ds,ax
			_puts	'Usage : mld.com beat.xdv'
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
			mov		ax,1		; 
			ret
driver_init	endp

;------------------------------------------------------------------------------
;最初
beat_start	proc	far
			push	ds
			mov		ax,cs
			mov		ds,ax
			mov		[beat_steptime],192/BEAT
			mov		[beat_count   ],BEAT
			pop		ds
			ret
beat_start	endp

;------------------------------------------------------------------------------
;最後
beat_stop	proc	far
			push	ds
			mov		ax,cs
			mov		ds,ax
			mov		[beat_steptime],192/BEAT
			mov		[beat_count   ],BEAT
			pop		ds
			ret
beat_stop	endp

;------------------------------------------------------------------------------
;常時割り込み部
beat_counting	proc	far
			push	ds
			push	es
			push	di
			push	si
			mov		ax,cs
			mov		ds,ax

			dec		[beat_steptime]
			jnz		bc_end
			mov		[beat_steptime],192/BEAT
			xor		[beat_count],0e0h
			mov		bx,[beat_count]
			or		bx,101b
			
			cld
			mov		ax,0a000h
			mov		es,ax
			mov		di,150
			mov		si,offset play_msg
			mov		cx,5
			rep		movsw
			mov		ax,0a200h
			mov		es,ax
			mov		di,150
			mov		cx,5
			mov		ax,bx
			rep		stosw
	bc_end:
			pop		si
			pop		di
			pop		es
			pop		ds
			ret
beat_counting	endp

			end		start
