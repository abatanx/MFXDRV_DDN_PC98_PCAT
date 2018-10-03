;==============================================================================
; MFXDDN sound driver module
;						YAMAHA YM2203 FM(OPN) driver
;  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
			jumps
			.186
			.model	tiny
			.code

version		equ		'0.01'

include		stdio.inc
include		ddn.inc
include		option.inc
include		usertool.inc
include		opn.inc
include		opnfunc.inc
include		opnterm.inc

			.code
			assume	cs:@code,ds:@code
			org		100h
start:
			jmp		near ptr com_start

;------------------------------------------------------------------------------
; ƒhƒ‰ƒCƒo[ƒXƒe[ƒ^ƒXƒe[ƒuƒ‹ ddn.inc ‚É€‹’
;
org	DRVTYPE	
				dtype		dw	NORMAL_DEVICE
org	DRVID
				did			db	'OPN            ',00h
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
				dch			db	3
org	DRVUSECH
				dusech		db	3
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
				dw			offset opn_ecm
				dw			offset opn_note_off
				dw			offset opn_note_on
				dw			offset opn_poly_keypress
				dw			offset opn_bank_select
				dw			offset opn_modulation
				dw			offset opn_pol_time
				dw			offset opn_data_entry
				dw			offset opn_volume
				dw			offset opn_panpot
				dw			offset opn_expression
				dw			offset opn_hold1
				dw			offset opn_poltament
				dw			offset opn_sostenuto
				dw			offset opn_soft
				dw			offset opn_pol_ctrl
				dw			offset opn_effect1
				dw			offset opn_effect3
				dw			offset opn_nrpn
				dw			offset opn_rpn	
				dw			offset opn_prog_chg
				dw			offset opn_ch_presser
				dw			offset opn_pitchbend
				dw			offset opn_all_soundoff
				dw			offset opn_all_resetctrler
				dw			offset opn_all_noteoff
				dw			offset opn_omni_off
				dw			offset opn_omni_on
				dw			offset opn_mono
				dw			offset opn_poly
				dw			offset opn_active_sence
				dw			offset opn_exclusive
				dw			offset opn_vibrato
				dw			offset opn_master_volume
;------------------------------------------------------------------------------
				even
.data

even
volume_buf		db		3 dup(?)
exp_buf			db		3 dup(?)
velo_buf		db		3 dup(?)
notestatus		db		3 dup(?)
mastervol		db		?
volumerevision	db		?
fnumber1		db		3 dup(?)
fnumber2		db		3 dup(?)
lfo			MODTABLE	3 dup(?)
volumedown		db		0
OPNPORT1		dw		?
OPNPORT2		dw		?

even
soundtblmax		dw			?
soundtbl		OPNTONE		MAXSOUND dup(?)

dinstmsg	db	'[32mPC98[36m YAMAHA YM2203(OPN) driver[m version '
			db	'0'+ver_int,'.','0'+ver_real/10,'0'+ver_real mod 10,ver_char,CR
			db	'copyright (c) 1994 ABA / T.Kobayashi and Interfair '
			db	'All Rights Reserved.',CR,'$'
dusemsg		db	'OPN ‚Å‰‰‘t‰Â”\‚Å‚· OPN.XDV ver.'
			db	'0'+ver_int,'.','0'+ver_real/10,'0'+ver_real mod 10,ver_char,CR
			db	'$'
.code

;------------------------------------------------------------------------------
;íŠ„‚è‚İ•”•ª
driver_timer_interrupt	proc	far
			call	int_modulation
			ret
driver_timer_interrupt	endp

;------------------------------------------------------------------------------
;ƒtƒ@ƒ“ƒNƒVƒ‡ƒ“ƒGƒ‰[
opn_func_error	proc	far
			ret
opn_func_error	endp

;------------------------------------------------------------------------------
;ƒhƒ‰ƒCƒo[‰ğ•úI—¹‰Šú‰»
driver_end	proc	far				; MLD ŒÄ‚Ño‚µ‚Í FAR ‚¾‚æB
			mov		ah,0
			call	init_opnsound
			mov		ah,1
			call	init_opnsound
			mov		ah,2
			call	init_opnsound
			ret
driver_end	endp

;------------------------------------------------------------------------------
;í’“‚ÉÀs‚·‚éƒhƒ‰ƒCƒo[‰Šú‰»
driver_init	proc	far				; MLD ŒÄ‚Ño‚µ‚Í FAR ‚¾‚æB

			mov		OPNPORT1,188h
			mov		OPNPORT2,18ah

;ƒIƒvƒVƒ‡ƒ“ƒ`ƒFƒbƒN=====
; /io=xxxxh
			option	'io',VALUE_PARAM,@fast11,error_opt
			mov		OPNPORT1,ax
			add		ax,2
			mov		OPNPORT2,ax
; /v=xxx
@fast11:
			option	'v',VALUE_PARAM,@fast1,error_opt
			cmp		ax,128
			jb		vol_ok
			_puts	'/v=xxx ‚Ìw’è‚ª•s³‚Å‚·(0`127)B'
			jmp		@fast1
vol_ok:
			mov		[volumedown],al
			_puts	'OPN‚Ì‰¹—Ê‚ğİ’è‚µ‚Ü‚µ‚½B'
; /id=xxxx
	@fast1:
			option	'id',STR_PARAM,@fast,error_opt
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
			_puts	'DRIVER-ID ‚ğ•ÏX‚µ‚Ü‚µ‚½B'
			jmp		@fast

	error_opt:
			_puts	'ƒpƒ‰ƒ[ƒ^‚ªˆá‚¢‚Ü‚·B'
	@fast:
			call	check_opn		; OPNƒ`ƒFƒbƒN
			jb		not_stay_opn	; OPN‚È‚µB‚®[B
			mov		ah,0
			call	init_opnsound	; OPN‰Šú‰»
			mov		ah,1
			call	init_opnsound	; OPN‰Šú‰»
			mov		ah,2
			call	init_opnsound	; OPN‰Šú‰»
			jb		not_stay_opn

			mov		bh,0ffh
			call	read_opnreg
			cmp		al,1
			jz		@fast2
			_put	'YM2203(OPN) '
			_put	'YM2203'
			jmp		put_ioadr
	@fast2:
			_put	'YM2608(OPNŒİŠ·•”) '
	put_ioadr:
			_put	'I/O port ['
			puthex_16reg	OPNPORT1
			_put	'h/'
			puthex_16reg	OPNPORT2
			_puts	'h] ‚ğg—p‚µ‚Ü‚·B'

			mov		ax,3			; 3 Channel
			ret
	not_stay_opn:
			mov		ax,0
			ret
driver_init	endp

;OPN‚Ìƒ`ƒFƒbƒN
check_opn	proc
			mov		cx,10000		; 1–œ‰ñ‚¿‚¥‚Á‚­`
	lp_co:
			mov		dx,OPNPORT1
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
;‰‰‘tŠJn‚ÉÀs‚·‚é‚Æ‚±
driver_play	proc	far			; DDNŒÄo‚Í FAR ‚¾‚æ
			mov		ah,0
			call	init_opnsound
			mov		ah,1
			call	init_opnsound
			mov		ah,2
			call	init_opnsound
			call	init_opnbuf
			ret
driver_play	endp

;------------------------------------------------------------------------------
;‰‰‘tI—¹‚ÉÀs‚·‚é‚Æ‚±
driver_stop	proc	far			; DDNŒÄo‚Í FAR ‚¾‚æ
			mov		ah,0
			call	init_opnsound
			mov		ah,1
			call	init_opnsound
			mov		ah,2
			call	init_opnsound
			ret
driver_stop	endp

;------------------------------------------------------------------------------
;‚c‚n‚r‚©‚ç‚ÌÀs‚É•\¦‚·‚éƒƒbƒZ[ƒW
com_start	proc
			mov		ax,cs
			mov		ds,ax
			_print	dinstmsg
			_print	usage
.data
usage		db	'Usage  ; ',CR
			db	'         mld.exe opn.xdv [option...]',CR
optionlist	db	'Option ; ',CR
			db	'         /io=xxxxH ƒTƒEƒ“ƒhƒ{[ƒh‚ÌI/OƒAƒhƒŒƒX‚ğw’è‚µ‚Ü‚·(DEF:188H)B',CR
			db	'         /id=xxxx  DRIVER-ID ‚ğ•ÏX‚µ‚Ü‚·(DEF:OPN)',CR
			db	'         /v=xxx    ‰¹—Ê’²®‚µ‚Ü‚·(0`127,DEF:0)',CR
			db	CR
			db	'$'
.code
			_exit	NULL
com_start	endp

			end		start
