;==============================================================================
; MFXDDN sound driver module
;						YAMAHA YM2203 SSG driver
;  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
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
include		ssg.inc
include		ssgfreq.inc
include		usertool.inc
include		ssgvib.inc

extrn		set_voice :near
extrn		set_volume:near
extrn		write_opnreg:near
extrn		volume_buf:word
extrn		exp_buf:word
extrn		velo_buf:word
extrn		mastervol:word
extrn		soundtbl:SSGTONE
extrn		soundtblmax:word
extrn		notestatus:byte
extrn		ssg_tone_reset:near
extrn		fnumber:word,lfo:MODTABLE

;---------------------------- ddn func proc.(00) ECM
ssg_ecm		proc	far
			public	ssg_ecm
			push	cs
			pop		ds
			
			cmp		es:[bx]  ,word ptr DRVIDNUM		; OPN.XDVに対してのECMか?
			jz		ecm_pass1
			ret
	ecm_pass1:
			cmp		es:[bx+2],byte ptr 00h			; 音源ドライバか?
			jz		ecm_go
			ret
	ecm_go:
			mov		al,es:[bx+5]
			cmp		al,00h					; 音色登録だ!
			jz		ecm_set_sound
			mov		al,es:[bx+5]
			cmp		al,02h					; レジスタ書き込みだ!
			jz		ecm_set_sound
			ret
ssg_ecm		endp

;音色登録 ==============
ecm_set_sound	proc	far
			add		bx,6
			cmp		[soundtblmax],MAXSOUND
			jb		set_sound_ok
			ret
	set_sound_ok:
			mov		ax,type SSGTONE
			mul		[soundtblmax]
			mov		si,ax
			add		si,offset soundtbl
			mov		ax,es:[bx]
			mov		[si].banknum,ax
			mov		al,es:[bx+2]
			mov		[si].no     ,al
			add		bx,3
			mov		[si].datofs,bx
			mov		[si].datseg,es
			inc		[soundtblmax]
			ret
ecm_set_sound	endp

;レジスタ書き込み =====================
ecm_write_opnreg	proc
			mov		ah,es:[bx]
			mov		al,es:[bx+1]
			push	bx
			mov		bx,ax
			call	write_opnreg
			pop		bx
			add		bx,2
			ret
ecm_write_opnreg	endp

;---------------------------- ddn func proc.(01) ノートオフ
;	ch		opnチャンネル
;	bh		ノートナンバー
;
ssg_note_off	proc	far
			public	ssg_note_off
			xor		ax,ax
			mov		al,ch
			mov		si,ax
			cmp		[notestatus+si],bh
			jnz		on_off_end
			mov		[notestatus+si],0
			
			mov		bx,0800h
			add		bh,ch
			call	write_opnreg
	on_off_end:
			ret
ssg_note_off	endp

;---------------------------- ddn func proc.(02) ノートオン
;	ch		opnチャンネル
;	bh		ノートナンバー
;	bl		ベロシティー
;
ssg_note_on	proc	far
			public	ssg_note_on

			xor		ax,ax
			mov		al,ch
			mov		si,ax
			mov		[si+notestatus],bh
			shl		si,1
			mov		byte ptr [si+velo_buf],bl	; Velocity登録

			mov		bl,bh
			xor		bh,bh
			shl		bx,1
			mov		ax,[ssgfreq+bx]
			mov		[si+fnumber],ax

			mov		bh,ch
			shl		bh,1						; FREQレシスタ(LOW)
			mov		bl,al
			call	write_opnreg
			inc		bh							; FREQレジスタ(HIGH)
			mov		bl,ah
			call	write_opnreg

			mov		ah,ch
			call	ssg_tone_reset

			mov		al,type MODTABLE
			mul		ch
			mov		bx,ax
			add		bx,offset lfo
			cmp		[bx].mod_flag,MOD_NOACTIVE
			jz		ssg_non_noactive_mod
			mov		[bx].mod_flag,MOD_STANDBY
	ssg_non_noactive_mod:

			mov		ah,ch
			call	set_volume			; velocity

			ret
ssg_note_on	endp

;---------------------------- ddn func proc.(03) ポリフォニックキープレッシャー
;	ch		ssgチャンネル
;	bh		ノートナンバー
;	bl		プレッシャー値
;
ssg_poly_keypress	proc	far
			public	ssg_poly_keypress
			ret
ssg_poly_keypress	endp

;---------------------------- ddn func proc.(04) バンクセレクト
;	ch		opnチャンネル
;	bx		バンクナンバー
;
ssg_bank_select	proc	far
			public	ssg_bank_select
			ret
ssg_bank_select	endp

;---------------------------- ddn func proc.(05) モジュレーション
;	ch		ssgチャンネル
;	bh		モジュレーションデプス
;
ssg_modulation	proc	far
			public	ssg_modulation
			mov		al,type MODTABLE
			mul		ch
			add		ax,offset lfo
			mov		si,ax
			mov		[si].mod_depth,bh
			ret
			ret
ssg_modulation	endp

;---------------------------- ddn func proc.(06) ポルタメントタイム
;	ch		ssgチャンネル
;	bh		ポルタメントタイム
;
ssg_pol_time	proc	far
			public	ssg_pol_time
			ret
ssg_pol_time	endp

;---------------------------- ddn func proc.(07) データエントリー
;	ch		ssgチャンネル
;	bx		RPN/NRPNのパラメータに対する値
;
ssg_data_entry	proc	far
			public	ssg_data_entry
			ret
ssg_data_entry	endp

;---------------------------- ddn func proc.(08) ボリューム
;	ch		ssgチャンネル
;	bh		ボリューム
;
ssg_volume		proc	far
			public	ssg_volume
			xor		ax,ax
			mov		al,bh
			xor		bx,bx
			mov		bl,ch
			shl		bx,1
			mov		[volume_buf+bx],ax
			
			mov		ah,ch
			call	set_volume
			ret
ssg_volume	endp

;---------------------------- ddn func proc.(09) パンポット
;	ch		ssgチャンネル
;	bh		パンポット
;
ssg_panpot		proc	far
			public	ssg_panpot
			ret
ssg_panpot		endp

;---------------------------- ddn func proc.(0a) エクスプレッション
;	ch		ssgチャンネル
;	bh		エクスプレッション
;
ssg_expression	proc	far
			public	ssg_expression
			xor		ax,ax
			mov		al,bh
			xor		bx,bx
			mov		bl,ch
			shl		bx,1
			mov		[exp_buf+bx],ax
			
			mov		ah,ch
			call	set_volume
			ret
ssg_expression	endp

;---------------------------- ddn func proc.(0b) ホールド１
;	ch		ssgチャンネル
;	bh		ホールドコントロール値
;
ssg_hold1		proc	far
			public	ssg_hold1
			ret
ssg_hold1		endp

;---------------------------- ddn func proc.(0c) ポルタメント
;	ch		ssgチャンネル
;	bh		ポルタメントコントロール値
;
ssg_poltament	proc	far
			public	ssg_poltament
			ret
ssg_poltament	endp

;---------------------------- ddn func proc.(0d) ソステヌート
;	ch		ssgチャンネル
;	bh		ソステヌートコントロール値
;
ssg_sostenuto	proc	far
			public	ssg_sostenuto
			ret
ssg_sostenuto	endp

;---------------------------- ddn func proc.(0e) ソフト
;	ch		ssgチャンネル
;	bh		ソフトコントロール値
;
ssg_soft		proc	far
			public	ssg_soft
			ret
ssg_soft		endp

;---------------------------- ddn func proc.(0f) ポルタメントコントロール
;	ch		ssgチャンネル
;	bh		ソースノートナンバー
;
ssg_pol_ctrl	proc	far
			public	ssg_pol_ctrl
			ret
ssg_pol_ctrl	endp

;---------------------------- ddn func proc.(10) 汎用effect1(ﾘﾊﾞｰﾌﾞｾﾝﾄﾞﾚﾍﾞﾙ)
;	ch		ssgチャンネル
;	bh		コントロール値
;
ssg_effect1		proc	far
			public	ssg_effect1
			ret
ssg_effect1		endp

;---------------------------- ddn func proc.(11) 汎用effect3(ｺｰﾗｽｾﾝﾄﾞﾚﾍﾞﾙ)
;	ch		ssgチャンネル
;	bh		コントロール値
;
ssg_effect3		proc	far
			public	ssg_effect3
			ret
ssg_effect3		endp

;---------------------------- ddn func proc.(12) NRPN
;	ch		ssgチャンネル
;	bh		mm,ll選択 0:mm 1:ll
;	bl		データ
ssg_nrpn		proc	far
			public	ssg_nrpn
			ret
ssg_nrpn		endp

;---------------------------- ddn func proc.(13) RPN
;	ch		ssgチャンネル
;	bh		mm,ll選択 0:mm 1:ll
;	bl		データ
ssg_rpn			proc	far
			public	ssg_rpn
			ret
ssg_rpn			endp

;---------------------------- ddn func proc.(14) プログラムチェンジ
;	ch		ssgチャンネル
;	bh		音色番号
;
ssg_prog_chg	proc	far
			public	ssg_prog_chg
			mov		ah,ch
			mov		al,bh
			call	set_voice
			ret
ssg_prog_chg	endp

;---------------------------- ddn func proc.(15) チャンネルプレッシャー
;	ch		ssgチャンネル
;	bh		チャンネルプレッシャー値
;
ssg_ch_presser	proc	far
			public	ssg_ch_presser
			ret
ssg_ch_presser	endp

;---------------------------- ddn func proc.(16) ピッチベンドレンジ
;	ch		ssgチャンネル
;	bx		ピッチベンド値
;
ssg_pitchbend	proc	far
			public	ssg_pitchbend
			ret
ssg_pitchbend	endp

;---------------------------- ddn func proc.(17) オールサウンドオフ
;	ch		ssgチャンネル
;
ssg_all_soundoff	proc	far
			public	ssg_all_soundoff
			ret
ssg_all_soundoff	endp

;---------------------------- ddn func proc.(18) オールリセットコントローラー
;	ch		ssgチャンネル
;
ssg_all_resetctrler	proc	far
			public	ssg_all_resetctrler
			ret
ssg_all_resetctrler	endp

;---------------------------- ddn func proc.(19) オールノートオフ
;	ch		ssgチャンネル
;
ssg_all_noteoff	proc	far
			public	ssg_all_noteoff
			ret
ssg_all_noteoff	endp

;---------------------------- ddn func proc.(1a) OMNI OFF
;	ch		ssgチャンネル
;
ssg_omni_off	proc	far
			public	ssg_omni_off
			ret
ssg_omni_off	endp

;---------------------------- ddn func proc.(1b) OMNI ON
;	ch		ssgチャンネル
;
ssg_omni_on		proc	far
			public	ssg_omni_on
			ret
ssg_omni_on		endp

;---------------------------- ddn func proc.(1c) MONO
;	ch		ssgチャンネル
;	bh		MONO数
;
ssg_mono		proc	far
			public	ssg_mono
			ret
ssg_mono		endp

;---------------------------- ddn func proc.(1d) POLY
;	ch		ssgチャンネル
;
ssg_poly		proc	far
			public	ssg_poly
			ret
ssg_poly		endp

;---------------------------- ddn func proc.(1e) アクティブセンシング
;
ssg_active_sence	proc	far
			public	ssg_active_sence
			ret
ssg_active_sence	endp

;---------------------------- ddn func proc.(1f) エクスクルーシブメッセージ
;	es:bx	エクスクルーシブデータ列
;	cx		長さ
;
ssg_exclusive	proc	far
			public	ssg_exclusive
			ret
ssg_exclusive	endp

;---------------------------- ddn func proc.(20) ビブラート設定
;	cx		音色番号
;	bh		ビブラートレート
;	bl		ビブラートデプス
;	dh		ビブラートディレイ
;
ssg_vibrato		proc	far
			public	ssg_vibrato
			ret
ssg_vibrato		endp

;---------------------------- ddn func proc.(21) マスターボリューム
;	bh		マスターボリューム値
;
ssg_master_volume	proc	far
			public	ssg_master_volume
			mov		byte ptr [mastervol],bh
			mov		ah,0
			call	set_volume
			mov		ah,1
			call	set_volume
			mov		ah,2
			call	set_volume
			ret
ssg_master_volume	endp

;---------------------------- ddn func proc.(21) マスターボリューム
;	bh		マスターボリューム値
;
opn_master_volume	proc	far
			public	opn_master_volume
			mov		byte ptr [mastervol],bh
			mov		ah,0
			call	set_volume
			mov		ah,1
			call	set_volume
			mov		ah,2
			call	set_volume
			ret
opn_master_volume	endp

;------------------------------------------------------------------
; Amplitude Modulation(Tremolo)
;
int_modulation	proc
			public	int_modulation
			mov		cx,3
			mov		bx,offset lfo
			xor		dh,dh
	modnext:
			push	cx
			push	bx
			push	dx
			mov		ch,dh
			call	modulation_main
			pop		dx
			pop		bx
			pop		cx
			inc		dh
			add		bx,type MODTABLE
			loop	modnext
			ret

	modulation_main:
			mov		al,[bx].mod_flag
			cmp		al,MOD_STANDBY
			jz		mod_standby_proc
			cmp		al,MOD_SYNC
			jz		mod_sync_proc
			cmp		al,MOD_MAIN
			jz		mod_main_proc
			ret

;----- Standby
	mod_standby_proc:
			mov		[bx].mod_flag,MOD_SYNC
			mov		ax,[bx].mod_sync
			mov		[bx].mod_sync_cnt,ax
			mov		[bx].mod_trace,0
			ret
;----- ModSync
	mod_sync_proc:
			dec		[bx].mod_sync_cnt
			jnz		mod_sync_until
			mov		[bx].mod_flag,MOD_MAIN
	mod_sync_until:
			ret
;----- ModMain
	mod_main_proc:
			mov		ax,[bx].mod_speed
			add		[bx].mod_trace,ax
			jnb		mod_main_normal
			xor		ax,ax
			jmp		mod_main_start
	mod_main_normal:
			mov		ax,[bx].mod_trace
	mod_main_start:
			mov		al,ah
			xor		ah,ah
			mov		si,ax
			mov		al,[lfo_sin_function+si]
			mov		ah,[bx].mod_depth
			imul	ah						; ax に、増減値
			cwd
			mov		si,400					; 感度(100以上)
			idiv	si						; ax に、実際の増減値
			
			xor		bx,bx
			mov		bl,ch
			shl		bx,1
			mov		dx,[fnumber+bx]
			add		dx,ax

			add		bh,ch
			shl		bh,1
			mov		bl,dl
			call	write_opnreg

			inc		bh
			mov		bl,dh
			call	write_opnreg
			ret

int_modulation	endp

			end

