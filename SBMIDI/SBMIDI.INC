;==============================================================================
; MFXDDN sound driver
;						MIDI Interface driver for 98(GS)
;  copyright (c) 1993 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================

DRVIDNUM	equ		0001h				; DRV-ID number
ver_int		equ		1
ver_real	equ		00
ver_char	equ		' '

DRR				equ		40h			; bit mask of RECEVE is enable
DSR				equ		80h			; bit mask of SEND   is enable

GM_MODULE		equ		1
GS_MODULE		equ		2

comment#
DSP_RESET		equ		226h
DSP_READ		equ		22ah
DSP_COMMAND		equ		22ch
DSP_DATA		equ		22ch
DSP_WSTATUS		equ		22ch
DSP_DSTATUS		equ		22eh
#

global	DSP_RESET,DSP_READ,DSP_COMMAND,DSP_DATA:word
global	DSP_WSTATUS,DSP_DSTATUS:word

global	INTERFACE,MODULE:word

global	progchg:word					; プログラムチェンジフラグ
global	volume_buf:word:16				; ボリュームバッファ
global	mastervol_buf:word				; masterボリュームバッファ

