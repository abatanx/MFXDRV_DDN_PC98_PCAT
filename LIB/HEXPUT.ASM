;/////////////////////////////////////////////////////////////////////////////;
;
;      Multi module music driver MFXDDN(tm) kernel system release 0.00 
;  MFXDDN(tm) Music driver For XMML , Deconcentrate Drivers Network System
;  copyright (c) 1993 ABA / T.Kobayashi and Interfair  All Rights Reserved.
;
;/////////////////////////////////////////////////////////////////////////////;
;プログラマーズインターフェース
; １６進数表示
;
include		model.inc
include		stdio.inc
public	puthex_8reg
public	puthex_16reg

IF	calltype	EQ	_near
			.code
ELSE
			.code	MAINSEG
ENDIF

;------------------------------------------------------------------------------
;８ビットレジスタの１６進数表示
;	al <- 数値
;
puthex_8reg		proc
			mov		ah,al
			mov		di,offset buffer
			cld
			mov		al,ah
			shr		al,4
			stosb
			mov		al,ah
			and		al,0fh
			stosb
			mov		al,0ffh
			stosb
			call	puthex
			ret
puthex_8reg		endp

;------------------------------------------------------------------------------
;１６ビットレジスタの１６進数表示
;	ax <- 数値
;
puthex_16reg		proc
			mov		bx,ax
			mov		di,offset buffer
			cld
			mov		al,bh
			shr		al,4
			stosb
			mov		al,bh
			and		al,0fh
			stosb
			mov		al,bl
			shr		al,4
			stosb
			mov		al,bl
			and		al,0fh
			stosb
			mov		al,0ffh
			stosb
			call	puthex
			ret
puthex_16reg		endp

;------------------------------------------------------------------------------
; １６進数表示共通部分
puthex		proc
			push	si
			mov		bh,0
			mov		si,offset buffer
	puthex_next:
			lodsb
			cmp		al,0ffh
			jz		puthex_exit
			cmp		al,10
			jnb		puthex_plus_a
	puthex_plus_0:
			add		al,'0'
			mov		dl,al
			jmp		puthex_putc
	puthex_plus_a:
			add		al,'A'-10
			mov		dl,al
	puthex_putc:
			mov		ax,0200h
			int		21h
			jmp		puthex_next
	puthex_exit:
			pop		si
			ret
puthex		endp

buffer		db		32 dup(?)

			end
