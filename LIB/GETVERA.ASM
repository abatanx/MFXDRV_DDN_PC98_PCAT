comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN ���䃉�C�u����
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// �h���C�o�[�ԍ��擾
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

mfxddn_get_driver_version_local	proc	buffer:dword
		public	mfxddn_get_driver_version_local
		push	es
		mov		bx,word ptr buffer
		mov		es,word ptr buffer+2
		mov		ah,04h
		int		DDNVECT
		pop		es
		mov		ax,cx
		mfxddn_errset	8
		ret
mfxddn_get_driver_version_local	endp

end