;==============================================================================
; MFXDDN sound driver module
;						YAMAHA YM2203 FM(OPN) driver
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
include		ssg.inc

extrn		write_opnreg:near
extrn		volume_buf:word
extrn		exp_buf:word
extrn		velo_buf:word
extrn		mastervol:word
extrn		notestatus:byte
extrn		trflag:word,trvolume:word

;------------------------------------------------------------------------------
; 音量を設定する
;ah		チャンネル
set_volume	proc
			public	set_volume
			push	bp
			mov		bx,cs
			mov		ds,bx

			mov		bp,ax					; bpに保存
			xor		bx,bx
			mov		bl,ah
			cmp		[notestatus+bx],0
			jz		sv_end					; NOTEがないので...
			shl		bx,1
			mov		al,byte ptr [volume_buf+bx]
			mov		cl,byte ptr [exp_buf+bx]
			inc		cl
			mul		cl
			shr		ax,7
			mov		cl,byte ptr [velo_buf+bx]
			inc		cl
			mul		cl
			shr		ax,7
			
			cmp		[trflag+bx],FALSE
			jz		sv_master
			push	ax
			mov		al,byte ptr [trvolume+bx]
			mov		ah,8
			imul	ah
			mov		bx,ax
			pop		ax
			add		ax,bx

			cmp		ax,128
			jl		sv0_ok1
			mov		ax,127
			jmp		sv_master
	sv0_ok1:
			cmp		ax,0
			jnl		sv_master
			mov		ax,0
			
	sv_master:
			mov		cl,byte ptr [mastervol]
			inc		cl
			mul		cl
			shr		ax,10					; al<-実際の音量

			mov		bx,bp				; bpに保存
			add		bh,08h				; bh=ch+08h
			mov		bl,al
			call	write_opnreg
	sv_end:
			pop		bp
			ret
set_volume	endp

end
