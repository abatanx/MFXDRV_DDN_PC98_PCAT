;==============================================================================
; MFXDDN sound driver module
;						YAMAHA YM2203 FM(OPN) driver
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
include		ssg.inc

extrn		trflag:word,trofs:word,trseg:word
extrn		trpointer:word,trcounter:word,trvolume:word
extrn		soundtblmax:word
extrn		soundtbl:SSGTONE
extrn		set_volume:near,lfo:MODTABLE
;------------------------------------------------------------------------------
; ���F��������
;ah		�`�����l��(0..2)
;al		���F�ԍ�
;
set_voice	proc
			public	set_voice
			xor		bx,bx
			mov		bl,ah
			shl		bx,1

			mov		cx,[soundtblmax]
			or		cx,cx
			jz		sv_end
			mov		si,offset soundtbl
	sv_search:
			cmp		[si].no,al
			jz		sv_found
			add		si,type SSGTONE
			loop	sv_search
			mov		[trflag+bx],FALSE
			jmp		sv_end
	sv_found:
			mov		ch,ah				; �݁[�������I
			push	ds
			push	si
			push	bx
			mov		ax,cs
			mov		es,ax
			mov		bx,[si].datofs
			mov		dx,[si].datseg
			mov		si,bx
			mov		ds,dx

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
	sv_setsound:
			pop		bx
			pop		si
			pop		ds

			mov		[trflag+bx],TRUE
			mov		ax,[si].datofs
			add		ax,5					; MOD�e�[�u�����X�L�b�v
			mov		[trofs+bx],ax
			mov		ax,[si].datseg
			mov		[trseg+bx],ax
			mov		[trpointer+bx],0
			mov		[trcounter+bx],1
			mov		[trvolume +bx],0
	sv_end:
			ret
set_voice	endp

;------------------------------------------------------------------------------
; SSG���F�g���[�V���O
;ah		�`�����l��(0..2)
;
ssg_tone_simurate	proc
			public	ssg_tone_simurate
			mov		ch,ah
			xor		bx,bx
			mov		bl,ch
			shl		bx,1
			cmp		[trflag+bx],FALSE
			jz		sts_end					; ���F?�Ȃɂ���(��)
			dec		[trcounter+bx]
			jnz		sts_end					; �܂��܂�����
			mov		es,[trseg+bx]
			mov		di,[trpointer+bx]
			add		di,[trofs+bx]
			mov		al,es:[di]				; �����l
			cmp		al,80h					; ���FEND
			jz		sts_end
			cbw
			add		[trvolume+bx],ax
			mov		al,es:[di+1]			; �J�E���^
			cbw
			mov		[trcounter+bx],ax
			add		[trpointer+bx],2
			mov		ah,ch
			call	set_volume
	sts_end:
			ret
ssg_tone_simurate	endp

;------------------------------------------------------------------------------
; SSG���F�g���[�V���O�̃��Z�b�g
;ah		�`�����l��(0..2)
;
ssg_tone_reset	proc
			public	ssg_tone_reset
			push	ax
			push	bx
			xor		bx,bx
			mov		bl,ah
			shl		bx,1
			cmp		[trflag+bx],FALSE
			jz		str_end					; ���F?�Ȃɂ���(��)
			mov		[trcounter+bx],1
			mov		[trpointer+bx],0
			mov		[trvolume+bx] ,0
	str_end:
			pop		bx
			pop		ax
			ret
ssg_tone_reset	endp
			end
