;==============================================================================
; MFXDDN専用 driver
;						わーどぷろせっさ。
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
; ドライバーステータステーブル ddn.inc に準拠
;
DRVID_NUMBER	equ			0001h				; DRVID-Number
org	DRVTYPE	
				dtype		dw	ETC_DEVICE
org	DRVID					;	'----･----+----･',--h
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
				dw	offset word_controller	;00h	ECM機能
;------------------------------------------------------------------------------

LOCATION	dw	0h						; 最初、左上
COLOR		db	0e1h					; 最初、白

.data
dinstmsg	db	'[32mPC98[33m Lyric data display driver[m version 1.00',CR
			db	'copyright (c) 1994 ABA / T.Kobayashi and Interfair '
			db	'All Rights Reserved.',CR,'$'
dusemsg		db	'歌詞を表示できます!$'

.code

;------------------------------------------------------------------------------
;ＤＯＳ割り込み時に表示するメッセージ
com_start	proc
			mov		ax,cs
			mov		ds,ax
			_puts	'Usage : mld.exe word.xdv'
			_exit	NULL
com_start	endp
;------------------------------------------------------------------------------
;常駐時に実行するドライバー初期化
driver_init	proc	far
			mov		ax,1
			ret
driver_init	endp

;------------------------------------------------------------------------------
;ワードコントローラー
word_controller	proc	far
			cmp		es:[bx],word ptr DRVID_NUMBER
			jz		wc_main
			ret
	wc_main:
			mov		ax,es
			mov		ds,ax
			mov		si,bx
			mov		dx,[si+3]			; dx: CTRLID+文字列長さ

			add		si,5				; CTRLID+DATAの最初のADR
			mov		bx,si
			add		bx,dx				; CTRLID+DATAの最後のADR
			dec		dx

			cld
			lodsb

	;CTRL-IDチェック
			cmp		al,00h				; 文字表示
			jz		put_strings
			cmp		al,01h				; 色変更
			jz		chg_color
			cmp		al,02h				; 場所変更
			jz		chg_location
			cmp		al,03h				; 画面消去
			jz		clr_display
	wc_end:
			ret
word_controller	endp

;------------------------------------------------------------------------------
; 文字列表示
put_strings	proc	;最下位行画面の消去
			cld
			mov		ax,0a000h
			mov		es,ax
			mov		di,cs:[LOCATION]	; 最下位
			xor		ax,ax
			mov		cx,dx
			rep		stosw

			mov		ax,0a200h
			mov		es,ax
			mov		di,cs:[LOCATION]	; 最下位
			xor		ax,ax
			mov		al,cs:[COLOR]		; 色
			mov		cx,dx
			rep		stosw

			mov		ax,0a000h
			mov		es,ax
			mov		di,cs:[LOCATION]	; 最下位

			shl		dx,1
			add		cs:[LOCATION],dx
;解析開始
pstr_next:
			cmp		si,bx
			jnb		wc_end				; 終了
;sjisチェック
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
; 色変更
chg_color	proc
			lodsb
			mov		cs:[COLOR],al
			jmp		wc_end
chg_color	endp
;------------------------------------------------------------------------------
; 場所変更
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
; 画面消去
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