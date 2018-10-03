;==============================================================================
; MFXDDN sound driver module
;						MIDI Interface driver for 98
;  copyright (c) 1993 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; �^�[�~�i������
;
			jumps
			.186
			.model	tiny
			.code


include		stdio.inc
include		ddn.inc
include		midi.inc

;------------------------------------------------------------------------------
	if	MIDI_BUFFERING	EQ	TRUE
extrn midi_databuf	:byte
extrn midi_datalen	:word
extrn midi_dataadr	:word
extrn midi_datawrt	:word
	endif
extrn INTERFACE		:word
extrn volume_buf	:word
extrn mastervol_buf	:word

;------------------------------------------------------------------------------
; �f�[�^�o�b�t�@������
;
init_databuf	proc
			public	init_databuf
	if	MIDI_BUFFERING	EQ	TRUE
			mov		[midi_datalen],0
			mov		[midi_dataadr],0
			mov		[midi_datawrt],0
	endif
			mov		[mastervol_buf],127
	
			mov		cx,16
			mov		ax,cs
			mov		es,ax
			mov		di,offset volume_buf
			cld
			mov		ax,100
			rep		stosw
	
			ret
init_databuf	endp

;------------------------------------------------------------------------------
; �l�h�c�h���t�f�[�^�o�b�t�@�Ƀf�[�^�����ߍ���
;al		�f�[�^
;
midi_out	proc
			public	midi_out
IF	MIDI_BUFFERING EQ TRUE			;------------ Buffering Program
			push	bx
			mov		bx,cs
			mov		ds,bx

			mov		bx,[midi_datawrt]
			mov		[bx+midi_databuf],al
			inc		bx
			cmp		bx,datasiz
			jb		siz_normal
	;���ӂ�Ă�`(�����[��)
			xor		bx,bx
	siz_normal:
			mov		[midi_datawrt],bx
			inc		[midi_datalen]

			pop		bx
			ret
ELSE								;------------ Non Buffering Program
			push	ds
			push	dx
			push	ax
			mov		dx,cs
			mov		ds,dx
			cmp		[INTERFACE],RS232C_INTERFACE
			jz		ms_nbuf_rs232c
	
; == MPU401���M(UART)
	ms_nbuf_mpu:
	ms_nbuf_mpu_wait_drr:
			mov		dx,[MPU_STATUS]
			in		al,dx
			out		5fh,al
			out		5fh,al
			out		5fh,al
			test	al,DRR
			jz		ms_nbuf_mpu_wait_ok
			mov		dx,[MPU_DATA]
			in		al,dx
			out		5fh,al
			out		5fh,al
			out		5fh,al
			jmp		ms_nbuf_mpu_wait_drr
	ms_nbuf_mpu_wait_ok:
			pop		ax
			mov		dx,[MPU_DATA]
			out		dx,al
			jmp		ms_nbuf_endop

; == RS232C���M
	ms_nbuf_rs232c:
			in		al,32h
			test	al,1
			jz		ms_nbuf_rs232c
			pop		ax
			out		30h,al
	ms_nbuf_endop:
			pop		dx
			pop		ds
			ret
ENDIF
midi_out	endp

;------------------------------------------------------------------------------
; ���܂����l�h�c�h���M�f�[�^���A�Ƃ��Ƃ��o�͂���̂����B
;
midi_send	proc
			public	midi_send
IF	MIDI_BUFFERING EQ TRUE
			pushf
			sti
			
			push	ds
			push	si
			push	cx
			
			mov		ax,cs
			mov		ds,ax
			mov		cx,[midi_datalen]
			mov		si,[midi_dataadr]
			add		si,offset midi_databuf
			cld
	ms_next_entry:
			jcxz	ms_nodata			; �����܂��`

			cmp		[INTERFACE],RS232C_INTERFACE
			jz		ms_rs232c
	
; == MPU401���M(UART)
	ms_mpu:
			mov		dx,[MPU_STATUS]
	ms_mpu_wait_drr:
			in		al,dx
			test	al,DRR
			jnz		ms_mpu_wait_drr
	ms_mpu_wait_ok:
			lodsb
			mov		dx,[MPU_DATA]
			out		dx,al
			jmp		ms_endop

; == RS232C���M
	ms_rs232c:
			in		al,32h
			out		5fh,al
			test	al,1
			jz		ms_rs232c
			lodsb
			out		30h,al
			out		5fh,al

; == MIDI�f�[�^�I�[�o�[�t���[�`�F�b�N
	ms_endop:
			dec		cx
			inc		[midi_dataadr]
			cmp		si,offset midi_databuf + datasiz
			jb		ms_next_entry		; ���[�Ղʂ�����
			mov		[midi_dataadr],0
			mov		si,offset midi_databuf
			jmp		ms_next_entry
	ms_nodata:
			mov		[midi_datalen],cx
			
			pop		cx
			pop		si
			pop		ds
			popf
			ret
ELSE
			ret
ENDIF
midi_send	endp

			end
