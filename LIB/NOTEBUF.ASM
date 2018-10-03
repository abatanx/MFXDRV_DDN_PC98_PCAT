comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// ノートバッファ制御
//
// --- Caution ---
// ノートバッファを指定して、そこに現在keyonしているノートを記録します。
// 1トラック 128Byte必要です。なお、ノートバッファを使用するアプリケーション
// を終了させるときは mfxddn_rel_note_buffer で解放してください。しない場合
// 暴走の原因となります。
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

mfxddn_set_note_buffer	proc	track:word,buffer:dword
		public	mfxddn_set_note_buffer
		push	es
		mov		al,byte ptr track
		mov		bx,word ptr buffer
		mov		es,word ptr buffer+2
		mov		ah,1ah
		int		DDNVECT
		pop		es
		mfxddn_errset	8
		xor		ax,ax
		ret
mfxddn_set_note_buffer	endp

mfxddn_rel_note_buffer	proc	track:word
		public	mfxddn_rel_note_buffer
		mov		al,byte ptr track
		mov		ah,1bh
		int		DDNVECT
		mfxddn_errset	8
		xor		ax,ax
		ret
mfxddn_rel_note_buffer	endp

end
