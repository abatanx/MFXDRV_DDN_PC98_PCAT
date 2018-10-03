;==============================================================================
; MFXDDN timer driver module
;							Interval timer driver 98
;  copyright (c) 1993 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
			jumps
			dosseg
			.186
			.model	tiny
			.code

include		stdio.inc
include		ddn.inc

TM_OPTIMIZE			=		25				; ¸“x
											; 10/n(ms) ‚ÅŠ„‚è‚İ
LOCAL_STACKSIZE		=		512				; Local Stack size
			org		100h
start:
			jmp		short com_start

;------------------------------------------------------------------------------
; ƒhƒ‰ƒCƒo[ƒXƒe[ƒ^ƒXƒe[ƒuƒ‹ ddn.inc ‚É€‹’
;
DRVIDNUM		equ			1001h
org	DRVTYPE	
				dtype		dw	TIMER_DEVICE
org	DRVID					;	'----¥----+----¥',--h
				did			db	'ITVALTIMER98   ',00h
org	DRVINIT
				dinit		dw	offset driver_init
org	DRVEND
				dend		dw	offset driver_end
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
				dverreal	db	10
org	DRVINSTMSG
				dw			offset dinstmsg
org	DRVUSEMSG
				dw			offset dusemsg
org	DRVFUNC
;----------------- controll ---------------- no ----- comment -----------------
				dw	offset NULL				; 0h	ECM‹@”\
				dw	offset init_timer		; 1h	ƒ^ƒCƒ}[‰Šú‰»
				dw	offset set_tempo		; 2h	ƒeƒ“ƒ|‚Ìİ’è
				dw	offset timer_start		; 3h	ƒ^ƒCƒ}[n“®
				dw	offset timer_stop		; 4h	ƒ^ƒCƒ}[’â~
				dw	offset set_timebase		; 5h	ƒ^ƒCƒ€ƒx[ƒXİ’è
;------------------------------------------------------------------------------
.data
; ƒ[ƒJƒ‹ƒXƒ^ƒbƒNƒGƒŠƒA
			even
local_sp_old	dw	?
local_ss_old	dw	?
local_stack_buf	dw	LOCAL_STACKSIZE dup(?)
local_stack		label	word

CPU8		equ		8
CPU10		equ		10

TIMER8		equ		4E00h/(TM_OPTIMIZE)		; 1msec Š„‚è‚İ for  8MHz
TIMER10		equ		6000h/(TM_OPTIMIZE)		; 1msec Š„‚è‚İ for 10MHz

CLOCK		db		?					; ƒ^ƒCƒ}[“®ìƒ‚[ƒh
			even
SPEED		dw		?					; Š„‚è‚İŠÔŠu( 0.1msec )
TEMPO		dw		?					; ƒeƒ“ƒ|ŒvZŒ‹‰Ê
TEMPO_CNT	dw		?					; ƒeƒ“ƒ|ƒJƒEƒ“ƒ^[
TIMEBASE	dw		1					; ƒ^ƒCƒ€ƒx[ƒX

			even
ddn_interrupt		label	dword		; íŠ„‚è‚İƒWƒƒƒ“ƒvæ
ddn_interrupt_ofs	dw	?
ddn_interrupt_seg	dw	?

timer_vector		label	dword		; ‚à‚Æ‚Ìƒ^ƒCƒ}Š„‚è‚İ
timer_ofs			dw		0
timer_seg			dw		0

timer_switch		db		0			; ƒ^ƒCƒ}[ó‘Ô(ON/OFF)

			even
timer_reint			dw		FALSE		; ƒ^ƒCƒ}[Š„‚è‚İÄ“üƒ`ƒFƒbƒN
timer_reint_all		dw		FALSE

dinstmsg	db	'[32mPC98[33m Interval timer driver [mversion 1.10',CR
			db	'copyright (c) 1993-94 ABA / T.Kobayashi and Interfair'
			db	' All Rights Reserved.',CR,'$'
dusemsg		db	'Interval Timer ‚ğg—p‚µ‚Ä‰‰‘t‚µ‚Ü‚·B$'


.code

;------------------------------------------------------------------------------
;‚c‚n‚rŠ„‚è‚İ‚É•\¦‚·‚éƒƒbƒZ[ƒW
com_start	proc
			mov		ax,cs
			mov		ds,ax
			_puts	'Usage : mld.exe itvtimer.xdv'
			_exit	NULL
com_start	endp

;------------------------------------------------------------------------------
;ƒ^ƒCƒ}[Š„‚è‚İPIC ‘€ì(ŠJn)
timer_on	proc
			pushf
			push	ax
			cli
			in		al,02h
			and		al,0feh
			out		02h,al
			out		5fh,al
			out		5fh,al
			out		5fh,al
			pop		ax
			popf
			ret
timer_on	endp

;------------------------------------------------------------------------------
;ƒ^ƒCƒ}[Š„‚è‚İPIC ‘€ì(‹Ö~)
timer_off	proc
			pushf
			push	ax
			cli
			in		al,02h
			or		al,01h
			out		02h,al
			out		5fh,al
			out		5fh,al
			out		5fh,al
			pop		ax
			popf
			ret
timer_off	endp

;------------------------------------------------------------------------------
; EOI ”­s
put_eoi		proc
			pushf
			push	ax
			cli
			mov		al,20h
			out		00h,al
			out		5fh,al
			out		5fh,al
			out		5fh,al
			pop		ax
			popf
			ret
put_eoi		endp

;------------------------------------------------------------------------------
;í’“‚ÉÀs‚·‚éƒhƒ‰ƒCƒo[‰Šú‰»
driver_init	proc	far
			pushf
			cli

			mov		ax,cs
			mov		ds,ax

			call	timer_off
			mov		ax,3508h
			int		21h
			mov		[timer_ofs],bx
			mov		[timer_seg],es

			push	ds
			xor		ax,ax
			mov		ds,ax
			test	ds:[0501h],byte ptr 80h
			pop		ds
			_put	'ƒVƒXƒeƒ€ƒNƒƒbƒN‚ğ '
			jz		_5M
	_8M:
			mov		[CLOCK],CPU8
			mov		[SPEED],TIMER8
			mov		bl,8
			mov		ax,3002h
			int		50h
			jmp		di_exit
	_5M:
			mov		[CLOCK],CPU10
			mov		[SPEED],TIMER10
			mov		bl,10
			mov		ax,3002h
			int		50h
	di_exit:
			_puts	'MHzŒn‚Å‰Šú‰»‚µ‚Ü‚µ‚½B'
			mov		[TEMPO],10			;‰Šú’l
			mov		[TEMPO_CNT],10		;‰Šú’l
			push	ds
			xor		ax,ax
			mov		ds,ax
			mov		ds:[08h*4  ],offset interrupt_tmdev
			mov		ds:[08h*4+2],cs
			pop		ds
			mov		ax,1		; ƒ^ƒCƒ}[‚Í‚PŒÂ‚Æ‚¢‚¤‚±‚Æ‚ÅEEE
			popf
			ret
driver_init	endp

;------------------------------------------------------------------------------
;ƒhƒ‰ƒCƒo[‰ğ•úI—¹‰Šú‰»
driver_end	proc	far			; DDN ŒÄo‚È‚Ì‚Å FAR CALL
			pushf
			cli
			call	timer_off
			push	es
			push	bx
			xor		ax,ax
			mov		es,ax
			mov		ax,cs:[timer_ofs]
			mov		bx,cs:[timer_seg]
			or		ax,ax
			jz		de_not_vected
			mov		es:[08h*4  ],ax
			mov		es:[08h*4+2],bx
	de_not_vected:
			pop		bx
			pop		es
			popf
			ret
driver_end	endp

;------------------------------------------------------------------------------
; ITVTIMERê—p ƒCƒ“ƒ^[ƒoƒ‹ƒ^ƒCƒ}[ IOCS
set_timer	proc
			pushf
			push	ax
			push	cx
			cli
			mov		cx,cs:[SPEED]

			mov		al,36h
			out		77h,al
			out		5fh,al
			out		5fh,al

			mov		al,cl
			out		71h,al
			out		5fh,al
			out		5fh,al

			mov		al,ch
			out		71h,al
			out		5fh,al
			out		5fh,al

			pop		cx
			pop		ax
			popf
			ret
set_timer	endp
;------------------------------------------------------------------------------
;Š„‚è‚İˆ—		‚½‚¢‚Ü‚í‚è‚±‚İ‚Å‚±‚±‚É‚­‚é‚Ì‚§B
interrupt_tmdev		proc
			call	put_eoi
			sub		cs:[TEMPO_CNT],1
			jnbe	it_next
			mov		cs:[TEMPO_CNT],0
	it_next:
			cmp		cs:[timer_reint_all],FALSE
			jz		it_start
			iret

	it_start:
			mov		cs:[timer_reint_all],TRUE
			_local_on
			sti
			cmp		cs:[TEMPO_CNT],0
			jnbe	it_ret2
			push	bx
			push	es
			mov		bx,cs:[TEMPO]
			mov		cs:[TEMPO_CNT],bx
			cmp		cs:[timer_switch],OFF
			jz		skip_call_ddn
			call	dword ptr cs:[ddn_interrupt]		; DDN ‚ğ far call
	skip_call_ddn:
			pop		es
			pop		bx

	it_ret2:
			cli
			_local_off
			mov		cs:[timer_reint_all],FALSE
			iret
interrupt_tmdev		endp

;---------------------------- Timer Function  proc.(00) ƒ^ƒCƒ}[‰Šú‰»
;	es:bx  = MFXDDN Š„‚è‚İæƒAƒhƒŒƒX
;ret@ax
;	NULL	‰Šú‰»Š®—¹
;	?		‰Šú‰»‚Å‚«‚È‚©‚Á‚½
;
init_timer	proc	far
			mov		[ddn_interrupt_ofs],bx
			mov		[ddn_interrupt_seg],es
			mov		ax,NULL
			ret
init_timer	endp

;---------------------------- Timer Function  proc.(01) ƒeƒ“ƒ|İ’è
;	bx     = ƒeƒ“ƒ|(1..65535)
;
set_tempo	proc	far
			or		bx,bx
			jz		st_error		; 0 divƒ`ƒFƒbƒN
			
			xor		dx,dx
			mov		ax,125*TM_OPTIMIZE
			div		bx
			cmp		dx,125*TM_OPTIMIZE/2
			cmc
			adc		ax,0
			xor		dx,dx
			mov		bx,[TIMEBASE]
			div		bx
			mov		[TEMPO],ax
	st_error:
			call	set_timer
			ret
set_tempo	endp

;---------------------------- Timer Function  proc.(02) ƒ^ƒCƒ}[n“®
;
timer_start	proc	far
			push	es
			call	timer_off
			mov		bx,cs
			mov		es,bx
			mov		bx,offset interrupt_tmdev
			call	set_timer
			call	timer_on
			mov		[timer_switch],ON
			pop		es
			ret
timer_start	endp

;---------------------------- Timer Function  proc.(03) ƒ^ƒCƒ}[’â~
;
timer_stop	proc	far
			call	timer_off
			mov		[timer_switch],OFF
			ret
timer_stop	endp

;---------------------------- Timer Function  proc.(04) ƒ^ƒCƒ€ƒx[ƒX
;
set_timebase	proc	far
			push	cx
			push	dx

			cmp		bx,48
			jnb		stb_rec		; timebase ‚ª 48ˆÈ‰º‚¾‚Á‚½‚ç 48‚É‚·‚é(‹­§)
			mov		bx,48
	stb_rec:
			xor		dx,dx
			mov		ax,bx
			mov		cx,48
			div		cx
			mov		[TIMEBASE],ax
			
			pop		dx
			pop		cx
			call	set_timer
			ret
set_timebase	endp

			end		start

;
; Interval Time Base Count ‚ª 0.1msec ‚Ì‚Æ‚«A
; ƒeƒ“ƒ|‚ğ S  ƒ^ƒCƒ€ƒx[ƒX‚ğ B ‚Æ‚·‚é‚ÆAŠ„‚è‚İŠÔŠuT ‚ÌŸ®‚ª¬—§‚·‚éB
;       60 * 1000 * 10     600000
; T =  †¢†¢†¢†¢†¢†¢†¢†¢ = †¢†¢†¢†¢
;           S * B           S * B
;
; B = 48 ‚Æ‚·‚é‚ÆA
;
;      12500
; T = †¢†¢†¢†¢
;        S
;
;
; Interval Time Base Count ‚ª 1msec ‚Ì‚Æ‚«A
; ƒeƒ“ƒ|‚ğ S  ƒ^ƒCƒ€ƒx[ƒX‚ğ B ‚Æ‚·‚é‚ÆAŠ„‚è‚İŠÔŠuT ‚ÌŸ®‚ª¬—§‚·‚éB
;       60 * 1000       60000
; T =  †¢†¢†¢†¢†¢†¢ = †¢†¢†¢†¢
;         S * B         S * B
;
; B = 48 ‚Æ‚·‚é‚ÆA
;
;      1250
; T = †¢†¢†¢
;        S
;

; Version Revision_ Comment_____________________________________________________
	1.00B	1.1		‚Æ‚è‚ ‚¦‚¸Š®¬
	1.00B	1.2		TEANAN‚Ìw“E‚É‚æ‚éƒ^ƒCƒ}Š„‚è‚İ‚Ì’x‚³‚ğ‰ğÁ
					‚Ü‚¾AŠ®‘S‚É‚È‚¨‚Á‚Ä‚È‚¢‚¯‚Ç‚ËB
	1.00B	1.3		Š„‚è‚İƒxƒNƒ^‚ğ•œ‹A‚µ‚Ä‚È‚©‚Á‚½`!!
					ƒeƒ“ƒ|‚¸‚ê”­¶’†`
	1.00B	1.4		ƒ[ƒJƒ‹ƒXƒ^ƒbƒN‚ğÏ‚ñ‚¾BˆÀ’è“®ì‚·‚é‚æ‚¤‚É‚È‚Á‚½B
	1.01	1.4.1	ÀŒ±”Å Ä“üƒ`ƒFƒbƒN‚ğŒµ‚µ‚­‚·‚é
			1.4.2	ÀŒ±”Å Ä“üƒ`ƒFƒbƒN‚ğŠÃ‚­‚·‚é
			1.4.3	ƒ[ƒJƒ‹ƒXƒ^ƒbƒN‚ğŒ¸‚ç‚µ‚Ä‚İ‚é
	1.02	1.5		‚¿‚å‚Á‚Æ®—‚µ‚½‚çAlocalstackŒ¸‚ç‚µ‚Ä‚àˆÀ’è“®ì‚·‚é‚æ‚¤‚É
					‚È‚Á‚½B‚ ‚¤‚ ‚¤B
	1.10	1.6		‚¤[‚ŞA–\‘–‚·‚é‚Ì‚ÍA‚¤‚¥‚¢‚ÆŠÖŒW‚¾‚Á‚½‚ç‚µ‚¢B‚µ‚­‚µ‚­B
