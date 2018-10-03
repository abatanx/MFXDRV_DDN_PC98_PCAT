;/////////////////////////////////////////////////////////////////////////////;
;
;      Multi module music driver MFXDDN(tm) kernel system release 0.00 
;  MFXDDN(tm) Music driver For XMML , Deconcentrate Drivers Network System
;  copyright (c) 1993 ABA / T.Kobayashi and Interfair  All Rights Reserved.
;
;/////////////////////////////////////////////////////////////////////////////;
;プログラマーズインターフェース
; ２進数表示
;
IF	PROGMODE		EQ	COMTYPE
MFXDRVDDN_KERNEL	equ	TRUE
include		model.inc
include		stdio.inc
include		ddn.inc
			.code

ENDIF

;------------------------------------------------------------------------------
;８ビットレジスタの２進数表示
;	al <- 数値
;
putbin_8reg		proc
			mov		ah,al
			mov		di,offset buffer
			cld
			mov		cx,8
	putbin_8reg_next:
			shl		ah,1
			sbb		al,al
			and		al,1
			stosb
			loop	putbin_8reg_next
			mov		al,0ffh
			stosb
			call	putbin
			ret
putbin_8reg		endp

;------------------------------------------------------------------------------
;１６ビットレジスタの２進数表示
;	ax <- 数値
;
putbin_16reg		proc
			mov		bx,ax
			mov		di,offset buffer
			cld
			mov		cx,16
	putbin_16reg_next:
			shl		bx,1
			sbb		al,al
			and		al,1
			stosb
			loop	putbin_16reg_next
			mov		al,0ffh
			stosb
			call	putbin
			ret
putbin_16reg		endp

;------------------------------------------------------------------------------
; ２進数表示共通部分
putbin		proc
			push	si
			mov		bh,0
			mov		si,offset buffer
	putbin_next:
			lodsb
			cmp		al,0ffh
			jz		putbin_exit
			add		al,'0'
			mov		dl,al
			mov		ax,0200h
			int		21h
			jmp		putbin_next
	putbin_exit:
			pop		si
			ret
putbin		endp

buffer		db		32 dup(?)
;\@KILL
			end
;\@END
