/*---------------------------------------------------------------------------
       MFXDRV/DDN system XMML3.00 compiler MPLUS(mfxc+) release 1.00
  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
 *---------------------------------------------------------------------------*/
//
// �t�@�C������
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
// �t�@�C���̓ǂݏo���I�[�v��
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
// �t�@�C���̓ǂݏo���I�[�v��2
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

// �t�@�C���̃N���[�Y
void bclose(BFILE *fp)
{
	if( fp->type==BFILE_FILE )
	{
		free((unsigned char *)fp->buf);
		close(fp->fd);
	}
	free((unsigned char *)fp);
}

// �ꕶ���ǂݏo��(fp�̍X�V�Ȃ�)
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

// �ꕶ���i��
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

// �ꕶ���ǂݏo��(fp�̍X�V�Ȃ�)
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
					printf("/* ... */ ���t�@�C���G���h���͂���ł��܂��B\n");
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

// �ꕶ���ǂݏo���߂���
int bgetc(BFILE *fp)
{
	int c;
	c = btop(fp);
	bnext(fp);
	fp->chr = NULL;
	return c;
}

// �ꕶ���ǂݏo�� & buntilchar
int bgetc2(BFILE *fp)
{
	int c;
	buntilchar(fp);
	c = bgetc(fp);
	buntilchar(fp);
	return c;
}

// �P���[�h�ǂݏo��
word bgetw(BFILE *fp)
{
	word retc;
	retc  = bgetc(fp);
	retc |= bgetc(fp)*256;
	return retc;
}

// �P�u���b�N�ǂݏo��
int bread(void *buf,unsigned size,BFILE *fp)
{
	unsigned char *data;
	unsigned i;
	data = (unsigned char *)buf;
	for( i=0 ; i<size ; i++ )*(data++) = bgetc(fp);
	return NULL;
}

// �w�蕶���܂œǂݏo��
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

// �w�蕶���܂œǂݏo��
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

// ���K�񕶎��̓ǂݏo��
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

// ���K�񕶎��̓ǂݏo�� & buntilchar
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

// ���K�񕶎��̓ǂݏo�� & buntilchar & *�t��
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

// �����̓ǂݏo�� & buntilchar
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

// �����̓ǂݏo�� & buntilchar
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
				printf("16�i���\�L���ُ�ł�(%s)�B\n",buf);
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
				printf("10�i���\�L���ُ�ł�(%s)�B\n",buf);
				return 0;
			}
			data++;
		}
		x = atoi((char *)buf);
	}
	buntilchar(fp);

	return x;
}

// �X�y�[�X �y�� tab�̃X�L�b�v
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

// ���^�[���܂œǂݏo��
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

// ���^�[���܂ŃX�L�b�v
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

// �X�y�[�X�Ⴕ���̓��^�[���܂œǂݏo��
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

// ��������������܂ŃX�L�b�v
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