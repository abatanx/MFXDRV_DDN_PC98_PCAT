;==============================================================================
; MFXDDN sound driver module
;                       YAMAHA YM3812 FM(OPL2) driver (Sound Braster) for DOS/V
;  copyright (c) 1995 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; OPL2 ���ʊ֌W����
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
; ���ʂ�ݒ肷��
;ah             �`�����l��
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
			shr             ax,7                            ; al<-����
			mov             cl,[mastervol]
			inc				cl
			mul             cl
			shr             ax,7                            ; al<-OPL2���ۂ̉���
			cmp             ax,127
			jbe             sv_ok
			mov             ax,127
	sv_ok:
			cmp             [volumerevision],FALSE
			jz              sv_skip_revision
			mov             bx,offset log10
			xlat                                            ;     ���ʕ␳
	sv_skip_revision:
			mov             cl,al                           ; cl<-�␳��̎��ۂ̉���
			shr				cl,1
			xor             cl,63                           ; ���ʐݒ�l
			add             cl,[volumedown]
			cmp             cl,64
			jb              set_vpr
			mov             cl,63
	set_vpr:
			pop             bx
			mov				bl,bh
			xor				bh,bh
			mov             ch,bl                           ; ch<-�`�����l��
			mov             al,[bx+YM3812_KSTL]             ; KSLTL ��ǂݏo��
			and             al,11000000b                    ; KSL���������o��
			or              al,cl                           ; KSLTL �ݒ�
			mov             cl,[bx+CHTBL]
			mov				bl,al

			mov             bh,YM3812_KSTL
			add             bh,cl
			add             bh,3                          ; CARRIER�I��
;			mov             bl,0                          ; test
            call    write_opl2reg
if   DEBUG   eq      TRUE                        
			puthex_8reg     bl
endif
			ret
set_volume      endp

end
