; ==============================================
;                                               
;    �o�b�l�ŃL�[�N���b�N���uP86CLK�v(�vPCM86)  
;                                               
;                 Version 0.05  1993/12/27      
;                 Copyright  (C)  �܂��܂�      
;                                               
; ==============================================

; ---------- �՗� ---------------------------------------------->8�c
; v0.01	1993/09/22
;	�o�b�l�W�U���O�P�O�ɑΉ������i�n�j�d�\�t�g�B
;	�L�[�N���b�N���Ƃ��ă������ɂ���o�b�l�f�[�^���Đ�����B
; v0.02	1993/09/24
;	�o�b�l�W�U���O�P�P�ɑΉ��B
;	�ō��P�U�����܂ło�b�l��炷�B
; v0.03	1993/09/25
;	�o�b�l�W�U���O�P�Q�ɑΉ��B
;	�o�b�l�W�U�̏풓�`�F�b�N�̃o�O�𒼂����B
;	�ő�o�b�l�`�����l�����͂o�b�l�W�U�Ɉˑ�����悤�ɂ����B
;	���O�P�Q�̈��S��H�ɑΉ��B���p�J�n�^�I���͂��o���B
; v0.04	1993/11/17
;	�o�b�l�W�U���O�Q�Q�ɑΉ��B
; v0.05	1993/12/27
;	�o�b�l�W�U�̂e�l�����h���C�o�Ή��ɔ����A�`�����l���Ɖ��F�ԍ�
;	��ύX�B�`�����l���O�^���F�ԍ��Q�S�O�ԁ`�Q�S�X��
; ------------------------------------------------------------------

VER_NUM		EQU	<'0.05'>

CR		EQU	0DH		; ���s
LF		EQU	0AH		; ���A
BEL		EQU	07h		; �x��
TAB		EQU	09h
EOS		EQU	'$'

MSDOS		EQU	21H
PCM86		EQU	0F4H
P86CVEC		EQU	09H

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
		JMP	START

P86C_ID		DB	'P86CLK',00,05

; ========== �풓�����i�h�m�s�O�X�g�j ======================

INT_ENTRY	PROC	FAR

		PUSH	AX
		PUSH	ES
		SUB	AX,AX
		MOV	ES,AX
		MOV	AL,ES:[0528H]
		MOV	CS:[KEY_N],AL
		POP	ES
		POP	AX

		PUSHF
		CALL	DWORD PTR CS:[ORG_INT] ; ���x�N�^�̏���������

		PUSH	AX
		PUSH	ES
		SUB	AX,AX
		MOV	ES,AX
		MOV	AL,ES:[0528H]
		CMP	AL,CS:[KEY_N]
		POP	ES
		POP	AX
		JE	INT_END

PCM_ON:
		PUSH	AX
		PUSH	DX
		MOV	AH,01H			; FUNC:TONE_SET
		MOV	AL,0			; CH  
		MOV	DL,CS:[TONE_NUM]	; TONE
		INT	PCM86
		OR	AL,AL
		JZ	PCM_ON_SKP1

		MOV	AH,01H			; FUNC:TONE_SET
		MOV	AL,0			; CH  
		MOV	DL,240			; TONE
		MOV	CS:[TONE_NUM],DL
		INT	PCM86
PCM_ON_SKP1:
		MOV	AH,02H			; FUNC:KEY_ON
		MOV	AL,0			; CH  
		INT	PCM86
		INC	CS:[TONE_NUM]
		POP	DX
		POP	AX
INT_END:
		IRET

INT_ENTRY	ENDP

; ---------- �풓���[�N�G���A ------------------------------

		ALIGN	4
ORG_INT		DD	?
KEY_N		DB	?
TONE_NUM	DB	240

		ALIGN	16
		PSIZE	= $

; ========== ��풓���� ====================================

START:
		CLD				; ���W�X�^������
		MOV	AX,CS
		MOV	DS,AX
		MOV	ES,AX

PUT_TITLE:
		dispstr	<OFFSET MSG_TITLE>	; �^�C�g���\��

CHK_PCM86:
		MOV	AH,35H
		MOV	AL,PCM86
		INT	21H			; �x�N�^�A�h���X�̎擾 ES:BX
		MOV	SI,OFFSET KEYWORD
		ADD	BX,3			; �S�o�C�g�ڂ���
		MOV	DI,BX
		MOV	CX,5
		REPZ	CMPSB
		JZ	CHK_STAY1

		dispstr	<OFFSET MSG_ERR_NOTSTAY> ; �o�b�l�W�U���풓���ĂȂ�
		MOV	AX,4C00H
		INT	MSDOS
CHK_STAY1:
		CMP	BYTE PTR ES:[DI],0
		JA	P86C_CHK
		CMP	BYTE PTR ES:[DI+1],37		; ver 0.37 �ȏ�n�j
		JAE	P86C_CHK
		dispstr	<OFFSET MSG_ERR_VERSION>	; �o�[�W�����Â�
		MOV	AX,4C00H
		INT	MSDOS

P86C_CHK:
		MOV	AH,35H
		MOV	AL,P86CVEC
		INT	21h
		MOV	WORD PTR [ORG_INT],BX
		MOV	WORD PTR [ORG_INT+2],ES
		MOV	SI,OFFSET P86C_ID
		MOV	DI,SI
		MOV	CX,8
		REPZ	CMPSB
		JNE	STAY

REMOVE:
		MOV	AH,00H			; ���p�I����
		MOV	AL,11H
		INT	PCM86
		CMP	AL,0FFH
		JE	ERR_END

		MOV	AH,25H			; �x�N�^�����߂�
		MOV	AL,P86CVEC
		LDS	DX,DWORD PTR ES:[ORG_INT]
		INT	MSDOS

		PUSH	ES			; �̈���J��
		MOV	ES,WORD PTR ES:[002CH]
		MOV	AH,49H
		INT	MSDOS
		POP	ES
		MOV	AH,49H
		INT	MSDOS

		MOV	AX,CS
		MOV	DS,AX
		dispstr	<OFFSET MSG_REMOVE>	; �풓�������܂���
		MOV	AX,4C00H
		INT	MSDOS

STAY:
		MOV	AH,00H			; ���p�J�n��
		MOV	AL,10H
		INT	PCM86
		CMP	AL,0FFH
		JE	ERR_END

		MOV	AX,CS
		MOV	DS,AX
		MOV	DX,OFFSET INT_ENTRY	; �x�N�^�̃Z�b�g
		MOV	AH,25H
		MOV	AL,P86CVEC
		INT	MSDOS

		dispstr	<OFFSET MSG_STAY>	; �풓���b�Z�[�W

		MOV	DX,OFFSET PSIZE
		SHR	DX,4
		MOV	AX,3100H
		INT	MSDOS

ERR_END:
		dispstr	<OFFSET MSG_ERR>	; �G���[
		MOV	AX,4C00H
		INT	MSDOS

; ---------- �e�탏�[�N�G���A ------------------------------

KEYWORD		DB	'PCM86'

MSG_TITLE	DB	'�y�@�o�W�U�b�k�j�@�z KEY-CLICK for PCM86  version '
		DB	VER_NUM,CR,LF
		DB	'COPYRIGHT (C) 1993 �͂�����܂� WWJ58637(PC-VAN)'
		DB	CR,LF,EOS
MSG_ERR_NOTSTAY	DB	'�o�b�l�W�U���풓���Ă܂���',CR,LF,EOS
MSG_ERR_VERSION	DB	'�o�b�l�W�U�̃o�[�W�������Â��ł���',CR,LF,EOS
MSG_STAY	DB	'�풓�����`��',CR,LF,EOS
MSG_REMOVE	DB	'�풓�������܂����`��',CR,LF,EOS
MSG_ERR		DB	'�o�b�l�W�U�`�o�h�̃G���`�Ȃ́`��',CR,LF,EOS

; ========== �����܂� ======================================

CODE		ENDS
		END	PMAIN
