;==============================================================================
; MFXDDN sound driver module
;						YAMAHA YM2608 FM(OPNA) driver
;  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; OPN 音量関係操作
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
algvoltype	db	0001b			; ALG#0		左から OP1....OP4
			db	0001b			; ALG#1		で、1のとき、そのオペレータの
			db	0001b			; ALG#2		TLを変化させて音量を変える。
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
; 音量を設定する
;ah		チャンネル
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
			shr		ax,7				; al<-音量
			mov		cl,[mastervol]
			mul		cl
			shr		ax,7				; al<-OPN実際の音量
			cmp		ax,127
			jbe		sv_ok
			mov		ax,127
	sv_ok:
			cmp		[volumerevision],FALSE
			jz		sv_skip_revision
			mov		bx,offset log10
			xlat						;     音量補正
	sv_skip_revision:
			mov		cl,al				; cl<-補正後の実際の音量
			xor		cl,127				; 音量設定値
			pop		bx
			mov		ch,bh				; ch<-チャンネル
			mov		bl,bh
			xor		bh,bh				; bx<-チャンネル

			mov		al,[bx+FBALG]		; FB/ALG を読み出す
			and		al,00000111b		; ALGだけ抜き出す
			xor		bx,bx
			mov		bl,al
			mov		al,[bx+algvoltype]	; VOLUME変化させるOP.番号を取得
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
