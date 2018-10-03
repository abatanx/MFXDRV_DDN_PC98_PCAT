;==============================================================================
; MFXDDNê—p driver
;						‚ê‚×‚é‚ß[‚½‚Ÿ‚É‚á‚ÌB
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
; ƒhƒ‰ƒCƒo[ƒXƒe[ƒ^ƒXƒe[ƒuƒ‹ ddn.inc ‚É€‹’
;
org	DRVTYPE	
				dtype		dw	ETC_DEVICE
org	DRVID					;	'----¥----+----¥',--h
				did			db	'‚ê‚×‚é‚ß[‚½98 ',00h
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
dinstmsg	db	'[32mPC98[33m Level meter display driver[m version 0.01ƒÀ(test)',CR
			db	'copyright (c) 1994 ABA / T.Kobayashi and Interfair '
			db	' all rights reserved,',CR,'$'
dusemsg		db	'ƒŒƒxƒ‹ƒ[ƒ^[‚ğ•\¦‚µ‚Ü‚µ‚ã‚ÌB$'
.code

;------------------------------------------------------------------------------
;‚c‚n‚rŠ„‚è‚İ‚É•\¦‚·‚éƒƒbƒZ[ƒW
com_start	proc
			mov		ax,cs
			mov		ds,ax
			_puts	'Usage : mld.com level.xdv'
			_exit	NULL
com_start	endp

;------------------------------------------------------------------------------
;‚È‚ñ‚à‚µ‚È‚¢(DDN)
dummy_func	proc	far
			ret
dummy_func	endp

;------------------------------------------------------------------------------
;í’“‚ÉÀs‚·‚éƒhƒ‰ƒCƒo[‰Šú‰»
driver_init	proc	far
			push	cs
			pop		ds

			option	'io',NO_PARAM,nai,era
			_puts	'”F¯‚Å‚«‚Ü‚µ‚½‚ '
			mov		ax,1
			ret
	nai:
			_puts	'‚È‚¢A‚Æ”F¯‚³‚ê‚Ü‚µ‚½‚ '
			mov		ax,1
			ret
	era:
			_puts	'‚¦‚ç[A‚Æ”F¯‚³‚ê‚Ü‚µ‚½‚Ÿ'
			mov		ax,1
			ret
driver_init	endp


			end		start
