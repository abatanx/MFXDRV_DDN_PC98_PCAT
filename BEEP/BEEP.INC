;==============================================================================
; MFXDDN sound driver
;						BEEP Interface driver for 98(GS)
;  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; HEADER FILE
;
%tabsize	4

_10MHZ		equ		1
_8MHZ		equ		2

OCTAVE		=	12

beep_on		macro
			mov		al,06h
			out		37h,al
			out		5fh,al
			out		5fh,al
			endm

beep_off	macro
			mov		al,07h
			out		37h,al
			out		5fh,al
			out		5fh,al
			endm

beep_set	macro
			push	ax
			mov		dx,3fdfh
			mov		al,76h
			out		77h,al
			out		5fh,al
			out		5fh,al
			pop		ax
			mov		dx,3fdbh

			out		73h,al
			xchg	ah,al
			out		5fh,al
			out		5fh,al
			out		73h,al
			out		5fh,al
			out		5fh,al
			endm

beep_set2	macro
			push	ax
			mov		al,76h
			out		77h,al
			out		5fh,al
			out		5fh,al
			pop		ax

			mov		dx,0073h
			out		dx,ax
			out		5fh,al
			out		5fh,al
			endm
