;==============================================================================
; MFXDDN sound driver
;						MIDI Interface driver for 98(GS)
;  copyright (c) 1993 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================

DRVIDNUM	equ		0001h				; DRV-ID number
ver_int		equ		1
ver_real	equ		00
ver_char	equ		' '

;------------------------------------
MIDI_BUFFERING		equ		FALSE	; MIDI buffering

MPU_INTERFACE		equ		1		; MPU401互換インターフェース
RS232C_INTERFACE	equ		2		; RS232Cインターフェース

; for MPU
ifndef			MPU_SYSIO
extrn			MPU_STATUS	:word
extrn			MPU_COMMAND	:word
extrn			MPU_DATA	:word
endif

MPU_INTERRUPT	equ		2
MPU_ACK			equ		0feh		; ACK
DRR				equ		40h			; bit mask of RECEVE is enable
DSR				equ		80h			; bit mask of SEND   is enable

datasiz			equ		8192		; データバッファサイズ

GM_MODULE		equ		1
GS_MODULE		equ		2

