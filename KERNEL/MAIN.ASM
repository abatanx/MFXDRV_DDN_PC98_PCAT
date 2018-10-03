comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN kernel
// copyright (c) 1993,94 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// �J�[�l�����C���v���O����
//

 tasm /dLIB=LIBRARY

~
MFXDRVDDN_KERNEL	equ		TRUE
include		model.inc
include		stdio.inc
include		timerdrv.inc
include		ddn.inc

		jumps
IF	PROGMODE	eq	COMTYPE
		assume	cs:@code,ds:@code,es:@code
		.code
		org	100h
ELSE
include	segment.asm
ENDIF

_mfxddn_kernel_program	proc
		jmp		com_start
		
IF	PROGMODE	eq	COMTYPE
			db	0,'Interfair(R) '
;\@KILL LIGHT
dtamsg		db	'MFXDRV/DDN version ',ver,0dh,0ah
			db	'DOStyp'
comment^
;\@END LIGHT
dtamsg		db	'MFXDRV/DDN�炢�� version ',ver,'L',0dh,0ah
			db	'DOStypL'
;^
.data
Code_size	db	?
.code
ELSEIF	PROGMODE	eq	LIBTYPE
			db	'LIBtyp'
ELSE
			db	'ASMERRtyp'
ENDIF

		even
		
module_drv		dw	16 dup(0)		; �����f�o�C�X�o�^�e�[�u��(SEGMENT||NULL)
timer_drv		db	EOF				; ��ϰ�f�o�C�X�o�^�e�[�u��
;\@KILL LIGHT
timer_status	db	?				; ��ϰ�̏��
timebase		dw	?				; �^�C���x�[�X
tempo			dw	?				; �e���|
now_track		dw	?				; ���ݎ��s���̃g���b�N
pause_flag		dw	?				; �ꎞ��~�t���O
fadeout_static	dw	?				; �t�F�[�h�A�E�g�Œ�l
fadeout_active	dw	?				; �t�F�[�h�A�E�g�J�E���^
fadeout_flag	dw	?				; �t�F�[�h�A�E�g�t���O
mastervol		dw	?				; �}�X�^�[�{�����[��
volume_factor	dw	100				; �{�����[���t�@�N�^�[
play_counter	dd	?				; �v���C�J�E���^�[
play_skip_flag	dw	?				; ������t���O
play_skip_tempo	dw	?				; ������e���|
skip_flag		dw	?				; �X�L�b�v�t���O
timerout_flag	dw	?				; timerout�t���O(�����I�ɉ��t�~�߂�)
even
track_buf	DDN_CHBUF	MAXTRACK dup(?)		; ���t�o�b�t�@
even
repeat_buf	DDN_REPBUF	MAXTRACK dup(?)		; ���s�[�g�o�b�t�@
dec_buf		DDN_DECOMPOSE	MAXTRACK dup(?)	; ���U���o�b�t�@
;\@END LIGHT

even
ddnstay_flag	db		?
remove_flag		db		FALSE
infinity_play	db		FALSE

even
chainid		db		'DBUFchain',NULL	; �`�F�C���e�[�u��
chainadr	dw		50 dup(0)			; �`�F�C���A�h���X
play_table_temp	db	TABLE_SIZE dup(?)

		even
int50		label	dword
int50_ofs	dw	?
int50_seg	dw	?

ax_entry	dw	?
bx_entry	dw	?
cx_entry	dw	?
dx_entry	dw	?
es_entry	dw	?

farcall		label	dword
nearcall	label	word
farcall_ofs	dw		?
farcall_seg	dw		?

canusech	db		?

even
;XMML3.00 API������e�[�u��----------------------------------------------------
int_table:
;----------------- controll ---------------- no ----- comment -----------------
		dw	offset int50_rec_driver			; 0h	�h���C�o�[�o�^
		dw	offset int50_rel_driver			; 1h	�h���C�o�[���
		dw	offset int50_init_driver		; 2h	�h���C�o�[������
		dw	offset int50_get_driver_id		; 3h	�h���C�o�[ID�擾
		dw	offset int50_get_driver_status	; 4h	�h���C�o�[�X�e�[�^�X�擾
		dw	offset int50_get_driver_table	; 5h	�h���C�o�[�e�[�u���ԍ��擾
		dw	offset int50_get_track_value	; 6h	�g���b�N���[�N�G���A�̎擾
		dw	offset int50_get_driver_type	; 7h	�h���C�o�[�^�C�v�擾
		dw	offset int50_not_defined		; 8h	���U�[�u
		dw	offset int50_not_defined		; 9h	���U�[�u
		dw	offset int50_get_play_status	; ah	���t��Ԃ̎擾
		dw	offset int50_get_play_counter1	; bh	���t�J�E���^�ǂݏo��
		dw	offset int50_get_play_counter2	; ch	���t�J�E���^�ǂݏo��(192)
		dw	offset int50_not_defined		; dh	���U�[�u
		dw	offset int50_not_defined		; eh	���U�[�u
		dw	offset int50_not_defined		; fh	���U�[�u
		dw	offset int50_play_music			;10h	���t�J�n
		dw	offset int50_stop_music			;11h	���t�I��
		dw	offset int50_pause_music		;12h	���t�ꎞ��~
		dw	offset int50_continue_music		;13h	���t�ĊJ
		dw	offset int50_fadeout			;14h	�t�F�[�h�A�E�g
		dw	offset int50_play_skip_start	;15h	������J�n
		dw	offset int50_play_skip_end		;16h	������I��
		dw	offset int50_init_dcm			;17h	Init DriverDirectControll
		dw	offset int50_dcm				;18h	DriverDirectControll
		dw	offset int50_end_dcm			;19h	End DriverDirectControll
		dw	offset int50_set_notebuf		;1ah	�m�[�g�o�b�t�@�ݒ�
		dw	offset int50_rel_notebuf		;1bh	�m�[�g�o�b�t�@����
		dw	offset int50_replay_music		;1ch	�͂��߂���J�n
		dw	offset int50_not_defined		;1dh	���U�[�u
		dw	offset int50_not_defined		;1eh	���U�[�u
		dw	offset int50_not_defined		;1fh	���U�[�u
		dw	offset int50_play_se			;20h	���ʉ��J�n
		dw	offset int50_not_defined		;21h	���U�[�u
		dw	offset int50_not_defined		;22h	���U�[�u
		dw	offset int50_not_defined		;23h	���U�[�u
		dw	offset int50_not_defined		;24h	���U�[�u
		dw	offset int50_not_defined		;25h	���U�[�u
		dw	offset int50_not_defined		;26h	���U�[�u
		dw	offset int50_not_defined		;27h	���U�[�u
		dw	offset int50_not_defined		;28h	���U�[�u
		dw	offset int50_not_defined		;29h	���U�[�u
		dw	offset int50_not_defined		;2ah	���U�[�u
		dw	offset int50_not_defined		;2bh	���U�[�u
		dw	offset int50_not_defined		;2ch	���U�[�u
		dw	offset int50_not_defined		;2dh	���U�[�u
		dw	offset int50_not_defined		;2eh	���U�[�u
		dw	offset int50_not_defined		;2fh	���U�[�u
		dw	offset int50_putdec_8reg		;30h	8 bit reg. 10�i���\��
		dw	offset int50_puthex_8reg		;31h	8 bit reg. 16�i���\��
		dw	offset int50_putbin_8reg		;32h	8 bit reg.  2�i���\��
		dw	offset int50_putdec_16reg		;33h	16bit reg. 10�i���\��
		dw	offset int50_puthex_16reg		;34h	16bit reg. 16�i���\��
		dw	offset int50_putbin_16reg		;35h	16bit reg.  2�i���\��
		dw	offset int50_get_chainadr		;36h	chain table adr.�̎擾
		dw	offset int50_add_chain			;37h	chain table �ɒǉ�
		dw	offset int50_del_chain			;38h	chain table �̍폜
;------------------------------------------------------------------------------
;----------------------------------------------- int 50h ����^�[�~�i�� -------
; MFXDDN XMML3.00-API
;------------------------------------------------------------------------------

		even
int50_trap	proc	near						; �풓�`�F�b�NID
		jmp		short trap
jchk	db	'MFXkernel',ver
;\@KILL LIGHT
		db	'FlS'
comment^
;\@END LIGHT
		db	'LtS'
;^
trap:
		mov		cs:[ax_entry],ax
		mov		cs:[bx_entry],bx
		mov		cs:[cx_entry],cx
		mov		cs:[dx_entry],dx
		mov		cs:[es_entry],es
		push_all
		push	cs
		pop		ds
		
		push	ax
		push	bx
		xor		bx,bx
		mov		bl,ah
		shl		bx,1
		add		bx,offset int_table
		mov		ax,[bx]
		mov		[nearcall],ax
		pop		bx
		pop		ax

		call	word ptr [nearcall]
		pop_all
		mov		ax,cs:[ax_entry]
		mov		bx,cs:[bx_entry]
		mov		cx,cs:[cx_entry]
		mov		dx,cs:[dx_entry]
		mov		es,cs:[es_entry]
	err_funcout:
		iret

int50_trap	endp


;-------- �h���C�o�[ ID �ɑΉ�����e�[�u���ԍ���Ԃ�
; es:bx = �h���C�o�[ID�̕�����
;
;ret:
;ax
;	EOF		�h���C�o�[���Ȃ�
;	n>=0	�h���C�o�[�e�[�u��no
;es
;			�h���C�o�[�̃A�h���X
get_driver_table	proc
		push	ds
		push	bx
		push	cx
		push	dx
		push	si
		push	di
		
		mov		ax,cs
		mov		ds,ax
		mov		si,offset module_drv
		mov		cx,16
		xor		dx,dx
		cld
	gdt_next:
		inc		dx
		lodsw
		or		ax,ax
		jnz		gdt_id_cmp
	gdt_lp:
		loop	gdt_next
		jmp		gdt_error_out		;�o�^���Ăȁ`���I�I
	gdt_id_cmp:
		push	ds
		push	si
		push	di
		push	cx
		mov		ds,ax
		mov		si,DRVID
		mov		di,bx
		mov		cx,16
		cld
		rep		cmpsb
		pop		cx
		pop		di
		pop		si
		pop		ds
		jz		gdt_found
		jmp		gdt_lp
	gdt_found:
		dec		dx
		mov		es,ax				; RET:	ES <- DRVSEG
		mov		ax,dx				;		AX <- DRVNO
		jmp		gdt_ret
	gdt_error_out:
		mov		ax,EOF
	gdt_ret:
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ds
		ret
get_driver_table	endp

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;
; DDN-API����
;
;---------------------------- int 50h proc. ���o�^�t�@���N�V����
int50_not_defined	proc
		ret
int50_not_defined	endp

;---------------------------- int 50h proc.(00) �h���C�o�[�o�^
;	ah     = 0
;	es     = �h���C�o�[�̃Z�O�����g
;	int 50h
;ret
;	n>0		�g�p�\�`�����l��
;	EOF		�f�[�u���������ς�
;
int50_rec_driver	proc
		mov		si,offset module_drv
		mov		cx,16
		cld
rec_next_search:
		lodsw
		or		ax,ax
		jz		rec_seg
		loop	rec_next_search
		mov		[ax_entry],EOF
		ret
rec_seg:
		mov		[si-2],es
		cmp		es:[DRVTYPE],TIMER_DEVICE
		jnz		not_timer
		mov		ax,16
		sub		ax,cx
		mov		[timer_drv],al
	not_timer:
		mov		[ax_entry],NULL
		ret
int50_rec_driver	endp

;---------------------------- int 50h proc.(01) �h���C�o�[���
;	ah     = 1
;	es:bx  = �h���C�o�[ID�̕�����
;	int 50h
;ret
;	NULL	����ł���
;	EOF		����ł��Ȃ��A�܂��̓h���C�o�[���Ȃ�
;
int50_rel_driver	proc
		call	get_driver_table
		cmp		ax,EOF
		jnz		release_driver
cant_release_driver:
		mov		[ax_entry],EOF
		ret
release_driver:
		mov		bx,ax
		shl		bx,1
		mov		[bx+module_drv],word ptr 0
		mov		[ax_entry],NULL
		ret
int50_rel_driver	endp

;---------------------------- int 50h proc.(02) �h���C�o�[(����)������
;	ah     = 2
;	es:bx  = �h���C�o�[ID�̕�����
;	int 50h
;ret
;	NULL	�������ł���
;	EOF		�������ł��Ȃ��A�܂��̓h���C�o�[���Ȃ�
;
int50_init_driver	proc
		call	get_driver_table
		cmp		ax,EOF
		jnz		init_driver
		mov		[ax_entry],EOF
		ret
init_driver:
		mov		ax,es:[DRVINIT]
		or		ax,ax
		jz		init_driver_end

		mov		[farcall_ofs],ax
		mov		[farcall_seg],es
		push	ds
		mov		ax,es
		mov		ds,ax
		call	dword ptr cs:[farcall]
		pop		ds
init_driver_end:
		mov		[ax_entry],NULL
		ret
int50_init_driver	endp

;---------------------------- int 50h proc.(03) �h���C�o�[���擾
;	ah     = 3
;	al     = �e�[�u���i���o�[
;	int 50h
;
;ret@es:bx
;	�h���C�o�[�̖��O�̓������A�h���X
;
int50_get_driver_id	proc
		xor		ah,ah
		shl		ax,1
		mov		bx,ax
		mov		ax,[bx+module_drv]
		or		ax,ax
		jnz		@03
		mov		[ax_entry],word ptr EOF
		ret
	@03:
		mov		[es_entry],ax
		mov		[bx_entry],word ptr DRVID
		mov		[ax_entry],word ptr NULL
		ret
int50_get_driver_id	endp

;---------------------------- int 50h proc.(04) �h���C�o�[�X�e�[�^�X�̎擾
;	ah     = 4
;	es:bx  = �h���C�o�[ID�̕�����
;	int 50h
;ret@ah
;	n>=0	�g�p�\�ȃ`�����l����
;	EOF		�w��̃h���C�o�[���g�ݍ��܂�Ă��Ȃ�
;ret@al
;	�g�p���Ă���`�����l����
;ret@ch
;	�o�[�W���������_�ȏ�
;ret@cl
;	�o�[�W���������_����
;
int50_get_driver_status	proc
		call	get_driver_table
		cmp		ax,EOF
		jnz		get_ch_and_ver
		mov		ah,EOF
		mov		[ax_entry],ax
		ret
get_ch_and_ver:
		mov		ah,es:[DRVCH]
		mov		al,es:[DRVUSECH]
		mov		ch,es:[DRVVERINT]
		mov		cl,es:[DRVVERREAL]
		mov		[ax_entry],ax
		mov		[cx_entry],cx
		ret
int50_get_driver_status	endp

;---------------------------- int 50h proc.(05) �h���C�o�[�o�^�ԍ��擾
;	ah     = 5
;	es:bx  = �h���C�o�[ID�̕�����
;	int 50h
;
;ret@ax
;	EOF		�o�^����Ă��Ȃ�
;	?		�e�[�u���i���o�[
;
int50_get_driver_table	proc
		call	get_driver_table
		mov		[ax_entry],ax
		mov		[es_entry],es
		ret
int50_get_driver_table	endp

;---------------------------- int 50h proc.(06) �g���b�N���[�N�G���A�̎擾
;	ah     = 6
;	bh     = �g���b�N�ԍ�
;	bl     = ���[�N�ԍ�
;	int 50h
;
;ret@ax
;			���[�N�̓��e
;
int50_get_track_value	proc
;\@KILL LIGHT
		mov		ax,type DDN_CHBUF
		mul		bh
		xor		bh,bh
		add		bx,ax
		mov		ax,word ptr [track_buf + bx]
		mov		[ax_entry],ax
;\@END LIGHT
		ret
int50_get_track_value	endp

;---------------------------- int 50h proc.(07) �h���C�o�[�^�C�v�擾
;	ah     = 7
;	es:bx  = �h���C�o�[ID�̕�����
;	int 50h
;
;ret@ax
;	EOF		�o�^����Ă��Ȃ�
;	?		�h���C�o�[�^�C�v
;
int50_get_driver_type	proc
		call	get_driver_table
		cmp		ax,EOF
		jz		i5_gdtquit
		mov		ax,es:[DRVTYPE]
	i5_gdtquit:
		mov		[ax_entry],ax
		ret
int50_get_driver_type	endp

;---------------------------- int 50g proc.(0a) ���t��Ԃ̎擾
;	ah     = 0ah
;	int 50h
;
;ret@ax		���t���
;ret@bx		�^�C���x�[�X
;ret@cx		�e���|
;ret@dx		�}�X�^�[�{�����[��
int50_get_play_status	proc
;\@KILL LIGHT
		cmp		[pause_flag],FALSE
		jz		i5_gps_pafalse
		mov		ax,1
		jmp		i5_gps_paskip
	i5_gps_pafalse:
		mov		ax,0
	i5_gps_paskip:
		
		cmp		[play_skip_flag],FALSE
		jz		i5_gps_etc_reg
		or		ax,2
		
	i5_gps_etc_reg:
		mov		[ax_entry],ax
		mov		ax,[timebase]
		mov		[bx_entry],ax
		mov		ax,[tempo]
		mov		[cx_entry],ax
		mov		ax,[mastervol]
		mov		[dx_entry],ax
;\@END LIGHT
		ret
int50_get_play_status	endp

;---------------------------- int 50g proc.(0b) ���t�J�E���^�[�擾
;	ah     = 0bh
;	int 50h
;
;ret@dx:ax		���݂̃J�E���g�l
int50_get_play_counter1	proc
;\@KILL LIGHT
		mov		ax,word ptr [play_counter]
		mov		dx,word ptr [play_counter+2]
		mov		[ax_entry],ax
		mov		[dx_entry],dx
;\@END LIGHT
		ret
int50_get_play_counter1	endp

;---------------------------- int 50g proc.(0c) ���t���ߎ擾
;	ah     = 0ch
;	int 50h
;
;ret@dx:ax		���݉��t���̏���
;ret@bx			���݉��t���̏��߂̃J�E���^�[
int50_get_play_counter2	proc
;\@KILL LIGHT
		mov		bx,[timebase]
		shl		bx,2
		or		bx,bx
		jz		i5_gpc2_errorout		; div zero ��������
		mov		ax,word ptr [play_counter]
		mov		dx,word ptr [play_counter+2]
		div		bx
		mov		[ax_entry],ax
		mov		[dx_entry],dx
		ret
	i5_gpc2_errorout:
		mov		[ax_entry],0
		mov		[dx_entry],0
;\@END LIGHT
		ret
int50_get_play_counter2	endp

;---------------------------- int 50h proc.(1c) ���t�J�n
;	ah     = 1ch
;	int 50h
;
int50_replay_music	proc
		mov		ax,cs
		mov		es,ax
		mov		bx,offset play_table_temp
		push	es
		push	bx
		jmp		int50_play_music2
int50_replay_music	endp

;---------------------------- int 50h proc.(10) ���t�J�n
;	ah     = 10h
;	es:bx  = ���t�e�[�u���A�h���X
;	int 50h
;
int50_play_music	proc
;\@KILL LIGHT
		push	es
		push	bx

		push	es
		push	ds
		push	si
		push	di
		mov		ax,es
		mov		ds,ax
		mov		si,bx

		mov		ax,cs
		mov		es,ax
		mov		di,offset play_table_temp
		mov		cx,TABLE_SIZE-1
		cld
		rep		movsb
		pop		di
		pop		si
		pop		ds
		pop		es

int50_play_music2:
		mov		ah,11h
		int		50h						; ���t�I��

		mov		[pause_flag]    ,FALSE	; �ꎞ��~�s�I�I
		mov		[fadeout_flag]  ,FALSE	; �t�F�[�h�A�E�g�s�I�I
		mov		[play_skip_flag],FALSE	; ������s�I�I
		mov		[timerout_flag] ,TRUE	; ���t������~!!

		mov		word ptr [play_counter  ],0
		mov		word ptr [play_counter+2],0
		
		call	check_timerdrv
		or		ax,ax
		jz		timerdrv_enabled
		mov		[ax_entry],word ptr TIMERDEVICE_ERROR
		pop		bx
		pop		es
		ret
	timerdrv_enabled:
		call	check_sounddrv
		or		ax,ax
		jz		sounddrv_enabled
		mov		[ax_entry],word ptr SOUNDDEVICE_ERROR
		pop		bx
		pop		es
		ret
	sounddrv_enabled:
	;Track�o�b�t�@�̏�����
		mov		cx,MAXTRACK			;�S32�g���b�N
		mov		si,offset track_buf
  init_trackbufs:
		mov		[si].use_flag , FALSE
		add		si,type DDN_CHBUF
		loop	init_trackbufs
		
		pop		bx
		pop		es

; Music Information Header ��͊J�n
		mov		si,offset track_buf
		xor		cx,cx
		mov		cl,es:[bx]		;���t�g���b�N��
		or		cx,cx
		jnz		init_trackbuf_ok
		mov		[ax_entry],EOF	;���t�\�Ȏw��g���b�N����0�������̂�EOF
		ret
		
  init_trackbuf_ok:
		inc		bx
		mov		ax,es:[bx]		;�^�C���x�[�X
		mov		[timebase],ax
		add		bx,2
  init_trackbuf_usef:
		mov		ax,es:[bx]
		mov		dx,es:[bx+2]
		add		bx,4
		push	es
		push	bx

		mov		bx,ax	; ofs
		mov		es,dx	; seg
		
		push	cx
		push	bx
		push	es
		mov		ah,04h					; �g�p�\�ȃ`�����l���`�F�b�N
		int		50h
		cmp		ah,EOF
		pop		es
		pop		bx
		pop		cx
		jz		itu_lp1
		mov		[canusech],ah
		
		push	es
		push	bx
		call	get_driver_table
		pop		bx
		pop		es
		
		add		bx,16
		cmp		ax,EOF
		jz		itu_lp1
		mov		[si].driver_no,al	; Driver Table_NO
		mov		al,es:[bx]			; Driver Channel_NO
		cmp		al,255
		jz		itu_sound_true		; ���F�f�[�^�͗D�悾����(��)
		cmp		[canusech],al
		jbe		itu_lp1
	itu_sound_true:
		inc		bx

		mov		[si].channel,al
		mov		[si].mus_ofs,bx
		mov		[si].mus_seg,es
		mov		[si].use_flag,TRUE
	itu_lp1:
		pop		bx
		pop		es
	
		add		si,type DDN_CHBUF
		loop	init_trackbuf_usef
		call	start_playing
		mov		[ax_entry],NULL
;\@END LIGHT
		ret
;\@KILL LIGHT

check_timerdrv	proc		; �^�C�}�[�h���C�o�[�̃`�F�b�N�^������
		push	bx
		push	si
		push	es
		mov		cx,16
		mov		bx,EOF
		mov		si,offset module_drv
		cld
	next_timerdrv_entry_jpt:
		lodsw
		or		ax,ax
		jz		next_timerdrv_entry
		
		mov		es,ax
		cmp		es:[DRVTYPE],TIMER_DEVICE
		jnz		next_timerdrv_entry
		mov		bx,NULL				;�^�C�}�[�f�o�C�X���݂��m�F!�I!�I!�I
	next_timerdrv_entry:
		loop	next_timerdrv_entry_jpt

		mov		ax,bx
		pop		es
		pop		si
		pop		bx
		ret
check_timerdrv	endp

check_sounddrv	proc		; �T�E���h�h���C�o�[�̃`�F�b�N
		push	bx
		push	si
		push	es
		mov		cx,16
		mov		bx,EOF
		mov		si,offset module_drv
		cld
	next_normaldrv_entry_jpt:
		lodsw
		or		ax,ax
		jz		next_normaldrv_entry
		
		mov		es,ax
		cmp		es:[DRVTYPE],word ptr NORMAL_DEVICE
		jnz		next_normaldrv_entry
		mov		bx,NULL				;�^�C�}�[�f�o�C�X���݂��m�F!�I!�I!�I
	next_normaldrv_entry:
		loop	next_normaldrv_entry_jpt

		mov		ax,bx
		pop		es
		pop		si
		pop		bx
		ret
check_sounddrv	endp
;\@END LIGHT

int50_play_music	endp

;---------------------------- int 50h proc.(11) ���t�I��
;	ah     = 11h
;	int 50h
;
int50_stop_music	proc
;\@KILL LIGHT
		mov		[pause_flag]  ,FALSE		; �|�[�Y���Ȃ����
		mov		[fadeout_flag],FALSE		; �t�F�[�h�A�E�g�I�����Ă�
		mov		[timerout_flag],TRUE		; ���t������~
		timer_stop
		call	stop_playing
;\@END LIGHT
		ret
int50_stop_music	endp

;---------------------------- int 50h proc.(12) ���t�ꎞ��~
int50_pause_music	proc
;\@KILL LIGHT
		cmp		[pause_flag],FALSE
		jnz		cannot_pause
		mov		[pause_flag],TRUE
		timer_stop
cannot_pause:
;\@END LIGHT
		ret
int50_pause_music	endp

;---------------------------- int 50h proc.(13) ���t�ĊJ
int50_continue_music	proc
;\@KILL LIGHT
		cmp		[pause_flag],TRUE
		jnz		cannot_continue
		mov		[pause_flag],FALSE
		timer_start
cannot_continue:
;\@END LIGHT
		ret
int50_continue_music	endp

;---------------------------- int 50h proc.(14) �t�F�[�h�A�E�g
;	ah     = 14h
;	bx     = �X�s�[�h
;	int 50h
;
int50_fadeout	proc
;\@KILL LIGHT
		mov		[fadeout_static],bx
		mov		[fadeout_active],bx
		mov		[fadeout_flag],TRUE
;\@END LIGHT
		ret
int50_fadeout	endp

;---------------------------- int 50h proc.(15) ������J�n
;	ah     = 15h
;	bx     = �e���|
;	int 50h
;
int50_play_skip_start	proc
;\@KILL LIGHT
		cmp		[play_skip_flag] ,TRUE
		jz		i5_pss_exit
		mov		[play_skip_flag] ,TRUE
		mov		[play_skip_tempo],bx
		timer_settempo	bx
	i5_pss_exit:
;\@END LIGHT
		ret
int50_play_skip_start	endp

;---------------------------- int 50h proc.(16) ������I��
;	ah     = 16h
;	int 50h
;
int50_play_skip_end	proc
;\@KILL LIGHT
		cmp		[play_skip_flag] ,FALSE
		jz		i5_pse_exit
		mov		[play_skip_flag] ,FALSE
		mov		bx,[tempo]
		timer_settempo	bx
	i5_pse_exit:
;\@END LIGHT
		ret
int50_play_skip_end	endp

;---------------------------- int 50h proc.(17) dcm������
;	ah     = 17h
;	dl     = �g�p�������h���C�o�e�[�u���ԍ�
;	int 50h
;
int50_init_dcm	proc				;����������DRV_PLAY�����s���邾���B
		xor		bx,bx
		mov		bl,dl
		shl		bx,1
		mov		ax,[bx+module_drv]
		or		ax,ax
		jz		i5_i_dcm_erout
		mov		es,ax
		mov		ax,es:[DRVPLAY]
		or		ax,ax
		jz		i5_i_dcm_erout
		
		mov		cs:[farcall_ofs],ax
		mov		cs:[farcall_seg],es
		push	ds
		push	es
		pop		ds
		call	dword ptr cs:[farcall]
		pop		ds
	i5_i_dcm_erout:
		mov		[ax_entry],NULL
		ret
int50_init_dcm	endp

;---------------------------- int 50h proc.(18) dcm main
;	ah     = 18h
;	al     = �R���g���[���ԍ�
;	dl     = �g�p�������h���C�o�e�[�u���ԍ�
;	int 50h
;
int50_dcm	proc
		push	ax
		push	bx
		push	cx
		push	dx
		push	es
		
		xor		bx,bx
		mov		bl,dl
		shl		bx,1
		mov		bx,[bx+module_drv]
		or		bx,bx
		jz		i5_dcm_erout

		mov		es,bx
		xor		bx,bx
		mov		bl,al
		shl		bx,1
		mov		ax,es:[DRVFUNC+bx]
		or		ax,ax
		jz		i5_dcm_erout
		mov		cs:[farcall_ofs],ax
		mov		cs:[farcall_seg],es
		mov		ax,es
		mov		ds,ax
		pop		es
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		call	dword ptr cs:[farcall]
		mov		cs:[ax_entry],NULL
		ret

	i5_dcm_erout:
		pop		es
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		mov		cs:[ax_entry],EOF
		ret
int50_dcm	endp

;---------------------------- int 50h proc.(19) dcm�I��
;	ah     = 19h
;	dl     = �g�p�������h���C�o�e�[�u���ԍ�
;	int 50h
;
int50_end_dcm	proc				;����������DRV_STOP�����s���邾���B
		xor		bx,bx
		mov		bl,dl
		shl		bx,1
		mov		ax,[bx+module_drv]
		or		ax,ax
		jz		i5_e_dcm_erout
		mov		es,ax
		mov		ax,es:[DRVSTOP]
		or		ax,ax
		jz		i5_e_dcm_erout
		mov		[farcall_ofs],ax
		mov		[farcall_seg],es
		push	ds
		push	es
		pop		ds
		call	dword ptr cs:[farcall]
		pop		ds
	i5_e_dcm_erout:
		mov		[ax_entry],NULL
		ret
int50_end_dcm	endp

;---------------------------- int 50h proc.(1a) �m�[�g�o�b�t�@�ݒ�
;	ah     = 1ah
;	al     = �ݒ肵�����g���b�N
;   es:bx  = �o�b�t�@�̃A�h���X
;	int 50h
;
int50_set_notebuf	proc
;\@KILL LIGHT
		mov		dl,type DDN_CHBUF
		mul		dl
		add		ax,offset track_buf
		mov		si,ax
		mov		[si].note_ofs,bx
		mov		[si].note_seg,es
		mov		[ax_entry],NULL
;\@END LIGHT
		ret
int50_set_notebuf	endp

;---------------------------- int 50h proc.(1b) �m�[�g�o�b�t�@����
;	ah     = 1bh
;	al     = �����������g���b�N
;	int 50h
;
int50_rel_notebuf	proc
;\@KILL LIGHT
		mov		dl,type DDN_CHBUF
		mul		dl
		add		ax,offset track_buf
		mov		si,ax
		mov		[si].note_ofs,NULL
		mov		[si].note_seg,NULL
		mov		[ax_entry],NULL
;\@END LIGHT
		ret
int50_rel_notebuf	endp

;---------------------------- int 50h proc.(20) ���ʉ��J�n
;	ah     = 20h
;	es:bx  = ���ʉ����t�f�[�^
;	al     = ��L����g���b�N�ԍ�
;	ch     = �h���C�o�`�����l��
;	cl     = �h���C�o�e�[�u���ԍ�
;	int 50h
;
int50_play_se	proc
;\@KILL LIGHT
		push	bx
		xor		bx,bx
		mov		bl,al
		mov		ax,type DDN_CHBUF
		mul		bx
		mov		bx,ax
		add		bx,offset track_buf
		mov		[bx].use_flag , FALSE			; �g���b�N������
		mov		[bx].driver_no, cl				; �h���C�o�[�ԍ�
		mov		[bx].channel  , ch				; �h���C�o�[�`�����l��
		pop		ax
		mov		[bx].mus_ofs  , ax				; ���t�f�[�^offset
		mov		[bx].mus_seg  , es				; ���t�f�[�^segment
		mov		[bx].steptime , 1				; step time
		mov		[bx].use_flag , TRUE			; �g���b�N�L����
;\@END LIGHT
		ret
int50_play_se	endp

;---------------------------- int 50h proc.(30) 8 bit reg.10�i���\��
;	ah     = 30h
;	al     = �\�����@		1:�E�l��	2:���l��
;	bl     = ���l
;	int 50h
;
int50_putdec_8reg	proc
		mov		cx,cs
		mov		ds,cx
		mov		es,cx
		xchg	al,bl
		call	putdec_8reg
		ret
int50_putdec_8reg	endp

;---------------------------- int 50h proc.(31) 8 bit reg.16�i���\��
;	ah     = 31h
;	bl     = ���l
;	int 50h
;
int50_puthex_8reg	proc
		mov		cx,cs
		mov		ds,cx
		mov		es,cx
		mov		al,bl
		call	puthex_8reg
		ret
int50_puthex_8reg	endp

;---------------------------- int 50h proc.(32) 8 bit reg. 2�i���\��
;	ah     = 32h
;	bl     = ���l
;	int 50h
;
int50_putbin_8reg	proc
		mov		cx,cs
		mov		ds,cx
		mov		es,cx
		mov		al,bl
		call	putbin_8reg
		ret
int50_putbin_8reg	endp

;---------------------------- int 50h proc.(33) 16 bit reg.10�i���\��
;	ah     = 33h
;	al     = �\�����@		1:�E�l��	2:���l��
;	bx     = ���l
;	int 50h
;
int50_putdec_16reg	proc
		mov		cx,cs
		mov		ds,cx
		mov		es,cx
		xchg	ax,bx
		call	putdec_16reg
		ret
int50_putdec_16reg	endp

;---------------------------- int 50h proc.(34) 16 bit reg.16�i���\��
;	ah     = 34h
;	bx     = ���l
;	int 50h
;
int50_puthex_16reg	proc
		mov		cx,cs
		mov		ds,cx
		mov		es,cx
		mov		ax,bx
		call	puthex_16reg
		ret
int50_puthex_16reg	endp

;---------------------------- int 50h proc.(35) 16 bit reg. 2�i���\��
;	ah     = 35h
;	bl     = ���l
;	int 50h
;
int50_putbin_16reg	proc
		mov		cx,cs
		mov		ds,cx
		mov		es,cx
		mov		ax,bx
		call	putbin_16reg
		ret
int50_putbin_16reg	endp

;---------------------------- int 50h proc.(36) chain table adr.�̎擾
;	ah     = 36h
;	int 50h
;
int50_get_chainadr	proc
		mov		[bx_entry],offset chainid
		mov		[es_entry],cs
		ret
int50_get_chainadr	endp

;---------------------------- int 50h proc.(37) chain table �ɒǉ�
;	ah     = 37h
;	es     = �ǉ��A�h���X(seg)
;	int 50h
;
int50_add_chain	proc
		cld
		mov		bx,es
		mov		ax,cs
		mov		es,ax
		mov		di,offset chainadr
		mov		cx,50
		xor		ax,ax
		repnz	scasw
		sub		di,2
		mov		ax,bx
		stosw
		xor		ax,ax
		stosw
		mov		[ax_entry],NULL
		ret
int50_add_chain	endp

;---------------------------- int 50h proc.(38) chain table �@�̍폜
;	ah     = 38h
;	es     = �폜�A�h���X
;	int 50h
;
int50_del_chain	proc
		cld
		mov		bx,es
		mov		ax,cs
		mov		ds,ax
		mov		es,ax
		mov		si,offset chainadr
	i5_delchain_nextentry:
		lodsw
		or		ax,ax
		jz		i5_delchain_errexit
		cmp		ax,bx
		jnz		i5_delchain_nextentry
		
		mov		di,si
		sub		di,2
	i5_delchain:
		lodsw
		stosw
		or		ax,ax
		jnz		i5_delchain
		
		mov		[ax_entry],NULL
		ret
	i5_delchain_errexit:
		mov		[ax_entry],EOF
		ret
int50_del_chain	endp

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;
;  DOS ���s�G���g���[		kernel �풓/�������
;LIB�����Ă�Ƃ���
;  dx	; 'In'	�풓
;		; 'Re'	���
;
com_start	proc
		mov		ax,cs
		mov		ds,ax
		mov		es,ax

IF	PROGMODE	eq	LIBTYPE
		cmp		dx,'In'		; �풓
		jz		Lib_install
		cmp		dx,'Re'		; ���
		jz		Lib_remove
		mov		ax,EOF		; �G����
		ret
	Lib_install:
		mov		[remove_flag],FALSE
		jmp		Lib_next
	Lib_remove:
		mov		[remove_flag],TRUE
	Lib_next:
ENDIF

;�I�v�V�������--------
IF	PROGMODE	eq	COMTYPE	;---- COM�`���̎�...
		_print	tit

option_check:
		mov		si,81h
		cld
	option_check_next:
		lodsb
		cmp		al,0dh
		jz		option_end			; �I�v�V�����I��
		cmp		al,'-'				; -
		jz		option_start
		cmp		al,'/'				; /
		jz		option_start
		cmp		al,' '				; space
		jz		option_check_next
		cmp		al,09h				; tab
		jz		option_check_next
	
	option_error:
		call	put_usage
		mov		ax,4cffh
		int		21h					; �ُ�I��

	option_start:
		lodsb
		cmp		al,'r'				; �풓����
		jz		remove_on
		cmp		al,'R'
		jz		remove_on
		cmp		al,'v'				; ���ʒ���
		jz		volume_ctrl
		cmp		al,'V'
		jz		volume_ctrl
		jmp		option_error

;/r �I�v�V����
	remove_on:
		mov		[remove_flag],TRUE
		jmp		option_check_next

;/v �I�v�V����
	volume_ctrl:
		xor		bx,bx
	volume_ctrl_loop:
		lodsb
		mov		cl,al
		cmp		cl,'0'
		jb		volume_ctrl_end
		cmp		cl,'9'
		jnbe	volume_ctrl_end
		mov		al,10
		mul		bl
		mov		bx,ax
		sub		cl,'0'
		xor		ch,ch
		add		bx,cx
		jmp		volume_ctrl_loop
	volume_ctrl_end:
		mov		[volume_factor],bx
		_put	'���ʂ�ʏ�o�͂� '
		mov		ax,bx
		mov		bl,1
		pushf
		push	si
		push	ds
		call	putdec_16reg
		pop		ds
		pop		si
		popf
		_puts	'(%)�ɐݒ肵�܂���.'
		dec		si
		jmp		option_check_next

	option_end:
ENDIF
;�풓�`�F�b�N ---
		mov		ax,3550h
		int		21h
		mov		si,offset jchk
		mov		di,si
		mov		ax,cs
		mov		ds,ax
		mov		cx,16
		cld
		rep		cmpsb
		jz		stay_ddn
	notstay_ddn:
		mov		[ddnstay_flag],FALSE			; DDN�풓���Ă�
		jmp		main_start
	stay_ddn:
		mov		[ddnstay_flag],TRUE				; DDN�풓���ĂȂ�

;�풓�Ɖ���E�E�E�ǂ����Ȃ�?
main_start:
		cmp		[remove_flag],TRUE
		jz		remove

;�풓
install:
		cmp		[ddnstay_flag],FALSE
		jz		install_main

IF	PROGMODE	eq	COMTYPE
		call	put_device
		mov		ax,4c00h
		int		21h
ELSE
		mov		ax,EOF
		ret
ENDIF

	install_main:
		mov		ax,3550h
		int		21h

		mov		cs:[int50_ofs],bx
		mov		cs:[int50_seg],es
		mov		ax,cs
		mov		ds,ax
		mov		dx,offset int50_trap
		mov		ax,2550h
		int		21h

IF	PROGMODE	eq	COMTYPE
		_print	tracks
		_puts	'int 50H �� MFXDDN-API3.00�p�Ƃ��Ďg�p���܂��B'
		_puts	'MFXDRV/DDN ���풓���܂����B'

		mov		ax,cs
		mov		ds,ax
		mov		es,ax
		mov		si,offset dtamsg
		mov		di,81h
		xor		dl,dl
		cld
	dta_wnext:
		lodsb
		stosb
		inc		dl
		cmp		al,0dh
		jnz		dta_wnext
		mov		ds:[80h],dl

		mov		dx,offset Code_size
		add		dx,200h
		shr		dx,4
		inc		dx
		
		mov		ax,3100h
		int		21h
ELSE
		mov		ax,NULL
		ret
ENDIF

;���
remove:
		cmp		[ddnstay_flag],TRUE
		jz		remove_main
IF	PROGMODE	eq	COMTYPE
		_puts	'�풓���Ă��܂���B'
		mov		ax,4c00h
		int		21h
ELSE
		mov		ax,EOF
		ret
ENDIF
	remove_main:
		mov		ah,11h			; ���t�I��
		int		50h

		mov		ax,3550h
		int		21h
		push	es
		
;=== �`�F�C���������[���
		mov		ax,es
		mov		ds,ax
		mov		si,offset chainadr
freecmem:
		lodsw
		or		ax,ax
		jz		freecmem_ok
		mov		es,ax
		mov		ax,4900h
		int		21h
		jb		freecmem_err
		jmp		freecmem
freecmem_err:
IF	PROGMODE	eq	COMTYPE
		push	ds
		mov		ax,cs
		mov		ds,ax
		_put	'MEMORY�̉�����ł��܂���ł���(segment '
		mov		bx,es
		call	int50_puthex_16reg
		_puts	'H)'
		pop		ds
ENDIF
		jmp		freecmem

;=== �h���C�o������������Ăяo��
freecmem_ok:
		pop		es
		push	es
		mov		ax,es
		mov		ds,ax
		mov		si,offset module_drv
		mov		cx,16
		xor		bp,bp
freedrv:
		cld
		lodsw
		or		ax,ax
		jz		skip_free
		mov		es,ax

IF	PROGMODE	eq	COMTYPE
		mov		bx,DRVID
	put_frdrvid:
		mov		dl,es:[bx]
		or		dl,dl
		jz		go_frdrv
		mov		ah,02h
		int		21h
		inc		bx
		jmp		put_frdrvid
	go_frdrv:
		push	ds
		mov		ax,cs
		mov		ds,ax
		_puts	'���������܂��B'
		pop		ds
ENDIF
	
		mov		bx,es:[DRVEND]
		or		bx,bx
		jz		skip_drv_end
		mov		cs:[farcall_ofs],bx
		mov		cs:[farcall_seg],es
		push	cx
		push	si
		push	ds
		push	es
		push	bp
		pushf
		push	es
		pop		ds
		call	dword ptr cs:[farcall]
		popf
		pop		bp
		pop		es
		pop		ds
		pop		si
		pop		cx
	skip_drv_end:
		mov		ax,4900h
		int		21h
		inc		bp
	skip_free:
		loop	freedrv

IF	PROGMODE	eq	COMTYPE
		mov		ax,cs
		mov		ds,ax
		or		bp,bp
		jz		skip_freemsg
		_put	'�ȏ�AXDV �h���C�o�[�� '
		mov		bx,bp
		mov		ax,3001h
		int		50h
		_puts	'�� �풓�������܂����B'
ENDIF

	skip_freemsg:
		pop		es
		push	es
		
;=== ���̈���
IF	PROGMODE	eq	COMTYPE
		mov		es,es:[002ch]
		mov		ax,4900h
		int		21h
ENDIF
		pop		es

;=== ���荞�݃x�N�^���A
		mov		dx,es:[int50_ofs]
		mov		ds,es:[int50_seg]
		mov		ax,2550h
		int		21h

;=== �v���Z�X���������
IF	PROGMODE	eq	COMTYPE
		mov		ax,4900h
		int		21h
		mov		ax,cs
		mov		ds,ax
		_puts	'MFXDRV/DDN ��������܂����B'
		_exit	0
ELSE
		ret
ENDIF

IF	PROGMODE	eq	COMTYPE
; �I�v�V������\��
put_usage:
		_print	usage_data
		ret
; �f�o�C�X�̕\��
put_device:
		call	put_crlf
		_put	'  --- MFXDRV/DDN �O���h���C�o�� --- XMML3.00 rel.'
		_puts	xmml_rel
		
		mov		ax,3550h
		int		21h
		mov		ax,es
		mov		ds,ax
		mov		si,offset module_drv
		xor		bx,bx
		mov		cx,16
		cld
	pd_next:
		lodsw
		or		ax,ax
		jz		pd_not_driver
		push	ds
		push	cs
		pop		ds
		push	ax
		_put	'�E'
		pop		ax
		mov		ds,ax
		mov		dx,ds:[DRVUSEMSG]
		mov		ax,0900h
		int		21h
		push	cs
		pop		ds
		call	put_crlf
		pop		ds
		inc		bx
	pd_not_driver:
		loop	pd_next
		
		push	cs
		pop		ds
		
		or		bx,bx
		jz		pd_none_driver
		call	put_crlf
		_put	' �ȏ� '
		mov		ax,3001h
		int		50h
		_puts	'�̋@�\���g�p�\�ł��B'
		ret
	
	pd_none_driver:
		_puts	' �Ȃɂ��g�ݍ��܂�Ă��܂���B'
		ret

ENDIF

com_start	endp

; ���s�I�I
put_crlf	proc
		push	ax
		push	dx
		mov		dl,0dh
		mov		ah,02h
		int		21h
		mov		dl,0ah
		mov		ah,02h
		int		21h
		pop		dx
		pop		ax
		ret
put_crlf	endp

_mfxddn_kernel_program		endp

;--------- �t���J�[�l��
;\@KILL LIGHT
IF	PROGMODE	eq	COMTYPE
.data
tit			db	'Multi module music driver MFXDRV/DDN kernel version ',ver,CR
			db	'copyright (c) 1993-95 by ABA / T.Kobayashi and Interfair All Rights Reserved.',CR,EOL
usage_data	db	'usage  ; ',CR
			db	'         mfxddn [/|-(option)]....',CR
			db	'option ; ',CR
			db	'         /r     �풓����',CR,'$'
tracks		db	'�S',MAXTRACK/10+'0',MAXTRACK mod 10+'0','�g���b�N�𐧌�\�ł��B',CR,'$'
ENDIF
;\@END LIGHT

;--------- ���C�g�J�[�l��
;\@KILL LIGHT
comment^
;\@END LIGHT
.data
tit			db	'Multi module sound driver MFXDRV/DDN kernel(light) version ',ver,'L',CR
			db	'copyright (c) 1995 by ABA / T.Kobayashi and Interfair All Rights Reserved.',CR,EOL
usage_data	db	'usage  ; ',CR
			db	'         mfxddnl [/|-(option)]....',CR
			db	'option ; ',CR
			db	'         /vX    �{�����[������(X=0�`200(%):Def /v100)
			db	'         /r     �풓����',CR,'$'
tracks		db	'�O���h���C�o�� 16��� ����\�ł��B',CR,'$'
;^

;\@KILL
		end		_mfxddn_kernel_program
;\@END

; Version Revision_ Comment_____________________________________________________
;	0.01B	1.1		�Ƃ肠���������B
;	0.60	1.2		���蓮�삷��悤�ɂȂ����B
;					�o�b�t�@�����ꂢ�ɏ���������悤�ɂ����B
;					���t�J�E���^�t�@���N�V�����ǉ��B
;					���p�ł�����B�����(��)�B
;	0.70	1.3		�`�F�C���o�b�t�@�V�X�e�����̗p�����I
;	0.80	1.4		DCM�t�@���N�V������ǉ��B�h���C�o����local�Ȑ��䂪�ł���
;					��(��������ʉ�API??)�B
;	0.82	1.5		DCM��Bugfix�B
;	0.82++	1.5.1	DCM��Bugfix�B
;	0.84++	1.5.2	sustenuto,tenuto,hold1,poltament��Bugfix�B
;	0.85	1.6		Chg.Channel��BIN�d�l�ǉ��ɔ����@�\�g��(�b���)
;	0.87	1.7		�J��Ԃ��������T�|�[�g�����B
;	0.90	1.8		FAR CALL��CHECK������������
;	0.95	1.9		TIMERDRV�̎d�l�ύX�ɔ����v���O�����ύX(�̂�TIMER�h���C�o
;					�͎g�p�s�f�[�f)
;	0.99	1.10	ECM�@�\�ǉ��A���ׂĂ�XMMLformat�𖞂�����
;	0.99A	1.11	ETCDRV��ECM�@�\���g���Ȃ� bug��fix�����B
;	1.00	1.12	���[(������) v(^^)
;	1.00	1.13	�\�[�X��LIB�Ή��ɂ����`�B���[(������) v(^^)
;	1.02	1.14	����[��A���F�pECM�ɑΏ����ĕ֗��ɂȂ����B
;	1.10	1.15	bug�C��,NOTEBUF�@�\��ǉ�
;	1.12	1.16	�J��Ԃ��n��bug�C��
;	1.14	1.17	�}�X�^�[�{�����[���n��bug�C��
;	1.15	1.18	�X�L�b�v�t���O�ǉ�
;	1.16	1.19	�s�b�`�x���h��0000-4000-7f7f ���� �ʏ�̕␔�\���ɕύX�B
;	1.17	1.19.1	�ŏ��� 1clock �ڂŁAdos-function���g�p�\�ɂȂ���
;					�����A�s�s�����Ȃ���΁Aver 1.20 �ɏ��i�`^^;
