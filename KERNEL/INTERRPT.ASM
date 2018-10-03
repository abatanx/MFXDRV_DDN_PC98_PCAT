;/////////////////////////////////////////////////////////////////////////////;
;
;      Multi module music driver MFXDDN(tm) kernel system release 0.00 
;  MFXDDN(tm) Music driver For XMML , Deconcentrate Drivers Network System
;  copyright (c) 1993 ABA / T.Kobayashi and Interfair  All Rights Reserved.
;
;/////////////////////////////////////////////////////////////////////////////;
;
; ���荞�ݕ�
;
IF	PROGMODE		eq	COMTYPE
MFXDRVDDN_KERNEL	equ	TRUE
include		model.inc
include		stdio.inc
include		ddn.inc
include		timerdrv.inc
.code
ENDIF

firstclock	db		?

;-------- �h���C�o�ďo
;ah		�t�@���N�V�����i���o�[
;al		�h���C�o�e�[�u���̔ԍ�
;
call_driver	proc
			push	ds
			push	es
			push	bx
			push	ax
			mov		bx,cs
			mov		ds,bx

			xor		bx,bx
			mov		bl,al
			shl		bx,1
			mov		bx,[module_drv + bx]
			or		bx,bx
			jz		cd_erout
	cd_call:
			mov		es,bx
			xor		bx,bx
			mov		bl,ah
			shl		bx,1
			mov		bx,es:[DRVFUNC + bx]
			or		bx,bx
			jz		cd_erout
			mov		[driver_call_ofs],bx
			mov		[driver_call_seg],es
			mov		bx,es
			mov		ds,bx				; ds �� �h���C�o�[�� seg �ɂ��Ƃ��B

			pop		ax
			pop		bx
			pop		es
			push_all
			call	dword ptr cs:[driver_call]
			pop_all
			pop		ds
			ret

	cd_erout:
			pop		ax
			pop		bx
			pop		es
			pop		ds
			ret

			even
driver_call		label	dword
driver_call_ofs	dw		?
driver_call_seg	dw		?

call_driver	endp

;\@KILL LIGHT
;-------- ���t�O�������^�J�n
;
start_playing	proc
			mov		ax,cs
			mov		ds,ax
			push	ds
			mov		es,ax
			mov		bx,offset interrupt_kernel
			init_timer
			timer_settempo	255					; �Ƃ肠�����ŏ��� tempo = 255
			mov		bx,[timebase]
			set_timebase
			pop		ds

	; ���t�O�Ɋe�h���C�o�[������������
			mov		cx,16
			mov		si,offset module_drv
			cld
	sp_nextentry:
			lodsw
			or		ax,ax
			jz		sp_skip
			mov		es,ax
			mov		ax,es:[DRVPLAY]
			or		ax,ax
			jz		sp_skip
			mov		[driver_call_ofs],ax
			mov		[driver_call_seg],es
			push	ds
			push	si
			push	cx
			pushf
			push	es
			pop		ds
			call	dword ptr cs:[driver_call]
			popf
			pop		cx
			pop		si
			pop		ds
	sp_skip:
			loop	sp_nextentry

	;���t���[�N�G���A������(MIDI�I�ȏ����l�ŏ��������܂�)
			mov		ax,cs
			mov		ds,ax

			mov		cx,MAXTRACK
			mov		si,offset track_buf
	init_trackbuf:
			cmp		[si].channel,255
			jz		init_trackbuf_ns1
			mov		[si].steptime	,02h	; ���FECM�͗D��I�ɖ炷�̂�^^;
			jmp		init_trackbuf_ns2		; ���ʂ̋Ȃ͉䖝�䖝�B
	init_trackbuf_ns1:
			mov		[si].channel	,0		; 255 �� 0�ɖ߂�
			mov		[si].steptime	,01h	; ���ʂ̋Ȃ��1clock�����B
	init_trackbuf_ns2:
			mov		[si].note		,0
			mov		[si].velocity	,0
			mov		[si].program	,0
			mov		[si].volume		,100
			mov		[si].expression	,100
			mov		[si].modulation	,255
			mov		[si].panpot		,64
			mov		[si].bank		,0
			mov		[si].pkeypresser,0
			mov		[si].hold1		,FALSE
			mov		[si].poltament	,FALSE
			mov		[si].sustenuto	,FALSE
			mov		[si].soft		,FALSE
			mov		[si].poltctrl	,0
			mov		[si].ueff1sendlv,40
			mov		[si].ueff2sendlv,0
			mov		[si].ueff3sendlv,0
			mov		[si].chpresser	,0
			mov		[si].pitchbend	,0
			mov		[si].note_count	,0
			mov		[si].note_total ,0
			cmp		[si].note_seg,0
			jz		skip_init_notebuf
			push	cx
			mov		di,[si].note_ofs
			mov		es,[si].note_seg
			mov		cx,128/2
			cld
			xor		ax,ax
			rep		stosw
			pop		cx
	skip_init_notebuf:
			add		si,type DDN_CHBUF
			loop	init_trackbuf
	;���s�[�g�o�b�t�@������
			mov		cx,MAXTRACK
			mov		si,offset repeat_buf
	init_repeatbuf:
			mov		[si].rep_level,0
			add		si,type DDN_REPBUF
			loop	init_repeatbuf
	
	;���L���o�b�t�@������
			mov		cx,MAXTRACK
			mov		si,offset dec_buf
	init_decbuf:
			mov		[si].dec_flag,FALSE
			add		si,type DDN_DECOMPOSE
			loop	init_decbuf
	
	;�ꎞ��~�t���O�̏�����
			mov		[pause_flag],FALSE
	;�}�X�^�[�{�����[��������
			mov		[mastervol],127
	;�t�F�[�h�A�E�g�t���O������
			mov		[fadeout_flag],FALSE
	;�X�L�b�v�t���O������
			mov		[skip_flag],FALSE
			mov		[timerout_flag],FALSE

			mov		[firstclock],1
			timer_virtual_start
			call	far ptr interrupt_kernel
			timer_start
			ret
start_playing	endp

;-------- ���t�I��
;
stop_playing	proc
			mov		ax,cs
			mov		ds,ax
			push	es

	;�X�L�b�v�t���O������
			mov		[skip_flag],FALSE

	;���t���[�N�G���A�I��������
			mov		cx,MAXTRACK
			mov		si,offset track_buf
	stop_trackbuf:
			mov		[si].use_flag	,FALSE
			cmp		[si].note_seg,0
			jz		skip_clearnotebuf
			push	di
			push	cx
			mov		di,[si].note_ofs
			mov		es,[si].note_seg
			mov		cx,128/2
			cld
			xor		ax,ax
			rep		stosw
			pop		cx
			pop		di
		skip_clearnotebuf:
			add		si,type DDN_CHBUF
			loop	stop_trackbuf

	; ���t��Ɋe�h���C�o�[������������
			mov		ax,cs
			mov		ds,ax
			mov		cx,16
			mov		si,offset module_drv
			cld
	stp_nextentry:
			lodsw
			or		ax,ax
			jz		stp_skip
			mov		es,ax
			mov		ax,es:[DRVSTOP]
			or		ax,ax
			jz		stp_skip
			mov		[driver_call_ofs],ax
			mov		[driver_call_seg],es
			push	ds
			push	si
			push	cx
			pushf
			push	es
			pop		ds
			call	dword ptr cs:[driver_call]
			popf
			pop		cx
			pop		si
			pop		ds
	stp_skip:
			loop	stp_nextentry
			pop		es

			ret
stop_playing	endp

;-------- �^�C�}�[���荞�ݐ�̉��t���C���v���O����
; �^�C�}�[�h���C�o�[����Afar call �ŌĂ΂�Ă���̂ŁAret far ��
; ���ǂ�́B��������A�^�C�}�h���C�o�[���A�������荞�݂��ݒ肵�Ă����̂����B
;
interrupt_kernel	proc	far
			push_all
			sti
			cld
			
	ik_skk:
			mov		ax,cs
			mov		ds,ax

			cmp		[timerout_flag],TRUE
			jz		interrupt_end

			add		word ptr [play_counter  ],1
			adc		word ptr [play_counter+2],0

;*** 1.fadeout�̃`�F�b�N
			cmp		[fadeout_flag],FALSE	; �t�F�[�h�A�E�g���Ă那�H
			je		no_fadeout				; ���Ăˁ`��B
			dec		[fadeout_active]
			jnz		no_fadeout				; �J�E���^�[���܂��܂����B
			mov		ax,[fadeout_static]
			mov		[fadeout_active],ax
			sub		[mastervol],FADEOUT_DELTA ; master volume�`�F�b�N
			jbe		fadeout_end
			mov		bh,byte ptr [mastervol]

			xor		bl,bl
			mov		cx,16
			mov		si,offset module_drv
	fik_nextmdl_entry:
			push	ds
			push	cx
			push	bx
			cld
			lodsw
			or		ax,ax
			jz		fik_nextmdl
			mov		es,ax
			cmp		es:[DRVTYPE],word ptr NORMAL_DEVICE
			jne		fik_nextmdl
			push	si
			push	cx
			mov		ah,21h
			mov		al,bl
			call	call_driver
			pop		cx
			pop		si
	fik_nextmdl:
			pop		bx
			pop		cx
			pop		ds
			inc		bl
			loop	fik_nextmdl_entry
			jmp		no_fadeout

	fadeout_end:					; �t�F�[�h�A�E�g�I���I
			mov		[fadeout_flag],FALSE
			mov		ah,11h
			int		50h
			jmp		ik_exit

	no_fadeout:

;*** 2.���t�`�F�b�N
			mov		ax,cs
			mov		ds,ax
			mov		si,offset track_buf
			mov		[now_track],0
			mov		cx,MAXTRACK
	ik_nexttrk_entry:
			push	cx
			push	ds
			push	si
			cmp		[si].use_flag,FALSE
			jz		ik_nexttrk					; �g���b�N�g�p���ĂȂ���B
			dec		[si].steptime
			jnz		ik_nexttrk					; steptime ���I�[�o�[���ĂȂ���B

			mov		di,[si].mus_ofs
			mov		es,[si].mus_seg
			call	track_function
	ik_nexttrk:
			pop		si
			pop		ds
			pop		cx
			add		si,type DDN_CHBUF
			inc		[now_track]
			loop	ik_nexttrk_entry
			
			mov		cx,16
			mov		si,offset module_drv
	ik_nextmdl_entry:
			lodsw
			or		ax,ax
			jz		ik_nextmdl
			
			mov		es,ax
			mov		ax,es:[DRVINT]
			or		ax,ax
			jz		ik_nextmdl
			mov		[driver_call_ofs],ax
			mov		[driver_call_seg],es
			push	si
			push	cx
			push	ds
			
			push	es
			pop		ds
			call	dword ptr cs:[driver_call]
			
			pop		ds
			pop		cx
			pop		si
	ik_nextmdl:
			loop	ik_nextmdl_entry
	ik_exit:
			cmp		[skip_flag],TRUE
			jz		ik_skk
	interrupt_end:
;			mov		[firstclock],0
			pop_all
			ret
interrupt_kernel	endp
;\@END LIGHT

;\@KILL
			end
;\@END
