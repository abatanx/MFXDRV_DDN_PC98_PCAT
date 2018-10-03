;==============================================================================
; MFXDDN sound driver module
;						YAMAHA YM2608 FM(OPNA) driver
;  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; OPN ���ʊ֌W����
;
			jumps
			.186
			.model	tiny
			.code

include		stdio.inc
include		ddn.inc
include		opna.inc
include		opnaexp.inc

.data
algvoltype	db	0001b			; ALG#0		������ OP1....OP4
			db	0001b			; ALG#1		�ŁA1�̂Ƃ��A���̃I�y���[�^��
			db	0001b			; ALG#2		TL��ω������ĉ��ʂ�ς���B
			db	0001b			; ALG#3
			db	0101b			; ALG#4
			db	0111b			; ALG#5
			db	0111b			; ALG#6
			db	1111b			; ALG#7

OP1			equ	1000b
OP2			equ	0100b
OP3			equ	0010b
OP4			equ	0001b
.code

;------------------------------------------------------------------------------
; ���ʂ�ݒ肷��
;ah		�`�����l��
set_volume	proc
			mov		bx,cs
			mov		ds,bx
			push	ax
			xor		bx,bx
			mov		bl,ah
			mov		al,[bx+volume_buf]
			mov		cl,[bx+exp_buf]
			inc		cl
			mul		cl
			shr		ax,7
			mov		cl,[velo_buf+bx]
			inc		cl
			mul		cl
			shr		ax,7				; al<-����
			mov		cl,[mastervol]
			mul		cl
			shr		ax,7				; al<-OPN���ۂ̉���
			cmp		ax,127
			jbe		sv_ok
			mov		ax,127
	sv_ok:
			cmp		[volumerevision],FALSE
			jz		sv_skip_revision
			mov		bx,offset log10
			xlat						;     ���ʕ␳
	sv_skip_revision:
			mov		cl,al				; cl<-�␳��̎��ۂ̉���
			xor		cl,127				; ���ʐݒ�l
			pop		bx
			mov		ch,bh				; ch<-�`�����l��
			mov		bl,bh
			xor		bh,bh				; bx<-�`�����l��

			mov		al,[bx+FBALG]		; FB/ALG ��ǂݏo��
			and		al,00000111b		; ALG���������o��
			xor		bx,bx
			mov		bl,al
			mov		al,[bx+algvoltype]	; VOLUME�ω�������OP.�ԍ����擾
	op1_vol:
			test	al,OP1
			jz		op2_vol
			mov		bh,YM2203_TL1
			add		bh,ch
			mov		bl,cl
			call	write_opnareg
	op2_vol:
			test	al,OP2
			jz		op3_vol
			mov		bh,YM2203_TL2
			add		bh,ch
			mov		bl,cl
			call	write_opnareg
	op3_vol:
			test	al,OP3
			jz		op4_vol
			mov		bh,YM2203_TL3
			add		bh,ch
			mov		bl,cl
			call	write_opnareg
	op4_vol:
			test	al,OP4
			jz		opx_vol_end
			mov		bh,YM2203_TL4
			add		bh,ch
			mov		bl,cl
			call	write_opnareg
	opx_vol_end:
			ret
set_volume	endp

end