;==============================================================================
; MFXDDN sound driver module
;			YAMAHA YM3812 FM(OPL2) driver (Sound Braster) for DOS/V
;  copyright (c) 1995 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; OPL2 ���F�֌W����
;
			jumps
			.186
			.model	tiny
			.code

include		stdio.inc
include		ddn.inc
include		sb.inc
include		sbdeflt.inc

;------------------------------------------------------------------------------
; ���F��������
;ah		�`�����l��(0..2)
;al		���F�ԍ�
;
set_voice	proc
			mov		bx,cs
			mov		ds,bx
			mov		es,bx
			xor		bx,bx
			cld
			mov		cx,[soundtblmax]
			or		cx,cx
			jz		sv_def
			mov		si,offset soundtbl
	sv_nex:
			cmp		[si].no,al
			jz		sv_searched
			add		si,type OPL2TONE
			loop	sv_nex
	sv_def:
			mov		ch,ah
			mov		si,offset opl2default
			mov		bx,cs
			mov		ds,bx
			jmp		sv_searched2

; ���F�o�^ main
	sv_searched:
			mov		bx,[si].datofs
			mov		dx,[si].datseg
			mov		si,bx
			mov		ds,dx
	sv_searched2:
			mov		ch,ah				; �݁[�������I
			add		si,5				; �g�����͂Ƃ΂��܁[���B
; �`�����l���R���o�[�g
			xor		bx,bx
			mov		bl,ch
			mov		cl,cs:[bx+CHTBL]
; �����������`
	sv_setsound:
			mov		ah,ch
			call	init_opl2sound

; Sound Charcteristic
			cld
			lodsw
			mov		bh,YM3812_AMVIB
			add		bh,cl
			mov		bl,al
			call	write_opl2reg		; MODULATER
			add		bh,3
			mov		bl,ah
			call	write_opl2reg		; CARRIER
; Key Scaling / Total Level
			lodsw
			mov		bh,YM3812_KSTL
			add		bh,cl
			mov		bl,al
			call	write_opl2reg		; MODULATER
			add		bh,3
			mov		bl,ah
			call	write_opl2reg		; CARRIER

			xor		bx,bx
			mov		bl,ch
			mov		cs:[KSLTL+bx],ah	; ���ʒ����p�ɕۑ����悧�B
; Attack rate / Decay rate
			lodsw
			mov		bh,YM3812_ARDR
			add		bh,cl
			mov		bl,al
			call	write_opl2reg		; MODULATER
			add		bh,3
			mov		bl,ah
			call	write_opl2reg		; CARRIER
; Sustin level / Release rate
			lodsw
			mov		bh,YM3812_SLRR
			add		bh,cl
			mov		bl,al
			call	write_opl2reg		; MODULATER
			add		bh,3
			mov		bl,ah
			call	write_opl2reg		; CARRIER
; Wave Style
			lodsw
			mov		bh,YM3812_WS
			add		bh,cl
			mov		bl,al
			call	write_opl2reg		; MODULATER
			add		bh,3
			mov		bl,ah
			call	write_opl2reg		; CARRIER
; FEEDBACK & Connection
			lodsb
			mov		bh,YM3812_FBCON
			add		bh,ch
			mov		bl,al
			call	write_opl2reg

			mov		ah,ch
			call	set_volume
			
			ret
			
set_voice	endp

			end
