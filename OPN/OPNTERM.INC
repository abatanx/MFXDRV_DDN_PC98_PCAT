;==============================================================================
; MFXDDN sound driver module
;						YAMAHA YM2203 FM(OPN) driver
;  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; OPN ターミナル部分マクロ
;
extrn	write_opnreg:near

opnwrt		macro	register,data
			mov		bh,register
			mov		bl,data
			call	write_opnreg
			endm

