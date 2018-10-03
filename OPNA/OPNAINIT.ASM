;==============================================================================
; MFXDDN sound driver module
;						YAMAHA YM2608 FM(OPNA) driver
;  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; OPN 初期化部
;
			jumps
			.186
			.model	tiny
			.code

include		stdio.inc
include		ddn.inc
include		option.inc
include		opna.inc

;------------------------------------------------------------------------------
; 発生している音を消去する
; ah:チャンネル
init_opnsound	proc
		push	bx
		push	cx

		mov		bx,8000h
		add		bh,ah
		call	write_opnareg
		
		mov		bx,8400h
		add		bh,ah
		call	write_opnareg
		
		mov		bx,8800h
		add		bh,ah
		call	write_opnareg
		
		mov		bx,8c00h
		add		bh,ah
		call	write_opnareg
		
		mov		bx,407fh
		add		bh,ah
		call	write_opnareg
		
		mov		bx,447fh
		add		bh,ah
		call	write_opnareg
		
		mov		bx,487fh
		add		bh,ah
		call	write_opnareg
		
		mov		bx,4c7fh
		add		bh,ah
		call	write_opnareg

		pop		cx
		pop		bx
		ret
init_opnsound	endp

;------------------------------------------------------------------------------
; バッファを初期化
;
init_opnbuf		proc
		
		mov		ax,cs
		mov		es,ax
		mov		ds,ax
		cld

		mov		di,offset volume_buf
		mov		cx,3
		mov		ax,100
		rep		stosb

		mov		di,offset exp_buf
		mov		cx,3
		mov		ax,127
		rep		stosb

		mov		di,offset velo_buf
		mov		cx,3
		mov		ax,0
		rep		stosb

		mov		di,offset fnumber1
		mov		cx,3
		mov		al,0
		rep		stosb

		mov		di,offset fnumber2
		mov		cx,3
		mov		al,0
		rep		stosb

		mov		[mastervol],127
		mov		[soundtblmax],0
		mov		[volumerevision],TRUE
		ret
init_opnbuf		endp

		end

