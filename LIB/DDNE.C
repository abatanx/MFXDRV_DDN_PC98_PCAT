/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN ���䃉�C�u����
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// �G���[���b�Z�[�W�n
*/
#include	<stdio.h>
#include	"mfxddn.h"

static	char *errmsg[]={
	"mfxdrv/ddn ��Install����Ă��܂���B",
	"�ȃf�[�^�̂��߂̃������[������܂���B",
	"�ȃf�[�^�̃t�@�C����������܂���B",
	"mud �t�@�C���ł͂���܂���B",
	"mud�t�@�C���̃t�H�[�}�b�g���Ⴂ�܂��B",
	"����driver �� Install����Ă��܂���B",
	"mud �t�@�C�����傫�����܂��B",
	"���t�����B",
	"���s�����B",
	"���s���s�B"
};

extern	int mfxddn_err;

char *mfxddn_errmsg(void)
{
	return errmsg[mfxddn_err];
}
