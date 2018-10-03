/*---------------------------------------------------------------------------
       MFXDRV/DDN system XMML3.00 compiler MPLUS(mfxc+) release 1.00
  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
 *---------------------------------------------------------------------------*/
//
// オブジェクトコマンド処理
//
#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>
#include	<dos.h>
#include	<dir.h>
#include	<mfile.h>
#include	"mplus.h"

int obj(BFILE *fpr,char *objname)
{
	char buf[64],buf2[64],trkname[64],fname[64],trkfile[64];
	char *tmpdir;
	int i,j,ci,c;

	bstandard2( buf,63,fpr );
	if( stricmp(buf,"object") )
	{
		erl(fpr);
		printf(".%s という命令は使用できません。\n",buf);
		return FALSE;
	}
	bstandard2( objname,63,fpr );

	tmpdir = getenv("TMP");

	if( !tmpdir )
	{
		sprintf(fname,TMPFILE);
	}
	else
	{
		strcpy(buf2,tmpdir);
		cut_dirmark(buf2);
		sprintf(fname,"%s\\"TMPFILE,buf2);
	}

	for( i=0; i<MAXTRACK; i++)
	{
		trk[i].linkflag  = LINK_INTERNAL;
		trk[i].linktrack = 0;
		for( j=0; j<4; j++)
		{
			strcpy( trk[i].chain[j].module,"OFF" );
			trk[i].chain[j].channel = 0;
		}
	}

	maxtrack = 0;

	while( btop(fpr)!='{' )
	{
		bstandard2( trk[maxtrack].name,31,fpr );
		
		if( (c=bgetc(fpr))!='=' )
		{
			erl(fpr);
			printf("トラックの指定が不正です。\n");
			return FALSE;
		}
		ci = 0;
		buntilchar(fpr);
		for(;;)
		{
			bstandard3( trk[maxtrack].chain[ci].module,31,fpr );
			if( strcmp(trk[maxtrack].chain[ci].module,"*COND"  )!=NULL &&
				strcmp(trk[maxtrack].chain[ci].module,"*SOUND" )!=NULL &&
				strcmp(trk[maxtrack].chain[ci].module,"OFF"    )!=NULL )
			{
				if( trk[maxtrack].chain[ci].module[0]=='_' && ci!=0 )
				{
					erl(fpr);
					printf("\'_\' 外部オブジェクト参照の書式が不明です。\n");
					return FALSE;
				}

				if( bgetc(fpr)!='(' )
				{
					erl(fpr);
					printf("\'(\' がありません。\n");
					return FALSE;
				}
				buntilchar(fpr);
				bstandard2(buf,63,fpr);
				trk[maxtrack].chain[ci].channel = atoi(buf);
				if( bgetc(fpr)!=')' )
				{
					erl(fpr);
					printf("\')\' がありません。\n");
					return FALSE;
				}
				buntilchar(fpr);
			}
			c = bgetc(fpr);
			buntilchar(fpr);

			if( c==';' )break;
			else if( trk[maxtrack].chain[ci].module[0]=='_' )
			{
				erl(fpr);
				printf("\'_\' 外部オブジェクト参照のオブジェクト名は1つまでです。\n");
				return FALSE;
			}
			else if( c==',' )
			{
				if( ++ci>=4 )
				{
					erl(fpr);
					printf("音源指定は 4 つまでです。\n");
					return FALSE;
				}
			}
			else {
				erl(fpr);
				printf("音源の区切りが不明です。\n");
				return FALSE;
			}
		}

		if( trk[maxtrack].chain[ci].module[0]=='_' )
		{
			trk[maxtrack].linkflag  = LINK_EXTERNAL;
			trk[maxtrack].linktrack = trk[maxtrack].chain[0].channel;
		}

		sprintf(trkfile,"%s.$%02d",fname,maxtrack);
		if( mopen(trkfile,&fpw[maxtrack])==EOF )
		{
			printf("テンポラリファイルが作成できません。\n");
			exits(1);
		}

		if( ++maxtrack>=MAXTRACK )
		{
			erl(fpr);
			printf("トラック数がオーバーしています(MAX:%d)。\n",MAXTRACK);
			return FALSE;
		}
		
	}
	bnext(fpr);
	return TRUE;
}
