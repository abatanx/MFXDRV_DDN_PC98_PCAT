;==============================================================================
; MFXDDN sound driver module
;                       YAMAHA YM3812 FM(OPL2) driver (Sound Braster) for DOS/V
;  copyright (c) 1995 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; OPL2 音量関係操作
;
			jumps
			.186
			.model  tiny
			.code

include         stdio.inc
include         usertool.inc
include         ddn.inc
include         sb.inc
include         sbexp.inc


;------------------------------------------------------------------------------
; 音量を設定する
;ah             チャンネル
set_volume      proc
			mov             bx,cs
			mov             ds,bx
			push		    ax
			xor             bx,bx
			mov             bl,ah
			mov             al,[bx+volume_buf]
			mov             cl,[bx+exp_buf]
			inc             cl
			mul             cl
			shr             ax,7
			mov             cl,[velo_buf+bx]
			inc             cl
			mul             cl
			shr             ax,7                            ; al<-音量
			mov             cl,[mastervol]
			inc				cl
			mul             cl
			shr             ax,7                            ; al<-OPL2実際の音量
			cmp             ax,127
			jbe             sv_ok
			mov             ax,127
	sv_ok:
			cmp             [volumerevision],FALSE
			jz              sv_skip_revision
			mov             bx,offset log10
			xlat                                            ;     音量補正
	sv_skip_revision:
			mov             cl,al                           ; cl<-補正後の実際の音量
			shr				cl,1
			xor             cl,63                           ; 音量設定値
			add             cl,[volumedown]
			cmp             cl,64
			jb              set_vpr
			mov             cl,63
	set_vpr:
			pop             bx
			mov				bl,bh
			xor				bh,bh
			mov             ch,bl                           ; ch<-チャンネル
			mov             al,[bx+YM3812_KSTL]             ; KSLTL を読み出す
			and             al,11000000b                    ; KSLだけ抜き出す
			or              al,cl                           ; KSLTL 設定
			mov             cl,[bx+CHTBL]
			mov				bl,al

			mov             bh,YM3812_KSTL
			add             bh,cl
			add             bh,3                          ; CARRIER選択
;			mov             bl,0                          ; test
            call    write_opl2reg
if   DEBUG   eq      TRUE                        
			puthex_8reg     bl
endif
			ret
set_volume      endp

end
