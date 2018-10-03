;==============================================================================
; MFXDDN専用 driver
;						れべるめーたぁメイン
;  copyright (c) 1993 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================

			jumps
			.186
			.model	tiny
			.code


include		..\kernel\ddn.inc
include		..\kernel\stdio.inc

NUM1TO32	equ		7651h
LEVEL1		equ		7632h
LEVEL2		equ		7642h

LEVEL_TYPE	=		LEVEL2

velo		db		32 dup(?)
counter		dw		32 dup(?)
enable		db		?

public		velo,counter,enable


_level_meter	proc
			public	_level_meter
			push	bp
			mov		ax,cs
			mov		ds,ax
			
			mov		cx,16
			xor		dx,dx
			xor		di,di
			xor		si,si
			cld
	lpx:
			cmp		cx,16
			jnz		not_r
			mov		si,160
			mov		di,160
		not_r:
			mov		ah,06h
			mov		bh,dl
			mov		bl,0
			int		50h

			cmp		al,TRUE
			jnz		track_false
		track_true:
			mov		ah,06h
			mov		bh,dl
			mov		bl,30
			int		50h
			mov		bx,dx
			shl		bx,1
			cmp		[counter+bx],ax
			jz		track_sk

			mov		[counter+bx],ax
			mov		ah,06h
			mov		bh,dl
			mov		bl,10
			int		50h
			mov		bx,dx
			mov		[velo+bx],al
		track_sk:
			mov		ax,0e1h
			mov		bp,0c5h
			jmp		track_atr_w
		track_false:
			mov		ax,021h
			mov		bp,045h
		track_atr_w:
			mov		bx,dx
			sub		[velo+bx],2
			jnb		atr_w
			mov		[velo+bx],0
;アトリビュート書き込み
	atr_w:
;			test	[enable],1
;			jz		vramw_skip
			mov		bx,0a200h
			mov		es,bx
			stosw
			stosw
			mov		ax,bp
			stosw
			stosw
			xchg	si,di
;文字書き込み
			mov		bx,0a000h
			mov		es,bx
			mov		ax,NUM1TO32
			add		ax,dx
			call	jisput
			mov		bx,dx
			xor		ax,ax
			mov		al,[velo+bx]
			shr		al,4
			add		ax,LEVEL_TYPE
			call	jisput
			xchg	si,di
	vramw_skip:
			inc		dx
			loop	lpx
			xor		[enable],1
			pop		bp
			ret
_level_meter	endp

jisput		proc
			mov		bx,ax
			xchg	ah,al
			sub		al,20h
			stosw
			mov		ax,bx
			xchg	ah,al
			sub		al,20h
			add		ah,80h
			stosw
			ret
jisput		endp
end
