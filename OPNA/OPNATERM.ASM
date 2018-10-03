;==============================================================================
; MFXDDN sound driver module
;						YAMAHA YM2608 FM(OPNA) driver
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
include		opna.inc
include		opnafltr.inc

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
; OPNA レジスタにデータを書き込む
;bh		レジスタ番号
;bl		データ
;
write_opnareg		proc

			pushf
			push	ax
			push	cx
			push	dx
			push	ds
			mov		ax,cs
			mov		ds,ax
			
			mov		dx,OPNPORT1
	opnawrt1:
			in		al,dx
			test	al,80h
			jnz		opnawrt1

			mov		cx,21/6+1
			__regwait

			mov		dx,OPNAPORT1
			mov		al,bh
			out		dx,al

			mov		cx,21/6+1
			__regwait

			mov		dx,OPNPORT1
	opnawrt2:
			in		al,dx
			test	al,80h
			jnz		opnawrt2

			mov		cx,21/6+1
			__regwait

			mov		dx,OPNAPORT2
			mov		al,bl
			out		dx,al

			cmp		bh,0a0h
			jnb		opna_wait_a0b6
			cmp		bh,21h
			jnb		opna_wait_219e
			cmp		bh,11h
			jnb		opna_wait_111d
			cmp		bh,10h
			jz		opna_wait_10
	opna_wait_000f:
			mov		cx,21/6+1
			jmp		opna_wait_start
	opna_wait_10:
			mov		cx,720/6+1
			jmp		opna_wait_start
	opna_wait_111d:
			mov		cx,194/6+1
			jmp		opna_wait_start
	opna_wait_219e:
			mov		cx,194/6+1
			jmp		opna_wait_start
	opna_wait_a0b6:
			mov		cx,59/6+1
	opna_wait_start:
			__regwait

			pop		ds
			pop		dx
			pop		cx
			pop		ax
			popf
		
			ret
write_opnareg	endp

;------------------------------------------------------------------------------
; OPNA レジスタからデータを読み込む
;bh		レジスタ番号
;
read_opnareg		proc
			pushf
			push	ax
			push	cx
			push	dx
			cli
			mov		dx,OPNPORT1
	opnaread1:
			in		al,dx
			test	al,80h
			jnz		opnaread1

			mov		cx,21/6+1
			__regwait

			mov		dx,OPNAPORT1
			mov		al,bh
			out		dx,al

			mov		cx,21/6+1
			__regwait

			mov		dx,OPNPORT1
	opnaread2:
			in		al,dx
			test	al,80h
			jnz		opnaread2

			mov		cx,21/6+1
			__regwait

			mov		dx,OPNAPORT2
			in		al,dx
			mov		bl,al
			pop		dx
			pop		cx
			pop		ax
			popf
			mov		al,bl

			ret
read_opnareg	endp

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

			mov		dx,OPNPORT1
			mov		al,bh
			out		dx,al

			mov		cx,21/6+1
			__regwait

			mov		dx,OPNPORT1
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
			jnb		opn_wait_a0b6
			cmp		bh,21h
			jnb		opn_wait_219e
			cmp		bh,11h
			jnb		opn_wait_111d
			cmp		bh,10h
			jz		opn_wait_10
	opn_wait_000f:
			mov		cx,21/6+1
			jmp		opn_wait_start
	opn_wait_10:
			mov		cx,720/6+1
			jmp		opn_wait_start
	opn_wait_111d:
			mov		cx,194/6+1
			jmp		opn_wait_start
	opn_wait_219e:
			mov		cx,194/6+1
			jmp		opn_wait_start
	opn_wait_a0b6:
			mov		cx,59/6+1
	opn_wait_start:
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

			mov		dx,OPNPORT1
			mov		al,bh
			out		dx,al

			mov		cx,21/6+1
			__regwait

			mov		dx,OPNPORT1
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