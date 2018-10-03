;==============================================================================
; MFXDDN sound driver module
;						MIDI Interface driver for 98
;  copyright (c) 1993 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; ターミナル部分
;
			jumps
			.186
			.model	tiny
			.code

include		stdio.inc
include		ddn.inc
include		sbmidi.inc
;------------------------------------------------------------------------------
; データバッファ初期化
;
init_databuf	proc
			public	init_databuf
			mov		[mastervol_buf],127
	
			mov		cx,16
			mov		ax,cs
			mov		es,ax
			mov		di,offset volume_buf
			cld
			mov		ax,100
			rep		stosw
	
			ret
init_databuf	endp

;------------------------------------------------------------------------------
; ＭＩＤＩ演奏データバッファにデータをため込む
;al		データ
;
midi_out	proc
			public	midi_out
			push	dx
			push	ax
	mo_wait1:
			mov		dx,cs:DSP_WSTATUS
			in		al,dx
			test	al,80h
			jnz		mo_wait1

			mov		dx,cs:DSP_COMMAND
			pop		ax
			out		dx,al

			pop		dx
			ret
midi_out	endp

			end
