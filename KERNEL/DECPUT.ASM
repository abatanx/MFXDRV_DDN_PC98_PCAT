;/////////////////////////////////////////////////////////////////////////////;
;
;      Multi module music driver MFXDDN(tm) kernel system release 0.00 
;  MFXDDN(tm) Music driver For XMML , Deconcentrate Drivers Network System
;  copyright (c) 1993 ABA / T.Kobayashi and Interfair  All Rights Reserved.
;
;/////////////////////////////////////////////////////////////////////////////;
;プログラマーズインターフェース
; １０進数表示
;
IF	PROGMODE		EQ	COMTYPE
MFXDRVDDN_KERNEL	equ	TRUE
include		model.inc
include		stdio.inc
include		ddn.inc
			.code
ENDIF

NUML		equ		1
NUMR		equ		2

;------------------------------------------------------------------------------
;８ビットレジスタの１０進数表示
;	al <- 数値
;	bl <- フォーマットタイプ	(1:左詰め 2:右詰め)
;
putdec_8reg		proc
			mov		di,offset buffer
			cld
			xor		ah,ah
			mov		dl,100
			div		dl
			stosb
			mov		al,ah
			xor		ah,ah
			mov		dl,10
			div		dl
			stosb
			mov		al,ah
			stosb
			mov		al,0ffh
			stosb

			cmp		bl,NUMR
			jz		putdec_8reg_right
			call	putdec_lp
			ret
	putdec_8reg_right:
			call	putdec_rp
			ret
putdec_8reg		endp

;------------------------------------------------------------------------------
;１６ビットレジスタの１０進数表示
;	ax <- 数値
;	bl <- フォーマットタイプ	(1:左詰め 2:右詰め)
;
putdec_16reg	proc
			mov		di,offset buffer
			cld
			xor		dx,dx
			mov		cx,10000
			div		cx
			stosb
			mov		ax,dx
			xor		dx,dx
			mov		cx,1000
			div		cx
			stosb
			mov		ax,dx
			xor		dx,dx
			mov		cx,100
			div		cx
			stosb
			mov		ax,dx
			xor		dx,dx
			mov		cx,10
			div		cx
			stosb
			mov		al,dl
			stosb
			mov		al,0ffh
			stosb

			cmp		bl,NUMR
			jz		putdec_16reg_right
			call	putdec_lp
			ret
	putdec_16reg_right:
			call	putdec_rp
			ret
putdec_16reg		endp

;------------------------------------------------------------------------------
; １０進数左詰め表示共通部分
putdec_lp	proc
			push	si
			mov		bh,0
			mov		si,offset buffer
	putdec_lp_next:
			lodsb
			cmp		al,0ffh
			jz		putdec_lp_exit
			cmp		al,0					; 数値が0かどうか
			jnz		putdec_lp_not_zero
			cmp		bh,0					; すでに0以外の数値がでているか
			jz		putdec_lp_next			; でてない
	putdec_lp_not_zero:
			mov		bh,1
			add		al,'0'
			mov		dl,al
			mov		ax,0200h
			int		21h
			jmp		putdec_lp_next
	putdec_lp_exit:
			cmp		bh,0
			jnz		putdec_lp_normexit
			mov		dl,'0'
			mov		ax,0200h
			int		21h
	putdec_lp_normexit:
			pop		si
			ret
putdec_lp	endp

;------------------------------------------------------------------------------
; １０進数右詰め表示共通部分
putdec_rp	proc
			push	si
			mov		bh,0
			mov		si,offset buffer
	putdec_rp_next:
			lodsb
			cmp		al,0ffh
			jz		putdec_rp_exit
			cmp		al,0					; 数値が0かどうか
			jnz		putdec_rp_not_zero
			cmp		bh,0					; すでに0以外の数値がでているか
			jnz		putdec_rp_not_zero		; でてる
			mov		dl,' '
			mov		ax,0200h
			int		21h
			jmp		putdec_rp_next
	putdec_rp_not_zero:
			mov		bh,1
			add		al,'0'
			mov		dl,al
			mov		ax,0200h
			int		21h
			jmp		putdec_rp_next
	putdec_rp_exit:
			cmp		bh,0
			jnz		putdec_rp_normexit
			mov		dl,08h
			mov		ax,0200h
			int		21h
			mov		dl,'0'
			mov		ax,0200h
			int		21h
	putdec_rp_normexit:
			pop		si
			ret
putdec_rp	endp

;\@KILL
buffer		db		10 dup(?)
			end
;\@END
