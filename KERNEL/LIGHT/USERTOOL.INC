;/////////////////////////////////////////////////////////////////////////////;
;      Multi module music driver MFXDDN(tm) kernel system release 0.00 
;  copyright (c) 1993 ABA / T.Kobayashi and Interfair  All Rights Reserved.
;ユーザーインターフェース
;/////////////////////////////////////////////////////////////////////////////;

RIGHTPUT	equ		1
LEFTPUT		equ		2

;8bitレジスタの１０進数表示
putdec_8reg		macro	numeric,type
			push	ax
			push	bx
			mov		bl,numeric
			mov		ah,30h
			mov		al,type
			int		50h
			pop		bx
			pop		ax
			endm

;16ビットレジスタの１０進表示
putdec_16reg	macro	numeric,type
			push	ax
			push	bx
			mov		bx,numeric
			mov		ah,30h
			mov		al,type
			int		50h
			pop		bx
			pop		ax
			endm

;8ビットレジスタの１６進表示
puthex_8reg		macro	numeric
			push	ax
			push	bx
			mov		bl,numeric
			mov		ah,31h
			int		50h
			pop		bx
			pop		ax
			endm

;16ビットレジスタの１６進表示
puthex_16reg	macro	numeric
			push	ax
			push	bx
			mov		bx,numeric
			mov		ah,34h
			int		50h
			pop		bx
			pop		ax
			endm

;8ビットレジスタの２進表示
putbin_8reg		macro	numeric
			push	ax
			push	bx
			mov		bl,numeric
			mov		ah,32h
			int		50h
			pop		bx
			pop		ax
			endm

;16ビットレジスタの２進表示
putbin_16reg	macro	numeric
			push	ax
			push	bx
			mov		bx,numeric
			mov		ax,35h
			int		50h
			pop		bx
			pop		ax
			endm

