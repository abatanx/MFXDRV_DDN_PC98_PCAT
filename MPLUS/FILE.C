/*---------------------------------------------------------------------------
       MFXDRV/DDN system XMML3.00 compiler MPLUS(mfxc+) release 1.00
  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
 *---------------------------------------------------------------------------*/
//
// ファイル制御
//

#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>
#include	<io.h>
#include	<fcntl.h>
#include	<mylib.h>
#include	<alloc.h>
#include	"mplus.h"

int bnumflag,bnum16flag;

//
// ファイルの読み出しオープン
//
BFILE *bopen(char *filename)
{
	BFILE *fp;
	
	if( (fp=(BFILE *)malloc(sizeof(BFILE)))==NULL )return NULL;

	strcpy( fp->filename,filename );

	if( (fp->fd=open(filename,O_BINARY|O_RDONLY))==EOF )return NULL;
	if( (fp->buf=(unsigned char *)malloc(BFILE_BUFSIZE+100))==NULL ){
		free((unsigned char *)fp);
		return NULL;
	}
	fp->size  = filelength(fp->fd);
	fp->binfp = 0;
	fp->fp    = 0;
	fp->chr   = NULL;
	fp->line  = 1;
	fp->type  = BFILE_FILE;
	read( fp->fd,fp->buf,BFILE_BUFSIZE );
	return fp;
}

//
// ファイルの読み出しオープン2
//
int bopen2(BFILE *fp,char *filename,char *buffer,int line,int size)
{
	fp->size  = size;
	fp->binfp = 0;
	fp->fp    = 0;
	fp->chr   = NULL;
	fp->line  = line;
	fp->buf   = (byte *)buffer;
	fp->type  = BFILE_MEMORY;
	strcpy( fp->filename,filename );
	return NULL;
}

// ファイルのクローズ
void bclose(BFILE *fp)
{
	if( fp->type==BFILE_FILE )
	{
		free((unsigned char *)fp->buf);
		close(fp->fd);
	}
	free((unsigned char *)fp);
}

// 一文字読み出し(fpの更新なし)
int btopmain(BFILE *fp)
{
	int c;
	if( fp->fp+(long)fp->binfp >= fp->size ) c = EOF;
	else {
		c = *(fp->buf+fp->binfp);
	}
	if( c=='\n' )fp->chr = '\n';
	return c;
}

// 一文字進む
void bnext(BFILE *fp)
{
	if( fp->chr=='\n' )
	{
		fp->line++;
		fp->chr = NULL;
	}
	fp->binfp++;
	if( fp->binfp>=BFILE_BUFSIZE && fp->type==BFILE_FILE ){
		fp->fp    += BFILE_BUFSIZE;
		fp->binfp  = 0;
		read( fp->fd,fp->buf,BFILE_BUFSIZE );
	}
}

// 一文字読み出し(fpの更新なし)
int btop(BFILE *fp)
{
	int c;
	BFILE fp2;

	c = btopmain(fp);
	if( c=='/' )
	{
		fp2 = *fp;
		bnext(&fp2);

		if( btopmain(&fp2)=='*' )
		{
			bnext(&fp2);
			while(1)
			{
				c = btopmain(&fp2);
				bnext(&fp2);

				if( c==EOF )
				{
					erl(&fp2,ERR);
					printf("/* ... */ がファイルエンドをはさんでいます。\n");
					break;
				}
				else if( c=='*' )
				{
					c = btopmain(&fp2);
					if( c=='/' )
					{
						bnext(&fp2);
						c = btopmain(&fp2);
						break;
					}
				}
			}
			*fp = fp2;
		}
	}
	return c;
}

// 一文字読み出しめいん
int bgetc(BFILE *fp)
{
	int c;
	c = btop(fp);
	bnext(fp);
	fp->chr = NULL;
	return c;
}

// 一文字読み出し & buntilchar
int bgetc2(BFILE *fp)
{
	int c;
	buntilchar(fp);
	c = bgetc(fp);
	buntilchar(fp);
	return c;
}

// １ワード読み出し
word bgetw(BFILE *fp)
{
	word retc;
	retc  = bgetc(fp);
	retc |= bgetc(fp)*256;
	return retc;
}

// １ブロック読み出し
int bread(void *buf,unsigned size,BFILE *fp)
{
	unsigned char *data;
	unsigned i;
	data = (unsigned char *)buf;
	for( i=0 ; i<size ; i++ )*(data++) = bgetc(fp);
	return NULL;
}

// 指定文字まで読み出し
int breadchar(void *buf,unsigned size,unsigned char c,BFILE *fp)
{
	unsigned char *data;
	unsigned i;
	int angle=0;
	data = (unsigned char *)buf;
	for( i=0 ; i<size-1 ; i++ ){
		*data = bgetc(fp);
		if( *data=='\"' )angle=1-angle;
		if( (*data==c && !angle) || *data==0xff )break;
		data++;
	}
	*data=NULL;
	return NULL;
}

// 指定文字まで読み出し
int breadchar2(void *buf,unsigned size,unsigned char c1,unsigned char c2,BFILE *fp)
{
	unsigned char *data;
	unsigned i;
	data = (unsigned char *)buf;
	for( i=0 ; i<size-1 ; i++ ){
		*data = btop(fp);
		if( *data==c1 || *data==c2 || *data==0xff )break;
		bnext(fp);
		data++;
	}
	*data=NULL;
	return NULL;
}

// 正規列文字の読み出し
int bstandard(void *buf,unsigned size,BFILE *fp)
{
	unsigned char *data;
	unsigned i;
	data = (unsigned char *)buf;
	for( i=0 ; i<size ; i++ ){
		*data = btop(fp);
		if( (*data<'0' || *data>'9') && (*data<'a' || *data>'z') &&
			(*data<'A' || *data>'Z') && *data!='_' )break;
		data++;
		bnext(fp);
	}
	*data=NULL;
	return NULL;
}

// 正規列文字の読み出し & buntilchar
int bstandard2(void *buf,unsigned size,BFILE *fp)
{
	unsigned char *data;
	unsigned i;
	data = (unsigned char *)buf;
	for( i=0 ; i<size ; i++ ){
		*data = btop(fp);
		if( (*data<'0' || *data>'9') && (*data<'a' || *data>'z') &&
			(*data<'A' || *data>'Z') && *data!='_' )break;
		data++;
		bnext(fp);
	}
	*data=NULL;
	buntilchar(fp);

	return NULL;
}

// 正規列文字の読み出し & buntilchar & *付き
int bstandard3(void *buf,unsigned size,BFILE *fp)
{
	unsigned char *data;
	unsigned i;
	data = (unsigned char *)buf;
	for( i=0 ; i<size ; i++ ){
		*data = btop(fp);
		if( (*data<'0' || *data>'9') && (*data<'a' || *data>'z') &&
			(*data<'A' || *data>'Z') && *data!='_' && *data!='*' )break;
		data++;
		bnext(fp);
	}
	*data=NULL;
	buntilchar(fp);

	return NULL;
}

// 数字の読み出し & buntilchar
int bnumber(BFILE *fp)
{
	unsigned char *data,buf[256];
	unsigned i,x;

	bnumflag = FALSE;
	data = buf;
	for( i=0 ; i<255 ; i++ ){
		*data = btop(fp);
		if( *data<'0' || *data>'9' )break;
		data++;
		bnext(fp);
		bnumflag = TRUE;
	}
	*data=NULL;
	buntilchar(fp);
	x = atoi((char *)buf);

	return x;
}

// 数字の読み出し & buntilchar
int bnumber16(BFILE *fp)
{
	unsigned char *data,buf[256];
	unsigned i,x;

	bnum16flag = FALSE;

	data = buf;
	for( i=0 ; i<255 ; i++ ){
		*data = btop(fp);
		if( (*data<'0' || *data>'9') &&
			(*data<'a' || *data>'f') &&
			(*data<'A' || *data>'F') && *data!='x' && *data!='X' )break;
		data++;
		bnext(fp);
		bnum16flag = TRUE;
	}
	*data=NULL;
	if( buf[0]=='0' && (buf[1]=='x' || buf[1]=='X') )
	{
		data = buf+2;
		while( *data!=NULL )
		{
			if( *data=='x' || *data=='X' )
			{
				erl(fp,ERR);
				printf("16進数表記が異常です(%s)。\n",buf);
				return 0;
			}
			data++;
		}
		sscanf((char *)(buf+2),"%x",&x);
	}
	else
	{
		data = buf;
		while( *data!=NULL )
		{
			if( *data<'0' || *data>'9' )
			{
				erl(fp,ERR);
				printf("10進数表記が異常です(%s)。\n",buf);
				return 0;
			}
			data++;
		}
		x = atoi((char *)buf);
	}
	buntilchar(fp);

	return x;
}

// スペース 及び tabのスキップ
int bskipspace(BFILE *fp)
{
	int c;
	for(;;)
	{
		c = btop(fp);
		if( c==' ' || c==0x09 ){
			bnext(fp);
			continue;
		}
		break;
	}
	return NULL;
}

// リターンまで読み出し
int bgets(void *buf,unsigned size,BFILE *fp)
{
	unsigned char *data;
	unsigned i;
	data = (unsigned char *)buf;
	for( i=0 ; i<size ; i++ ){
		*data=bgetc(fp);
		if( *data=='\n' || *data=='\r' || *data==0xff )break;
		data++;
	}
	*data=NULL;
	return NULL;
}

// リターンまでスキップ
int buntilreturn(BFILE *fp)
{
	int c;
	for(;;)
	{
		c = bgetc(fp);
		if( c=='\n' || c=='\r' || c==EOF )break;
	}
	return NULL;
}

// スペース若しくはリターンまで読み出し
int bgetspace(void *buf,unsigned size,BFILE *fp)
{
	unsigned char *data;
	unsigned i;
	data = (unsigned char *)buf;
	for( i=0 ; i<size ; i++ ){
		*data=bgetc(fp);
		if(	*data=='\n' || *data=='\r' || *data==' ' ||
			*data=='\t' || *data==0xff )break;
		data++;
	}
	*data=NULL;
	return NULL;
}

// 何か文字が来るまでスキップ
int buntilchar(BFILE *fp)
{
	int c;
	unsigned char *data;
	for(;;)
	{
		c = btop(fp);
		if( c==EOF )break;
		if( c<=' ' )
			bnext(fp);
		else
			break;
	}
	return NULL;
}

