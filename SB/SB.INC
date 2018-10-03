;==============================================================================
; MFXDDN sound driver module
;                       YAMAHA YM3812 FM(OPL2) driver (Sound Braster) for DOS/V
;  copyright (c) 1995 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================

DRVIDNUM        equ             0078h                           ; DRV-ID number
ver_int         equ             0
ver_real        equ             60
ver_char        equ             ' '
MAXCHANNEL      equ             9
FORCE           equ             FALSE                           ; 強制認識
DEBUG           equ             FALSE                           ; debugモード
DOSV			equ				TRUE
;
; YM-3812 レジスタマップ定義
;
YM3812_CSMSEL           equ             008h
YM3812_AMVIB            equ             020h
YM3812_KSTL             equ             040h
YM3812_ARDR             equ             060h
YM3812_SLRR             equ             080h
YM3812_FNUM_L           equ             0a0h
YM3812_FNUM_H           equ             0b0h
YM3812_FBCON            equ             0c0h
YM3812_KEY              equ             0b0h
YM3812_WS               equ             0e0h
YM3812_DRUMS			equ				0bdh
NOTEON                  =               20h

if	DOSV	eq	TRUE
SB_DSP_RESET            equ             06h
SB_DSP_STATUS           equ             0eh
SB_DSP_READ             equ             0ah
SB_DSP_WRITE            equ             0ch
SB_DSP_WRITESTATUS      equ             0ch
SB_OPL2PORT1            equ             08h
SB_OPL2PORT2            equ             09h
SB_OPL2MIXERPORT1       equ             04h
SB_OPL2MIXERPORT2       equ             05h
else
SB_DSP_RESET            equ             0600h
SB_DSP_STATUS           equ             0e00h
SB_DSP_READ             equ             0a00h
SB_DSP_WRITE            equ             0c00h
SB_DSP_WRITESTATUS      equ             0c00h
SB_OPL2PORT1            equ             0800h
SB_OPL2PORT2            equ             0900h
SB_OPL2MIXERPORT1       equ             0400h
SB_OPL2MIXERPORT2       equ             0500h
endif

;音色定義テーブル
OPL2TONE                struc
	banknum         dw              ?
	no              db              ?
	datofs          dw              ?
	datseg          dw              ?
			ends
MAXSOUND        =       256                             ; 最大音色定義可能数

;モジュレーションテーブル
MODTABLE        struc
	mod_flag        db              ?
	mod_sync        dw              ?
	mod_sync_cnt    dw              ?
	mod_depth       db              ?
	mod_speed       dw              ?
	mod_trace       dw              ?
			ends

MOD_STANDBY                     =               1
MOD_SYNC                        =               2
MOD_MAIN                        =               3
MOD_NOACTIVE            =               4

global          fnumber1:byte:MAXCHANNEL,fnumber2:byte:MAXCHANNEL
global          pitch:word:MAXCHANNEL
global          init_opl2sound:near
global          init_opl2buf:near
global          int_modulation:near
global          read_opl2reg:near
global          write_opl2reg:near,write_opl2mixreg:near
global          FBALG:byte:MAXCHANNEL,mastervol:byte,volumerevision:byte
global          volume_buf:byte:MAXCHANNEL,exp_buf:byte:MAXCHANNEL,velo_buf:byte:MAXCHANNEL
global          set_volume:near
global          tonedata_seg:word
global          soundtbl:OPL2TONE:MAXSOUND,soundtblmax:word,lfo:MODTABLE:MAXCHANNEL
global          set_voice:near
global          notestatus:byte:MAXCHANNEL
global          OPL2PORT1,OPL2PORT2:word,OPL2MIXER1,OPL2MIXER2:word
global          volumedown:byte
global          KSLTL:byte:MAXCHANNEL
global          CHTBL:byte,wa:near
global          outports:near

if      DEBUG   eq              TRUE
_out            macro   reg,data
			local   ff,kk
			pushf
			push    bx
			push    cx
			jmp             kk
	ff              db              ??filename,'.asm$'
	kk:
			mov             bx,offset ff
			mov             cx,offset $
			call    outports
			pop             cx
			pop             bx
			popf
			endm
else
_out            macro   reg,data
			out             reg,data
			endm
endif
