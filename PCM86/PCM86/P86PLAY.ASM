; ==============================================
;                                               
;   �o�b�l�W�U�p�@�o�b�l�Đ��c�[���uP86PLAY�v	
;                                               
;                 Version 0.08  1993/12/27      
;                 Copyright  (C)  �܂��܂�      
;                                               
; ==============================================

; ---------- �՗� ---------------------------------------------->8�c
; v0.01	1993/09/21
;	�o�b�l�W�U���O�P�O�ɑΉ������Đ��c�[���Ƃ��č쐬�B�������ɂ�
;	��o�b�l�f�[�^���Đ�������B
; v0.03	1993/09/25
;	�o�b�l�W�U���O�P�Q�ɑΉ��B
;	�o�b�l�W�U�̏풓�`�F�b�N�̃o�O�𒼂����B
; v0.04	1993/11/17
;	�o�b�l�W�U���O�Q�Q�ɑΉ��B
;	�t�@�C�������w�肷��ƁA��������F�ԍ��Q�O�O�Ƀ��[�h���āA�`��
;	���l���O�����F�ԍ��Q�O�O�ɐݒ肵�A�L�[�I���B
;	���[�h���鉹�F�ԍ��A�Z�b�g����`�����l���͉ρB
;	�{�����[�������E�ʁX�ɐݒ�\�B
;	���[�h�ł���o�b�l�`���́A�o�b�W�i�X�e���I�^���m�����j�̂݁B
; v0.05	1993/11/18
;	�o�b�l�W�U���O�Q�R�ɑΉ��B
; v0.06 1993/12/05
;	�w-N�x�I�v�V�������̃��b�Z�[�W������
; v0.07 1993/12/12
;	�w-N�x�I�v�V�������̃��b�Z�[�W�����ǁF���̂Q
;	�t�@�C����������Ȃ������Ƃ��̏����ǉ�
; v0.08 1993/12/28
; ------------------------------------------------------------------

VER_NUM		EQU	<'0.08'>

CR		EQU	0DH		; ���s
LF		EQU	0AH		; ���A
TAB		EQU	09h
EOS		EQU	'$'

MSDOS		EQU	21H
PCM86		EQU	0F4H

; ---------- ������i���j�̏o�́uDISPSTR�v -----------------

DISPSTR		MACRO	ADR
		MOV	AH,09H
		MOV	DX,ADR
		INT	MSDOS
		ENDM

; ----------------------------------------------------------

		.186			; 80186 ���߃Z�b�g

CODE		SEGMENT
		ASSUME	CS:CODE,DS:CODE,SS:CODE

		ORG	5CH

FCB		DB	36 DUP(?)
DTA		DB	128 DUP(?)

; ========== ���C�� ======================================

PMAIN:
		CLD				; ���W�X�^������
		MOV	AX,CS
		MOV	DS,AX
		MOV	ES,AX

CHK_PCM86:
		MOV	AH,35H
		MOV	AL,PCM86
		INT	21H			; �x�N�^�A�h���X�̎擾
		MOV	SI,OFFSET KEYWORD
		ADD	BX,3			; �S�o�C�g�ڂ���
		MOV	DI,BX
		MOV	CX,5
		REPZ	CMPSB
		JZ	CHK_STAY1

		dispstr	<OFFSET MSG_ERR_NOTSTAY>	; �풓���ĂȂ�
		MOV	AX,4C00H
		INT	MSDOS
CHK_STAY1:
		CMP	BYTE PTR ES:[DI],0
		JA	GET_OPT
		CMP	BYTE PTR ES:[DI+1],37		; ver 0.37 �ȏ�n�j
		JAE	GET_OPT

		dispstr	<OFFSET MSG_ERR_VERSION>	; �o�[�W�������Â�
		MOV	AX,4C00H
		INT	MSDOS

; ---------- �I�v�V�����̉�� ------------------------------

GET_OPT:
		MOV	SI,0080h
		LODSB
		OR	AL,AL
		JZ	PUT_HELP
GET_CMDL:
		LODSB
		CMP	AL,' '
		JZ	GET_CMDL
		CMP	AL,TAB
		JZ	GET_CMDL
		CMP	AL,CR
		JZ	OPT_ERR
		CMP	AL,'/'
		JZ	CHK_OPT
		CMP	AL,'-'
		JZ	CHK_OPT
		DEC	SI
		JMP	OPT_FLOAD		; �t�@�C�����[�h

CHK_OPT:
		LODSB
		OR	AL,00100000B		; �������ɂ��낦��
		CMP	AL,'?'
		JZ	PUT_HELP		; �w���v
		CMP	AL,'h'
		JZ	PUT_HELP		; �w���v
		CMP	AL,'s'
		JZ	OPT_STEREO		; �X�e���I
		CMP	AL,'n'
		JZ	OPT_L_ONLY		; ���[�h����
		CMP	AL,'v'
		JZ	OPT_VOLUME		; �{�����[��
		CMP	AL,'t'
		JZ	OPT_TONE		; �o�b�l���F�ԍ�
		CMP	AL,'c'
		JZ	OPT_CH			; �`�����l���ԍ�
		JMP	OPT_ERR

OPT_ERR:
		dispstr	<OFFSET MSG_TITLE>	; �^�C�g���\��
		dispstr	<OFFSET MSG_ERR_OPTION>	; �I�v�V�����G���[
		dispstr	<OFFSET MSG_HELP>	; �w���v�̕\��
		MOV	AX,4C00H
		INT	MSDOS
PUT_HELP:
		dispstr	<OFFSET MSG_TITLE>	; �^�C�g���\��
		dispstr	<OFFSET MSG_HELP>	; �w���v�̕\��
		MOV	AX,4C00H
		INT	MSDOS

OPT_STEREO:
		MOV	[MONORAL_FLG],0
		JMP	GET_CMDL

OPT_L_ONLY:
		MOV	[LOAD_ONLY],1
		JMP	GET_CMDL

OPT_VOLUME:
		LODSB
		OR	AL,00100000B		; �������ɂ��낦��
		CMP	AL,'r'
		JZ	OPT_VOLUMER		; �E�{�����[���H
		CMP	AL,'l'
		JZ	OPT_VOLUMEL		; ���{�����[���H
		JMP	OPT_ERR
OPT_VOLUMER:
		MOV	BX,OFFSET VOL_RIGHT
		JMP	SET_VOLUME
OPT_VOLUMEL:
		MOV	BX,OFFSET VOL_LEFT
SET_VOLUME:
		CALL	GET_NUM
		JC	OPT_ERR
		CMP	AX,17
		JNC	OPT_ERR
		OR	AX,AX
		JZ	OPT_ERR
		MOV	[BX],AL
		JMP	GET_CMDL

OPT_TONE:
		CALL	GET_NUM
		JC	OPT_ERR
		CMP	AX,250
		JNC	OPT_ERR
		MOV	[TONE_NUM],AL
		JMP	GET_CMDL

OPT_CH:
		CALL	GET_NUM
		JC	OPT_ERR
		CMP	AX,20
		JNC	OPT_ERR
		MOV	[CH_NUM],AL
		JMP	GET_CMDL

OPT_FLOAD:
		CMP	LOAD_ONLY,0		; �w-N�x�I�v�V�����H
		JNZ	OPT_FLOAD1
		dispstr	<OFFSET MSG_TITLE>	; �^�C�g���\��
		dispstr	<OFFSET MSG_LOAD>	; ���[�h���`
OPT_FLOAD1:
		PUSH	DS
		POP	ES

		MOV	DX,[EXT_NAME_ADR]
		CALL	GET_FILE_NAME		; �t�@���l�[���𓾂�
		CALL	OPEN_FILE		; �t�@�C�����I�[�v��
		JNC	SET_PCMDAT
		MOV	AH,04H			; FUNC:TONE_CLEAR
		MOV	AL,TONE_NUM		; TONE
		INT	PCM86			; ���F�N���A
		CMP	LOAD_ONLY,0		; �w-N�x�I�v�V�����H
		JNZ	OPT_FLOAD3
		dispstr	<OFFSET MSG_ERR_FOPEN>	; �t�@�C�����G���[
		MOV	AX,4C00H
		INT	MSDOS
OPT_FLOAD3:
		dispstr	<OFFSET MSG_ERR_FOPEN2>	; �t�@�C�����G���[
		MOV	AX,4C00H
		INT	MSDOS

SET_PCMDAT:
		CMP	LOAD_ONLY,0		; �w-N�x�I�v�V�����H
		JZ	OPT_FLOAD2
		dispstr	<OFFSET MSG_LOAD2>	; ���[�h���`
OPT_FLOAD2:
		MOV	AH,04H			; FUNC:TONE_CLEAR
		MOV	AL,TONE_NUM		; TONE
		INT	PCM86			; ���F�N���A
SET_PCMDAT1:
		MOV	CX,0400H
		CALL	READ_FILE
		MOV	SI,OFFSET FREAD_BUFFER
		MOV	AH,05H			; FUNC:TONE_LOAD
		MOV	AL,TONE_NUM		; TONE
		INT	PCM86			; ���F�Z�b�g
		OR	AL,AL
		JZ	SET_PCMDAT2
		JMP	P86PLAY_ERR
SET_PCMDAT2:
		CMP	[FREAD_ENDF],0
		JZ	SET_PCMDAT1

		CALL	CLOSE_FILE		; �t�@�C�����N���[�Y
		MOV	AH,06H			; ���F���Z�b�g
		MOV	AL,[TONE_NUM]
		MOV	DH,[VOL_LEFT]
		MOV	DL,[VOL_RIGHT]
		MOV	BX,4000H
		MOV	CL,[MONORAL_FLG]
		MOV	CH,[_8BIT_FLG]
		INT	PCM86
		OR	AL,AL
		JZ	PLAY_PCM
		JMP	P86PLAY_ERR

; ---------- �o�b�l�̍Đ� ----------------------------------

PLAY_PCM:
		MOV	AH,01H			; FUNC:TONE_SET
		MOV	AL,CH_NUM		; CH  
		MOV	DL,TONE_NUM		; TONE
		INT	PCM86
		OR	AL,AL
		JNZ	P86PLAY_ERR

		CMP	LOAD_ONLY,0		; ���[�h���邾���H
		JNZ	P86PLAY_END

		MOV	AH,02H			; FUNC:KEY_ON
		MOV	AL,CH_NUM		; CH  
		INT	PCM86
		OR	AL,AL
		JNZ	P86PLAY_ERR
		dispstr	<OFFSET MSG_PLAY>	; �Đ������`

P86PLAY_END:
		MOV	AX,4C00H		; ����I��
		INT	MSDOS
P86PLAY_ERR:
		CMP	LOAD_ONLY,0		; ���[�h���邾���H
		JNZ	P86PLAY_ERR_2
		dispstr	<OFFSET MSG_ERR_PCM86>	; �G���[
		MOV	AX,4C00H
		INT	MSDOS
P86PLAY_ERR_2:
		dispstr	<OFFSET MSG_ERR_PCM86_>	; �G���[
		MOV	AX,4C00H
		INT	MSDOS

; ---------- �T�u���[�`�� ---------------------------

GET_NUM		PROC	NEAR

		PUSH	BX
		PUSH	CX
		PUSH	DX
		PUSH	SI

		XOR	AX,AX
		XOR	BX,BX
		MOV	CX,10
GET_NUML:
		MOV	BL,DS:[SI]
		SUB	BL,'0'
		CMP	BL,10
		JNC	GET_NUME
		INC	SI
		MUL	CX
		ADD	AX,BX
		JMP	GET_NUML

GET_NUME:
		POP	DX
		CMP	SI,DX
		JZ	GET_NUMN	;	�ȗ����ꂽ�ꍇ
		POP	DX
		POP	CX
		POP	BX
		CLC
		RET
GET_NUMN:
		MOV	SI,DX
		POP	DX
		POP	CX
		POP	BX
		MOV	AX,0FFFFH
		STC
		RET
GET_NUM		ENDP


GET_FILE_NAME	PROC	NEAR

		PUSH	CS
		POP	ES
		MOV	DI,OFFSET FILE_NAME
		XOR	AH,AH
GET_FN_LOOP:
		LODSB
		CMP	AL,' '
		JZ	GET_FN_END
		CMP	AL,TAB
		JZ	GET_FN_END
		CMP	AL,CR
		JZ	GET_FN_END
		CMP	AL,','
		JZ	GET_FN_END
		STOSB
		CMP	AL,'.'
		JNZ	GET_FN_LOOP
		MOV	AH,0FFH
		JMP	GET_FN_LOOP
GET_FN_END:
		OR	AH,AH
		JNZ	SKIP_EXT
		PUSH	SI
		MOV	SI,DX
		MOVSW
		MOVSW
		POP	SI
SKIP_EXT:
		XOR	AL,AL
		STOSB
		RET

GET_FILE_NAME	ENDP


OPEN_FILE	PROC	NEAR

		MOV	AX,3D00H
		XOR	CX,CX
		MOV	DX,OFFSET FILE_NAME
		INT	21H
		MOV	[HANDLE],AX
		RET

OPEN_FILE	ENDP


CLOSE_FILE	PROC	NEAR

		MOV	AH,3EH
		MOV	BX,[HANDLE]
		INT	21H
		RET

CLOSE_FILE	ENDP


READ_FILE	PROC	NEAR

		MOV	[FREAD_ENDF],0
		MOV	AH,3FH
		MOV	BX,[HANDLE]
		MOV	DX,OFFSET FREAD_BUFFER
		INT	21H
		CMP	AX,CX
		JNZ	READ_FILE1
		JMP	READ_FILE_END
READ_FILE1:
		MOV	[FREAD_ENDF],1
		MOV	DI,OFFSET FREAD_BUFFER
		ADD	DI,AX
		SUB	CX,AX
		XOR	AX,AX
		REP	STOSB
READ_FILE_END:
		RET

READ_FILE	ENDP

; ---------- �e�탏�[�N�G���A ------------------------------

KEYWORD		DB	'PCM86'

CH_NUM		DB	0
TONE_NUM	DB	240
VOL_LEFT	DB	3
VOL_RIGHT	DB	3
MONORAL_FLG	DB	1	; 0=STEREO / 1=MONORAL
_8BIT_FLG	DB	1	; 0=16bit  / 1=8bit
LOAD_ONLY	DB	0
CH_SET_FLG	DB	1
HANDLE		DW	?
FREAD_ENDF	DB	0
EXT_NAME_ADR	DW	EXT_PC8
EXT_PC8		DB	'.pc8'
EXT_P16		DB	'.p16'
EXT_PHL		DB	'.phl'

MSG_TITLE	DB	'�y�@�o�W�U�o�k�`�x�@�z PCM-PLAYER for PCM86  version '
		DB	VER_NUM,CR,LF
		DB	'COPYRIGHT (C) 1993 �͂�����܂� ( WWJ58637 / PC-VAN )'
		DB	CR,LF,CR,LF,EOS
MSG_LOAD	DB	'�f�[�^�����[�h���`���@',CR,LF,EOS
MSG_LOAD2	DB	'o',EOS
MSG_PLAY	DB	'�o�b�l���Đ������`��',CR,LF,EOS
MSG_ERR_NOTSTAY	DB	'�o�b�l�W�U���풓���Ă܂���',CR,LF,EOS
MSG_ERR_VERSION	DB	'�o�b�l�W�U�̃o�[�W�������Â��ł���',CR,LF,EOS
MSG_ERR_OPTION	DB	'���`��I�v�V����������s�\�ł���',CR,LF,EOS
MSG_ERR_PCM86	DB	'�o�b�l�W�U�`�o�h�̃G���[�Ȃ́�',CR,LF,EOS
MSG_ERR_PCM86_	DB	'e',EOS
MSG_ERR_FOPEN	DB	'�t�@�C�����ǂ߂܂���',CR,LF,EOS
MSG_ERR_FOPEN2	DB	'.',EOS
MSG_HELP	DB	'USAGE  : P86PLAY [[-|/][OPTION(s)]] FILENAME   ',CR,LF
		DB	'OPTION : -H    �w���v�\��(���̃��b�Z�[�W)      ',CR,LF
		DB	'         -C#   �`�����l���ԍ�(0-19  DEF=0  )   ',CR,LF
		DB	'         -T#   �o�b�l���F�ԍ�(0-249 DEF=200)   ',CR,LF
		DB	'         -VL#  ���{�����[��(1:MAX 16:MIN DEF=2)',CR,LF
		DB	'         -VR#  �E�{�����[��(1:MAX 16:MIN DEF=2)',CR,LF
		DB	'         -N    �o�b�l�Đ��ƃ��b�Z�[�W�o�͂�}��',CR,LF
		DB	EOS

		ALIGN	4

FILE_NAME	DB	64 DUP(?)
FREAD_BUFFER	DB	400H DUP(?)

; ========== �����܂� ======================================

CODE		ENDS
		END	PMAIN
