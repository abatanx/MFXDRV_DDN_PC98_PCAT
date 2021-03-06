/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// DRIVER ID のSPACE補正
*/

#include	<stdio.h>
#include	"mfxddn.h"

static	char	_nearpointer[256];

/*
// DRVID を補正
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
// FarをNearに変更する(Small Model)
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