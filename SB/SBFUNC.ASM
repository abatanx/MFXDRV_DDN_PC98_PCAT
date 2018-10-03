;========================================================
; MFXDDN sound driver module
;                       YAMAHA YM3812 FM(OPL2) driver (Sound Braster) for DOS/V
;  copyright (c) 1995 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================
;
; ファンクション部分
;

;※
; このプログラムは全て XMML rel3.00 仕様の通常音源デバイスモジュール規格に
; 準じています。
; XMML rel.3.00 copyright (c) ABA / T.Kobayashi and Interfair 
;                                                                                                       all rights reserved
;※
			jumps
			.186
			.model  tiny
			.code

include         stdio.inc
include         ddn.inc
include         sb.inc
include         usertool.inc
include         sbfreq.inc
include         sbvib.inc

jptable		dw	offset ecm_set_sound
			dw	offset ecm_set_revisionflag
			dw	offset ecm_write_opl2reg
ECMFUNCMAX      =       3

;---------------------------- ddn func proc.(00) ECM
opl2_ecm                proc    far
			public  opl2_ecm
			
			cmp             es:[bx]  ,word ptr DRVIDNUM             ; OPL2.XDVに対してのECMか?
			jz              ecm_pass1
			ret
	ecm_pass1:
			cmp             es:[bx+2],byte ptr 00h                  ; 音源ドライバか?
			jz              ecm_go
			ret
	ecm_go:
			mov             al,es:[bx+5]
			add             bx,6
			
			xor             ah,ah
			cmp             ax,ECMFUNCMAX
			jnb             oe_e

			shl             ax,1
			add             ax,offset jptable
			mov             si,ax
			call    word ptr [si]
	oe_e:
			ret
opl2_ecm                endp

;音色登録 =============================
ecm_set_sound   proc
			cmp             [soundtblmax],MAXSOUND
			jb              set_sound_ok
			ret
	set_sound_ok:
			mov             ax,type OPL2TONE
			mul             [soundtblmax]
			mov             si,ax
			add             si,offset soundtbl
			mov             ax,es:[bx]
			mov             [si].banknum,ax
			mov             al,es:[bx+2]
			mov             [si].no     ,al
			add             bx,3
			mov             [si].datofs,bx
			mov             [si].datseg,es
			inc             [soundtblmax]
			ret
ecm_set_sound   endp

;音量補正フラグ =======================
ecm_set_revisionflag    proc
			cmp             es:[bx],byte ptr 00h
			jz              esr_false
			mov             [volumerevision],TRUE
			ret
	esr_false:
			mov             [volumerevision],FALSE
			ret
ecm_set_revisionflag    endp

;レジスタ書き込み =====================
ecm_write_opl2reg       proc
			mov             ah,es:[bx]
			mov             al,es:[bx+1]
			push    bx
			mov             bx,ax
			call    write_opl2reg
			pop             bx
			add             bx,2
			ret
ecm_write_opl2reg       endp

;---------------------------- ddn func proc.(01) ノートオフ
;       ch              opl2チャンネル
;       bh              ノートナンバー
;
opl2_note_off   proc    far
			public  opl2_note_off
			xor             ax,ax
			mov             al,ch
			mov             si,ax
			cmp             [notestatus+si],bh
			jnz             on_off_end
			mov             [notestatus+si],0
			
			mov             bh,YM3812_FNUM_H
			add             bh,ch
			mov             bl,0
			call			write_opl2reg
	on_off_end:
			ret
opl2_note_off   endp

;---------------------------- ddn func proc.(02) ノートオン
;       ch              opl2チャンネル
;       bh              ノートナンバー
;       bl              ベロシティー
;
opl2_note_on    proc    far
			public  opl2_note_on
			xchg    ax,bx
			xor             bx,bx
			mov             bl,ch
			mov             [bx+notestatus],ah
			mov             [bx+velo_buf],al
			shl				bx,1
			mov				di,[bx+pitch]
			xchg            ax,bx
			push	bx
			mov		bh,YM3812_FNUM_H
			add     bh,ch
			xor     bl,bl
			call    write_opl2reg
			pop		bx

			cmp				bh,12
			jnb				opl2_ok1
			mov				bh,12
	opl2_ok1:
			cmp				bh,108
			jb				opl2_ok2
			mov				bh,108
	opl2_ok2:
			mov				bl,bh
			xor				bh,bh
			mov				ax,bx
			mov				cl,12
			div				cl
			dec				al
			mov				dl,al

			mov				dl,al
			mov				bl,ah
			xor				bh,bh
			shl				bx,1

			mov             ax,[bx+opl2freq]                ; ax < Fnum
			add				ax,di							; diはpitchだよ。

			mov             bh,YM3812_FNUM_H
			add             bh,ch
			mov             bl,ah
			shl             dl,2                                    ; 改造～
			and             bl,00000011b
			or              bl,dl
			or              bl,NOTEON                ; key-on
			call    write_opl2reg

			mov             bh,YM3812_FNUM_L
			add             bh,ch
			mov             bl,al
			call    write_opl2reg

			xor             bx,bx
			mov             bl,ch
			mov             [bx+fnumber1],al
			mov             [bx+fnumber2],ah

			mov             ah,ch
			call    set_volume                      ; velocity

			ret
opl2_note_on    endp

;---------------------------- ddn func proc.(03) ポリフォニックキープレッシャー
;       ch              opl2チャンネル
;       bh              ノートナンバー
;       bl              プレッシャー値
;
opl2_poly_keypress      proc    far
			public  opl2_poly_keypress
			ret
opl2_poly_keypress      endp

;---------------------------- ddn func proc.(04) バンクセレクト
;       ch              opl2チャンネル
;       bx              バンクナンバー
;
opl2_bank_select        proc    far
			public  opl2_bank_select
			ret
opl2_bank_select        endp

;---------------------------- ddn func proc.(05) モジュレーション
;       ch              opl2チャンネル
;       bh              モジュレーションデプス
;
opl2_modulation proc    far
			public  opl2_modulation
			mov             al,type MODTABLE
			mul             ch
			add             ax,offset lfo
			mov             si,ax
			mov             [si].mod_depth,bh
			ret
opl2_modulation endp

;---------------------------- ddn func proc.(06) ポルタメントタイム
;       ch              opl2チャンネル
;       bh              ポルタメントタイム
;
opl2_pol_time   proc    far
			public  opl2_pol_time
			ret
opl2_pol_time   endp

;---------------------------- ddn func proc.(07) データエントリー
;       ch              opl2チャンネル
;       bx              RPN/NRPNのパラメータに対する値
;
opl2_data_entry proc    far
			public  opl2_data_entry
			ret
opl2_data_entry endp

;--------------------------- ddn func proc.(08) ボリューム
;       ch              opl2チャンネル
;       bh              ボリューム
;
opl2_volume             proc    far
			public  opl2_volume
			mov             al,bh
			xor             bx,bx
			mov             bl,ch
			mov             [bx+volume_buf],al
			mov             ah,ch
			call    set_volume
			ret
opl2_volume     endp

;---------------------------- ddn func proc.(09) パンポット
;       ch              opl2チャンネル
;       bh              パンポット
;
opl2_panpot             proc    far
			public  opl2_panpot
			ret
opl2_panpot             endp

;---------------------------- ddn func proc.(0a) エクスプレッション
;       ch              opl2チャンネル
;       bh              エクスプレッション
;
opl2_expression proc    far
			public  opl2_expression
			mov             al,bh
			xor             bx,bx
			mov             bl,ch
			mov             [bx+exp_buf],al
			mov             ah,ch
			call    set_volume
			ret
opl2_expression endp

;---------------------------- ddn func proc.(0b) ホールド１
;       ch              opl2チャンネル
;       bh              ホールドコントロール値
;
opl2_hold1              proc    far
			public  opl2_hold1
			ret
opl2_hold1              endp

;---------------------------- ddn func proc.(0c) ポルタメント
;       ch              opl2チャンネル
;       bh              ポルタメントコントロール値
;
opl2_poltament  proc    far
			public  opl2_poltament
			ret
opl2_poltament  endp

;---------------------------- ddn func proc.(0d) ソステヌート
;       ch              opl2チャンネル
;       bh              ソステヌートコントロール値
;
opl2_sostenuto  proc    far
			public  opl2_sostenuto
			ret
opl2_sostenuto  endp

;---------------------------- ddn func proc.(0e) ソフト
;       ch              opl2チャンネル
;       bh              ソフトコントロール値
;
opl2_soft               proc    far
			public  opl2_soft
			ret
opl2_soft               endp

;---------------------------- ddn func proc.(0f) ポルタメントコントロール
;       ch              opl2チャンネル
;       bh              ソースノートナンバー
;
opl2_pol_ctrl   proc    far
			public  opl2_pol_ctrl
			ret
opl2_pol_ctrl   endp

;---------------------------- ddn func proc.(10) 汎用effect1(ﾘﾊﾞｰﾌﾞｾﾝﾄﾞﾚﾍﾞﾙ)
;       ch              opl2チャンネル
;       bh              コントロール値
;
opl2_effect1            proc    far
			public  opl2_effect1
			ret
opl2_effect1            endp

;---------------------------- ddn func proc.(11) 汎用effect3(ｺｰﾗｽｾﾝﾄﾞﾚﾍﾞﾙ)
;       ch              opl2チャンネル
;       bh              コントロール値
;
opl2_effect3            proc    far
			public  opl2_effect3
			ret
opl2_effect3            endp

;---------------------------- ddn func proc.(12) NRPN
;       ch              opl2チャンネル
;       bh              mm,ll選択 0:mm 1:ll
;       bl              データ
opl2_nrpn               proc    far
			public  opl2_nrpn
			ret
opl2_nrpn               endp

;---------------------------- ddn func proc.(13) RPN
;       ch              opl2チャンネル
;       bh              mm,ll選択 0:mm 1:ll
;       bl              データ
opl2_rpn                        proc    far
			public  opl2_rpn
			ret
opl2_rpn                        endp

;---------------------------- ddn func proc.(14) プログラムチェンジ
;       ch              opl2チャンネル
;       bh              音色番号
;
opl2_prog_chg   proc    far
			public  opl2_prog_chg
			mov             ah,ch
			mov             al,bh
			call    set_voice
			ret
opl2_prog_chg   endp

;---------------------------- ddn func proc.(15) チャンネルプレッシャー
;       ch              opl2チャンネル
;       bh              チャンネルプレッシャー値
;
opl2_ch_presser proc    far
			public  opl2_ch_presser
			ret
opl2_ch_presser endp

;---------------------------- ddn func proc.(16) ピッチベンドレンジ
;       ch              opl2チャンネル
;       bx              ピッチベンド値
;
opl2_pitchbend  proc    far
			public  opl2_pitchbend
			mov		ax,bx
			xor     bx,bx
			mov     bl,ch
			shl		bx,1
			mov		[pitch+bx],ax
			ret
opl2_pitchbend  endp

;---------------------------- ddn func proc.(17) オールサウンドオフ
;       ch              opl2チャンネル
;
opl2_all_soundoff       proc    far
			public  opl2_all_soundoff
			xor             bx,bx
			mov             bl,ch
			mov             [notestatus+bx],0
			mov             ah,ch
			call    init_opl2sound
			ret
opl2_all_soundoff       endp

;---------------------------- ddn func proc.(18) オールリセットコントローラー
;       ch              opl2チャンネル
;
opl2_all_resetctrler    proc    far
			public  opl2_all_resetctrler
			xor             bx,bx
			mov             bl,ch
			mov             [bx+notestatus],0
			mov             [bx+volume_buf],100
			mov             [bx+exp_buf],127
			mov             [bx+velo_buf],0
			shl				bx,1
			mov             [bx+pitch],0
			mov             ah,ch
			call    init_opl2sound
			ret
opl2_all_resetctrler    endp

;---------------------------- ddn func proc.(19) オールノートオフ
;       ch              opl2チャンネル
;
opl2_all_noteoff        proc    far
			public  opl2_all_noteoff
			xor             bx,bx
			mov             bl,ch
			mov             [notestatus+bx],0
			mov             ah,ch
			call    init_opl2sound
			ret
opl2_all_noteoff        endp

;---------------------------- ddn func proc.(1a) OMNI OFF
;       ch              opl2チャンネル
;
opl2_omni_off   proc    far
			public  opl2_omni_off
			ret
opl2_omni_off   endp

;---------------------------- ddn func proc.(1b) OMNI ON
;       ch              opl2チャンネル
;
opl2_omni_on            proc    far
			public  opl2_omni_on
			ret
opl2_omni_on            endp

;---------------------------- ddn func proc.(1c) MONO
;       ch              opl2チャンネル
;       bh              MONO数
;
opl2_mono               proc    far
			public  opl2_mono
			ret
opl2_mono               endp

;---------------------------- ddn func proc.(1d) POLY
;       ch              opl2チャンネル
;
opl2_poly               proc    far
			public  opl2_poly
			ret
opl2_poly               endp

;---------------------------- ddn func proc.(1e) アクティブセンシング
;
opl2_active_sence       proc    far
			public  opl2_active_sence
			ret
opl2_active_sence       endp

;---------------------------- ddn func proc.(1f) エクスクルーシブメッセージ
;       es:bx   エクスクルーシブデータ列
;       cx              長さ
;
opl2_exclusive  proc    far
			public  opl2_exclusive
			ret
opl2_exclusive  endp

;---------------------------- ddn func proc.(20) ビブラート設定
;       cx              音色番号
;       bh              ビブラートレート
;       bl              ビブラートデプス
;       dh              ビブラートディレイ
;
opl2_vibrato            proc    far
			public  opl2_vibrato
			ret
opl2_vibrato            endp

;---------------------------- ddn func proc.(21) マスターボリューム
;       bh              マスターボリューム値
;
opl2_master_volume      proc    far
			public  opl2_master_volume
			mov             byte ptr [mastervol],bh

			mov             cx,MAXCHANNEL
			xor             ah,ah
	mv_set: 
			push	ax
			push	cx
			call    set_volume
			pop		cx
			pop		ax
			inc             ah
			loop    mv_set
			ret
opl2_master_volume      endp

			end

