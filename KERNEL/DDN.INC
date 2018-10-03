;/////////////////////////////////////////////////////////////////////////////;
;      Multi module music driver MFXDDN(tm) kernel system release 1.00 
;  copyright (c) 1993 ABA / T.Kobayashi and Interfair  All Rights Reserved.
;ドライバー、カーネル共通インクルードファイル
;/////////////////////////////////////////////////////////////////////////////;

ver			equ		'1.18R3.1'				; mfxddn kernel バージョン
xmml_rel	equ		'1.3'					; XMML3.00 release番号

MAXTRACK			equ		32				; 処理トラック数
TIMERDEVICE_ERROR	equ		0010h
SOUNDDEVICE_ERROR	equ		0011h
MAX_NEST			=		16				; 繰り返しの最大ネスト数
FADEOUT_DELTA		=		2				; フェードアウトvolume減衰値
TABLE_SIZE			=		1024			; 64tr

;/////////////////////////////// Driver DTA

BASE			equ	100h
DRVTYPE			equ	BASE		+4			; ドライバータイプ(Timer/Normal)
DRVID			equ	DRVTYPE		+2			; ドライバーID
DRVINIT			equ	DRVID		+16			; 組み込み時の初期化サブ
DRVEND			equ	DRVINIT		+2			; 取り外し時の初期化サブ
DRVPLAY			equ	DRVEND		+2			; 演奏開始時のサブ
DRVSTOP			equ	DRVPLAY		+2			; 演奏終了時のサブ
DRVINT			equ	DRVSTOP		+2			; 常時割り込み先
DRVCH			equ	DRVINT		+2			; ドライバー使用可能チャンネル数
DRVUSECH		equ	DRVCH		+1			; ドライバー使用中チャンネル数
DRVVERINT		equ	DRVUSECH	+1			; ver. x.yy   バージョン x  (数値)
DRVVERREAL		equ	DRVVERINT	+1			; ver. x.yy   バージョン yy (数値)
DRVINSTMSG		equ	DRVVERREAL	+1			; 組み込み成功メッセージアドレス
DRVUSEMSG		equ	DRVINSTMSG	+2			; 組み込み中の機能表示ﾒｯｾｰｼﾞｱﾄﾞﾚｽ
DRVFUNC			equ	DRVUSEMSG	+2			; ファンクションアドレス

NORMAL_DEVICE	equ	0000h					; 通常デバイス
TIMER_DEVICE	equ	1000h					; タイマーデバイス
ETC_DEVICE		equ	2000h					; その他

TRUE			equ	01h
FALSE			equ	00h
ON				equ	01h
OFF				equ	00h
TIMER_ON		equ	00h						; 割り込み可能
TIMER_OFF		equ	-1h						; 割り込み不可能

IFDEF	MFXDRVDDN_KERNEL		; 以下、カーネルのコンパイル時のみだよ-------
;/////////////////////////////// DDN buffer
DDN_CHBUF	struc
	use_flag	db		?			; 0 :このトラックを使用中か?(TRUE/FALSE)
	driver_no	db		?			; 1 :使用ドライバのテーブル登録ナンバー
	channel		db		?			; 2 :ドライバのチャンネル
	mus_ofs		dw		?			; 3 :演奏データのオフセットアドレス
	mus_seg		dw		?			; 5 :演奏データのセグメントアドレス
	steptime	dw		?			; 7 :次の命令までのステップタイム
	note		db		?			; 9 :ノート(更新される)
	velocity	db		?			; 10:ベロシティー
	program		db		?			; 11:プログラムナンバー
	volume		db		?			; 12:ボリューム
	expression	db		?			; 13:エクスプレッション
	modulation	db		?			; 14:モジュレーション
	panpot		db		?			; 15:パンポット
	bank		dw		?			; 16:バンク
	pkeypresser	db		?			; 18:ポリフォニックキープレッシャー
	hold1		db		?			; 19:ホールド    (TRUE:on FALSE:off)
	poltament	db		?			; 20:ポルタメント(TRUE:on FALSE:off)
	sustenuto	db		?			; 21:ソステヌート(TRUE:on FALSE:off)
	soft		db		?			; 22:ソフト      (TRUE:on FALSE:off)
	poltctrl	db		?			; 23:ポルタメントコントロール
	ueff1sendlv	db		?			; 24:汎用エッフェクト１
	ueff2sendlv	db		?			; 25:汎用エッフェクト２
	ueff3sendlv	db		?			; 26:汎用エッフェクト３
	chpresser	db		?			; 27:チャンネルプレッシャー
	pitchbend	dw		?			; 28:ピッチベンドレンジ
	note_count	dw		?			; 30:ノートカウンター(Note on毎にカウントする)
	note_total	db		?			; 32:発生中のノートのトータル
	note_ofs	dw		?			; 33:ノートバッファのあるオフセット
	note_seg	dw		?			; 35:ノートバッファのあるセグメント
			ends

;/////////////////////////////// Repeat Buffer
DDN_REPBUF	struc
	rep_level		dw		?				; リピート深さ
	rep_count		dw		MAX_NEST dup(?)	; リピートカウント
	rep_address		dw		MAX_NEST dup(?)	; 戻りアドレス
	rep_exitaddress	dw		MAX_NEST dup(?)	; 抜けアドレス
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
;---- テスト用変数
global	firstclock:byte
ENDIF
