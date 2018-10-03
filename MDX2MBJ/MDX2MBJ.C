//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 SMF converter XMML object maker.
//                         MCV(tm) version 2.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
#include	<stdio.h>
#include	<stdlib.h>
#include	<alloc.h>
#include	<dos.h>
#include	<string.h>
#include	<dir.h>
#include	<io.h>
#include	<fcntl.h>
#include	<sys\stat.h>
#include	<mfile.h>
#include	<mylib.h>
#include	<process.h>
#include	"mcv.h"

#define		version_int		1
#define		version_real	00
#define		version_char	' '
#define		mem()			printf("	Available memory  :  %ldbytes.\n\n",coreleft())

#define		TMPFILE_F1		"m2mtch"
#define		TMPFILE_F2		"m2mtmp"
#define		MAX_LABEL		200
#define		CONDUCTOR		256

byte	*trace;

int main(int argc,char **argv)
{
	char	mbj[MAXPATH],mdx[MAXPATH];

	printf(
		"MDX to MBJ format converter Mdx2Mbj version %1d.%02d%c\n"
		"copyright (c) 1994 by ABA / T.Kobayashi and Interfair "
		"All Rights Reserved.\n\x1b[>5l",
		version_int,
		version_real,
		version_char
	);

	if( argc<=1 )
	{
		m2m_exit(EOF);
	}

	change_ext( *(argv+1),mbj,".mbj" );
	change_ext( *(argv+1),mdx,".mdx" );

	conv( mdx,mbj );

	return NULL;
}

void m2m_exit(int no)
{
	mem();
	exit(no);
}

int		pgetc( void )
{
	return (int)*(trace++);
}
word	pgetw( void )
{
	word a;
	a = *(trace)*256 | *(trace+1);
	return a;
}

void conv( char *mdx,char *mbj )
{
	FILE *fpr;
	byte *buffer;

	buffer = keep_highmemory(65500);
	if( (fpr=fopen(mdx,"rb"))==NULL )
	{
		printf("Can\'t open file \'%s\'.\n", mdx );
		m2m_exit(EOF);
	}
	fread( buffer,65500,1,fpr );
	fclose( fpr );

	trace = buffer;
	while( *(buffer++)!=NULL );

	