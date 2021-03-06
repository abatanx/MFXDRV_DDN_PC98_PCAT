;==============================================================================
; MFXDDN timer driver module
;							Interval timer driver 98
;  copyright (c) 1993 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
			jumps
			dosseg
			.186
			.model	tiny
			.code

include		stdio.inc
include		ddn.inc

TM_OPTIMIZE			=		25				; 精度
											; 10/n(ms) で割り込み
LOCAL_STACKSIZE		=		512				; Local Stack size
			org		100h
start:
			jmp		short com_start

;------------------------------------------------------------------------------
; ドライバーステータステーブル ddn.inc に準拠
;
DRVIDNUM		equ			1001h
org	DRVTYPE	
				dtype		dw	TIMER_DEVICE
org	DRVID					;	'----･----+----･',--h
				did			db	'ITVALTIMER98   ',00h
org	DRVINIT
				dinit		dw	offset driver_init
org	DRVEND
				dend		dw	offset driver_end
org	DRVPLAY
				dplay		dw	NULL
org	DRVSTOP
				dstop		dw	NULL
org	DRVINT
				dint		dw	NULL
org	DRVCH
				dch			db	?
org	DRVUSECH
				dusech		db	?
org	DRVVERINT
				dverint		db	1
org	DRVVERREAL
				dverreal	db	10
org	DRVINSTMSG
				dw			offset dinstmsg
org	DRVUSEMSG
				dw			offset dusemsg
org	DRVFUNC
;----------------- controll ---------------- no ----- comment -----------------
				dw	offset NULL				; 0h	ECM機能
				dw	offset init_timer		; 1h	タイマー初期化
				dw	offset set_tempo		; 2h	テンポの設定
				dw	offset timer_start		; 3h	タイマー始動
				dw	offset timer_stop		; 4h	タイマー停止
				dw	offset set_timebase		; 5h	タイムベース設定
;------------------------------------------------------------------------------
.data
; ローカルスタックエリア
			even
local_sp_old	dw	?
local_ss_old	dw	?
local_stack_buf	dw	LOCAL_STACKSIZE dup(?)
local_stack		label	word

CPU8		equ		8
CPU10		equ		10

TIMER8		equ		4E00h/(TM_OPTIMIZE)		; 1msec 割り込み for  8MHz
TIMER10		equ		6000h/(TM_OPTIMIZE)		; 1msec 割り込み for 10MHz

CLOCK		db		?					; タイマー動作モード
			even
SPEED		dw		?					; 割り込み間隔( 0.1msec )
TEMPO		dw		?					; テンポ計算結果
TEMPO_CNT	dw		?					; テンポカウンター
TIMEBASE	dw		1					; タイムベース

			even
ddn_interrupt		label	dword		; 常時割り込みジャンプ先
ddn_interrupt_ofs	dw	?
ddn_interrupt_seg	dw	?

timer_vector		label	dword		; もとのタイマ割り込み
timer_ofs			dw		0
timer_seg			dw		0

timer_switch		db		0			; タイマー状態(ON/OFF)

			even
timer_reint			dw		FALSE		; タイマー割り込み再入チェック
timer_reint_all		dw		FALSE

dinstmsg	db	'[32mPC98[33m Interval timer driver [mversion 1.10',CR
			db	'copyright (c) 1993-94 ABA / T.Kobayashi and Interfair'
			db	' All Rights Reserved.',CR,'$'
dusemsg		db	'Interval Timer を使用して演奏します。$'


.code

;------------------------------------------------------------------------------
;ＤＯＳ割り込み時に表示するメッセージ
com_start	proc
			mov		ax,cs
			mov		ds,ax
			_puts	'Usage : mld.exe itvtimer.xdv'
			_exit	NULL
com_start	endp

;------------------------------------------------------------------------------
;タイマー割り込みPIC 操作(開始)
timer_on	proc
			pushf
			push	ax
			cli
			in		al,02h
			and		al,0feh
			out		02h,al
			out		5fh,al
			out		5fh,al
			out		5fh,al
			pop		ax
			popf
			ret
timer_on	endp

;------------------------------------------------------------------------------
;タイマー割り込みPIC 操作(禁止)
timer_off	proc
			pushf
			push	ax
			cli
			in		al,02h
			or		al,01h
			out		02h,al
			out		5fh,al
			out		5fh,al
			out		5fh,al
			pop		ax
			popf
			ret
timer_off	endp

;------------------------------------------------------------------------------
; EOI 発行
put_eoi		proc
			pushf
			push	ax
			cli
			mov		al,20h
			out		00h,al
			out		5fh,al
			out		5fh,al
			out		5fh,al
			pop		ax
			popf
			ret
put_eoi		endp

;------------------------------------------------------------------------------
;常駐時に実行するドライバー初期化
driver_init	proc	far
			pushf
			cli

			mov		ax,cs
			mov		ds,ax

			call	timer_off
			mov		ax,3508h
			int		21h
			mov		[timer_ofs],bx
			mov		[timer_seg],es

			push	ds
			xor		ax,ax
			mov		ds,ax
			test	ds:[0501h],byte ptr 80h
			pop		ds
			_put	'システムクロックを '
			jz		_5M
	_8M:
			mov		[CLOCK],CPU8
			mov		[SPEED],TIMER8
			mov		bl,8
			mov		ax,3002h
			int		50h
			jmp		di_exit
	_5M:
			mov		[CLOCK],CPU10
			mov		[SPEED],TIMER10
			mov		bl,10
			mov		ax,3002h
			int		50h
	di_exit:
			_puts	'MHz系で初期化しました。'
			mov		[TEMPO],10			;初期値
			mov		[TEMPO_CNT],10		;初期値
			push	ds
			xor		ax,ax
			mov		ds,ax
			mov		ds:[08h*4  ],offset interrupt_tmdev
			mov		ds:[08h*4+2],cs
			pop		ds
			mov		ax,1		; タイマーは１個ということで・・・
			popf
			ret
driver_init	endp

;------------------------------------------------------------------------------
;ドライバー解放終了初期化
driver_end	proc	far			; DDN 呼出なので FAR CALL
			pushf
			cli
			call	timer_off
			push	es
			push	bx
			xor		ax,ax
			mov		es,ax
			mov		ax,cs:[timer_ofs]
			mov		bx,cs:[timer_seg]
			or		ax,ax
			jz		de_not_vected
			mov		es:[08h*4  ],ax
			mov		es:[08h*4+2],bx
	de_not_vected:
			pop		bx
			pop		es
			popf
			ret
driver_end	endp

;------------------------------------------------------------------------------
; ITVTIMER専用 インターバルタイマー IOCS
set_timer	proc
			pushf
			push	ax
			push	cx
			cli
			mov		cx,cs:[SPEED]

			mov		al,36h
			out		77h,al
			out		5fh,al
			out		5fh,al

			mov		al,cl
			out		71h,al
			out		5fh,al
			out		5fh,al

			mov		al,ch
			out		71h,al
			out		5fh,al
			out		5fh,al

			pop		cx
			pop		ax
			popf
			ret
set_timer	endp
;------------------------------------------------------------------------------
;割り込み処理		たいまわりこみでここにくるのぉ。
interrupt_tmdev		proc
			call	put_eoi
			sub		cs:[TEMPO_CNT],1
			jnbe	it_next
			mov		cs:[TEMPO_CNT],0
	it_next:
			cmp		cs:[timer_reint_all],FALSE
			jz		it_start
			iret

	it_start:
			mov		cs:[timer_reint_all],TRUE
			_local_on
			sti
			cmp		cs:[TEMPO_CNT],0
			jnbe	it_ret2
			push	bx
			push	es
			mov		bx,cs:[TEMPO]
			mov		cs:[TEMPO_CNT],bx
			cmp		cs:[timer_switch],OFF
			jz		skip_call_ddn
			call	dword ptr cs:[ddn_interrupt]		; DDN を far call
	skip_call_ddn:
			pop		es
			pop		bx

	it_ret2:
			cli
			_local_off
			mov		cs:[timer_reint_all],FALSE
			iret
interrupt_tmdev		endp

;---------------------------- Timer Function  proc.(00) タイマー初期化
;	es:bx  = MFXDDN 割り込み先アドレス
;ret@ax
;	NULL	初期化完了
;	?		初期化できなかった
;
init_timer	proc	far
			mov		[ddn_interrupt_ofs],bx
			mov		[ddn_interrupt_seg],es
			mov		ax,NULL
			ret
init_timer	endp

;---------------------------- Timer Function  proc.(01) テンポ設定
;	bx     = テンポ(1..65535)
;
set_tempo	proc	far
			or		bx,bx
			jz		st_error		; 0 divチェック
			
			xor		dx,dx
			mov		ax,125*TM_OPTIMIZE
			div		bx
			cmp		dx,125*TM_OPTIMIZE/2
			cmc
			adc		ax,0
			xor		dx,dx
			mov		bx,[TIMEBASE]
			div		bx
			mov		[TEMPO],ax
	st_error:
			call	set_timer
			ret
set_tempo	endp

;---------------------------- Timer Function  proc.(02) タイマー始動
;
timer_start	proc	far
			push	es
			call	timer_off
			mov		bx,cs
			mov		es,bx
			mov		bx,offset interrupt_tmdev
			call	set_timer
			call	timer_on
			mov		[timer_switch],ON
			pop		es
			ret
timer_start	endp

;---------------------------- Timer Function  proc.(03) タイマー停止
;
timer_stop	proc	far
			call	timer_off
			mov		[timer_switch],OFF
			ret
timer_stop	endp

;---------------------------- Timer Function  proc.(04) タイムベース
;
set_timebase	proc	far
			push	cx
			push	dx

			cmp		bx,48
			jnb		stb_rec		; timebase が 48以下だったら 48にする(強制)
			mov		bx,48
	stb_rec:
			xor		dx,dx
			mov		ax,bx
			mov		cx,48
			div		cx
			mov		[TIMEBASE],ax
			
			pop		dx
			pop		cx
			call	set_timer
			ret
set_timebase	endp

			end		start

;
; Interval Time Base Count が 0.1msec のとき、
; テンポを S  タイムベースを B とすると、割り込み間隔T の次式が成立する。
;       60 * 1000 * 10     600000
; T =  �｢�｢�｢�｢�｢�｢�｢�｢ = �｢�｢�｢�｢
;           S * B           S * B
;
; B = 48 とすると、
;
;      12500
; T = �｢�｢�｢�｢
;        S
;
;
; Interval Time Base Count が 1msec のとき、
; テンポを S  タイムベースを B とすると、割り込み間隔T の次式が成立する。
;       60 * 1000       60000
; T =  �｢�｢�｢�｢�｢�｢ = �｢�｢�｢�｢
;         S * B         S * B
;
; B = 48 とすると、
;
;      1250
; T = �｢�｢�｢
;        S
;

; Version Revision_ Comment_____________________________________________________
	1.00B	1.1		とりあえず完成
	1.00B	1.2		TEANAN氏の指摘によるタイマ割り込みの遅さを解消
					まだ、完全になおってないけどね。
	1.00B	1.3		割り込みベクタを復帰してなかった〜!!
					テンポずれ発生中〜
	1.00B	1.4		ローカルスタックを積んだ。安定動作するようになった。
	1.01	1.4.1	実験版 再入チェックを厳しくする
			1.4.2	実験版 再入チェックを甘くする
			1.4.3	ローカルスタックを減らしてみる
	1.02	1.5		ちょっと整理したら、localstack減らしても安定動作するように
					なった。あうあう。
	1.10	1.6		うーむ、暴走するのは、うぇいと関係だったらしい。しくしく。
