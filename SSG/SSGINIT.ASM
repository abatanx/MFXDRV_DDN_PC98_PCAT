;==============================================================================
; MFXDDN sound driver module
;						YAMAHA YM2203 SSG driver
;  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; SSG 初期化部
;
			jumps
			.186
			.model	tiny
			.code

include		stdio.inc
include		ddn.inc
include		option.inc
include		ssg.inc
include		ssgterm.inc

extrn		volume_buf:word
extrn		exp_buf:word
extrn		velo_buf:word
extrn		notestatus:byte
extrn		mastervol:word
extrn		soundtblmax:word
extrn		trflag:word
extrn		fnumber:word
;------------------------------------------------------------------------------
; 初期化
; ah:チャンネル
init_ssgsound	proc
		public	init_ssgsound
		push	bx
		mov		bx,0800h
		add		bh,ah
		call	write_opnreg
		mov		bx,07b8h
		call	write_opnreg
		mov		bx,0b00h
		call	write_opnreg
		mov		bx,0c00h
		call	write_opnreg
		mov		bx,0d00h
		call	write_opnreg
		mov		bx,0600h
		call	write_opnreg
		pop		bx
		ret
init_ssgsound	endp

;------------------------------------------------------------------------------
; バッファを初期化
;
init_ssgbuf		proc
		public	init_ssgbuf
		
		mov		ax,cs
		mov		es,ax
		mov		ds,ax
		cld

		mov		di,offset volume_buf
		mov		cx,3
		mov		ax,100
		rep		stosw

		mov		di,offset exp_buf
		mov		cx,3
		mov		ax,127
		rep		stosw

		mov		di,offset velo_buf
		mov		cx,3
		mov		ax,0
		rep		stosw

		mov		di,offset fnumber
		mov		cx,3
		mov		ax,0
		rep		stosw

		mov		di,offset trflag
		mov		cx,3
		mov		ax,FALSE
		rep		stosw
		
		mov		di,offset notestatus
		mov		cx,3
		mov		al,0
		rep		stosb
		
		mov		[mastervol],127
		
		mov		[soundtblmax],0
		ret
init_ssgbuf		endp

		end

