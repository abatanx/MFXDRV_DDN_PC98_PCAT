comment~
//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN ���䃉�C�u����
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// �������u���b�N�̏풓
//
~
include		ddnmodel.inc
include		ddndef.inc

		.code

ddn_stay_memory	proc	buffer:dword
		public	ddn_stay_memory
		push	es
		mov		ax,word ptr buffer+2
		push	ax
		dec		ax
		mov		es,ax
		pop		ax
		mov		es:[1],ax
		pop		es
		mov		ax,NULL
		ret
ddn_stay_memory	endp

end
