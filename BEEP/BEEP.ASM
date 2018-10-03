;==============================================================================
; MFXDDN sound driver module
;							beep driver for 98
;  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
			jumps
			.186
			.model	tiny
			.code

version		equ		'0.90'

include		stdio.inc
include		ddn.inc
include		option.inc
include		usertool.inc

include		beep.inc
include		beepfunc.inc

extrn		beep_note_init:near

			org		100h
start:
			jmp		short com_start

;------------------------------------------------------------------------------
; ƒhƒ‰ƒCƒo[ƒXƒe[ƒ^ƒXƒe[ƒuƒ‹ ddn.inc ‚É€‹’
;
org	DRVTYPE	
				dtype		dw	NORMAL_DEVICE
org	DRVID
				did			db	'BEEP           ',00h
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
				dch			db	1
org	DRVUSECH
				dusech		db	1
org	DRVVERINT
				dverint		db	0
org	DRVVERREAL
				dverreal	db	90
org	DRVINSTMSG
				dw			offset dinstmsg
org	DRVUSEMSG
				dw			offset dusemsg
org	DRVFUNC	
;----------------- controll ---------------------------------------------------
				dw			NULL
				dw			offset beep_note_off
				dw			offset beep_note_on
				dw			offset beep_poly_keypress
				dw			offset beep_bank_select
				dw			offset beep_modulation
				dw			offset beep_pol_time
				dw			offset beep_data_entry
				dw			offset beep_volume
				dw			offset beep_panpot
				dw			offset beep_expression
				dw			offset beep_hold1
				dw			offset beep_poltament
				dw			offset beep_sostenuto
				dw			offset beep_soft
				dw			offset beep_pol_ctrl
				dw			offset beep_effect1
				dw			offset beep_effect3
				dw			offset beep_nrpn
				dw			offset beep_rpn	
				dw			offset beep_prog_chg
				dw			offset beep_ch_presser
				dw			offset beep_pitchbend
				dw			offset beep_all_soundoff
				dw			offset beep_all_resetctrler
				dw			offset beep_all_noteoff
				dw			offset beep_omni_off
				dw			offset beep_omni_on
				dw			offset beep_mono
				dw			offset beep_poly
				dw			offset beep_active_sence
				dw			offset beep_exclusive
				dw			offset beep_vibrato
				dw			offset beep_master_volume
;------------------------------------------------------------------------------
.data
dinstmsg	db	'[32mPC98[33m BEEP sound driver[m version ',version,CR
			db	'copyright (c) 1993 ABA / T.Kobayashi and Interfair '
			db	'All Rights Reserved.',CR,'$'
dusemsg		db	'BEEP‰¹Œ¹‚Å‰‰‘t‰Â”\‚¾‚æ‚Áš! '
			db	'SingleMode['
dusemsg_single	db	'x'
			db	']$'

				even

CPUCLOCK	dw		?				; CPU“®ìƒNƒƒbƒN
single		dw		FALSE			; ’P”­‰¹ƒ‚[ƒh
public		CPUCLOCK,single

.code
;------------------------------------------------------------------------------
;íŠ„‚è‚İ•”•ª
driver_timer_interrupt	proc	far
extrn		note_out:near
			call	note_out
			ret
driver_timer_interrupt	endp

;------------------------------------------------------------------------------
;ƒtƒ@ƒ“ƒNƒVƒ‡ƒ“ƒGƒ‰[
beep_func_error	proc	far
			ret
beep_func_error	endp

;------------------------------------------------------------------------------
;‚c‚n‚rŠ„‚è‚İ‚É•\¦‚·‚éƒƒbƒZ[ƒW
com_start	proc
			mov		ax,cs
			mov		ds,ax
			_print	dinstmsg
			_print	usage
.data
usage		db	'Usage  ; ',CR
			db	'         mld.exe beep.xdv [option...]',CR
optionlist	db	'Option ; ',CR
			db	'         /ch=x     ‹­ˆø‚Ég—p‚Å‚«‚éƒ`ƒƒƒ“ƒlƒ‹‚ğ xŒÂ‚É‚µ‚Ü‚·(DEF:1)',CR
			db	'         /id=xxxx  DRIVER-ID ‚ğ•ÏX‚µ‚Ü‚·(DEF:BEEP)',CR
			db	'         /s        ’P”­‰¹ƒ‚[ƒh',CR
			db	'         /?        ƒIƒvƒVƒ‡ƒ“‚ğ•\¦‚µ‚Ü‚·',CR
			db	CR
			db	'$'
.code
			_exit	NULL
com_start	endp

;------------------------------------------------------------------------------
;ƒhƒ‰ƒCƒo[‰ğ•úI—¹‰Šú‰»
driver_end	proc	far			; DDN ŒÄo‚È‚Ì‚Å FAR CALL
			call	beep_init
			ret
driver_end	endp

;------------------------------------------------------------------------------
;í’“‚ÉÀs‚·‚éƒhƒ‰ƒCƒo[‰Šú‰»
driver_init	proc	far
			push	es
			xor		ax,ax
			mov		es,ax
			mov		al,es:[501h]			; CLOCK mode
			test	es:[500h],byte ptr 1
			pop		es
			jnz		beep_canuse
			xor		ax,ax
			ret
	beep_canuse:
			test	al,80h					; CLOCK check
			jnz		di_8mhz
	di_10mhz:
			mov		[CPUCLOCK],_10MHZ
			jmp		di_ok
	di_8mhz:
			mov		[CPUCLOCK],_8MHZ
	di_ok:
			call	beep_note_init
			call	beep_init

;œƒIƒvƒVƒ‡ƒ“‚Ì‚¿‚¥‚Á‚­` =============================
;¦ USAGE
			option	'?',NO_PARAM,@@1,error_opt
			_print	usage
			mov		ax,NULL
			ret

;¦ /ID ƒIƒvƒVƒ‡ƒ“‚Ìƒ`ƒFƒbƒN‚Å[[‚·B----------------
	@@1:
			option	'id',STR_PARAM,@@2,error_opt
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
	@@1loop:
			lodsb
			or		al,al
			jz		@@1end
			stosb
			loop	@@1loop
	@@1end:
			pop		ds
			_puts	'DRIVER-ID ‚ğ•ÏX‚µ‚Ü‚µ‚½B'

;¦ /CH ƒIƒvƒVƒ‡ƒ“‚Ìƒ`ƒFƒbƒN‚Å[[‚·B----------------
	@@2:
			option	'ch',VALUE_PARAM,@@3,error_opt
			mov		[dch]   ,al
			mov		[dusech],al
			_puts	'g—p‰Â”\ƒ`ƒƒƒ“ƒlƒ‹”‚ğ•ÏX‚µ‚Ü‚µ‚½B'

;¦ /S ƒIƒvƒVƒ‡ƒ“‚Ìƒ`ƒFƒbƒN‚Å[[‚·B----------------
	@@3:
			option	's',NO_PARAM,@@4,error_opt
			mov		[single],TRUE
			_puts	'’P”­‰¹ƒ‚[ƒh‚Éİ’è‚µ‚Ü‚µ‚½B'
			mov		[dch],1
			mov		[dusech],1
			mov		[dusemsg_single],'o'
			jmp		@@4

;¦ ƒIƒvƒVƒ‡ƒ“‚¦‚ç[[[[[[       ----------------
	error_opt:
			_print	optionlist

	@@4:
			xor		ax,ax
			mov		al,[dch]
			ret
driver_init	endp

;------------------------------------------------------------------------------
;‰‰‘tŠJn‚ÉÀs‚·‚é‚Æ‚±
driver_play	proc	far			; DDNŒÄo‚È‚Ì‚Å FAR CALL
			call	beep_note_init
			call	beep_init
			ret
driver_play	endp

;------------------------------------------------------------------------------
;‰‰‘tI—¹‚ÉÀs‚·‚é‚Æ‚±
driver_stop	proc	far			; DDNŒÄo‚È‚Ì‚Å FAR CALL
			call	beep_note_init
			call	beep_init
			ret
driver_stop	endp

;------------------------------------------------------------------------------
;BEEP‰Šú‰»
beep_init	proc
			beep_off
			push	ds
			push	cs
			pop		ds
			cmp		[CPUCLOCK],_8MHZ
			jz		bi_8mhz
	bi_10mhz:
			mov		ax,1229
			jmp		bi_set
	bi_8mhz:
			mov		ax,998
	bi_set:
			beep_set
			pop		ds
			ret
beep_init	endp

			end		start

revision	version		comment
1.1			0.01		‚Æ‚è‚ ‚¦‚¸Š®¬
1.2			0.02		8MHzƒ‚[ƒh’Ç‰ÁB/ID /? ƒIƒvƒVƒ‡ƒ“’Ç‰ÁB
