;==============================================================================
; MFXDDN sound driver module
;						beep Interface driver for 98
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
include		beep.inc
include		beepfreq.inc

.data
beep_note	db		100h dup(0)		; ノート情報
even
xnote		dw		?
xnote_tmp	dw		?
beep_hz		dw		?
steps		db		0

single_note				dw		0	; ノート
single_mod_lev			dw		0	; Modulationレベル
single_mod_levdir		dw		1	; Modulationレベル方向、大きさ
single_mod_nowlev		dw		0	; 現在のModulationレベル
single_mod_nowlevdir	dw		0	; 現在のModulationレベルの方向
single_mod_sync			dw		10	; Modulation-Stating Sync
single_mod_nowsync		dw		0	; 現在のMod.-Stating Sync counter
single_mod_switch		dw	FALSE	; Modulaitonスイッチ

STEPS		=		2
.code

extrn		CPUCLOCK:word,single:word

;---------------------------- ノート情報の出力
note_out	proc
			public	note_out
			mov		ax,cs
			mov		ds,ax
			cmp		[single],TRUE		; 単発音モード
			jz		single_note_out

			dec		[steps]
			jz		note_out_start
			ret
	note_out_start:
			mov		[steps],STEPS			; 24step で動作だ！
			mov		si,offset beep_note
			add		si,[xnote]
			mov		cx,80h					; 0～80h of note.
			cld
	nout_next:
			inc		[xnote]
			cmp		[xnote],80h
			jb		nout_skip_80
			mov		[xnote],0
		nout_skip_80:
			mov		si,offset beep_note
			add		si,[xnote]
			lodsb
			or		al,al
			jnz		nout_send_freq
			loop	nout_next
			mov		[xnote_tmp],0
			beep_off						; 出力ノートなし (beep off)
			ret
	nout_send_freq:
			mov		ax,[xnote]
			cmp		[xnote_tmp],ax			; 今鳴ってるのとチェック
			jz		b						; いっしょだから無視～
			mov		[xnote_tmp],ax
			
			mov		dl,12
			div		dl						; al=octv ah=note
			mov		dx,ax
			xor		bx,bx
			mov		bl,dh
			shl		bx,1
			
			cmp		[CPUCLOCK],_10MHZ
			jnz		nout_8mhz
	nout_10mhz:
			mov		ax,word ptr [freq_10mhz + bx]
			jmp		nout_freq_setok
	nout_8mhz:
			mov		ax,word ptr [freq_8mhz  + bx]
	nout_freq_setok:
			mov		cl,dl
			sub		cl,1
			jnbe	a
			mov		cl,1
	a:
			dec		cl
			shr		ax,cl
			push	ax
			beep_off
			pop		ax
			beep_set
	b:
			beep_on
			ret
note_out	endp

;---------------------------- バッファクリア
beep_note_init	proc
			public	beep_note_init
			beep_off
			mov		al,73h
			mov		dx,3fdfh
			out		dx,al
			out		5fh,al
			out		5fh,al
			
			push	cx
			push	di
			push	es
			push	cs
			pop		es
			mov		di,offset beep_note
			cld
			mov		cx,OCTAVE*12
			xor		al,al
			rep		stosb
			mov		[xnote],0
			mov		[steps],STEPS
			
			mov		[single_note],0
			pop		es
			pop		di
			pop		cx
			ret
beep_note_init	endp

;---------------------------- 単発音モード
single_note_out	proc
			cmp		[single_note],0
			jnz		snout_main
			ret
	snout_main:
	jmp		snout_normal

			cmp		[single_mod_lev],0
			jz		snout_normal
			cmp		[single_mod_sync],0
			jz		snout_normal
			cmp		[single_mod_switch],TRUE
			jz		snout_mod_on

			dec		[single_mod_nowsync]
			cmp		[single_mod_nowsync],0
			jnz		snout_normal
			mov		[single_mod_switch],TRUE
	
	snout_mod_on:
			mov		ax,[single_mod_nowlevdir]
			add		[single_mod_nowlev],ax
			mov		ax,[single_mod_nowlev]
			cmp		ax,[single_mod_lev]
			jz		snout_neg
			neg		ax
			cmp		ax,[single_mod_lev]
			jz		snout_neg
			jmp		snout_normal
	snout_neg:
			neg		[single_mod_nowlevdir]

	snout_normal:
			mov		ax,[single_note]
			mov		dl,12
			div		dl						; al=octv ah=note
			mov		dx,ax
			xor		bx,bx
			mov		bl,dh
			shl		bx,1

			cmp		[CPUCLOCK],_10MHZ
			jnz		snout_8mhz
	snout_10mhz:
			mov		ax,word ptr [freq_10mhz + bx]
			jmp		snout_freq_setok
	snout_8mhz:
			mov		ax,word ptr [freq_8mhz  + bx]
	snout_freq_setok:
			mov		cl,dl
			sub		cl,2
			jnbe	bn_a
			mov		cl,1
	bn_a:
			dec		cl
			shr		ax,cl
			push	ax
;			beep_off
			pop		ax
;			add		ax,[single_mod_nowlev]
;			beep_set
			beep_on
			ret
single_note_out	endp

;---------------------------- ddn func proc.(00) 音源初期化
;ret@ax
;	NULL	初期化完了
;
beep_init_beepmodule	proc	far
			public	beep_init_beepmodule
			beep_off
			call	beep_note_init
			xor		ax,ax
			ret
beep_init_beepmodule	endp

;---------------------------- ddn func proc.(01) ノートオフ
;	ch		beepチャンネル
;	bh		ノートナンバー
;	bl		ベロシティー
;
beep_note_off	proc	far
			public	beep_note_off
			push	cs
			pop		ds
			
			cmp		[single],TRUE				; 単発音モード
			jz		bnoff_snote_off
			
			mov		bl,bh
			xor		bh,bh
			cmp		[beep_note+bx],byte ptr 0
			jz		bnoff_exit
			dec		byte ptr [beep_note+bx]
	bnoff_exit:
			ret

;単発音終了
	bnoff_snote_off:
			mov		bl,bh
			xor		bh,bh
;			cmp		[single_note],bx
;			jz		bnoff_snote_off_exit
			mov		[single_note],0
			beep_off
	bnoff_snote_off_exit:
			ret

beep_note_off	endp

;---------------------------- ddn func proc.(02) ノートオン
;	ch		beepチャンネル
;	bh		ノートナンバー
;	bl		ベロシティー
;
beep_note_on	proc	far
			public	beep_note_on
;時分割発音
			push	cs
			pop		ds
			
			cmp		[single],TRUE				; 単発音モード
			jz		bnon_snote_on
			
			or		bl,bl
			jz		beep_note_off
			mov		bl,bh
			xor		bh,bh
			cmp		byte ptr [beep_note+bx],127
			jnb		bnon_exit
			inc		byte ptr [beep_note+bx]
	bnon_exit:
			ret

;単発音
	bnon_snote_on:
;			cmp		[single_note],0				; 発音中??
;			jnz		bnon_snote_on_exit			; だよねー。
			mov		ax,[single_mod_sync]
			mov		[single_mod_nowsync],ax
			mov		ax,[single_mod_levdir]
			mov		[single_mod_nowlevdir],ax
			mov		[single_mod_switch],FALSE

			mov		bl,bh
			xor		bh,bh
			mov		[single_note],bx

			mov		ax,bx
			mov		dl,12
			div		dl						; al=octv ah=note
			mov		dx,ax
			xor		bx,bx
			mov		bl,dh
			shl		bx,1

			cmp		[CPUCLOCK],_10MHZ
			jnz		bnon_8mhz
	bnon_10mhz:
			mov		ax,word ptr [freq_10mhz + bx]
			jmp		bnon_freq_setok
	bnon_8mhz:
			mov		ax,word ptr [freq_8mhz  + bx]
	bnon_freq_setok:
			mov		cl,dl
			sub		cl,2
			jnbe	bnon_a
			mov		cl,1
	bnon_a:
			dec		cl
			shr		ax,cl
			push	ax
			beep_off
			pop		ax
			beep_set
			beep_on
	bnon_snote_on_exit:
			ret
beep_note_on	endp

;---------------------------- ddn func proc.(03) ポリフォニックキープレッシャー
;	ch		beepチャンネル
;	bh		ノートナンバー
;	bl		プレッシャー値
;
beep_poly_keypress	proc	far
			public	beep_poly_keypress
			ret
beep_poly_keypress	endp

;---------------------------- ddn func proc.(04) バンクセレクト
;	ch		beepチャンネル
;	bx		バンクナンバー
;
beep_bank_select	proc	far
			public	beep_bank_select
			ret
beep_bank_select	endp

;---------------------------- ddn func proc.(05) モジュレーション
;	ch		beepチャンネル
;	bh		モジュレーションデプス
;
beep_modulation	proc	far
			public	beep_modulation
			mov		bl,bh
			xor		bh,bh
			mov		[single_mod_lev],bx
			ret
beep_modulation	endp

;---------------------------- ddn func proc.(06) ポルタメントタイム
;	ch		beepチャンネル
;	bh		ポルタメントタイム
;
beep_pol_time	proc	far
			public	beep_pol_time
			ret
beep_pol_time	endp

;---------------------------- ddn func proc.(07) データエントリー
;	ch		beepチャンネル
;	bx		RPN/NRPNのパラメータに対する値
;
beep_data_entry	proc	far
			public	beep_data_entry
			ret
beep_data_entry	endp

;---------------------------- ddn func proc.(08) ボリューム
;	ch		beepチャンネル
;	bh		ボリューム
;
beep_volume		proc	far
			public	beep_volume
			ret
beep_volume	endp

;---------------------------- ddn func proc.(09) パンポット
;	ch		beepチャンネル
;	bh		パンポット
;
beep_panpot		proc	far
			public	beep_panpot
			ret
beep_panpot		endp

;---------------------------- ddn func proc.(0a) エクスプレッション
;	ch		beepチャンネル
;	bh		エクスプレッション
;
beep_expression	proc	far
			public	beep_expression
			ret
beep_expression	endp

;---------------------------- ddn func proc.(0b) ホールド１
;	ch		beepチャンネル
;	bh		ホールドコントロール値
;
beep_hold1		proc	far
			public	beep_hold1
			ret
beep_hold1		endp

;---------------------------- ddn func proc.(0c) ポルタメント
;	ch		beepチャンネル
;	bh		ポルタメントコントロール値
;
beep_poltament	proc	far
			public	beep_poltament
			ret
beep_poltament	endp

;---------------------------- ddn func proc.(0d) ソステヌート
;	ch		beepチャンネル
;	bh		ソステヌートコントロール値
;
beep_sostenuto	proc	far
			public	beep_sostenuto
			ret
beep_sostenuto	endp

;---------------------------- ddn func proc.(0e) ソフト
;	ch		beepチャンネル
;	bh		ソフトコントロール値
;
beep_soft		proc	far
			public	beep_soft
			ret
beep_soft		endp

;---------------------------- ddn func proc.(0f) ポルタメントコントロール
;	ch		beepチャンネル
;	bh		ソースノートナンバー
;
beep_pol_ctrl	proc	far
			public	beep_pol_ctrl
			ret
beep_pol_ctrl	endp

;---------------------------- ddn func proc.(10) 汎用effect1(ﾘﾊﾞｰﾌﾞｾﾝﾄﾞﾚﾍﾞﾙ)
;	ch		beepチャンネル
;	bh		コントロール値
;
beep_effect1		proc	far
			public	beep_effect1
			ret
beep_effect1		endp

;---------------------------- ddn func proc.(11) 汎用effect3(ｺｰﾗｽｾﾝﾄﾞﾚﾍﾞﾙ)
;	ch		beepチャンネル
;	bh		コントロール値
;
beep_effect3		proc	far
			public	beep_effect3
			ret
beep_effect3		endp

;---------------------------- ddn func proc.(12) NRPN
;	ch		beepチャンネル
;	bh		mm,ll選択 0:mm 1:ll
;	bl		データ
beep_nrpn		proc	far
			public	beep_nrpn
			ret
beep_nrpn		endp

;---------------------------- ddn func proc.(13) RPN
;	ch		beepチャンネル
;	bh		mm,ll選択 0:mm 1:ll
;	bl		データ
beep_rpn			proc	far
			public	beep_rpn
			ret
beep_rpn			endp

;---------------------------- ddn func proc.(14) プログラムチェンジ
;	ch		beepチャンネル
;	bh		音色番号
;
beep_prog_chg	proc	far
			public	beep_prog_chg
			ret
beep_prog_chg	endp

;---------------------------- ddn func proc.(15) チャンネルプレッシャー
;	ch		beepチャンネル
;	bh		チャンネルプレッシャー値
;
beep_ch_presser	proc	far
			public	beep_ch_presser
			ret
beep_ch_presser	endp

;---------------------------- ddn func proc.(16) ピッチベンドレンジ
;	ch		beepチャンネル
;	bx		ピッチベンド値
;
beep_pitchbend	proc	far
			public	beep_pitchbend
			ret
beep_pitchbend	endp

;---------------------------- ddn func proc.(17) オールサウンドオフ
;	ch		beepチャンネル
;
beep_all_soundoff	proc	far
			public	beep_all_soundoff
			call	beep_note_init
			ret
beep_all_soundoff	endp

;---------------------------- ddn func proc.(18) オールリセットコントローラー
;	ch		beepチャンネル
;
beep_all_resetctrler	proc	far
			public	beep_all_resetctrler
			call	beep_note_init
			ret
beep_all_resetctrler	endp

;---------------------------- ddn func proc.(19) オールノートオフ
;	ch		beepチャンネル
;
beep_all_noteoff	proc	far
			public	beep_all_noteoff
			call	beep_note_init
			ret
beep_all_noteoff	endp

;---------------------------- ddn func proc.(1a) OMNI OFF
;	ch		beepチャンネル
;
beep_omni_off	proc	far
			public	beep_omni_off
			ret
beep_omni_off	endp

;---------------------------- ddn func proc.(1b) OMNI ON
;	ch		beepチャンネル
;
beep_omni_on		proc	far
			public	beep_omni_on
			ret
beep_omni_on		endp

;---------------------------- ddn func proc.(1c) MONO
;	ch		beepチャンネル
;	bh		MONO数
;
beep_mono		proc	far
			public	beep_mono
			ret
beep_mono		endp

;---------------------------- ddn func proc.(1d) POLY
;	ch		beepチャンネル
;
beep_poly		proc	far
			public	beep_poly
			ret
beep_poly		endp

;---------------------------- ddn func proc.(1e) アクティブセンシング
;
beep_active_sence	proc	far
			public	beep_active_sence
			ret
beep_active_sence	endp

;---------------------------- ddn func proc.(1f) エクスクルーシブメッセージ
;	es:bx	エクスクルーシブデータ列
;	cx		長さ
;
beep_exclusive	proc	far
			public	beep_exclusive
			ret
beep_exclusive	endp

;---------------------------- ddn func proc.(20) ビブラート設定
;	cx		音色番号
;	bh		ビブラートレート
;	bl		ビブラートデプス
;	dh		ビブラートディレイ
;
beep_vibrato		proc	far
			public	beep_vibrato
			ret
beep_vibrato		endp

;---------------------------- ddn func proc.(21) マスターボリューム
;	bh		マスターボリューム値
;
beep_master_volume	proc	far
			public	beep_master_volume
			ret
beep_master_volume	endp

			end

