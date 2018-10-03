;==============================================================================
; MFXDDN sound driver module
;						YAMAHA YM2608 FM(OPNA) driver
;  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; OPN ���F�֌W����
;
			jumps
			.186
			.model	tiny
			.code

include		stdio.inc
include		ddn.inc
include		opna.inc
include		opndeflt.inc

FBALG		db		3 dup(?)			; FB/ALG �ۑ��p�o�b�t�@

;------------------------------------------------------------------------------
; ���F��������
;ah		�`�����l��(0..2)
;al		���F�ԍ�
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
;			ret							; ���o�^�B�����炸T_T

; ���F�o�^ main
	sv_searched:
			mov		ch,ah				; �݁[�������I
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
			
; �����������`
	sv_setsound:
			mov		bh,YM2203_NOTE
			mov		bl,ch
			call	write_opnareg
			mov		ah,ch
			call	init_opnsound
; �f�B�`���[���^�}���`�v���C���W�X�^�ݒ�
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
; �g�[�^�����x�����W�X�^�ݒ�
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
; �L�[�{�[�h���[�g�X�P�[�����O�[���^�A�^�b�N���W�X�^�ݒ�
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
; �f�B�P�C���W�X�^�ݒ�
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
; �T�X�e�B�����W�X�^�ݒ�
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
; �T�X�e�B�����x���^�����[�X�W�����W�X�^�ݒ�
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
; �t�B�[�h�o�b�N�^�A���S���Y�����W�X�^�ݒ�
			lodsb
			mov		bh,YM2203_FBALG
			add		bh,ch
			mov		bl,al
			call	write_opnareg
			pop		si
			pop		ds
			
			xor		bx,bx
			mov		bl,ch
			mov		[bx+FBALG],al		; FB/ALG�ۑ�
			
			mov		ah,ch
			call	set_volume
			
			ret
			
set_voice	endp

			end