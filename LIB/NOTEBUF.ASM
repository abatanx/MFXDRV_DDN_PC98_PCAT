comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN ���䃉�C�u����
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// �m�[�g�o�b�t�@����
//
// --- Caution ---
// �m�[�g�o�b�t�@���w�肵�āA�����Ɍ���keyon���Ă���m�[�g���L�^���܂��B
// 1�g���b�N 128Byte�K�v�ł��B�Ȃ��A�m�[�g�o�b�t�@���g�p����A�v���P�[�V����
// ���I��������Ƃ��� mfxddn_rel_note_buffer �ŉ�����Ă��������B���Ȃ��ꍇ
// �\���̌����ƂȂ�܂��B
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