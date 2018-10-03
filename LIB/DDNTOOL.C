/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN ���䃉�C�u����
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// DRIVER ID ��SPACE�␳
*/

#include	<stdio.h>
#include	"mfxddn.h"

static	char	_nearpointer[256];

/*
// DRVID ��␳
*/
void mfxddn_add_space(char *buf,char *drvid)
{
	int i;
	for( i=0; i<=14 ; i++ )buf[ i ] = ' ';
	buf[ 15 ] = '\0';
	
	i = 0;
	while( *drvid!=NULL )buf[i++] = *( drvid++ );
}

/*
// Far��Near�ɕύX����(Small Model)
*/
char *ddn_far2near(char far *data)
{
	int i;
	char *nearpointer = _nearpointer;
	if( data==NULL )nearpointer = NULL;
	else
	{
		for( i=0; i<255 && *data!=NULL ; i++ )
		{
			nearpointer[i] = *(data++);
		}
		nearpointer[i]='\0';
	}
	return nearpointer;
}
