/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 制御ライブラリ
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
//
// 最適化されたデータを展開する(flz) 圧縮コード : FZ
// master.lib 対応版
*/

#include	<stdio.h>
#include	<master.h>
#include	"mfxddn.h"

int ddn_flz_load_fp_mtlib(char far *buf,long fsize)
{
	long size = 0;
	unsigned fs,p1,p2,p3,i,j,man,max;
	int c,min_n;
	unsigned char cc;

	min_n = file_getc();
	p2=0;
	size ++;
	while((c=file_getc())!=EOF){
		size++;
		if( size>fsize )break;
		if( p2>65510   )return(EOF);
		if(c!=min_n)*(buf+p2++)=c;
		else{
			c=file_getc();
			size++;
			if(c==0)*(buf+p2++)=min_n;
			else {
				max=(unsigned)c;
				man=(unsigned)file_getc();
				size++;
				for(i=0;i<=max;i++)*(buf+p2+i)=*(buf+p2-256+man+i);
				p2=p2+max;
			}
		}
	}
	return(NULL);
}
