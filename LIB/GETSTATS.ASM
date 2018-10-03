comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// 演奏ステータス取得各種
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

; 演奏状況の取得
mfxddn_get_playstatus	proc
		public	mfxddn_get_playstatus
		mov		ah,0ah
		int		DDNVECT
		mfxddn_errset	8
		ret
mfxddn_get_playstatus	endp

; タイムベースの取得
mfxddn_get_timebase	proc
		public	mfxddn_get_timebase
		call	mfxddn_get_playstatus
		mov		ax,bx
		ret
mfxddn_get_timebase	endp

; テンポの取得
mfxddn_get_tempo	proc
		public	mfxddn_get_tempo
		call	mfxddn_get_playstatus
		mov		ax,cx
		ret
mfxddn_get_tempo	endp

; マスターボリュームの取得
mfxddn_get_mastervolume	proc
		public	mfxddn_get_mastervolume
		call	mfxddn_get_playstatus
		mov		ax,dx
		ret
mfxddn_get_mastervolume	endp

end
