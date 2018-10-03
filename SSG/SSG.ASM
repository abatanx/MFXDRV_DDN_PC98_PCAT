;==============================================================================
; MFXDDN sound driver module
;						YAMAHA YM2203 SSG driver
;  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
			jumps
			.186
			.model	tiny
			.code

version		equ		'0.20'

include		stdio.inc
include		ddn.inc
include		option.inc
include		usertool.inc
include		ssg.inc
include		ssgfunc.inc
include		ssgterm.inc

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
				did			db	'SSG            ',00h
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
				dverint		db	0
org	DRVVERREAL
				dverreal	db	20
org	DRVINSTMSG
				dw			offset dinstmsg
org	DRVUSEMSG
				dw			offset dusemsg
org	DRVFUNC	
;----------------- controll ---------------------------------------------------
				dw			offset ssg_ecm
				dw			offset ssg_note_off
				dw			offset ssg_note_on
				dw			offset ssg_poly_keypress
				dw			offset ssg_bank_select
				dw			offset ssg_modulation
				dw			offset ssg_pol_time
				dw			offset ssg_data_entry
				dw			offset ssg_volume
				dw			offset ssg_panpot
				dw			offset ssg_expression
				dw			offset ssg_hold1
				dw			offset ssg_poltament
				dw			offset ssg_sostenuto
				dw			offset ssg_soft
				dw			offset ssg_pol_ctrl
				dw			offset ssg_effect1
				dw			offset ssg_effect3
				dw			offset ssg_nrpn
				dw			offset ssg_rpn	
				dw			offset ssg_prog_chg
				dw			offset ssg_ch_presser
				dw			offset ssg_pitchbend
				dw			offset ssg_all_soundoff
				dw			offset ssg_all_resetctrler
				dw			offset ssg_all_noteoff
				dw			offset ssg_omni_off
				dw			offset ssg_omni_on
				dw			offset ssg_mono
				dw			offset ssg_poly
				dw			offset ssg_active_sence
				dw			offset ssg_exclusive
				dw			offset ssg_vibrato
				dw			offset ssg_master_volume
;------------------------------------------------------------------------------
				even
.data

extrn		init_ssgsound:near
extrn		init_ssgbuf:near,int_modulation:near
extrn		ssg_tone_simurate:near

even
OPNPORT1		dw		DEF_OPNPORT1
OPNPORT2		dw		DEF_OPNPORT2

volume_buf		dw		3 dup(?)
exp_buf			dw		3 dup(?)
velo_buf		dw		3 dup(?)
mastervol		dw		?
notestatus		db		3 dup(?)
trflag			dw		3 dup(?)
trofs			dw		3 dup(?)
trseg			dw		3 dup(?)
trpointer		dw		3 dup(?)
trcounter		dw		3 dup(?)
trvolume		dw		3 dup(?)
fnumber			dw		3 dup(?)
lfo			MODTABLE	3 dup(?)
	public		lfo,fnumber
	public		volume_buf
	public		exp_buf
	public		velo_buf
	public		mastervol
	public		notestatus
	public		trflag,trofs,trseg,trpointer,trcounter,trvolume

soundtblmax		dw			?
soundtbl		SSGTONE		MAXSOUND dup(?)
	public		soundtbl
	public		soundtblmax

dinstmsg	db	'[32mPC98[36m YAMAHA YM2203(SSG) driver[m version ',version,CR
			db	'copyright (c) 1994 ABA / T.Kobayashi and Interfair '
			db	'All Rights Reserved.',CR,'$'
dusemsg		db	'YM2203(SSG) ‚Å‰‰‘t‰Â”\‚Å‚· SSG.XDV ver.',version,'$'
.code

;------------------------------------------------------------------------------
;íŠ„‚è‚İ•”•ª
driver_timer_interrupt	proc	far
			mov		ax,cs
			mov		ds,ax
			mov		ah,0
			call	ssg_tone_simurate
			mov		ah,1
			call	ssg_tone_simurate
			mov		ah,2
			call	ssg_tone_simurate
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
			call	init_ssgsound
			mov		ah,1
			call	init_ssgsound
			mov		ah,2
			call	init_ssgsound
			ret
driver_end	endp

;------------------------------------------------------------------------------
;í’“‚ÉÀs‚·‚éƒhƒ‰ƒCƒo[‰Šú‰»
driver_init	proc	far				; MLD ŒÄ‚Ño‚µ‚Í FAR ‚¾‚æB
			mov		ax,cs
			mov		ds,ax
;¦ USAGE
			option	'?',NO_PARAM,@@io,error_opt
			_print	usage
			mov		ax,-1
			ret

;¦ /IO:xxxxH ƒIƒvƒVƒ‡ƒ“‚Ìƒ`ƒFƒbƒN‚Å[[‚·B----------
	@@io:
			option	'io',VALUE_PARAM,@@id,error_opt
			mov		OPNPORT1,ax
			add		ax,2
			mov		OPNPORT2,ax
			_puts	'I/O ƒAƒhƒŒƒX‚ğ•ÏX‚µ‚Ü‚µ‚½B'
;¦ /ID ƒIƒvƒVƒ‡ƒ“‚Ìƒ`ƒFƒbƒN‚Å[[‚·B----------------
	@@id:
			option	'id',STR_PARAM,chk,error_opt
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
			jmp		chk
;¦ ƒIƒvƒVƒ‡ƒ“‚¦‚ç[[[[[[       ----------------
	error_opt:
			_print	optionlist
			mov		ax,-1
			ret
chk:
			call	check_ssg		; OPNƒ`ƒFƒbƒN
			jb		not_stay_ssg	; OPN‚È‚µB‚®[B
			mov		ah,0
			call	init_ssgsound	; SSG‰Šú‰»
			mov		ah,1
			call	init_ssgsound	; SSG‰Šú‰»
			mov		ah,2
			call	init_ssgsound	; SSG‰Šú‰»
			jb		not_stay_ssg
			mov		ax,3			; 3 Channel
			ret
	not_stay_ssg:
			mov		ax,0
			ret
driver_init	endp

;SSG(YM2203)‚Ìƒ`ƒFƒbƒN
check_ssg	proc
			mov		cx,10000		; 1–œ‰ñ‚¿‚¥‚Á‚­`
	lp_co:
			mov		dx,OPNPORT1
			in		al,dx
			cmp		al,0ffh
			jnz		stay_ssg
			loop	lp_co
			stc
			ret
	stay_ssg:
			clc
			ret
check_ssg	endp

;------------------------------------------------------------------------------
;‰‰‘tŠJn‚ÉÀs‚·‚é‚Æ‚±
driver_play	proc	far			; DDNŒÄo‚Í FAR ‚¾‚æ
			mov		ah,0
			call	init_ssgsound
			mov		ah,1
			call	init_ssgsound
			mov		ah,2
			call	init_ssgsound
			call	init_ssgbuf
			ret
driver_play	endp

;------------------------------------------------------------------------------
;‰‰‘tI—¹‚ÉÀs‚·‚é‚Æ‚±
driver_stop	proc	far			; DDNŒÄo‚Í FAR ‚¾‚æ
			mov		ah,0
			call	init_ssgsound
			mov		ah,1
			call	init_ssgsound
			mov		ah,2
			call	init_ssgsound
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
			db	'         mld.exe ssg.xdv [option...]',CR
optionlist	db	'Option ; ',CR
			db	'         /io=xxxxH ƒTƒEƒ“ƒhƒ{[ƒh‚ÌI/OƒAƒhƒŒƒX‚ğw’è‚µ‚Ü‚·(DEF:188H)B',CR
			db	'         /id=xxxx  DRIVER-ID ‚ğ•ÏX‚µ‚Ü‚·(DEF:SSG)',CR
			db	'         /?        ƒIƒvƒVƒ‡ƒ“‚ğ•\¦‚µ‚Ü‚·',CR
			db	CR
			db	'$'
.code
			_exit	NULL
com_start	endp

			end		start
