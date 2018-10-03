;==============================================================================
; 音源ドライバ作成用ベースプログラム
; 本プログラムは、public domain softwareです。ご自由にお使い下さい。
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
include		pcm86.inc

			.code
			assume	cs:@code,ds:@code
			org		100h
start:
			jmp		near ptr com_start

;------------------------------------------------------------------------------
; ドライバーステータステーブル ddn.inc に準拠
;
org	DRVTYPE
				dtype		dw	STATUS_DRVTYPE
org	DRVID
				did			db	STATUS_DRVID
org	DRVINIT
	;★MLD.EXE で登録時に実行するサブルーチンのアドレスを指定します。
	;MLD.EXEからは far call(callf)されますが、アドレスはこのように 2byte
	;のnearアドレスで与えて下さい。
	;NULL の場合、このエリアは使用しません。
				dinit		dw	offset driver_init

org	DRVEND
	;★mfxddn /r 時に実行するサブルーチンのアドレスを指定します。
	;MLD.EXEからは far call(callf)されますが、アドレスはこのように 2byte
	;のnearアドレスで与えて下さい。
	;NULL の場合、このエリアは使用しません。
				dend		dw	offset driver_end

org	DRVPLAY
	;★演奏開始時に実行するサブルーチンのアドレスを指定します。
	;mfxddn は far call(callf)しますが、アドレスはこのように 2byte
	;のnearアドレスで与えて下さい。
	;NULL の場合、このエリアは使用しません。
				dplay		dw	offset driver_play

org	DRVSTOP
	;★演奏終了時に実行するサブルーチンのアドレスを指定します。
	;mfxddn は far call(callf)しますが、アドレスはこのように 2byte
	;のnearアドレスで与えて下さい。
	;NULL の場合、このエリアは使用しません。
				dstop		dw	offset driver_stop

org	DRVINT
	;★演奏中、常時実行するサブルーチンのアドレスを指定します。
	;たとえば timebase=48 なら、1小節(4/4)で、192回呼び出されます。
	;従ってサブルーチンはできるだけ軽い処理を行って下さい。
	;mfxddn は far call(callf)しますが、アドレスはこのように 2byte
	;のnearアドレスで与えて下さい。
	;NULL の場合、このエリアは使用しません。
				dint		dw	offset driver_timer_interrupt

org	DRVCH
	;★ドライバが使用可能なチャンネル数を設定します。
	;ここは、設定しても意味がないかもしれません。
				dch			db	STATUS_DRVCH

org	DRVUSECH
	;★ドライバが使用中なチャンネル数を設定します。
	;ここは、設定しても意味がないかもしれません。
				dusech		db	STATUS_DRVUSECH

org	DRVVERINT
	;★バージョン番号 x.yy の x を指定します。
				dverint		db	version_int

org	DRVVERREAL
	;★バージョン番号 x.yy の yy を指定します。
				dverreal	db	version_real

org	DRVINSTMSG
	;★MLD.EXE で登録時に表示するメッセージの格納されたアドレスを
	;与えて下さい。なお、文字列の最後は '$' です。
				dw			offset dinstmsg

org	DRVUSEMSG
	;★mfxddn の機能表示で表示するメッセージの格納されたアドレスを
	;与えて下さい。なお、文字列の最後は '$' です。
				dw			offset dusemsg

org	DRVFUNC
	;★ここからが、usl_drv.doc に記述されている機能を実際に実行する
	;サブルーチンのアドレスを与えるところです。
	;mfxddn は far call(callf)しますが、アドレスはこのように 2byte
	;のnearアドレスで与えて下さい。
	;NULL の場合、このエリアは使用しません。
	;また、offset func_ecm から順に、usl_drv.doc の ah=0 から、ah=最後 まで
	;対応しています。
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

KEYWORD		db	'PCM86'
dinstmsg	db	'【  ＰＣＭ８６  】 STEREO-MULTI PCM DRIVER CONTROL DRIVER Version ',version,CR
			db	'pcm86.com copyright (C) 1993 はせがわまき(まきまき) WWJ58637(PC-VAN)',CR
			db	'pcm86.xdv copyright (C) 1994 ABA / Interfair , All Rights Reserved.',CR
			db	'$'

dusemsg		db	'【 ＰＣＭ８６ 】 制御ドライバ Ver.',version
			db	'$'

.code

;------------------------------------------------------------------------------
;★常時割り込み部分
	;★演奏中、常時実行するサブルーチンです。
	;たとえば timebase=48 なら、1小節(4/4)で、192回呼び出されます。
	;従ってサブルーチンはできるだけ軽い処理を行って下さい。
	;また、必ず far return(retf) で戻って下さい。
	;呼び出されたとき、ds は、このプログラムのセグメントcs (ds:=cs)
	;になっています。
driver_timer_interrupt	proc	far
			ret
driver_timer_interrupt	endp

;------------------------------------------------------------------------------
;★演奏終了時実行
	;★演奏終了時に実行するサブルーチンです。
	;必ず far return(retf) で戻って下さい。
	;呼び出されたとき、ds は、このプログラムのセグメントcs (ds:=cs)
	;になっています。
driver_end	proc	far
			mov		ax,0011h
			int		PCM86
			ret
driver_end	endp

;------------------------------------------------------------------------------
;★mld.exe 登録時実行
	;★MLD.EXE の登録時に実行するサブルーチンです。
	;必ず far return(retf) で戻って下さい。
	;呼び出されたとき、ds は、このプログラムのセグメントcs (ds:=cs)
	;になっています。また、このサブルーチンの中だけ 
	;mld拡張API(int 51h) が使用可能です。
	;音源が存在した場合		ax = 使用できるチャンネル数
	;音源が存在しない場合	ax = 0
	;を代入し、retf で戻って下さい。
driver_init	proc	far				; MLD 呼び出しは FAR だよ。
	;(1)音源があるかチェック
	;(2)ないなら、ax:=0 で retf
	;(3)初期化処理
	;(4)ax:=使用可能チャンネル数 で retf
			MOV		AH,35H
			MOV		AL,PCM86
			INT		21H			; ベクタアドレスの取得 ES:BX
			MOV		SI,OFFSET KEYWORD
			ADD		BX,3			; ４バイト目から
			MOV		DI,BX
			MOV		CX,5
			REPZ	CMPSB
			JZ		CHK_STAY1
			_puts	'PCM86 が常駐していません。'
			xor		ax,ax
			ret
CHK_STAY1:
			CMP		BYTE PTR ES:[DI],'L'
			JZ		P86_OK_L
			CMP		BYTE PTR ES:[DI],' '
			JZ		P86_OK
			CMP		BYTE PTR ES:[DI+1],37		; ver 0.37 以上ＯＫ
			JAE		P86_OK
			_puts	'PCM86 のバージョンが古いです。'
			xor		ax,ax
			ret
P86_OK:
			_put	'PCM86(通常版) '
			mov		cx,20
			jmp		P86_INSTALL
P86_OK_L:
			_put	'PCM86L(軽量版) '
			mov		cx,10
P86_INSTALL:
			_puts	'を認識しました。'
			mov		ax,0010h
			int		PCM86
			mov		[dch],cl
			mov		[dusech],cl
			mov		ax,cx
			ret
driver_init	endp

;------------------------------------------------------------------------------
;★演奏開始時実行
driver_play	proc	far
			call	pcm_entry_init
	;★演奏開始時に実行するサブルーチンのアドレスを指定します。
	;必ず far return(retf) で戻って下さい。
	;ここでは、音源の初期化、消音などを行って下さい。
	;また、呼び出されたとき、ds は、このプログラムのセグメントcs (ds:=cs)
	;になっています。
			ret
driver_play	endp

;------------------------------------------------------------------------------
;★演奏終了時実行
driver_stop	proc	far			; DDN呼出は FAR だよ
			call	pcm_entry_init
	;★演奏終了時に実行するサブルーチンのアドレスを指定します。
	;必ず far return(retf) で戻って下さい。
	;ここでは、音源の初期化、消音などを行って下さい。
	;また、呼び出されたとき、ds は、このプログラムのセグメントcs (ds:=cs)
	;になっています。
			ret
driver_stop	endp

;------------------------------------------------------------------------------
;★comにrenameして実行すると、ここに来ます。
com_start	proc
			mov		ax,cs
			mov		ds,ax
			_print	dinstmsg
			_exit	NULL
com_start	endp
;------------------------------------------------------------------------------
			end		start
