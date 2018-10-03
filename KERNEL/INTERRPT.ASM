;/////////////////////////////////////////////////////////////////////////////;
;
;      Multi module music driver MFXDDN(tm) kernel system release 0.00 
;  MFXDDN(tm) Music driver For XMML , Deconcentrate Drivers Network System
;  copyright (c) 1993 ABA / T.Kobayashi and Interfair  All Rights Reserved.
;
;/////////////////////////////////////////////////////////////////////////////;
;
; 割り込み部
;
IF	PROGMODE		eq	COMTYPE
MFXDRVDDN_KERNEL	equ	TRUE
include		model.inc
include		stdio.inc
include		ddn.inc
include		timerdrv.inc
.code
ENDIF

firstclock	db		?

;-------- ドライバ呼出
;ah		ファンクションナンバー
;al		ドライバテーブルの番号
;
call_driver	proc
			push	ds
			push	es
			push	bx
			push	ax
			mov		bx,cs
			mov		ds,bx

			xor		bx,bx
			mov		bl,al
			shl		bx,1
			mov		bx,[module_drv + bx]
			or		bx,bx
			jz		cd_erout
	cd_call:
			mov		es,bx
			xor		bx,bx
			mov		bl,ah
			shl		bx,1
			mov		bx,es:[DRVFUNC + bx]
			or		bx,bx
			jz		cd_erout
			mov		[driver_call_ofs],bx
			mov		[driver_call_seg],es
			mov		bx,es
			mov		ds,bx				; ds を ドライバーの seg にしとく。

			pop		ax
			pop		bx
			pop		es
			push_all
			call	dword ptr cs:[driver_call]
			pop_all
			pop		ds
			ret

	cd_erout:
			pop		ax
			pop		bx
			pop		es
			pop		ds
			ret

			even
driver_call		label	dword
driver_call_ofs	dw		?
driver_call_seg	dw		?

call_driver	endp

;\@KILL LIGHT
;-------- 演奏前初期化／開始
;
start_playing	proc
			mov		ax,cs
			mov		ds,ax
			push	ds
			mov		es,ax
			mov		bx,offset interrupt_kernel
			init_timer
			timer_settempo	255					; とりあえず最初は tempo = 255
			mov		bx,[timebase]
			set_timebase
			pop		ds

	; 演奏前に各ドライバーを初期化する
			mov		cx,16
			mov		si,offset module_drv
			cld
	sp_nextentry:
			lodsw
			or		ax,ax
			jz		sp_skip
			mov		es,ax
			mov		ax,es:[DRVPLAY]
			or		ax,ax
			jz		sp_skip
			mov		[driver_call_ofs],ax
			mov		[driver_call_seg],es
			push	ds
			push	si
			push	cx
			pushf
			push	es
			pop		ds
			call	dword ptr cs:[driver_call]
			popf
			pop		cx
			pop		si
			pop		ds
	sp_skip:
			loop	sp_nextentry

	;演奏ワークエリア初期化(MIDI的な初期値で初期化します)
			mov		ax,cs
			mov		ds,ax

			mov		cx,MAXTRACK
			mov		si,offset track_buf
	init_trackbuf:
			cmp		[si].channel,255
			jz		init_trackbuf_ns1
			mov		[si].steptime	,02h	; 音色ECMは優先的に鳴らすので^^;
			jmp		init_trackbuf_ns2		; 普通の曲は我慢我慢。
	init_trackbuf_ns1:
			mov		[si].channel	,0		; 255 を 0に戻す
			mov		[si].steptime	,01h	; 普通の曲より1clock速い。
	init_trackbuf_ns2:
			mov		[si].note		,0
			mov		[si].velocity	,0
			mov		[si].program	,0
			mov		[si].volume		,100
			mov		[si].expression	,100
			mov		[si].modulation	,255
			mov		[si].panpot		,64
			mov		[si].bank		,0
			mov		[si].pkeypresser,0
			mov		[si].hold1		,FALSE
			mov		[si].poltament	,FALSE
			mov		[si].sustenuto	,FALSE
			mov		[si].soft		,FALSE
			mov		[si].poltctrl	,0
			mov		[si].ueff1sendlv,40
			mov		[si].ueff2sendlv,0
			mov		[si].ueff3sendlv,0
			mov		[si].chpresser	,0
			mov		[si].pitchbend	,0
			mov		[si].note_count	,0
			mov		[si].note_total ,0
			cmp		[si].note_seg,0
			jz		skip_init_notebuf
			push	cx
			mov		di,[si].note_ofs
			mov		es,[si].note_seg
			mov		cx,128/2
			cld
			xor		ax,ax
			rep		stosw
			pop		cx
	skip_init_notebuf:
			add		si,type DDN_CHBUF
			loop	init_trackbuf
	;リピートバッファ初期化
			mov		cx,MAXTRACK
			mov		si,offset repeat_buf
	init_repeatbuf:
			mov		[si].rep_level,0
			add		si,type DDN_REPBUF
			loop	init_repeatbuf
	
	;共有化バッファ初期化
			mov		cx,MAXTRACK
			mov		si,offset dec_buf
	init_decbuf:
			mov		[si].dec_flag,FALSE
			add		si,type DDN_DECOMPOSE
			loop	init_decbuf
	
	;一時停止フラグの初期化
			mov		[pause_flag],FALSE
	;マスターボリューム初期化
			mov		[mastervol],127
	;フェードアウトフラグ初期化
			mov		[fadeout_flag],FALSE
	;スキップフラグ初期化
			mov		[skip_flag],FALSE
			mov		[timerout_flag],FALSE

			mov		[firstclock],1
			timer_virtual_start
			call	far ptr interrupt_kernel
			timer_start
			ret
start_playing	endp

;-------- 演奏終了
;
stop_playing	proc
			mov		ax,cs
			mov		ds,ax
			push	es

	;スキップフラグ初期化
			mov		[skip_flag],FALSE

	;演奏ワークエリア終了初期化
			mov		cx,MAXTRACK
			mov		si,offset track_buf
	stop_trackbuf:
			mov		[si].use_flag	,FALSE
			cmp		[si].note_seg,0
			jz		skip_clearnotebuf
			push	di
			push	cx
			mov		di,[si].note_ofs
			mov		es,[si].note_seg
			mov		cx,128/2
			cld
			xor		ax,ax
			rep		stosw
			pop		cx
			pop		di
		skip_clearnotebuf:
			add		si,type DDN_CHBUF
			loop	stop_trackbuf

	; 演奏後に各ドライバーを初期化する
			mov		ax,cs
			mov		ds,ax
			mov		cx,16
			mov		si,offset module_drv
			cld
	stp_nextentry:
			lodsw
			or		ax,ax
			jz		stp_skip
			mov		es,ax
			mov		ax,es:[DRVSTOP]
			or		ax,ax
			jz		stp_skip
			mov		[driver_call_ofs],ax
			mov		[driver_call_seg],es
			push	ds
			push	si
			push	cx
			pushf
			push	es
			pop		ds
			call	dword ptr cs:[driver_call]
			popf
			pop		cx
			pop		si
			pop		ds
	stp_skip:
			loop	stp_nextentry
			pop		es

			ret
stop_playing	endp

;-------- タイマー割り込み先の演奏メインプログラム
; タイマードライバーから、far call で呼ばれてくるので、ret far で
; もどるの。そしたら、タイマドライバーが、次期割り込みも設定してくれるのかも。
;
interrupt_kernel	proc	far
			push_all
			sti
			cld
			
	ik_skk:
			mov		ax,cs
			mov		ds,ax

			cmp		[timerout_flag],TRUE
			jz		interrupt_end

			add		word ptr [play_counter  ],1
			adc		word ptr [play_counter+2],0

;*** 1.fadeoutのチェック
			cmp		[fadeout_flag],FALSE	; フェードアウトしてるぅ？
			je		no_fadeout				; してね～よ。
			dec		[fadeout_active]
			jnz		no_fadeout				; カウンターもまだまだだ。
			mov		ax,[fadeout_static]
			mov		[fadeout_active],ax
			sub		[mastervol],FADEOUT_DELTA ; master volumeチェック
			jbe		fadeout_end
			mov		bh,byte ptr [mastervol]

			xor		bl,bl
			mov		cx,16
			mov		si,offset module_drv
	fik_nextmdl_entry:
			push	ds
			push	cx
			push	bx
			cld
			lodsw
			or		ax,ax
			jz		fik_nextmdl
			mov		es,ax
			cmp		es:[DRVTYPE],word ptr NORMAL_DEVICE
			jne		fik_nextmdl
			push	si
			push	cx
			mov		ah,21h
			mov		al,bl
			call	call_driver
			pop		cx
			pop		si
	fik_nextmdl:
			pop		bx
			pop		cx
			pop		ds
			inc		bl
			loop	fik_nextmdl_entry
			jmp		no_fadeout

	fadeout_end:					; フェードアウト終了！
			mov		[fadeout_flag],FALSE
			mov		ah,11h
			int		50h
			jmp		ik_exit

	no_fadeout:

;*** 2.演奏チェック
			mov		ax,cs
			mov		ds,ax
			mov		si,offset track_buf
			mov		[now_track],0
			mov		cx,MAXTRACK
	ik_nexttrk_entry:
			push	cx
			push	ds
			push	si
			cmp		[si].use_flag,FALSE
			jz		ik_nexttrk					; トラック使用してないよ。
			dec		[si].steptime
			jnz		ik_nexttrk					; steptime もオーバーしてないよ。

			mov		di,[si].mus_ofs
			mov		es,[si].mus_seg
			call	track_function
	ik_nexttrk:
			pop		si
			pop		ds
			pop		cx
			add		si,type DDN_CHBUF
			inc		[now_track]
			loop	ik_nexttrk_entry
			
			mov		cx,16
			mov		si,offset module_drv
	ik_nextmdl_entry:
			lodsw
			or		ax,ax
			jz		ik_nextmdl
			
			mov		es,ax
			mov		ax,es:[DRVINT]
			or		ax,ax
			jz		ik_nextmdl
			mov		[driver_call_ofs],ax
			mov		[driver_call_seg],es
			push	si
			push	cx
			push	ds
			
			push	es
			pop		ds
			call	dword ptr cs:[driver_call]
			
			pop		ds
			pop		cx
			pop		si
	ik_nextmdl:
			loop	ik_nextmdl_entry
	ik_exit:
			cmp		[skip_flag],TRUE
			jz		ik_skk
	interrupt_end:
;			mov		[firstclock],0
			pop_all
			ret
interrupt_kernel	endp
;\@END LIGHT

;\@KILL
			end
;\@END
