;==============================================================================
; MFXDDN sound driver module
;						YAMAHA YM2203 FM(OPN) driver
;  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
;==============================================================================

DRVIDNUM	equ		0008h				; DRV-ID number
ver_int		equ		0
ver_real	equ		80
ver_char	equ		' '

;
; YM-2203 レジスタマップ定義
;

YM2203_NOTE		equ		28h
YM2203_DT1ML1	equ		30h
YM2203_DT3ML3	equ		34h
YM2203_DT2ML2	equ		38h
YM2203_DT4ML4	equ		3ch
YM2203_TL1		equ		40h
YM2203_TL3		equ		44h
YM2203_TL2		equ		48h
YM2203_TL4		equ		4Ch
YM2203_KS1AR1	equ		50h
YM2203_KS3AR3	equ		54h
YM2203_KS2AR2	equ		58h
YM2203_KS4AR4	equ		5ch
YM2203_DR1		equ		60h
YM2203_DR3		equ		64h
YM2203_DR2		equ		68h
YM2203_DR4		equ		6ch
YM2203_SR1		equ		70h
YM2203_SR3		equ		74h
YM2203_SR2		equ		78h
YM2203_SR4		equ		7ch
YM2203_SL1RR1	equ		80h
YM2203_SL3RR3	equ		84h
YM2203_SL2RR2	equ		88h
YM2203_SL4RR4	equ		8ch
YM2203_FNUM1	equ		0a0h
YM2203_FNUM2	equ		0a4h
YM2203_BLOCK	equ		0a4h
YM2203_CH3FNUM1	equ		0a8h
YM2203_CH3FNUM2	equ		0ach
YM2203_CH3BLOCK	equ		0ach
YM2203_FBALG	equ		0b0h

;音色定義テーブル
OPNTONE		struc
	banknum		dw		?
	no			db		?
	datofs		dw		?
	datseg		dw		?
			ends
MAXSOUND	=	256				; 最大音色定義可能数

;モジュレーションテーブル
MODTABLE	struc
	mod_flag		db		?
	mod_sync		dw		?
	mod_sync_cnt	dw		?
	mod_depth		db		?
	mod_speed		dw		?
	mod_trace		dw		?
			ends

MOD_STANDBY			=		1
MOD_SYNC			=		2
MOD_MAIN			=		3
MOD_NOACTIVE		=		4

global		fnumber1:byte:3,fnumber2:byte:3
global		init_opnsound:near
global		init_opnbuf:near
global		int_modulation:near
global		read_opnreg:near
global		write_opnreg:near
global		FBALG:byte:3,mastervol:byte,volumerevision:byte
global		volume_buf:byte:3,exp_buf:byte:3,velo_buf:byte:3
global		set_volume:near
global		tonedata_seg:word
global		soundtbl:OPNTONE:MAXSOUND,soundtblmax:word,lfo:MODTABLE:3
global		set_voice:near
global		notestatus:byte:3
global		OPNPORT1,OPNPORT2:word
global		volumedown:byte
