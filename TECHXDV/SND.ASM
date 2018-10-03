;==============================================================================
; �����h���C�o�쐬�p�x�[�X�v���O����
; �{�v���O�����́Apublic domain software�ł��B�����R�ɂ��g���������B
;                                         based programmed by ABA / T.Kobayashi
;==============================================================================
			jumps
			.186
			.model	tiny
			.code

include		stdio.inc
include		ddn.inc
include		option.inc
include		usertool.inc
include		snd.inc

			.code
			assume	cs:@code,ds:@code
			org		100h
start:
			jmp		near ptr com_start

;------------------------------------------------------------------------------
; �h���C�o�[�X�e�[�^�X�e�[�u�� ddn.inc �ɏ���
;
org	DRVTYPE
				dtype		dw	STATUS_DRVTYPE
org	DRVID
				did			db	STATUS_DRVID
org	DRVINIT
	;��MLD.EXE �œo�^���Ɏ��s����T�u���[�`���̃A�h���X���w�肵�܂��B
	;MLD.EXE����� far call(callf)����܂����A�A�h���X�͂��̂悤�� 2byte
	;��near�A�h���X�ŗ^���ĉ������B
	;NULL �̏ꍇ�A���̃G���A�͎g�p���܂���B
				dinit		dw	offset driver_init

org	DRVEND
	;��mfxddn /r ���Ɏ��s����T�u���[�`���̃A�h���X���w�肵�܂��B
	;MLD.EXE����� far call(callf)����܂����A�A�h���X�͂��̂悤�� 2byte
	;��near�A�h���X�ŗ^���ĉ������B
	;NULL �̏ꍇ�A���̃G���A�͎g�p���܂���B
				dend		dw	offset driver_end

org	DRVPLAY
	;�����t�J�n���Ɏ��s����T�u���[�`���̃A�h���X���w�肵�܂��B
	;mfxddn �� far call(callf)���܂����A�A�h���X�͂��̂悤�� 2byte
	;��near�A�h���X�ŗ^���ĉ������B
	;NULL �̏ꍇ�A���̃G���A�͎g�p���܂���B
				dplay		dw	offset driver_play

org	DRVSTOP
	;�����t�I�����Ɏ��s����T�u���[�`���̃A�h���X���w�肵�܂��B
	;mfxddn �� far call(callf)���܂����A�A�h���X�͂��̂悤�� 2byte
	;��near�A�h���X�ŗ^���ĉ������B
	;NULL �̏ꍇ�A���̃G���A�͎g�p���܂���B
				dstop		dw	offset driver_stop

org	DRVINT
	;�����t���A�펞���s����T�u���[�`���̃A�h���X���w�肵�܂��B
	;���Ƃ��� timebase=48 �Ȃ�A1����(4/4)�ŁA192��Ăяo����܂��B
	;�]���ăT�u���[�`���͂ł��邾���y���������s���ĉ������B
	;mfxddn �� far call(callf)���܂����A�A�h���X�͂��̂悤�� 2byte
	;��near�A�h���X�ŗ^���ĉ������B
	;NULL �̏ꍇ�A���̃G���A�͎g�p���܂���B
				dint		dw	offset driver_timer_interrupt

org	DRVCH
	;���h���C�o���g�p�\�ȃ`�����l������ݒ肵�܂��B
	;�����́A�ݒ肵�Ă��Ӗ����Ȃ���������܂���B
				dch			db	3

org	DRVUSECH
	;���h���C�o���g�p���ȃ`�����l������ݒ肵�܂��B
	;�����́A�ݒ肵�Ă��Ӗ����Ȃ���������܂���B
				dusech		db	3

org	DRVVERINT
	;���o�[�W�����ԍ� x.yy �� x ���w�肵�܂��B
				dverint		db	version_int

org	DRVVERREAL
	;���o�[�W�����ԍ� x.yy �� yy ���w�肵�܂��B
				dverreal	db	version_real

org	DRVINSTMSG
	;��MLD.EXE �œo�^���ɕ\�����郁�b�Z�[�W�̊i�[���ꂽ�A�h���X��
	;�^���ĉ������B�Ȃ��A������̍Ō�� '$' �ł��B
				dw			offset dinstmsg

org	DRVUSEMSG
	;��mfxddn �̋@�\�\���ŕ\�����郁�b�Z�[�W�̊i�[���ꂽ�A�h���X��
	;�^���ĉ������B�Ȃ��A������̍Ō�� '$' �ł��B
				dw			offset dusemsg

org	DRVFUNC
	;���������炪�Ausl_drv.doc �ɋL�q����Ă���@�\�����ۂɎ��s����
	;�T�u���[�`���̃A�h���X��^����Ƃ���ł��B
	;mfxddn �� far call(callf)���܂����A�A�h���X�͂��̂悤�� 2byte
	;��near�A�h���X�ŗ^���ĉ������B
	;NULL �̏ꍇ�A���̃G���A�͎g�p���܂���B
	;�܂��Aoffset func_ecm ���珇�ɁAusl_drv.doc �� ah=0 ����Aah=�Ō� �܂�
	;�Ή����Ă��܂��B
;----------------- controll ---------------------------------------------------
				dw			offset func_ecm
				dw			offset func_note_off
				dw			offset func_note_on
				dw			offset func_poly_keypress
				dw			offset func_bank_select
				dw			offset func_modulation
				dw			offset func_pol_time
				dw			offset func_data_entry
				dw			offset func_volume
				dw			offset func_panpot
				dw			offset func_expression
				dw			offset func_hold1
				dw			offset func_poltament
				dw			offset func_sostenuto
				dw			offset func_soft
				dw			offset func_pol_ctrl
				dw			offset func_effect1
				dw			offset func_effect3
				dw			offset func_nrpn
				dw			offset func_rpn	
				dw			offset func_prog_chg
				dw			offset func_ch_presser
				dw			offset func_pitchbend
				dw			offset func_all_soundoff
				dw			offset func_all_resetctrler
				dw			offset func_all_noteoff
				dw			offset func_omni_off
				dw			offset func_omni_on
				dw			offset func_mono
				dw			offset func_poly
				dw			offset func_active_sence
				dw			offset func_exclusive
				dw			offset func_vibrato
				dw			offset func_master_volume
;------------------------------------------------------------------------------
.data

dinstmsg	db	'�����h���C�o��{PROGRAM version ',version,CR
			db	'$'

dusemsg		db	'�����h���C�o��{PROGRAM version ',version
			db	'$'

.code

;------------------------------------------------------------------------------
;���펞���荞�ݕ���
	;�����t���A�펞���s����T�u���[�`���ł��B
	;���Ƃ��� timebase=48 �Ȃ�A1����(4/4)�ŁA192��Ăяo����܂��B
	;�]���ăT�u���[�`���͂ł��邾���y���������s���ĉ������B
	;�܂��A�K�� far return(retf) �Ŗ߂��ĉ������B
	;�Ăяo���ꂽ�Ƃ��Ads �́A���̃v���O�����̃Z�O�����gcs (ds:=cs)
	;�ɂȂ��Ă��܂��B
driver_timer_interrupt	proc	far
			ret
driver_timer_interrupt	endp

;------------------------------------------------------------------------------
;�����t�I�������s
	;�����t�I�����Ɏ��s����T�u���[�`���ł��B
	;�K�� far return(retf) �Ŗ߂��ĉ������B
	;�Ăяo���ꂽ�Ƃ��Ads �́A���̃v���O�����̃Z�O�����gcs (ds:=cs)
	;�ɂȂ��Ă��܂��B
driver_end	proc	far
			ret
driver_end	endp

;------------------------------------------------------------------------------
;��mld.exe �o�^�����s
	;��MLD.EXE �̓o�^���Ɏ��s����T�u���[�`���ł��B
	;�K�� far return(retf) �Ŗ߂��ĉ������B
	;�Ăяo���ꂽ�Ƃ��Ads �́A���̃v���O�����̃Z�O�����gcs (ds:=cs)
	;�ɂȂ��Ă��܂��B�܂��A���̃T�u���[�`���̒����� 
	;mld�g��API(int 51h) ���g�p�\�ł��B
	;���������݂����ꍇ		ax = �g�p�ł���`�����l����
	;���������݂��Ȃ��ꍇ	ax = 0
	;�������Aretf �Ŗ߂��ĉ������B
driver_init	proc	far				; MLD �Ăяo���� FAR ����B
	;(1)���������邩�`�F�b�N
	;(2)�Ȃ��Ȃ�Aax:=0 �� retf
	;(3)����������
	;(4)ax:=�g�p�\�`�����l���� �� retf
			mov		ax,3
			ret
driver_init	endp

;------------------------------------------------------------------------------
;�����t�J�n�����s
driver_play	proc	far
	;�����t�J�n���Ɏ��s����T�u���[�`���̃A�h���X���w�肵�܂��B
	;�K�� far return(retf) �Ŗ߂��ĉ������B
	;�����ł́A�����̏������A�����Ȃǂ��s���ĉ������B
	;�܂��A�Ăяo���ꂽ�Ƃ��Ads �́A���̃v���O�����̃Z�O�����gcs (ds:=cs)
	;�ɂȂ��Ă��܂��B
			ret
driver_play	endp

;------------------------------------------------------------------------------
;�����t�I�������s
driver_stop	proc	far			; DDN�ďo�� FAR ����
	;�����t�I�����Ɏ��s����T�u���[�`���̃A�h���X���w�肵�܂��B
	;�K�� far return(retf) �Ŗ߂��ĉ������B
	;�����ł́A�����̏������A�����Ȃǂ��s���ĉ������B
	;�܂��A�Ăяo���ꂽ�Ƃ��Ads �́A���̃v���O�����̃Z�O�����gcs (ds:=cs)
	;�ɂȂ��Ă��܂��B
			ret
driver_stop	endp

;------------------------------------------------------------------------------
;��com��rename���Ď��s����ƁA�����ɗ��܂��B
com_start	proc
			mov		ax,cs
			mov		ds,ax
			_print	dinstmsg
			_exit	NULL
com_start	endp
;------------------------------------------------------------------------------
			end		start
