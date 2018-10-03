CNTS		=		1

;==============================================================================
; ÇøÇ·ÇæÇÒÇ∑Ç∆ÇÁÇ¡Çœ
;==============================================================================
			jumps
			.186
			.model	tiny
			.code
			org		100h

include		stdio.inc
include		ddn.inc
include		option.inc
include		usertool.inc

BEAT		equ		4

start:
			jmp		near ptr com_start

;------------------------------------------------------------------------------
; ÉhÉâÉCÉoÅ[ÉXÉeÅ[É^ÉXÉeÅ[ÉuÉã ddn.inc Ç…èÄãí
;
org	DRVTYPE	
				dtype		dw	ETC_DEVICE
org	DRVID					;	'----•----+----•',--h
				did			db	'Ç®Ç«ÇÈ¡¨¡¨V.0.5',00h
org	DRVINIT
				dinit		dw	offset driver_init
org	DRVEND
				dend		dw	offset driver_end
org	DRVPLAY
				dplay		dw	offset initdance
org	DRVSTOP
				dstop		dw	NULL
org	DRVINT
				dint		dw	offset dance
org	DRVCH
				dch			db	0
org	DRVUSECH
				dusech		db	0
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
dinstmsg	db	'[31móxÇÍÅIóxÇÈÇÒÇæÅIÉ`ÉÉÉ`ÉÉÅI[m',CR
			db	'chad2.exeëŒâûî≈ oopyr.(c)1994 by Ç†ÇŒ',CR,'$'
dusemsg		db	'ÉGÉäÉUÉxÉXÅuÉ`ÉÉÉ`ÉÉÇ¡ÇΩÇÁÇ®Ç‹ÇπÇ≥ÇÒÇÀÇ•ÅBÅv$'
.code

chad		label	dword
chad_ofs	dw	?
chad_seg	dw	?
cnt			dw	?

waitbase	dw	2,1,1,1,1,2,1,1,1,1
waitbaseno	dw	0

;------------------------------------------------------------------------------
;ÇcÇnÇräÑÇËçûÇ›éûÇ…ï\é¶Ç∑ÇÈÉÅÉbÉZÅ[ÉW
com_start	proc
			mov		ax,cs
			mov		ds,ax
			_puts	'Usage : mld.exe chadance.xdv'
			_exit	NULL
com_start	endp

;------------------------------------------------------------------------------
;Ç»ÇÒÇ‡ÇµÇ»Ç¢(FAR)
dummy_func_far	proc	far
			ret
dummy_func_far	endp

;------------------------------------------------------------------------------
;èÌíìéûÇ…é¿çsÇ∑ÇÈÉhÉâÉCÉoÅ[èâä˙âª
driver_init	proc	far
			pushf
			cli
			xor		ax,ax
			mov		es,ax
			mov		ax,es:[0ah*4  ]
			mov		dx,es:[0ah*4+2]
			mov		[chad_ofs],ax
			mov		[chad_seg],dx

			mov		ax,offset int0a_trap
			mov		dx,cs
			mov		es:[0ah*4  ],ax
			mov		es:[0ah*4+2],dx
			popf

			mov		ax,1
			ret
driver_init	endp

;------------------------------------------------------------------------------
;èIóπéûÇ…é¿çsÇ∑ÇÈÉhÉâÉCÉoÅ[èâä˙âª
driver_end	proc	far
			pushf
			cli
			xor		ax,ax
			mov		es,ax
			mov		ax,[chad_ofs]
			mov		dx,[chad_seg]
			mov		es:[0ah*4  ],ax
			mov		es:[0ah*4+2],dx
			popf
			ret
driver_end	endp

;------------------------------------------------------------------------------
initdance	proc	far
			mov		ax,cs
			mov		ds,ax
			mov		ax,[waitbaseno]
			mov		cx,10
			sub		cx,ax
	reboot:
			push	cx
			pushf
			call	dword ptr [chad]
			pop		cx
			loop	reboot
	reboot_end:
			mov		ax,[waitbase]
			mov		[waitbaseno],0
			mov		[cnt],ax
			ret
initdance	endp

;------------------------------------------------------------------------------
int0a_trap	proc
			pushf
			push	ax
			cli
			mov		al,20h
			out		5fh,al
			out		5fh,al
			out		5fh,al
			out		5fh,al
			out		00h,al
			pop		ax
			popf
			iret
int0a_trap	endp

;------------------------------------------------------------------------------
dance		proc	far
			mov		ax,cs
			mov		ds,ax
			dec		[cnt]
			jnz		dance_end

			mov		bx,[waitbaseno]
			inc		bx
			cmp		bx,10
			jb		dance_go
			xor		bx,bx
	dance_go:
			mov		[waitbaseno],bx
			shl		bx,1
			mov		ax,[waitbase+bx]
			mov		[cnt],ax
			pushf
			call	dword ptr [chad]
	dance_end:
			ret
dance		endp

			end		start
