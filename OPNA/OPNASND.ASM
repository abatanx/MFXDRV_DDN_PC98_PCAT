;==============================================================================
; MFXDDN sound driver module
;						YAMAHA YM2608 FM(OPNA) driver
;  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; OPN 音色関係操作
;
			jumps
			.186
			.model	tiny
			.code

include		stdio.inc
include		ddn.inc
include		opna.inc
include		opndeflt.inc

FBALG		db		3 dup(?)			; FB/ALG 保存用バッファ

;------------------------------------------------------------------------------
; 音色書き込み
;ah		チャンネル(0..2)
;al		音色番号
;
set_voice	proc
			mov		bx,cs
			mov		ds,bx
			mov		es,bx
			cld
			mov		cx,[soundtblmax]
			or		cx,cx
			jz		sv_def
			mov		si,offset soundtbl
	sv_nex:
			cmp		[si].no,al
			jz		sv_searched
			add		si,type OPNTONE
			loop	sv_nex
	sv_def:
			mov		ch,ah
			push	ds
			push	si
			mov		si,offset opndefault
			mov		bx,cs
			mov		ds,bx
			mov		bx,si
			mov		dx,ds
			jmp		sv_searched2
;			ret							; 未登録。見つからずT_T

; 音色登録 main
	sv_searched:
			mov		ch,ah				; みーつけたっ！
			push	ds
			push	si
			mov		bx,[si].datofs
			mov		dx,[si].datseg
			mov		si,bx
			mov		ds,dx
	sv_searched2:
			mov		al,type MODTABLE
			mul		ch
			mov		bx,ax
			add		bx,offset lfo

			cld
			lodsw
			mov		es:[bx].mod_sync,ax
			lodsw
			mov		es:[bx].mod_speed,ax
			mov		es:[bx].mod_flag,MOD_STANDBY
			mov		es:[bx].mod_sync_cnt,0
			mov		es:[bx].mod_trace,0
			lodsb
			cmp		es:[bx].mod_speed,0
			jnz		sv_setsound
			mov		es:[bx].mod_flag,MOD_NOACTIVE
			
; 発音をけす～
	sv_setsound:
			mov		bh,YM2203_NOTE
			mov		bl,ch
			call	write_opnareg
			mov		ah,ch
			call	init_opnsound
; ディチューン／マルチプライレジスタ設定
			lodsw
			mov		bh,YM2203_DT1ML1
			add		bh,ch
			mov		bl,al
			call	write_opnareg
			mov		bh,YM2203_DT3ML3
			add		bh,ch
			mov		bl,ah
			call	write_opnareg

			lodsw
			mov		bh,YM2203_DT2ML2
			add		bh,ch
			mov		bl,al
			call	write_opnareg
			mov		bh,YM2203_DT4ML4
			add		bh,ch
			mov		bl,ah
			call	write_opnareg
; トータルレベルレジスタ設定
			lodsw
			mov		bh,YM2203_TL1
			add		bh,ch
			mov		bl,al
			call	write_opnareg
			mov		bh,YM2203_TL3
			add		bh,ch
			mov		bl,ah
			call	write_opnareg

			lodsw
			mov		bh,YM2203_TL2
			add		bh,ch
			mov		bl,al
			call	write_opnareg
			mov		bh,YM2203_TL4
			add		bh,ch
			mov		bl,ah
			call	write_opnareg
; キーボードレートスケーリング深さ／アタックレジスタ設定
			lodsw
			mov		bh,YM2203_KS1AR1
			add		bh,ch
			mov		bl,al
			call	write_opnareg
			mov		bh,YM2203_KS3AR3
			add		bh,ch
			mov		bl,ah
			call	write_opnareg

			lodsw
			mov		bh,YM2203_KS2AR2
			add		bh,ch
			mov		bl,al
			call	write_opnareg
			mov		bh,YM2203_KS4AR4
			add		bh,ch
			mov		bl,ah
			call	write_opnareg
; ディケイレジスタ設定
			lodsw
			mov		bh,YM2203_DR1
			add		bh,ch
			mov		bl,al
			call	write_opnareg
			mov		bh,YM2203_DR3
			add		bh,ch
			mov		bl,ah
			call	write_opnareg

			lodsw
			mov		bh,YM2203_DR2
			add		bh,ch
			mov		bl,al
			call	write_opnareg
			mov		bh,YM2203_DR4
			add		bh,ch
			mov		bl,ah
			call	write_opnareg
; サスティンレジスタ設定
			lodsw
			mov		bh,YM2203_SR1
			add		bh,ch
			mov		bl,al
			call	write_opnareg
			mov		bh,YM2203_SR3
			add		bh,ch
			mov		bl,ah
			call	write_opnareg

			lodsw
			mov		bh,YM2203_SR2
			add		bh,ch
			mov		bl,al
			call	write_opnareg
			mov		bh,YM2203_SR4
			add		bh,ch
			mov		bl,ah
			call	write_opnareg
; サスティンレベル／リリース係数レジスタ設定
			lodsw
			mov		bh,YM2203_SL1RR1
			add		bh,ch
			mov		bl,al
			call	write_opnareg
			mov		bh,YM2203_SL3RR3
			add		bh,ch
			mov		bl,ah
			call	write_opnareg

			lodsw
			mov		bh,YM2203_SL2RR2
			add		bh,ch
			mov		bl,al
			call	write_opnareg
			mov		bh,YM2203_SL4RR4
			add		bh,ch
			mov		bl,ah
			call	write_opnareg
; フィードバック／アルゴリズムレジスタ設定
			lodsb
			mov		bh,YM2203_FBALG
			add		bh,ch
			mov		bl,al
			call	write_opnareg
			pop		si
			pop		ds
			
			xor		bx,bx
			mov		bl,ch
			mov		[bx+FBALG],al		; FB/ALG保存
			
			mov		ah,ch
			call	set_volume
			
			ret
			
set_voice	endp

			end
