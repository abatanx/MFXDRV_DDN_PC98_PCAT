;/////////////////////////////////////////////////////////////////////////////;
;      Multi module music driver MFXDDN(tm) kernel system release 1.00 
;  copyright (c) 1993 ABA / T.Kobayashi and Interfair  All Rights Reserved.
;�h���C�o�[�A�J�[�l�����ʃC���N���[�h�t�@�C��
;/////////////////////////////////////////////////////////////////////////////;

ver			equ		'1.18R3.1'				; mfxddn kernel �o�[�W����
xmml_rel	equ		'1.3'					; XMML3.00 release�ԍ�

MAXTRACK			equ		32				; �����g���b�N��
TIMERDEVICE_ERROR	equ		0010h
SOUNDDEVICE_ERROR	equ		0011h
MAX_NEST			=		16				; �J��Ԃ��̍ő�l�X�g��
FADEOUT_DELTA		=		2				; �t�F�[�h�A�E�gvolume�����l
TABLE_SIZE			=		1024			; 64tr

;/////////////////////////////// Driver DTA

BASE			equ	100h
DRVTYPE			equ	BASE		+4			; �h���C�o�[�^�C�v(Timer/Normal)
DRVID			equ	DRVTYPE		+2			; �h���C�o�[ID
DRVINIT			equ	DRVID		+16			; �g�ݍ��ݎ��̏������T�u
DRVEND			equ	DRVINIT		+2			; ���O�����̏������T�u
DRVPLAY			equ	DRVEND		+2			; ���t�J�n���̃T�u
DRVSTOP			equ	DRVPLAY		+2			; ���t�I�����̃T�u
DRVINT			equ	DRVSTOP		+2			; �펞���荞�ݐ�
DRVCH			equ	DRVINT		+2			; �h���C�o�[�g�p�\�`�����l����
DRVUSECH		equ	DRVCH		+1			; �h���C�o�[�g�p���`�����l����
DRVVERINT		equ	DRVUSECH	+1			; ver. x.yy   �o�[�W���� x  (���l)
DRVVERREAL		equ	DRVVERINT	+1			; ver. x.yy   �o�[�W���� yy (���l)
DRVINSTMSG		equ	DRVVERREAL	+1			; �g�ݍ��ݐ������b�Z�[�W�A�h���X
DRVUSEMSG		equ	DRVINSTMSG	+2			; �g�ݍ��ݒ��̋@�\�\��ү���ޱ��ڽ
DRVFUNC			equ	DRVUSEMSG	+2			; �t�@���N�V�����A�h���X

NORMAL_DEVICE	equ	0000h					; �ʏ�f�o�C�X
TIMER_DEVICE	equ	1000h					; �^�C�}�[�f�o�C�X
ETC_DEVICE		equ	2000h					; ���̑�

TRUE			equ	01h
FALSE			equ	00h
ON				equ	01h
OFF				equ	00h
TIMER_ON		equ	00h						; ���荞�݉\
TIMER_OFF		equ	-1h						; ���荞�ݕs�\

IFDEF	MFXDRVDDN_KERNEL		; �ȉ��A�J�[�l���̃R���p�C�����݂̂���-------
;/////////////////////////////// DDN buffer
DDN_CHBUF	struc
	use_flag	db		?			; 0 :���̃g���b�N���g�p����?(TRUE/FALSE)
	driver_no	db		?			; 1 :�g�p�h���C�o�̃e�[�u���o�^�i���o�[
	channel		db		?			; 2 :�h���C�o�̃`�����l��
	mus_ofs		dw		?			; 3 :���t�f�[�^�̃I�t�Z�b�g�A�h���X
	mus_seg		dw		?			; 5 :���t�f�[�^�̃Z�O�����g�A�h���X
	steptime	dw		?			; 7 :���̖��߂܂ł̃X�e�b�v�^�C��
	note		db		?			; 9 :�m�[�g(�X�V�����)
	velocity	db		?			; 10:�x���V�e�B�[
	program		db		?			; 11:�v���O�����i���o�[
	volume		db		?			; 12:�{�����[��
	expression	db		?			; 13:�G�N�X�v���b�V����
	modulation	db		?			; 14:���W�����[�V����
	panpot		db		?			; 15:�p���|�b�g
	bank		dw		?			; 16:�o���N
	pkeypresser	db		?			; 18:�|���t�H�j�b�N�L�[�v���b�V���[
	hold1		db		?			; 19:�z�[���h    (TRUE:on FALSE:off)
	poltament	db		?			; 20:�|���^�����g(TRUE:on FALSE:off)
	sustenuto	db		?			; 21:�\�X�e�k�[�g(TRUE:on FALSE:off)
	soft		db		?			; 22:�\�t�g      (TRUE:on FALSE:off)
	poltctrl	db		?			; 23:�|���^�����g�R���g���[��
	ueff1sendlv	db		?			; 24:�ėp�G�b�t�F�N�g�P
	ueff2sendlv	db		?			; 25:�ėp�G�b�t�F�N�g�Q
	ueff3sendlv	db		?			; 26:�ėp�G�b�t�F�N�g�R
	chpresser	db		?			; 27:�`�����l���v���b�V���[
	pitchbend	dw		?			; 28:�s�b�`�x���h�����W
	note_count	dw		?			; 30:�m�[�g�J�E���^�[(Note on���ɃJ�E���g����)
	note_total	db		?			; 32:�������̃m�[�g�̃g�[�^��
	note_ofs	dw		?			; 33:�m�[�g�o�b�t�@�̂���I�t�Z�b�g
	note_seg	dw		?			; 35:�m�[�g�o�b�t�@�̂���Z�O�����g
			ends

;/////////////////////////////// Repeat Buffer
DDN_REPBUF	struc
	rep_level		dw		?				; ���s�[�g�[��
	rep_count		dw		MAX_NEST dup(?)	; ���s�[�g�J�E���g
	rep_address		dw		MAX_NEST dup(?)	; �߂�A�h���X
	rep_exitaddress	dw		MAX_NEST dup(?)	; �����A�h���X
			ends

;/////////////////////////////// DECOMPOSE buffer
DDN_DECOMPOSE	struc
	dec_flag		db		?
	dec_start_ch	db		?
	dec_end_ch		db		?
	dec_now_ch		db		?
			ends

;///
global	start_playing:near , stop_playing:near
global	putdec_8reg:near
global	puthex_8reg:near
global	putbin_8reg:near
global	putdec_16reg:near
global	puthex_16reg:near
global	putbin_16reg:near
global	call_driver:near
global	_mfxddn_kernel_program:near
global	call_driver:near
global	timer_drv:byte,now_track:word,module_drv:word:16
global	timer_status:byte
global	track_buf:DDN_CHBUF:MAXTRACK,repeat_buf:DDN_REPBUF:MAXTRACK
global	dec_buf:DDN_DECOMPOSE:MAXTRACK
global	mastervol:word,volume_factor:word
global	play_skip_flag:word,play_skip_tempo:word,skip_flag:word
global	tempo:word
global	track_function:near
global	module_drv:word:16,timer_drv:byte,timebase:word
global	timer_status:byte,now_track:word,pause_flag:word,skip_flag:word
global	fadeout_static:word,fadeout_active:word,fadeout_flag:word
global	timerout_flag:word
global	play_counter:dword
global	track_function:near,infinity_play:byte,play_table_temp:byte:TABLE_SIZE
;---- �e�X�g�p�ϐ�
global	firstclock:byte
ENDIF