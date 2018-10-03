;==============================================================================
; MFXDDN sound driver module
;                       YAMAHA YM3812 FM(OPL2) driver (Sound Braster) for DOS/V
;  copyright (c) 1995 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; OPL2 ターミナル部分
;
			jumps
			.186
			.model  tiny
			.code

include         stdio.inc
include         ddn.inc
include         sb.inc
include         sbfltr.inc
include         usertool.inc

;------------------------------------------------------------------------------
; ウェイト
; cx;回数
wa                      proc
			public  wa
			push    ax
			push	bx
			push	cx
			push    dx
			mov             dx,cs:OPL2PORT1
	opl2wx:
			in              al,dx
			test   			al,80h
			jnz             opl2wx
if	DOSV	eq	TRUE
;			mov		ah,86h
;			mov		cx,0
;			mov		dx,100
;			int		15h
			rept	7
			jmp		$+2
			endm
else
			rept	7
			out		5fh,al
			endm
endif
			pop             dx
			pop				cx
			pop				bx
			pop             ax
			ret
wa                      endp

__regwait       macro
			push    cx
			call    wa
			pop             cx
			endm

;------------------------------------------------------------------------------
; OPL2 レジスタにデータを書き込む
;bh             レジスタ番号
;bl             データ
;
write_opl2reg           proc
			pushf
			push    ax
			push    dx
			
			mov             dx,cs:OPL2PORT1
			mov             al,bh
			_out            dx,al
			call    wa
			mov             dx,cs:OPL2PORT2
			mov             al,bl
			_out            dx,al
			call    wa

			pop             dx
			pop             ax
			popf
			ret
write_opl2reg   endp

;------------------------------------------------------------------------------
; OPL2 レジスタからデータを読み込む
;bh             レジスタ番号
;
read_opl2reg            proc
			pushf
			push    ax
			push    cx
			push    dx
			cli
			mov             dx,OPL2PORT1
	opl2read1:
			in              al,dx
			test    al,80h
			jnz             opl2read1

			mov             cx,21/6+1
			__regwait

			mov             al,bh
			_out            dx,al

			mov             cx,21/6+1
			__regwait

	opl2read2:
			in              al,dx
			test    al,80h
			jnz             opl2read2

			mov             cx,21/6+1
			__regwait

			mov             dx,OPL2PORT2
			in              al,dx
			mov             bl,al
			pop             dx
			pop             cx
			pop             ax
			popf
			mov             al,bl

			ret
read_opl2reg    endp

;------------------------------------------------------------------------------
; MIXER レジスタにデータを書き込む
;bh             レジスタ番号
;bl             データ
;
write_opl2mixreg                proc

			pushf
			push    ax
			push    dx
			
			mov             dx,cs:OPL2MIXER1
			mov             al,bh
			_out            dx,al
			call    wa
			mov             dx,cs:OPL2MIXER2
			mov             al,bl
			_out            dx,al
			call    wa

			pop             dx
			pop             ax
			popf
			ret
write_opl2mixreg        endp

;------------------------------------------------------------------------------
; アウトレジスタチェック
;
if      DEBUG   eq      TRUE
outports        proc
			out     dx,al
			push_all
			push    cs
			pop             ds

			push    dx
			push    ax
			mov             ah,09h
			mov             dx,bx
			int             21h
			_put    '('
			putdec_16reg    cx,LEFTPUT
			_put    ')'
			pop             ax
			pop             dx

			push    dx
			push    ax
			_put    '_out '
			pop             ax
			pop             dx
			puthex_16reg    dx
			push    dx
			push    ax
			_put    'H,'
			pop             ax
			pop             dx
			puthex_8reg             al
			push    dx
			push    ax
			_puts   'H'
			pop             ax
			pop             dx
			pop_all
			ret
outports        endp
endif
			end

