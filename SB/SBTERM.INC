;==============================================================================
; MFXDDN sound driver module
;			YAMAHA YM3812 FM(OPL2) driver (Sound Braster) for DOS/V
;  copyright (c) 1995 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; OPN ターミナル部分マクロ
;
extrn	write_opl2reg:near

opl2wrt		macro	register,data
			mov		bh,register
			mov		bl,data
			call	write_opl2reg
			endm

