;==============================================================================
; MFXDDN sound driver module
;                       YAMAHA YM3812 FM(OPL2) driver (Sound Braster) for DOS/V
;  copyright (c) 1995 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; OPL2 初期化部
;
			jumps
			.186
			.model  tiny
			.code

include         stdio.inc
include         ddn.inc
include         option.inc
include         sb.inc
include         sbterm.inc

;------------------------------------------------------------------------------
; 発生している音を消去する
; ah:チャンネル
init_opl2sound  proc
		push    bx
		push    cx
		
		xor             bx,bx
		mov             bl,ah
		mov             ch,ah

		mov             cl,cs:[CHTBL+bx]

		mov             bh,YM3812_KSTL
		add             bh,cl
		mov             bl,03fh
		call            write_opl2reg
		add             bh,3
		mov             bl,03fh
		call            write_opl2reg

		mov             bh,YM3812_SLRR
		add             bh,cl
		mov             bl,0ffh
		call            write_opl2reg
		add             bh,3
		mov             bl,0ffh
		call            write_opl2reg

		mov             bh,YM3812_ARDR
		add             bh,cl
		mov             bl,0ffh
		call            write_opl2reg
		add             bh,3
		mov             bl,0ffh
		call            write_opl2reg

		mov             bh,YM3812_AMVIB
		add             bh,cl
		mov             bl,00h
		call            write_opl2reg
		add             bh,3
		mov             bl,00h
		call            write_opl2reg

		mov             bh,YM3812_WS
		add             bh,cl
		mov             bl,00h
		call            write_opl2reg
		add             bh,3
		mov             bl,00h
		call            write_opl2reg

		mov             bh,YM3812_FBCON
		add             bh,cl
		mov             bl,00h
		call            write_opl2reg
		add             bh,3
		mov             bl,00h
		call            write_opl2reg

        mov             bh,YM3812_FNUM_H
        add             bh,ch
        mov             bl,0
        call            write_opl2reg

        mov             bh,YM3812_FNUM_L
        add             bh,ch
        mov             bl,0
        call            write_opl2reg

        mov             bh,YM3812_DRUMS
        mov             bl,0
        call            write_opl2reg

		pop             cx
		pop             bx
		ret
init_opl2sound  endp

;------------------------------------------------------------------------------
; バッファを初期化
;
init_opl2buf            proc
		
		mov             ax,cs
		mov             es,ax
		mov             ds,ax
		cld

		mov             di,offset volume_buf
		mov             cx,MAXCHANNEL
		mov             ax,100
		rep             stosb

		mov             di,offset exp_buf
		mov             cx,MAXCHANNEL
		mov             ax,127
		rep             stosb

		mov             di,offset velo_buf
		mov             cx,MAXCHANNEL
		mov             ax,0
		rep             stosb

		mov             di,offset fnumber1
		mov             cx,MAXCHANNEL
		mov             al,0
		rep             stosb

		mov             di,offset fnumber2
		mov             cx,MAXCHANNEL
		mov             al,0
		rep             stosb

		mov             di,offset pitch
		mov             cx,MAXCHANNEL
		mov             ax,0
		rep             stosw

		mov             [mastervol],127
		mov             [soundtblmax],0
		mov             [volumerevision],TRUE
		ret
init_opl2buf            endp

		end

