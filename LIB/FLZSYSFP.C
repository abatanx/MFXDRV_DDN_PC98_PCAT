/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// 最適化されたデータを展開する(flz) 圧縮コード : FZ
*/

#include	<stdio.h>
#include	"mfxddn.h"

int ddn_flz_load_fp(char far *buf,FILE *fpr,long fsize)
{
	long size = 0;
	unsigned fs,p1,p2,p3,i,j,man,max;
	int c,min_n;
	unsigned char cc;

	min_n = fgetc(fpr);
	p2=0;
	size ++;
	while((c=fgetc(fpr))!=EOF){
		size++;
		if( size>fsize )break;
		if( p2>65510   )return(EOF);
		if(c!=min_n)*(buf+p2++)=c;
		else{
			c=fgetc(fpr);
			size++;
			if(c==0)*(buf+p2++)=min_n;
			else {
				max=(unsigned)c;
				man=(unsigned)fgetc(fpr);
				size++;
				for(i=0;i<=max;i++)*(buf+p2+i)=*(buf+p2-256+man+i);
				p2=p2+max;
			}
		}
	}
	return(NULL);
}
