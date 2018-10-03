;==============================================================================
; MFXDDN sound driver module
;						YAMAHA YM2203 FM(OPN) driver
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
include		opn.inc
include		opnfltr.inc

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
			local	__reg_adr
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

			pushf
			push	ax
			push	cx
			push	dx
			push	ds
			mov		ax,cs
			mov		ds,ax
			
			mov		dx,OPNPORT1
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

			mov		dx,OPNPORT2
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

			pop		ds
			pop		dx
			pop		cx
			pop		ax
			popf
		
			ret
write_opnreg	endp

;------------------------------------------------------------------------------
; OPN レジスタからデータを読み込む
;bh		レジスタ番号
;
read_opnreg		proc

			pushf
			push	ax
			push	cx
			push	dx
			cli
			mov		dx,OPNPORT1
	opnread1:
			in		al,dx
			test	al,80h
			jnz		opnread1

			mov		cx,21/6+1
			__regwait

			mov		al,bh
			out		dx,al

			mov		cx,21/6+1
			__regwait

	opnread2:
			in		al,dx
			test	al,80h
			jnz		opnread2

			mov		cx,21/6+1
			__regwait

			mov		dx,OPNPORT2
			in		al,dx
			mov		bl,al
			pop		dx
			pop		cx
			pop		ax
			popf
			mov		al,bl

			ret
read_opnreg	endp

			end
