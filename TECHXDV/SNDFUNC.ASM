;==============================================================================
; 音源ドライバ作成用ベースプログラム
; 本プログラムは、public domain softwareです。ご自由にお使い下さい。
;                                         based programmed by ABA / T.Kobayashi
;==============================================================================
;
; ファンクション部分
;

;※
; このプログラムは全て XMML rel3.00(1.2) 仕様の音源ドライバ規格に
; 準じています。各functionに関しては、usl_drv.doc をご覧下さい。
; XMML rel.3.00 copyright (c) ABA / T.Kobayashi and Interfair 
;													all rights reserved
;※
			jumps
			.186
			.model	tiny
			.code

include		stdio.inc
include		ddn.inc
include		usertool.inc
include		snd.inc

;---------------------------- ddn func proc.(00) ECM
func_ecm		proc	far
			ret
func_ecm		endp
;---------------------------- ddn func proc.(01) ノートオフ
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		ノートナンバー(0 ～ 127)
;
func_note_off	proc	far
			ret
func_note_off	endp

;---------------------------- ddn func proc.(02) ノートオン
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		ノートナンバー(0 ～ 127)
;	bl		ベロシティー(0 ～ 127)
;
func_note_on	proc	far
			ret
func_note_on	endp

;---------------------------- ddn func proc.(03) ポリフォニックキープレッシャー
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		ノートナンバー(0 ～ 127)
;	bl		プレッシャー値(0 ～ 127)
;
func_poly_keypress	proc	far
			ret
func_poly_keypress	endp

;---------------------------- ddn func proc.(04) バンクセレクト
;	ch		チャンネル番号(0 ～ drvch-1)
;	bx		バンクナンバー(0 ～ 0x7f7f)
;
func_bank_select	proc	far
			ret
func_bank_select	endp

;---------------------------- ddn func proc.(05) モジュレーション
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		モジュレーションデプス(0～127)
;
func_modulation	proc	far
			ret
func_modulation	endp

;---------------------------- ddn func proc.(06) ポルタメントタイム
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		ポルタメントタイム(0～127)
;
func_pol_time	proc	far
			ret
func_pol_time	endp

;---------------------------- ddn func proc.(07) データエントリー
;	ch		チャンネル番号(0 ～ drvch-1)
;	bx		RPN/NRPNのパラメータに対する値(0～0x7f7f)
;
func_data_entry	proc	far
			ret
func_data_entry	endp

;---------------------------- ddn func proc.(08) ボリューム
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		ボリューム(0～127)
;
func_volume		proc	far
			ret
func_volume	endp

;---------------------------- ddn func proc.(09) パンポット
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		パンポット(0～127)
;
func_panpot		proc	far
			ret
func_panpot		endp

;---------------------------- ddn func proc.(0a) エクスプレッション
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		エクスプレッション(0～127)
;
func_expression	proc	far
			ret
func_expression	endp

;---------------------------- ddn func proc.(0b) ホールド１
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		ホールドコントロール値(0～127)
;
func_hold1		proc	far
			ret
func_hold1		endp

;---------------------------- ddn func proc.(0c) ポルタメント
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		ポルタメントコントロール値(0～127)
;
func_poltament	proc	far
			ret
func_poltament	endp

;---------------------------- ddn func proc.(0d) ソステヌート
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		ソステヌートコントロール値(0～127)
;
func_sostenuto	proc	far
			ret
func_sostenuto	endp

;---------------------------- ddn func proc.(0e) ソフト
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		ソフトコントロール値(0～127)
;
func_soft		proc	far
			ret
func_soft		endp

;---------------------------- ddn func proc.(0f) ポルタメントコントロール
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		ソースノートナンバー(0～127)
;
func_pol_ctrl	proc	far
			ret
func_pol_ctrl	endp

;---------------------------- ddn func proc.(10) 汎用effect1(ﾘﾊﾞｰﾌﾞｾﾝﾄﾞﾚﾍﾞﾙ)
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		コントロール値(0～127)
;
func_effect1		proc	far
			ret
func_effect1		endp

;---------------------------- ddn func proc.(11) 汎用effect3(ｺｰﾗｽｾﾝﾄﾞﾚﾍﾞﾙ)
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		コントロール値(0～127)
;
func_effect3		proc	far
			ret
func_effect3		endp

;---------------------------- ddn func proc.(12) NRPN
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		mm,ll選択 0:mm 1:ll
;	bl		データ(0～127)
func_nrpn		proc	far
			ret
func_nrpn		endp

;---------------------------- ddn func proc.(13) RPN
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		mm,ll選択 0:mm 1:ll
;	bl		データ(0～127)
func_rpn			proc	far
			ret
func_rpn			endp

;---------------------------- ddn func proc.(14) プログラムチェンジ
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		音色番号(0～ 127? ～255)
;
func_prog_chg	proc	far
			ret
func_prog_chg	endp

;---------------------------- ddn func proc.(15) チャンネルプレッシャー
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		チャンネル番号(0 ～ drvch-1)プレッシャー値
;
func_ch_presser	proc	far
			ret
func_ch_presser	endp

;---------------------------- ddn func proc.(16) ピッチベンドレンジ
;	ch		チャンネル番号(0 ～ drvch-1)
;	bx		ピッチベンド値(0 ～ 0x7f7f)
;
func_pitchbend	proc	far
			ret
func_pitchbend	endp

;---------------------------- ddn func proc.(17) オールサウンドオフ
;	ch		チャンネル番号(0 ～ drvch-1)
;
func_all_soundoff	proc	far
			ret
func_all_soundoff	endp

;---------------------------- ddn func proc.(18) オールリセットコントローラー
;	ch		チャンネル番号(0 ～ drvch-1)
;
func_all_resetctrler	proc	far
			ret
func_all_resetctrler	endp

;---------------------------- ddn func proc.(19) オールノートオフ
;	ch		チャンネル番号(0 ～ drvch-1)
;
func_all_noteoff	proc	far
			ret
func_all_noteoff	endp

;---------------------------- ddn func proc.(1a) OMNI OFF
;	ch		チャンネル番号(0 ～ drvch-1)
;
func_omni_off	proc	far
			ret
func_omni_off	endp

;---------------------------- ddn func proc.(1b) OMNI ON
;	ch		チャンネル番号(0 ～ drvch-1)
;
func_omni_on		proc	far
			ret
func_omni_on		endp

;---------------------------- ddn func proc.(1c) MONO
;	ch		チャンネル番号(0 ～ drvch-1)
;	bh		MONO数
;
func_mono		proc	far
			ret
func_mono		endp

;---------------------------- ddn func proc.(1d) POLY
;	ch		チャンネル番号(0 ～ drvch-1)
;
func_poly		proc	far
			ret
func_poly		endp

;---------------------------- ddn func proc.(1e) アクティブセンシング
;
func_active_sence	proc	far
			ret
func_active_sence	endp

;---------------------------- ddn func proc.(1f) エクスクルーシブメッセージ
;	es:bx	エクスクルーシブデータ列
;	cx		長さ
;
func_exclusive	proc	far
			ret
func_exclusive	endp

;---------------------------- ddn func proc.(20) ビブラート設定
;	cx		音色番号
;	bh		ビブラートレート
;	bl		ビブラートデプス
;	dh		ビブラートディレイ
;
func_vibrato		proc	far
			ret
func_vibrato		endp

;---------------------------- ddn func proc.(21) マスターボリューム
;	bh		マスターボリューム値(0～127)
;
func_master_volume	proc	far
			ret
func_master_volume	endp

			end
