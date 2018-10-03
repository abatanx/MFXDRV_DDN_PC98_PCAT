; ==============================================
;                                               
;     ＰＣＭでＢＥＥＰ音「P86BEEP」(要PCM86)    
;                                               
;                 Version 0.05  1993/12/27      
;                 Copyright  (C)  まきまき      
;                                               
; ==============================================

; ---------- 遍歴 ---------------------------------------------->8…
; v0.01	1993/09/22
;	ＰＣＭ８６ｖ０１０に対応したＪＯＫＥソフト。
;	ＢＥＥＰ音としてメモリにあるＰＣＭデータを再生する。
; v0.02	1993/09/24
;	ＰＣＭ８６ｖ０１１に対応。
;	最高１６ｃｈまでＰＣＭを鳴らす。
; v0.03	1993/09/25
;	ＰＣＭ８６ｖ０１２に対応。
;	ＰＣＭ８６の常駐チェックのバグを直した。
;	最大ＰＣＭチャンネル数はＰＣＭ８６に依存するようにした。
;	ｖ０１２の安全回路に対応。利用開始／終了届を出す。
; v0.04	1993/11/17
;	ＰＣＭ８６ｖ０２２に対応。
; v0.05	1993/12/27
;	ＰＣＭ８６のＦＭ音源ドライバ対応に伴い、チャンネルと音色番号
;	を変更。チャンネル０／音色番号２４０番～２４９番
; ------------------------------------------------------------------

VER_NUM		EQU	<'0.05'>

CR		EQU	0DH		; 改行
LF		EQU	0AH		; 復帰
BEL		EQU	07h		; ベル
TAB		EQU	09h
EOS		EQU	'$'

MSDOS		EQU	21H
PCM86		EQU	0F4H
P86BVEC		EQU	18H

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
		JMP	START

P86B_ID		DB	'P86BEEP',00,05

; ========== 常駐部分（ＩＮＴ１８Ｈ） ======================

INT_ENTRY	PROC	FAR

		CMP	AH,17H		; ブザーＯＮ
		JE	BEEP_OFF
		CMP	AH,17		; ？？(笑)
		JE	PCM_ON		; ただのミスだったんだけど

		JMP	OLD_INT
BEEP_OFF:
		MOV	AH,18H
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
OLD_INT:
		JMP	DWORD PTR CS:[ORG_INT] ; 旧ベクタの処理をする

INT_ENTRY	ENDP

; ---------- 常駐ワークエリア ------------------------------

		ALIGN	4
ORG_INT		DD	?
TONE_NUM	DB	240

		ALIGN	16
		PSIZE	= $

; ========== 非常駐部分 ====================================

START:
		CLD				; レジスタ初期化
		MOV	AX,CS
		MOV	DS,AX
		MOV	ES,AX

PUT_TITLE:
		dispstr	<OFFSET MSG_TITLE>	; タイトル表示

CHK_PCM86:
		MOV	AH,35H
		MOV	AL,PCM86
		INT	21H			; ベクタアドレスの取得 ES:BX
		MOV	SI,OFFSET KEYWORD
		ADD	BX,3			; ４バイト目から
		MOV	DI,BX
		MOV	CX,5
		REPZ	CMPSB
		JZ	CHK_STAY1

		dispstr	<OFFSET MSG_ERR_NOTSTAY> ; ＰＣＭ８６が常駐してない
		MOV	AX,4C00H
		INT	MSDOS
CHK_STAY1:
		CMP	BYTE PTR ES:[DI],0
		JA	P86B_CHK
		CMP	BYTE PTR ES:[DI+1],37		; ver 0.37 以上ＯＫ
		JAE	P86B_CHK
		dispstr	<OFFSET MSG_ERR_VERSION>	; バージョン古い
		MOV	AX,4C00H
		INT	MSDOS

P86B_CHK:
		MOV	AH,35H
		MOV	AL,P86BVEC
		INT	21h
		MOV	WORD PTR [ORG_INT],BX
		MOV	WORD PTR [ORG_INT+2],ES
		MOV	SI,OFFSET P86B_ID
		MOV	DI,SI
		MOV	CX,9
		REPZ	CMPSB
		JNE	STAY

REMOVE:
		MOV	AH,00H			; 利用終了届
		MOV	AL,11H
		INT	PCM86
		CMP	AL,0FFH
		JE	ERR_END

		MOV	AH,25H			; ベクタ書き戻し
		MOV	AL,P86BVEC
		LDS	DX,DWORD PTR ES:[ORG_INT]
		INT	MSDOS

		PUSH	ES			; 領域を開放
		MOV	ES,WORD PTR ES:[002CH]
		MOV	AH,49H
		INT	MSDOS
		POP	ES
		MOV	AH,49H
		INT	MSDOS

		MOV	AX,CS
		MOV	DS,AX
		dispstr	<OFFSET MSG_REMOVE>	; 常駐解除しました
		MOV	AX,4C00H
		INT	MSDOS

STAY:
		MOV	AH,00H			; 利用開始届
		MOV	AL,10H
		INT	PCM86
		CMP	AL,0FFH
		JE	ERR_END

		MOV	AX,CS
		MOV	DS,AX
		MOV	DX,OFFSET INT_ENTRY	; ベクタのセット
		MOV	AH,25H
		MOV	AL,P86BVEC
		INT	MSDOS

		dispstr	<OFFSET MSG_STAY>	; 常駐メッセージ

		MOV	DX,OFFSET PSIZE
		SHR	DX,4
		MOV	AX,3100H
		INT	MSDOS

ERR_END:
		dispstr	<OFFSET MSG_ERR>	; エラー
		MOV	AX,4C00H
		INT	MSDOS

; ---------- 各種ワークエリア ------------------------------

KEYWORD		DB	'PCM86'

MSG_TITLE	DB	'【　Ｐ８６ＢＥＥＰ　】 PCM-BEEP for PCM86  version '
		DB	VER_NUM,CR,LF
		DB	'COPYRIGHT (C) 1993 はせがわまき WWJ58637(PC-VAN)'
		DB	CR,LF,EOS
MSG_ERR_NOTSTAY	DB	'ＰＣＭ８６が常駐してません☆',CR,LF,EOS
MSG_ERR_VERSION	DB	'ＰＣＭ８６のバージョンが古いです☆',CR,LF,EOS
MSG_STAY	DB	'常駐するよ～☆',BEL,CR,LF,EOS
MSG_REMOVE	DB	'常駐解除しました～☆',CR,LF,EOS
MSG_ERR		DB	'ＰＣＭ８６ＡＰＩのエラ～なの～☆',CR,LF,EOS

; ========== おしまい ======================================

CODE		ENDS
		END	PMAIN
