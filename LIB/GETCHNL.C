/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN ���䃉�C�u����
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
*/

#include	<stdio.h>
#include	"mfxddn.h"

/*
// �g�p�\�`�����l�����擾
*/
int mfxddn_get_driver_canusech(char *drvid)
{
	char buf[256];
	if( MFXDDN_Initialize==EOF ){
		mfxddn_errset(DDN_NOTINSTALLED);
		return EOF;
	}
	mfxddn_add_space( buf,drvid );
	return mfxddn_get_canuse_channel_local((char far *)buf);
}
