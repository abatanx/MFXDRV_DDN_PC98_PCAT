; ==============================================
;                                               
;   ＰＣＭ８６用　ＰＣＭ再生ツール「P86PLAY」	
;                                               
;                 Version 0.08  1993/12/27      
;                 Copyright  (C)  まきまき      
;                                               
; ==============================================

; ---------- 遍歴 ---------------------------------------------->8…
; v0.01	1993/09/21
;	ＰＣＭ８６ｖ０１０に対応した再生ツールとして作成。メモリにあ
;	るＰＣＭデータを再生させる。
; v0.03	1993/09/25
;	ＰＣＭ８６ｖ０１２に対応。
;	ＰＣＭ８６の常駐チェックのバグを直した。
; v0.04	1993/11/17
;	ＰＣＭ８６ｖ０２２に対応。
;	ファイル名を指定すると、それを音色番号２００にロードして、チャ
;	ンネル０を音色番号２００に設定し、キーオン。
;	ロードする音色番号、セットするチャンネルは可変。
;	ボリュームを左右別々に設定可能。
;	ロードできるＰＣＭ形式は、ＰＣ８（ステレオ／モノラル）のみ。
; v0.05	1993/11/18
;	ＰＣＭ８６ｖ０２３に対応。
; v0.06 1993/12/05
;	『-N』オプション時のメッセージを改良
; v0.07 1993/12/12
;	『-N』オプション時のメッセージを改良：その２
;	ファイルが見つからなかったときの処理追加
; v0.08 1993/12/28
; ------------------------------------------------------------------

VER_NUM		EQU	<'0.08'>

CR		EQU	0DH		; 改行
LF		EQU	0AH		; 復帰
TAB		EQU	09h
EOS		EQU	'$'

MSDOS		EQU	21H
PCM86		EQU	0F4H

; ---------- 文字列（＄）の出力「DISPSTR」 -----------------

DISPSTR		MACRO	ADR
		MOV	AH,09H
		MOV	DX,ADR
		INT	MSDOS
		ENDM

; ----------------------------------------------------------

		.186			; 80186 命令セット

CODE		SEGMENT
		ASSUME	CS:CODE,DS:CODE,SS:CODE

		ORG	5CH

FCB		DB	36 DUP(?)
DTA		DB	128 DUP(?)

; ========== メイン ======================================

PMAIN:
		CLD				; レジスタ初期化
		MOV	AX,CS
		MOV	DS,AX
		MOV	ES,AX

CHK_PCM86:
		MOV	AH,35H
		MOV	AL,PCM86
		INT	21H			; ベクタアドレスの取得
		MOV	SI,OFFSET KEYWORD
		ADD	BX,3			; ４バイト目から
		MOV	DI,BX
		MOV	CX,5
		REPZ	CMPSB
		JZ	CHK_STAY1

		dispstr	<OFFSET MSG_ERR_NOTSTAY>	; 常駐してない
		MOV	AX,4C00H
		INT	MSDOS
CHK_STAY1:
		CMP	BYTE PTR ES:[DI],0
		JA	GET_OPT
		CMP	BYTE PTR ES:[DI+1],37		; ver 0.37 以上ＯＫ
		JAE	GET_OPT

		dispstr	<OFFSET MSG_ERR_VERSION>	; バージョンが古い
		MOV	AX,4C00H
		INT	MSDOS

; ---------- オプションの解析 ------------------------------

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
		JMP	OPT_FLOAD		; ファイルロード

CHK_OPT:
		LODSB
		OR	AL,00100000B		; 小文字にそろえる
		CMP	AL,'?'
		JZ	PUT_HELP		; ヘルプ
		CMP	AL,'h'
		JZ	PUT_HELP		; ヘルプ
		CMP	AL,'s'
		JZ	OPT_STEREO		; ステレオ
		CMP	AL,'n'
		JZ	OPT_L_ONLY		; ロードだけ
		CMP	AL,'v'
		JZ	OPT_VOLUME		; ボリューム
		CMP	AL,'t'
		JZ	OPT_TONE		; ＰＣＭ音色番号
		CMP	AL,'c'
		JZ	OPT_CH			; チャンネル番号
		JMP	OPT_ERR

OPT_ERR:
		dispstr	<OFFSET MSG_TITLE>	; タイトル表示
		dispstr	<OFFSET MSG_ERR_OPTION>	; オプションエラー
		dispstr	<OFFSET MSG_HELP>	; ヘルプの表示
		MOV	AX,4C00H
		INT	MSDOS
PUT_HELP:
		dispstr	<OFFSET MSG_TITLE>	; タイトル表示
		dispstr	<OFFSET MSG_HELP>	; ヘルプの表示
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
		OR	AL,00100000B		; 小文字にそろえる
		CMP	AL,'r'
		JZ	OPT_VOLUMER		; 右ボリューム？
		CMP	AL,'l'
		JZ	OPT_VOLUMEL		; 左ボリューム？
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
		CMP	LOAD_ONLY,0		; 『-N』オプション？
		JNZ	OPT_FLOAD1
		dispstr	<OFFSET MSG_TITLE>	; タイトル表示
		dispstr	<OFFSET MSG_LOAD>	; ロード中～
OPT_FLOAD1:
		PUSH	DS
		POP	ES

		MOV	DX,[EXT_NAME_ADR]
		CALL	GET_FILE_NAME		; ファルネームを得る
		CALL	OPEN_FILE		; ファイルをオープン
		JNC	SET_PCMDAT
		MOV	AH,04H			; FUNC:TONE_CLEAR
		MOV	AL,TONE_NUM		; TONE
		INT	PCM86			; 音色クリア
		CMP	LOAD_ONLY,0		; 『-N』オプション？
		JNZ	OPT_FLOAD3
		dispstr	<OFFSET MSG_ERR_FOPEN>	; ファイル名エラー
		MOV	AX,4C00H
		INT	MSDOS
OPT_FLOAD3:
		dispstr	<OFFSET MSG_ERR_FOPEN2>	; ファイル名エラー
		MOV	AX,4C00H
		INT	MSDOS

SET_PCMDAT:
		CMP	LOAD_ONLY,0		; 『-N』オプション？
		JZ	OPT_FLOAD2
		dispstr	<OFFSET MSG_LOAD2>	; ロード中～
OPT_FLOAD2:
		MOV	AH,04H			; FUNC:TONE_CLEAR
		MOV	AL,TONE_NUM		; TONE
		INT	PCM86			; 音色クリア
SET_PCMDAT1:
		MOV	CX,0400H
		CALL	READ_FILE
		MOV	SI,OFFSET FREAD_BUFFER
		MOV	AH,05H			; FUNC:TONE_LOAD
		MOV	AL,TONE_NUM		; TONE
		INT	PCM86			; 音色セット
		OR	AL,AL
		JZ	SET_PCMDAT2
		JMP	P86PLAY_ERR
SET_PCMDAT2:
		CMP	[FREAD_ENDF],0
		JZ	SET_PCMDAT1

		CALL	CLOSE_FILE		; ファイルをクローズ
		MOV	AH,06H			; 音色情報セット
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

; ---------- ＰＣＭの再生 ----------------------------------

PLAY_PCM:
		MOV	AH,01H			; FUNC:TONE_SET
		MOV	AL,CH_NUM		; CH  
		MOV	DL,TONE_NUM		; TONE
		INT	PCM86
		OR	AL,AL
		JNZ	P86PLAY_ERR

		CMP	LOAD_ONLY,0		; ロードするだけ？
		JNZ	P86PLAY_END

		MOV	AH,02H			; FUNC:KEY_ON
		MOV	AL,CH_NUM		; CH  
		INT	PCM86
		OR	AL,AL
		JNZ	P86PLAY_ERR
		dispstr	<OFFSET MSG_PLAY>	; 再生するよ～

P86PLAY_END:
		MOV	AX,4C00H		; 正常終了
		INT	MSDOS
P86PLAY_ERR:
		CMP	LOAD_ONLY,0		; ロードするだけ？
		JNZ	P86PLAY_ERR_2
		dispstr	<OFFSET MSG_ERR_PCM86>	; エラー
		MOV	AX,4C00H
		INT	MSDOS
P86PLAY_ERR_2:
		dispstr	<OFFSET MSG_ERR_PCM86_>	; エラー
		MOV	AX,4C00H
		INT	MSDOS

; ---------- サブルーチン ---------------------------

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
		JZ	GET_NUMN	;	省略された場合
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

; ---------- 各種ワークエリア ------------------------------

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

MSG_TITLE	DB	'【　Ｐ８６ＰＬＡＹ　】 PCM-PLAYER for PCM86  version '
		DB	VER_NUM,CR,LF
		DB	'COPYRIGHT (C) 1993 はせがわまき ( WWJ58637 / PC-VAN )'
		DB	CR,LF,CR,LF,EOS
MSG_LOAD	DB	'データをロード中～☆　',CR,LF,EOS
MSG_LOAD2	DB	'o',EOS
MSG_PLAY	DB	'ＰＣＭを再生するよ～☆',CR,LF,EOS
MSG_ERR_NOTSTAY	DB	'ＰＣＭ８６が常駐してません☆',CR,LF,EOS
MSG_ERR_VERSION	DB	'ＰＣＭ８６のバージョンが古いです☆',CR,LF,EOS
MSG_ERR_OPTION	DB	'う～んオプションが理解不能です☆',CR,LF,EOS
MSG_ERR_PCM86	DB	'ＰＣＭ８６ＡＰＩのエラーなの☆',CR,LF,EOS
MSG_ERR_PCM86_	DB	'e',EOS
MSG_ERR_FOPEN	DB	'ファイルが読めません☆',CR,LF,EOS
MSG_ERR_FOPEN2	DB	'.',EOS
MSG_HELP	DB	'USAGE  : P86PLAY [[-|/][OPTION(s)]] FILENAME   ',CR,LF
		DB	'OPTION : -H    ヘルプ表示(このメッセージ)      ',CR,LF
		DB	'         -C#   チャンネル番号(0-19  DEF=0  )   ',CR,LF
		DB	'         -T#   ＰＣＭ音色番号(0-249 DEF=200)   ',CR,LF
		DB	'         -VL#  左ボリューム(1:MAX 16:MIN DEF=2)',CR,LF
		DB	'         -VR#  右ボリューム(1:MAX 16:MIN DEF=2)',CR,LF
		DB	'         -N    ＰＣＭ再生とメッセージ出力を抑制',CR,LF
		DB	EOS

		ALIGN	4

FILE_NAME	DB	64 DUP(?)
FREAD_BUFFER	DB	400H DUP(?)

; ========== おしまい ======================================

CODE		ENDS
		END	PMAIN
