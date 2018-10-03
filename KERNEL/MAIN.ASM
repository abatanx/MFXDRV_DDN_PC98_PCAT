comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN kernel
// copyright (c) 1993,94 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// カーネルメインプログラム
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
dtamsg		db	'MFXDRV/DDNらいと version ',ver,'L',0dh,0ah
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
		
module_drv		dw	16 dup(0)		; 音源デバイス登録テーブル(SEGMENT||NULL)
timer_drv		db	EOF				; ﾀｲﾏｰデバイス登録テーブル
;\@KILL LIGHT
timer_status	db	?				; ﾀｲﾏｰの状態
timebase		dw	?				; タイムベース
tempo			dw	?				; テンポ
now_track		dw	?				; 現在実行中のトラック
pause_flag		dw	?				; 一時停止フラグ
fadeout_static	dw	?				; フェードアウト固定値
fadeout_active	dw	?				; フェードアウトカウンタ
fadeout_flag	dw	?				; フェードアウトフラグ
mastervol		dw	?				; マスターボリューム
volume_factor	dw	100				; ボリュームファクター
play_counter	dd	?				; プレイカウンター
play_skip_flag	dw	?				; 早送りフラグ
play_skip_tempo	dw	?				; 早送りテンポ
skip_flag		dw	?				; スキップフラグ
timerout_flag	dw	?				; timeroutフラグ(強制的に演奏止める)
even
track_buf	DDN_CHBUF	MAXTRACK dup(?)		; 演奏バッファ
even
repeat_buf	DDN_REPBUF	MAXTRACK dup(?)		; リピートバッファ
dec_buf		DDN_DECOMPOSE	MAXTRACK dup(?)	; 分散情報バッファ
;\@END LIGHT

even
ddnstay_flag	db		?
remove_flag		db		FALSE
infinity_play	db		FALSE

even
chainid		db		'DBUFchain',NULL	; チェインテーブル
chainadr	dw		50 dup(0)			; チェインアドレス
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
;XMML3.00 API処理先テーブル----------------------------------------------------
int_table:
;----------------- controll ---------------- no ----- comment -----------------
		dw	offset int50_rec_driver			; 0h	ドライバー登録
		dw	offset int50_rel_driver			; 1h	ドライバー解放
		dw	offset int50_init_driver		; 2h	ドライバー初期化
		dw	offset int50_get_driver_id		; 3h	ドライバーID取得
		dw	offset int50_get_driver_status	; 4h	ドライバーステータス取得
		dw	offset int50_get_driver_table	; 5h	ドライバーテーブル番号取得
		dw	offset int50_get_track_value	; 6h	トラックワークエリアの取得
		dw	offset int50_get_driver_type	; 7h	ドライバータイプ取得
		dw	offset int50_not_defined		; 8h	リザーブ
		dw	offset int50_not_defined		; 9h	リザーブ
		dw	offset int50_get_play_status	; ah	演奏状態の取得
		dw	offset int50_get_play_counter1	; bh	演奏カウンタ読み出し
		dw	offset int50_get_play_counter2	; ch	演奏カウンタ読み出し(192)
		dw	offset int50_not_defined		; dh	リザーブ
		dw	offset int50_not_defined		; eh	リザーブ
		dw	offset int50_not_defined		; fh	リザーブ
		dw	offset int50_play_music			;10h	演奏開始
		dw	offset int50_stop_music			;11h	演奏終了
		dw	offset int50_pause_music		;12h	演奏一時停止
		dw	offset int50_continue_music		;13h	演奏再開
		dw	offset int50_fadeout			;14h	フェードアウト
		dw	offset int50_play_skip_start	;15h	早送り開始
		dw	offset int50_play_skip_end		;16h	早送り終了
		dw	offset int50_init_dcm			;17h	Init DriverDirectControll
		dw	offset int50_dcm				;18h	DriverDirectControll
		dw	offset int50_end_dcm			;19h	End DriverDirectControll
		dw	offset int50_set_notebuf		;1ah	ノートバッファ設定
		dw	offset int50_rel_notebuf		;1bh	ノートバッファ解除
		dw	offset int50_replay_music		;1ch	はじめから開始
		dw	offset int50_not_defined		;1dh	リザーブ
		dw	offset int50_not_defined		;1eh	リザーブ
		dw	offset int50_not_defined		;1fh	リザーブ
		dw	offset int50_play_se			;20h	効果音開始
		dw	offset int50_not_defined		;21h	リザーブ
		dw	offset int50_not_defined		;22h	リザーブ
		dw	offset int50_not_defined		;23h	リザーブ
		dw	offset int50_not_defined		;24h	リザーブ
		dw	offset int50_not_defined		;25h	リザーブ
		dw	offset int50_not_defined		;26h	リザーブ
		dw	offset int50_not_defined		;27h	リザーブ
		dw	offset int50_not_defined		;28h	リザーブ
		dw	offset int50_not_defined		;29h	リザーブ
		dw	offset int50_not_defined		;2ah	リザーブ
		dw	offset int50_not_defined		;2bh	リザーブ
		dw	offset int50_not_defined		;2ch	リザーブ
		dw	offset int50_not_defined		;2dh	リザーブ
		dw	offset int50_not_defined		;2eh	リザーブ
		dw	offset int50_not_defined		;2fh	リザーブ
		dw	offset int50_putdec_8reg		;30h	8 bit reg. 10進数表示
		dw	offset int50_puthex_8reg		;31h	8 bit reg. 16進数表示
		dw	offset int50_putbin_8reg		;32h	8 bit reg.  2進数表示
		dw	offset int50_putdec_16reg		;33h	16bit reg. 10進数表示
		dw	offset int50_puthex_16reg		;34h	16bit reg. 16進数表示
		dw	offset int50_putbin_16reg		;35h	16bit reg.  2進数表示
		dw	offset int50_get_chainadr		;36h	chain table adr.の取得
		dw	offset int50_add_chain			;37h	chain table に追加
		dw	offset int50_del_chain			;38h	chain table の削除
;------------------------------------------------------------------------------
;----------------------------------------------- int 50h 制御ターミナル -------
; MFXDDN XMML3.00-API
;------------------------------------------------------------------------------

		even
int50_trap	proc	near						; 常駐チェックID
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


;-------- ドライバー ID に対応するテーブル番号を返す
; es:bx = ドライバーIDの文字列
;
;ret:
;ax
;	EOF		ドライバーがない
;	n>=0	ドライバーテーブルno
;es
;			ドライバーのアドレス
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
		jmp		gdt_error_out		;登録してな～い！！
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
; DDN-API処理
;
;---------------------------- int 50h proc. 未登録ファンクション
int50_not_defined	proc
		ret
int50_not_defined	endp

;---------------------------- int 50h proc.(00) ドライバー登録
;	ah     = 0
;	es     = ドライバーのセグメント
;	int 50h
;ret
;	n>0		使用可能チャンネル
;	EOF		デーブルがいっぱい
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

;---------------------------- int 50h proc.(01) ドライバー解放
;	ah     = 1
;	es:bx  = ドライバーIDの文字列
;	int 50h
;ret
;	NULL	解放できた
;	EOF		解放できない、またはドライバーがない
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

;---------------------------- int 50h proc.(02) ドライバー(音源)初期化
;	ah     = 2
;	es:bx  = ドライバーIDの文字列
;	int 50h
;ret
;	NULL	初期化できた
;	EOF		初期化できない、またはドライバーがない
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

;---------------------------- int 50h proc.(03) ドライバー名取得
;	ah     = 3
;	al     = テーブルナンバー
;	int 50h
;
;ret@es:bx
;	ドライバーの名前の入ったアドレス
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

;---------------------------- int 50h proc.(04) ドライバーステータスの取得
;	ah     = 4
;	es:bx  = ドライバーIDの文字列
;	int 50h
;ret@ah
;	n>=0	使用可能なチャンネル数
;	EOF		指定のドライバーが組み込まれていない
;ret@al
;	使用しているチャンネル数
;ret@ch
;	バージョン小数点以上
;ret@cl
;	バージョン小数点未満
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

;---------------------------- int 50h proc.(05) ドライバー登録番号取得
;	ah     = 5
;	es:bx  = ドライバーIDの文字列
;	int 50h
;
;ret@ax
;	EOF		登録されていない
;	?		テーブルナンバー
;
int50_get_driver_table	proc
		call	get_driver_table
		mov		[ax_entry],ax
		mov		[es_entry],es
		ret
int50_get_driver_table	endp

;---------------------------- int 50h proc.(06) トラックワークエリアの取得
;	ah     = 6
;	bh     = トラック番号
;	bl     = ワーク番号
;	int 50h
;
;ret@ax
;			ワークの内容
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

;---------------------------- int 50h proc.(07) ドライバータイプ取得
;	ah     = 7
;	es:bx  = ドライバーIDの文字列
;	int 50h
;
;ret@ax
;	EOF		登録されていない
;	?		ドライバータイプ
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

;---------------------------- int 50g proc.(0a) 演奏状態の取得
;	ah     = 0ah
;	int 50h
;
;ret@ax		演奏状態
;ret@bx		タイムベース
;ret@cx		テンポ
;ret@dx		マスターボリューム
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

;---------------------------- int 50g proc.(0b) 演奏カウンター取得
;	ah     = 0bh
;	int 50h
;
;ret@dx:ax		現在のカウント値
int50_get_play_counter1	proc
;\@KILL LIGHT
		mov		ax,word ptr [play_counter]
		mov		dx,word ptr [play_counter+2]
		mov		[ax_entry],ax
		mov		[dx_entry],dx
;\@END LIGHT
		ret
int50_get_play_counter1	endp

;---------------------------- int 50g proc.(0c) 演奏小節取得
;	ah     = 0ch
;	int 50h
;
;ret@dx:ax		現在演奏中の小節
;ret@bx			現在演奏中の小節のカウンター
int50_get_play_counter2	proc
;\@KILL LIGHT
		mov		bx,[timebase]
		shl		bx,2
		or		bx,bx
		jz		i5_gpc2_errorout		; div zero ちぇっく
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

;---------------------------- int 50h proc.(1c) 演奏開始
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

;---------------------------- int 50h proc.(10) 演奏開始
;	ah     = 10h
;	es:bx  = 演奏テーブルアドレス
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
		int		50h						; 演奏終了

		mov		[pause_flag]    ,FALSE	; 一時停止不可！！
		mov		[fadeout_flag]  ,FALSE	; フェードアウト不可！！
		mov		[play_skip_flag],FALSE	; 早送り不可！！
		mov		[timerout_flag] ,TRUE	; 演奏強制停止!!

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
	;Trackバッファの初期化
		mov		cx,MAXTRACK			;全32トラック
		mov		si,offset track_buf
  init_trackbufs:
		mov		[si].use_flag , FALSE
		add		si,type DDN_CHBUF
		loop	init_trackbufs
		
		pop		bx
		pop		es

; Music Information Header 解析開始
		mov		si,offset track_buf
		xor		cx,cx
		mov		cl,es:[bx]		;演奏トラック数
		or		cx,cx
		jnz		init_trackbuf_ok
		mov		[ax_entry],EOF	;演奏可能な指定トラック数が0だったのでEOF
		ret
		
  init_trackbuf_ok:
		inc		bx
		mov		ax,es:[bx]		;タイムベース
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
		mov		ah,04h					; 使用可能なチャンネルチェック
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
		jz		itu_sound_true		; 音色データは優先だぞう(笑)
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

check_timerdrv	proc		; タイマードライバーのチェック／初期化
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
		mov		bx,NULL				;タイマーデバイス存在を確認!！!！!！
	next_timerdrv_entry:
		loop	next_timerdrv_entry_jpt

		mov		ax,bx
		pop		es
		pop		si
		pop		bx
		ret
check_timerdrv	endp

check_sounddrv	proc		; サウンドドライバーのチェック
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
		mov		bx,NULL				;タイマーデバイス存在を確認!！!！!！
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

;---------------------------- int 50h proc.(11) 演奏終了
;	ah     = 11h
;	int 50h
;
int50_stop_music	proc
;\@KILL LIGHT
		mov		[pause_flag]  ,FALSE		; ポーズもないよん
		mov		[fadeout_flag],FALSE		; フェードアウト終了してね
		mov		[timerout_flag],TRUE		; 演奏強制停止
		timer_stop
		call	stop_playing
;\@END LIGHT
		ret
int50_stop_music	endp

;---------------------------- int 50h proc.(12) 演奏一時停止
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

;---------------------------- int 50h proc.(13) 演奏再開
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

;---------------------------- int 50h proc.(14) フェードアウト
;	ah     = 14h
;	bx     = スピード
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

;---------------------------- int 50h proc.(15) 早送り開始
;	ah     = 15h
;	bx     = テンポ
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

;---------------------------- int 50h proc.(16) 早送り終了
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

;---------------------------- int 50h proc.(17) dcm初期化
;	ah     = 17h
;	dl     = 使用したいドライバテーブル番号
;	int 50h
;
int50_init_dcm	proc				;内部処理はDRV_PLAYを実行するだけ。
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
;	al     = コントロール番号
;	dl     = 使用したいドライバテーブル番号
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

;---------------------------- int 50h proc.(19) dcm終了
;	ah     = 19h
;	dl     = 使用したいドライバテーブル番号
;	int 50h
;
int50_end_dcm	proc				;内部処理はDRV_STOPを実行するだけ。
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

;---------------------------- int 50h proc.(1a) ノートバッファ設定
;	ah     = 1ah
;	al     = 設定したいトラック
;   es:bx  = バッファのアドレス
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

;---------------------------- int 50h proc.(1b) ノートバッファ解除
;	ah     = 1bh
;	al     = 解除したいトラック
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

;---------------------------- int 50h proc.(20) 効果音開始
;	ah     = 20h
;	es:bx  = 効果音演奏データ
;	al     = 占有するトラック番号
;	ch     = ドライバチャンネル
;	cl     = ドライバテーブル番号
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
		mov		[bx].use_flag , FALSE			; トラック無効化
		mov		[bx].driver_no, cl				; ドライバー番号
		mov		[bx].channel  , ch				; ドライバーチャンネル
		pop		ax
		mov		[bx].mus_ofs  , ax				; 演奏データoffset
		mov		[bx].mus_seg  , es				; 演奏データsegment
		mov		[bx].steptime , 1				; step time
		mov		[bx].use_flag , TRUE			; トラック有効化
;\@END LIGHT
		ret
int50_play_se	endp

;---------------------------- int 50h proc.(30) 8 bit reg.10進数表示
;	ah     = 30h
;	al     = 表示方法		1:右詰め	2:左詰め
;	bl     = 数値
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

;---------------------------- int 50h proc.(31) 8 bit reg.16進数表示
;	ah     = 31h
;	bl     = 数値
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

;---------------------------- int 50h proc.(32) 8 bit reg. 2進数表示
;	ah     = 32h
;	bl     = 数値
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

;---------------------------- int 50h proc.(33) 16 bit reg.10進数表示
;	ah     = 33h
;	al     = 表示方法		1:右詰め	2:左詰め
;	bx     = 数値
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

;---------------------------- int 50h proc.(34) 16 bit reg.16進数表示
;	ah     = 34h
;	bx     = 数値
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

;---------------------------- int 50h proc.(35) 16 bit reg. 2進数表示
;	ah     = 35h
;	bl     = 数値
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

;---------------------------- int 50h proc.(36) chain table adr.の取得
;	ah     = 36h
;	int 50h
;
int50_get_chainadr	proc
		mov		[bx_entry],offset chainid
		mov		[es_entry],cs
		ret
int50_get_chainadr	endp

;---------------------------- int 50h proc.(37) chain table に追加
;	ah     = 37h
;	es     = 追加アドレス(seg)
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

;---------------------------- int 50h proc.(38) chain table 　の削除
;	ah     = 38h
;	es     = 削除アドレス
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
;  DOS 実行エントリー		kernel 常駐/解放処理
;LIB化してるときは
;  dx	; 'In'	常駐
;		; 'Re'	解放
;
com_start	proc
		mov		ax,cs
		mov		ds,ax
		mov		es,ax

IF	PROGMODE	eq	LIBTYPE
		cmp		dx,'In'		; 常駐
		jz		Lib_install
		cmp		dx,'Re'		; 解放
		jz		Lib_remove
		mov		ax,EOF		; エラあ
		ret
	Lib_install:
		mov		[remove_flag],FALSE
		jmp		Lib_next
	Lib_remove:
		mov		[remove_flag],TRUE
	Lib_next:
ENDIF

;オプション解析--------
IF	PROGMODE	eq	COMTYPE	;---- COM形式の時...
		_print	tit

option_check:
		mov		si,81h
		cld
	option_check_next:
		lodsb
		cmp		al,0dh
		jz		option_end			; オプション終了
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
		int		21h					; 異常終了

	option_start:
		lodsb
		cmp		al,'r'				; 常駐解除
		jz		remove_on
		cmp		al,'R'
		jz		remove_on
		cmp		al,'v'				; 音量調整
		jz		volume_ctrl
		cmp		al,'V'
		jz		volume_ctrl
		jmp		option_error

;/r オプション
	remove_on:
		mov		[remove_flag],TRUE
		jmp		option_check_next

;/v オプション
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
		_put	'音量を通常出力の '
		mov		ax,bx
		mov		bl,1
		pushf
		push	si
		push	ds
		call	putdec_16reg
		pop		ds
		pop		si
		popf
		_puts	'(%)に設定しました.'
		dec		si
		jmp		option_check_next

	option_end:
ENDIF
;常駐チェック ---
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
		mov		[ddnstay_flag],FALSE			; DDN常駐してる
		jmp		main_start
	stay_ddn:
		mov		[ddnstay_flag],TRUE				; DDN常駐してない

;常駐と解放・・・どっちなの?
main_start:
		cmp		[remove_flag],TRUE
		jz		remove

;常駐
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
		_puts	'int 50H を MFXDDN-API3.00用として使用します。'
		_puts	'MFXDRV/DDN を常駐しました。'

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

;解放
remove:
		cmp		[ddnstay_flag],TRUE
		jz		remove_main
IF	PROGMODE	eq	COMTYPE
		_puts	'常駐していません。'
		mov		ax,4c00h
		int		21h
ELSE
		mov		ax,EOF
		ret
ENDIF
	remove_main:
		mov		ah,11h			; 演奏終了
		int		50h

		mov		ax,3550h
		int		21h
		push	es
		
;=== チェインメモリー解放
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
		_put	'MEMORYの解放ができませんでした(segment '
		mov		bx,es
		call	int50_puthex_16reg
		_puts	'H)'
		pop		ds
ENDIF
		jmp		freecmem

;=== ドライバ解放時初期化呼び出し
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
		_puts	'を解除します。'
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
		_put	'以上、XDV ドライバーを '
		mov		bx,bp
		mov		ax,3001h
		int		50h
		_puts	'個 常駐解除しました。'
ENDIF

	skip_freemsg:
		pop		es
		push	es
		
;=== 環境領域解放
IF	PROGMODE	eq	COMTYPE
		mov		es,es:[002ch]
		mov		ax,4900h
		int		21h
ENDIF
		pop		es

;=== 割り込みベクタ復帰
		mov		dx,es:[int50_ofs]
		mov		ds,es:[int50_seg]
		mov		ax,2550h
		int		21h

;=== プロセスメモリ解放
IF	PROGMODE	eq	COMTYPE
		mov		ax,4900h
		int		21h
		mov		ax,cs
		mov		ds,ax
		_puts	'MFXDRV/DDN を解放しました。'
		_exit	0
ELSE
		ret
ENDIF

IF	PROGMODE	eq	COMTYPE
; オプションを表示
put_usage:
		_print	usage_data
		ret
; デバイスの表示
put_device:
		call	put_crlf
		_put	'  --- MFXDRV/DDN 外部ドライバ状況 --- XMML3.00 rel.'
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
		_put	'・'
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
		_put	' 以上 '
		mov		ax,3001h
		int		50h
		_puts	'個の機能が使用可能です。'
		ret
	
	pd_none_driver:
		_puts	' なにも組み込まれていません。'
		ret

ENDIF

com_start	endp

; 改行！！
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

;--------- フルカーネル
;\@KILL LIGHT
IF	PROGMODE	eq	COMTYPE
.data
tit			db	'Multi module music driver MFXDRV/DDN kernel version ',ver,CR
			db	'copyright (c) 1993-95 by ABA / T.Kobayashi and Interfair All Rights Reserved.',CR,EOL
usage_data	db	'usage  ; ',CR
			db	'         mfxddn [/|-(option)]....',CR
			db	'option ; ',CR
			db	'         /r     常駐解除',CR,'$'
tracks		db	'全',MAXTRACK/10+'0',MAXTRACK mod 10+'0','トラックを制御可能です。',CR,'$'
ENDIF
;\@END LIGHT

;--------- ライトカーネル
;\@KILL LIGHT
comment^
;\@END LIGHT
.data
tit			db	'Multi module sound driver MFXDRV/DDN kernel(light) version ',ver,'L',CR
			db	'copyright (c) 1995 by ABA / T.Kobayashi and Interfair All Rights Reserved.',CR,EOL
usage_data	db	'usage  ; ',CR
			db	'         mfxddnl [/|-(option)]....',CR
			db	'option ; ',CR
			db	'         /vX    ボリューム調整(X=0～200(%):Def /v100)
			db	'         /r     常駐解除',CR,'$'
tracks		db	'外部ドライバを 16種類 制御可能です。',CR,'$'
;^

;\@KILL
		end		_mfxddn_kernel_program
;\@END

; Version Revision_ Comment_____________________________________________________
;	0.01B	1.1		とりあえず完成。
;	0.60	1.2		安定動作するようになった。
;					バッファをきれいに初期化するようにした。
;					演奏カウンタファンクション追加。
;					実用できるよん。やっと(笑)。
;	0.70	1.3		チェインバッファシステムを採用した！
;	0.80	1.4		DCMファンクションを追加。ドライバ毎のlocalな制御ができる
;					よ(いわゆる効果音API??)。
;	0.82	1.5		DCMのBugfix。
;	0.82++	1.5.1	DCMのBugfix。
;	0.84++	1.5.2	sustenuto,tenuto,hold1,poltamentのBugfix。
;	0.85	1.6		Chg.ChannelのBIN仕様追加に伴う機能拡張(暫定版)
;	0.87	1.7		繰り返し抜けをサポートした。
;	0.90	1.8		FAR CALLのCHECKを厳しくした
;	0.95	1.9		TIMERDRVの仕様変更に伴うプログラム変更(昔のTIMERドライバ
;					は使用不可デー素)
;	0.99	1.10	ECM機能追加、すべてのXMMLformatを満たした
;	0.99A	1.11	ETCDRVのECM機能が使えない bugをfixした。
;	1.00	1.12	おー(ﾊﾟﾁﾊﾟﾁ) v(^^)
;	1.00	1.13	ソースをLIB対応にした～。おー(ﾊﾟﾁﾊﾟﾁ) v(^^)
;	1.02	1.14	じゃーん、音色用ECMに対処して便利になった。
;	1.10	1.15	bug修正,NOTEBUF機能を追加
;	1.12	1.16	繰り返し系のbug修正
;	1.14	1.17	マスターボリューム系のbug修正
;	1.15	1.18	スキップフラグ追加
;	1.16	1.19	ピッチベンドの0000-4000-7f7f から 通常の補数表現に変更。
;	1.17	1.19.1	最初の 1clock 目で、dos-functionが使用可能になった
;					もし、不都合がなければ、ver 1.20 に昇格～^^;
