;/////////////////////////////////////////////////////////////////////////////;
;      Multi module music driver MFXDDN(tm) kernel system release 0.00 
;  copyright (c) 1993 ABA / T.Kobayashi and Interfair  All Rights Reserved.
;���[�U�[�C���^�[�t�F�[�X
;/////////////////////////////////////////////////////////////////////////////;

RIGHTPUT	equ		1
LEFTPUT		equ		2

;8bit���W�X�^�̂P�O�i���\��
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

;16�r�b�g���W�X�^�̂P�O�i�\��
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

;8�r�b�g���W�X�^�̂P�U�i�\��
puthex_8reg		macro	numeric
			push	ax
			push	bx
			mov		bl,numeric
			mov		ah,31h
			int		50h
			pop		bx
			pop		ax
			endm

;16�r�b�g���W�X�^�̂P�U�i�\��
puthex_16reg	macro	numeric
			push	ax
			push	bx
			mov		bx,numeric
			mov		ah,34h
			int		50h
			pop		bx
			pop		ax
			endm

;8�r�b�g���W�X�^�̂Q�i�\��
putbin_8reg		macro	numeric
			push	ax
			push	bx
			mov		bl,numeric
			mov		ah,32h
			int		50h
			pop		bx
			pop		ax
			endm

;16�r�b�g���W�X�^�̂Q�i�\��
putbin_16reg	macro	numeric
			push	ax
			push	bx
			mov		bx,numeric
			mov		ax,35h
			int		50h
			pop		bx
			pop		ax
			endm
