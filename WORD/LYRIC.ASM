;==============================================================================
; MFXDDNêÍóp driver
;						ÇÌÅ[Ç«Ç’ÇÎÇπÇ¡Ç≥ÅB
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
; ÉhÉâÉCÉoÅ[ÉXÉeÅ[É^ÉXÉeÅ[ÉuÉã ddn.inc Ç…èÄãí
;
DRVID_NUMBER	equ			0001h				; DRVID-Number
org	DRVTYPE	
				dtype		dw	ETC_DEVICE
org	DRVID					;	'----•----+----•',--h
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
				dw	offset word_controller	;00h	ECMã@î\
;------------------------------------------------------------------------------

LOCATION	dw	0h						; ç≈èâÅAç∂è„
COLOR		db	0e1h					; ç≈èâÅAîí

.data
dinstmsg	db	'[32mPC98[33m Lyric data display driver[m version 1.00',CR
			db	'copyright (c) 1994 ABA / T.Kobayashi and Interfair '
			db	'All Rights Reserved.',CR,'$'
dusemsg		db	'âÃéåÇï\é¶Ç≈Ç´Ç‹Ç∑!$'

.code

;------------------------------------------------------------------------------
;ÇcÇnÇräÑÇËçûÇ›éûÇ…ï\é¶Ç∑ÇÈÉÅÉbÉZÅ[ÉW
com_start	proc
			mov		ax,cs
			mov		ds,ax
			_puts	'Usage : mld.exe word.xdv'
			_exit	NULL
com_start	endp
;------------------------------------------------------------------------------
;èÌíìéûÇ…é¿çsÇ∑ÇÈÉhÉâÉCÉoÅ[èâä˙âª
driver_init	proc	far
			mov		ax,1
			ret
driver_init	endp

;------------------------------------------------------------------------------
;ÉèÅ[ÉhÉRÉìÉgÉçÅ[ÉâÅ[
word_controller	proc	far
			cmp		es:[bx],word ptr DRVID_NUMBER
			jz		wc_main
			ret
	wc_main:
			mov		ax,es
			mov		ds,ax
			mov		si,bx
			mov		dx,[si+3]			; dx: CTRLID+ï∂éöóÒí∑Ç≥

			add		si,5				; CTRLID+DATAÇÃç≈èâÇÃADR
			mov		bx,si
			add		bx,dx				; CTRLID+DATAÇÃç≈å„ÇÃADR
			dec		dx

			cld
			lodsb

	;CTRL-IDÉ`ÉFÉbÉN
			cmp		al,00h				; ï∂éöï\é¶
			jz		put_strings
			cmp		al,01h				; êFïœçX
			jz		chg_color
			cmp		al,02h				; èÍèäïœçX
			jz		chg_location
			cmp		al,03h				; âÊñ è¡ãé
			jz		clr_display
	wc_end:
			ret
word_controller	endp

;------------------------------------------------------------------------------
; ï∂éöóÒï\é¶
put_strings	proc	;ç≈â∫à çsâÊñ ÇÃè¡ãé
			cld
			mov		ax,0a000h
			mov		es,ax
			mov		di,cs:[LOCATION]	; ç≈â∫à 
			xor		ax,ax
			mov		cx,dx
			rep		stosw

			mov		ax,0a200h
			mov		es,ax
			mov		di,cs:[LOCATION]	; ç≈â∫à 
			xor		ax,ax
			mov		al,cs:[COLOR]		; êF
			mov		cx,dx
			rep		stosw

			mov		ax,0a000h
			mov		es,ax
			mov		di,cs:[LOCATION]	; ç≈â∫à 

			shl		dx,1
			add		cs:[LOCATION],dx
;âêÕäJén
pstr_next:
			cmp		si,bx
			jnb		wc_end				; èIóπ
;sjisÉ`ÉFÉbÉN
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
; êFïœçX
chg_color	proc
			lodsb
			mov		cs:[COLOR],al
			jmp		wc_end
chg_color	endp
;------------------------------------------------------------------------------
; èÍèäïœçX
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
; âÊñ è¡ãé
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