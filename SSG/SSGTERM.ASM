;==============================================================================
; MFXDDN sound driver module
;						YAMAHA YM2203 SSG driver
;  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; OPN ターミナル部分
;
			jumps
			.186
			.model	tiny
			.code

include		stdio.inc
include		ddn.inc
include		ssg.inc

;------------------------------------------------------------------------------
; ウェイト
; cx;回数
wa			proc
			shr		cx,1
	waits:
			out		5fh,al
			loop	waits
			ret
wa			endp

__regwait	macro
			push	cx
			call	wa
			pop		cx
			endm

;------------------------------------------------------------------------------
; OPN レジスタにデータを書き込む
;bh		レジスタ番号
;bl		データ
;
write_opnreg		proc
			public	write_opnreg
			pushf
			push	ax
			push	cx
			push	dx
			cli
			mov		dx,188h
	opnwrt1:
			in		al,dx
			test	al,80h
			jnz		opnwrt1

			mov		cx,21/6+1
			__regwait

			mov		al,bh
			out		dx,al

			mov		cx,21/6+1
			__regwait

	opnwrt2:
			in		al,dx
			test	al,80h
			jnz		opnwrt2

			mov		cx,21/6+1
			__regwait

			mov		dx,18ah
			mov		al,bl
			out		dx,al

			cmp		bh,0a0h
			jnb		wait_a0b6
			cmp		bh,21h
			jnb		wait_219e
			cmp		bh,11h
			jnb		wait_111d
			cmp		bh,10h
			jz		wait_10
	wait_000f:
			mov		cx,21/6+1
			jmp		wait_start
	wait_10:
			mov		cx,720/6+1
			jmp		wait_start
	wait_111d:
			mov		cx,194/6+1
			jmp		wait_start
	wait_219e:
			mov		cx,194/6+1
			jmp		wait_start
	wait_a0b6:
			mov		cx,59/6+1
	wait_start:
			__regwait

			pop		dx
			pop		cx
			pop		ax
			popf
		
			ret
write_opnreg	endp
			end
