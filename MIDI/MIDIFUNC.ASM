;==============================================================================
; MFXDDN sound driver module
;						MIDI Interface driver for 98
;  copyright (c) 1993 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; ファンクション部分
;

;※
; このプログラムは全て XMML rel3.00 仕様の通常音源デバイスモジュール規格に
; 準じています。
; XMML rel.3.00 copyright (c) ABA / T.Kobayashi and Interfair 
;													all rights reserved
;※
			jumps
			.186
			.model	tiny
			.code

include		stdio.inc
include		ddn.inc
include		midi.inc
include		miditerm.inc

extrn		MODULE:word
extrn		progchg:word
extrn		volume_buf:word
extrn		mastervol_buf:word

_ms			macro	data
			mov		al,data
			call	midi_out
			endm


;---------------------------- ddn func proc.(00) 音源初期化
;ret@ax
;	NULL	初期化完了
;
midi_init_midimodule	proc	far
			public	midi_init_midimodule
			xor		ax,ax
			ret
midi_init_midimodule	endp

;---------------------------- ddn func proc.(01) ノートオフ
;	ch		MIDIチャンネル
;	bh		ノートナンバー
;	bl		ベロシティー
;
midi_note_off	proc	far
			public	midi_note_off
			cmp		ch,09h
			jnz		mnof_main
			cmp		[progchg],TRUE
			jz		mnof_main
			ret
	mnof_main:
			or		ch,80h
			_ms		ch
			_ms		bh
			_ms		bl
			ret
midi_note_off	endp

;---------------------------- ddn func proc.(02) ノートオン
;	ch		MIDIチャンネル
;	bh		ノートナンバー
;	bl		ベロシティー
;
midi_note_on	proc	far
			public	midi_note_on
			cmp		ch,09h
			jnz		mnon_main
			cmp		[progchg],TRUE
			jz		mnon_main
			ret
	mnon_main:
			or		ch,90h
			_ms		ch
			_ms		bh
			_ms		bl
			ret
midi_note_on	endp

;---------------------------- ddn func proc.(03) ポリフォニックキープレッシャー
;	ch		MIDIチャンネル
;	bh		ノートナンバー
;	bl		プレッシャー値
;
midi_poly_keypress	proc	far
			public	midi_poly_keypress
			or		ch,0a0h
			_ms		ch
			_ms		bh
			_ms		bl
			ret
midi_poly_keypress	endp

;---------------------------- ddn func proc.(04) バンクセレクト
;	ch		MIDIチャンネル
;	bx		バンクナンバー
;
midi_bank_select	proc	far
			public	midi_bank_select
			or		ch,0b0h
			_ms		ch
			_ms		00h
			_ms		bh
			_ms		ch
			_ms		20h
			_ms		bl
			ret
midi_bank_select	endp

;---------------------------- ddn func proc.(05) モジュレーション
;	ch		MIDIチャンネル
;	bh		モジュレーションデプス
;
midi_modulation	proc	far
			public	midi_modulation
			cmp		[progchg],TRUE
			jz		mmod_main
			ret
	mmod_main:
			or		ch,0b0h
			_ms		ch
			_ms		01h
			_ms		bh
			ret
midi_modulation	endp

;---------------------------- ddn func proc.(06) ポルタメントタイム
;	ch		MIDIチャンネル
;	bh		ポルタメントタイム
;
midi_pol_time	proc	far
			public	midi_pol_time
			or		ch,0b0h
			_ms		ch
			_ms		05h
			_ms		bh
			ret
midi_pol_time	endp

;---------------------------- ddn func proc.(07) データエントリー
;	ch		MIDIチャンネル
;	bx		RPN/NRPNのパラメータに対する値
;
midi_data_entry	proc	far
			public	midi_data_entry
			cmp		[progchg],TRUE
			jz		mdatae_main
			ret
	mdatae_main:

			or		ch,0b0h
			_ms		ch
			or		bh,bh
			jnz		midi_entry_ll
	midi_entry_mm:
			_ms		06h
			_ms		bl
			ret
	midi_entry_ll:
			_ms		26h
			_ms		bl
			ret
midi_data_entry	endp

;---------------------------- ddn func proc.(08) ボリューム
;	ch		MIDIチャンネル
;	bh		ボリューム
;
midi_volume		proc	far
			public	midi_volume
			push	bx
			push	cx
			mov		al,bh
			xor		ah,ah
			mov		bl,ch
			xor		bh,bh
			shl		bx,1
			mov		[bx+volume_buf],ax
			pop		cx
			pop		bx

;			cmp		[MODULE],GS_MODULE
;			jz		gs_midivol
;			mov		ax,[mastervol_buf]
;			mul		bh
;			shr		ax,7
;			mov		bh,al

	gs_midivol:
			or		ch,0b0h
			_ms		ch
			_ms		07h
			_ms		bh
			ret
midi_volume	endp

;---------------------------- ddn func proc.(09) パンポット
;	ch		MIDIチャンネル
;	bh		パンポット
;
midi_panpot		proc	far
			public	midi_panpot
			or		ch,0b0h
			_ms		ch
			_ms		0ah
			_ms		bh
			ret
midi_panpot		endp

;---------------------------- ddn func proc.(0a) エクスプレッション
;	ch		MIDIチャンネル
;	bh		エクスプレッション
;
midi_expression	proc	far
			public	midi_expression
			or		ch,0b0h
			_ms		ch
			_ms		0bh
			_ms		bh
			ret
midi_expression	endp

;---------------------------- ddn func proc.(0b) ホールド１
;	ch		MIDIチャンネル
;	bh		ホールドコントロール値
;
midi_hold1		proc	far
			public	midi_hold1
			or		ch,0b0h
			_ms		ch
			_ms		40h
			_ms		bh
			ret
midi_hold1		endp

;---------------------------- ddn func proc.(0c) ポルタメント
;	ch		MIDIチャンネル
;	bh		ポルタメントコントロール値
;
midi_poltament	proc	far
			public	midi_poltament
			cmp		[progchg],TRUE
			jz		mpolt_main
			ret
	mpolt_main:
	
			or		ch,0b0h
			_ms		ch
			_ms		41h
			_ms		bh
			ret
midi_poltament	endp

;---------------------------- ddn func proc.(0d) ソステヌート
;	ch		MIDIチャンネル
;	bh		ソステヌートコントロール値
;
midi_sostenuto	proc	far
			public	midi_sostenuto
			or		ch,0b0h
			_ms		ch
			_ms		42h
			_ms		bh
			ret
midi_sostenuto	endp

;---------------------------- ddn func proc.(0e) ソフト
;	ch		MIDIチャンネル
;	bh		ソフトコントロール値
;
midi_soft		proc	far
			public	midi_soft
			or		ch,0b0h
			_ms		ch
			_ms		43h
			_ms		bh
			ret
midi_soft		endp

;---------------------------- ddn func proc.(0f) ポルタメントコントロール
;	ch		MIDIチャンネル
;	bh		ソースノートナンバー
;
midi_pol_ctrl	proc	far
			public	midi_pol_ctrl
			or		ch,0b0h
			_ms		ch
			_ms		54h
			_ms		bh
			ret
midi_pol_ctrl	endp

;---------------------------- ddn func proc.(10) 汎用effect1(ﾘﾊﾞｰﾌﾞｾﾝﾄﾞﾚﾍﾞﾙ)
;	ch		MIDIチャンネル
;	bh		コントロール値
;
midi_effect1		proc	far
			public	midi_effect1
			or		ch,0b0h
			_ms		ch
			_ms		5bh
			_ms		bh
			ret
midi_effect1		endp

;---------------------------- ddn func proc.(11) 汎用effect3(ｺｰﾗｽｾﾝﾄﾞﾚﾍﾞﾙ)
;	ch		MIDIチャンネル
;	bh		コントロール値
;
midi_effect3		proc	far
			public	midi_effect3
			or		ch,0b0h
			_ms		ch
			_ms		5dh
			_ms		bh
			ret
midi_effect3		endp

;---------------------------- ddn func proc.(12) NRPN
;	ch		MIDIチャンネル
;	bh		mm,ll選択 0:mm 1:ll
;	bl		データ
midi_nrpn		proc	far
			public	midi_nrpn
			or		ch,0b0h
			mov		cl,63h
			sub		cl,bh
			_ms		ch
			_ms		cl
			_ms		bl
			ret
midi_nrpn		endp

;---------------------------- ddn func proc.(13) RPN
;	ch		MIDIチャンネル
;	bh		mm,ll選択 0:mm 1:ll
;	bl		データ
midi_rpn			proc	far
			public	midi_rpn
			or		ch,0b0h
			mov		cl,65h
			sub		cl,bh
			_ms		ch
			_ms		cl
			_ms		bl
			ret
midi_rpn			endp

;---------------------------- ddn func proc.(14) プログラムチェンジ
;	ch		MIDIチャンネル
;	bh		音色番号
;
midi_prog_chg	proc	far
			public	midi_prog_chg
			cmp		[progchg],FALSE
			jz		mpc_exit
			or		ch,0c0h
			_ms		ch
			_ms		bh
	mpc_exit:
			ret
midi_prog_chg	endp

;---------------------------- ddn func proc.(15) チャンネルプレッシャー
;	ch		MIDIチャンネル
;	bh		チャンネルプレッシャー値
;
midi_ch_presser	proc	far
			public	midi_ch_presser
			or		ch,0d0h
			_ms		ch
			_ms		bh
			ret
midi_ch_presser	endp

;---------------------------- ddn func proc.(16) ピッチベンドレンジ
;	ch		MIDIチャンネル
;	bx		ピッチベンド値
;
midi_pitchbend	proc	far
			public	midi_pitchbend
			add		bx,8192		; 補正^^;;
			shl		bl,1		; 1個あげる + cy=?
			rcl		bh,1		; cy を 繰り上げ
			shr		bl,1		; 1個あげたのを戻す

			or		ch,0e0h
			_ms		ch
			_ms		bl
			_ms		bh
			ret
midi_pitchbend	endp

;---------------------------- ddn func proc.(17) オールサウンドオフ
;	ch		MIDIチャンネル
;
midi_all_soundoff	proc	far
			public	midi_all_soundoff
			or		ch,0b0h
			_ms		ch
			_ms		78h
			_ms		00h
			ret
midi_all_soundoff	endp

;---------------------------- ddn func proc.(18) オールリセットコントローラー
;	ch		MIDIチャンネル
;
midi_all_resetctrler	proc	far
			public	midi_all_resetctrler
			or		ch,0b0h
			_ms		ch
			_ms		79h
			_ms		00h
			ret
midi_all_resetctrler	endp

;---------------------------- ddn func proc.(19) オールノートオフ
;	ch		MIDIチャンネル
;
midi_all_noteoff	proc	far
			public	midi_all_noteoff
			or		ch,0b0h
			_ms		ch
			_ms		7bh
			_ms		00h
			ret
midi_all_noteoff	endp

;---------------------------- ddn func proc.(1a) OMNI OFF
;	ch		MIDIチャンネル
;
midi_omni_off	proc	far
			public	midi_omni_off
			or		ch,0b0h
			_ms		ch
			_ms		7ch
			_ms		00h
			ret
midi_omni_off	endp

;---------------------------- ddn func proc.(1b) OMNI ON
;	ch		MIDIチャンネル
;
midi_omni_on		proc	far
			public	midi_omni_on
			or		ch,0b0h
			_ms		ch
			_ms		7dh
			_ms		00h
			ret
midi_omni_on		endp

;---------------------------- ddn func proc.(1c) MONO
;	ch		MIDIチャンネル
;	bh		MONO数
;
midi_mono		proc	far
			public	midi_mono
			or		ch,0b0h
			_ms		ch
			_ms		7eh
			_ms		bh
			ret
midi_mono		endp

;---------------------------- ddn func proc.(1d) POLY
;	ch		MIDIチャンネル
;
midi_poly		proc	far
			public	midi_poly
			or		ch,0b0h
			_ms		ch
			_ms		7fh
			_ms		00h
			ret
midi_poly		endp

;---------------------------- ddn func proc.(1e) アクティブセンシング
;
midi_active_sence	proc	far
			public	midi_active_sence
			_ms		0feh
			ret
midi_active_sence	endp

;---------------------------- ddn func proc.(1f) エクスクルーシブメッセージ
;	es:bx	エクスクルーシブデータ列
;	cx		長さ
;
midi_exclusive	proc	far
			public	midi_exclusive
			push	ds
			push	si
			mov		si,bx
			mov		bx,es
			mov		ds,bx
			cld
			_ms		0f0h
	exclusive_next:
			push	cx
			lodsb
			call	midi_out
			pop		cx
			loop	exclusive_next
			_ms		0f7h
			pop		si
			pop		ds
			ret
midi_exclusive	endp

;---------------------------- ddn func proc.(20) ビブラート設定
;	cx		音色番号
;	bh		ビブラートレート
;	bl		ビブラートデプス
;	dh		ビブラートディレイ
;
midi_vibrato		proc	far
			public	midi_vibrato
			ret
midi_vibrato		endp

;---------------------------- ddn func proc.(21) マスターボリューム
;	bh		マスターボリューム値
;
midi_master_volume	proc	far
			public	midi_master_volume
			xor		ax,ax
			mov		al,bh
			inc		ax
			mov		[mastervol_buf],ax
			
			cmp		[MODULE],GS_MODULE
			jnz		gm
;----- GS音源 mastervolueme
	gs:
			push	bx
			_ms		0f0h
			_ms		41h
			_ms		10h
			_ms		42h
			_ms		12h
			_ms		40h
			_ms		00h
			_ms		04h
			pop		bx
			push	bx
			_ms		bh
	;check sum計算
	sum_ex:
			pop		bx
			mov		bl,bh
			xor		bh,bh
			add		bx,40h+00h+04h
			and		bx,127
			mov		ax,128
			sub		ax,bx
	ret:
			_ms		al
			_ms		0f7h
			ret

;----- GM音源 mastervolueme(擬似的にするのよぉ)
	gm:
			mov		si,offset volume_buf
			mov		cx,16
			xor		dh,dh
			cld
	gm_mastvol:
			lodsw
			mul		bh				; ax<- volume*bh
			shr		ax,7			; ax/128
			mov		dl,al
	
			mov		al,dh
			or		al,0b0h
			call	midi_out
			mov		al,07h
			call	midi_out
			mov		al,dl
			call	midi_out
			inc		dh
			loop	gm_mastvol

			ret
midi_master_volume	endp

			end

