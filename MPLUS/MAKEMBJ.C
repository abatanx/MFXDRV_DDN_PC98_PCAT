/*---------------------------------------------------------------------------
       MFXDRV/DDN system XMML3.00 compiler MPLUS(mfxc+) release 1.00
  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
 *---------------------------------------------------------------------------*/
//
// オブジェクトファイル作成
//
#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>
#include	<dos.h>
#include	<dir.h>
#include	<mfile.h>
#include	<io.h>
#include	"mplus.h"

#define		MMLBINFP	(0)
#define		MMLBINSIZE	(MAXTRACK*2)
#define		MMLBIN		(MAXTRACK*4)

static char *mplay_driver[256],*mplay_object[256];
int max_mplay=0;

void set_mplay(char *driver,char *object)
{
	if( max_mplay>255 )
	{
		erl(NULL,SYS|WNG);
		printf("優先処理バッファが不足しています。\n");
		return;
	}
	mplay_driver[max_mplay]=keepmem(strlen(driver+1));
	mplay_object[max_mplay]=keepmem(strlen(object+1));
	strcpy( mplay_driver[max_mplay],driver );
	strcpy( mplay_object[max_mplay],object );
	max_mplay++;
}

void makembj_header(MFILE *fp)
{
	char buf[1024];

	sprintf( buf,
		"XMML3.00 object - XMML3.00 compiler mPlus(mfxc+).exe ver.%1d.%02d%c\n"
		"copyright (c) 1991-94 by Interfair all rights reserved.\n"
		"\x1a%c",
		version_int,version_real,version_char,NULL
	);
	mwrite( buf,strlen(buf)+1,fp );
}

void makembj(MFILE *fp,char *objname)
{
	char *tmpdir,fname[MAXPATH],buf[256],filename[256];
	int i,j;
	long l,size;
	BFILE *fpr;

	tmpdir = getenv("TMP");
	if( !tmpdir )
	{
		sprintf(fname,TMPFILE);
	}
	else
	{
		strcpy(buf,tmpdir);
		cut_dirmark(buf);
		sprintf(fname,"%s\\"TMPFILE,buf);
	}

	mputc( 0x01,fp );						// オブジェクトstart
	mputs( objname,fp);
	mputc( NULL,fp );						// オブジェクト名書き出し
	mputw( timebase,fp );					// タイムベース書き出し

	for( i=0; i<32; i++)
	{
		if( trk[i].linkflag==LINK_INTERNAL )
		{
			mputc( 0x00,fp );					// とりあえず、このobject
			for( j=0; j<4; j++)
			{
				mputs( trk[i].chain[j].module ,fp );
				mputc( NULL,fp );
				mputc( trk[i].chain[j].channel,fp );
			}
			set_label( fp,MMLBINFP  +i+objects*MMLBIN,sizeof(long) );
			set_label( fp,MMLBINSIZE+i+objects*MMLBIN,sizeof(long) );
			mputw( 'NC',fp );
			mputw( NULL,fp );
		}
		else
		{
			mputc( 0x01,fp );
			mputs( trk[i].chain[0].module ,fp );
			mputc( NULL,fp );
			mputc( trk[i].chain[0].channel,fp );
		}
	}

	for( i=0; i<32; i++)
	{
		if( trk[i].linkflag==LINK_EXTERNAL )continue;
		if( i>=maxtrack )
		{
			set_label_value( MMLBINFP  +i+objects*MMLBIN,0 );
			set_label_value( MMLBINSIZE+i+objects*MMLBIN,0 );
			continue;
		}
		sprintf( filename,"%s.$%02d",fname,i );

		if( (fpr=bopen(filename))==NULL )
		{
			erl(NULL,SYS|ERR);
			printf("テンポラリファイル \'%s\' が読み込めません。\n",
				filename
			);
			exits(1);
		}
		size = tell(fpr->fd);
		set_label_value( MMLBINFP  +i+objects*MMLBIN,fp->fp);
		set_label_value( MMLBINSIZE+i+objects*MMLBIN,size  );

		for( l=0; l<size; l++)mputc( bgetc(fpr),fp );
		bclose(fpr);
	}
	printadt(root,fp);				// 音色バッファ書き出し
	mputw( 0xffff,fp );				// 音色終了
}

void makembs(char *filename)
{
	MFILE fp;
	BFILE *memor;
	char buf[1024];
	int i,c;

	struct date da;
	struct time ti;

	if( mopen(filename,&fp)==EOF )
	{
		erl(NULL,ERR|SYS);
		printf("\'%s\' が作成できません。\n",filename);
		exits(1);
	}
	sprintf( buf,
		"XMML3.00 source object - XMML3.00 compiler mPlus(mfxc+).exe ver.%1d.%02d%c\n"
		"copyright (c) 1991-94 by Interfair all rights reserved.\n"
		"\x1a%c",
		version_int,version_real,version_char,NULL
	);
	mwrite( buf,strlen(buf)+1,&fp );

	mputs( (char *)head.title,&fp );			mputc(NULL,&fp);
	mputs( (char *)head.composer,&fp );			mputc(NULL,&fp);
	mputs( (char *)head.arranger,&fp );			mputc(NULL,&fp);
	mputs( (char *)head.lyric,&fp );			mputc(NULL,&fp);
	mputs( (char *)head.artist,&fp );			mputc(NULL,&fp);
	mputs( (char *)head.copyright,&fp );		mputc(NULL,&fp);

	if( (memor=bopen(memofile))!=NULL )
	{
		while( (c=bgetc(memor))!=EOF )mputc( c,&fp );
		bclose(memor);
	}
	else 
	{
		mputs( (char *)"",&fp );
	}
	mputc(NULL,&fp);

	getdate( &da );
	gettime( &ti );
	
	mputc( da.da_year % 100,&fp);
	mputc( da.da_mon ,&fp );
	mputc( da.da_day ,&fp );
	mputc( ti.ti_hour,&fp );
	mputc( ti.ti_min ,&fp );
	mputc( ti.ti_sec ,&fp );

	for( i=0; i<max_mplay; i++)
	{
		mputc( 0x00,&fp );
		mputs( mplay_driver[i],&fp );
		mputc( NULL,&fp );
		mputs( mplay_object[i],&fp );
		mputc( NULL,&fp );
	}
	mputc( 0xff,&fp );

	mputs( "_main",&fp );
	mputc( NULL,&fp);

	mclose( &fp );
}
