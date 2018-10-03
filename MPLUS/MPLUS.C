/*---------------------------------------------------------------------------
       MFXDRV/DDN system XMML3.00 compiler MPLUS(mfxc+) release 1.00
  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
 *---------------------------------------------------------------------------*/
//
// ���C���v���O����
//
#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>
#include	<dos.h>
#include	<dir.h>
#include	<process.h>
#include	<mfile.h>
#include	<alloc.h>
#include	<mylib.h>
#include	"mplus.h"

MUDHEADMSG	head;
TRACKINFO	trk[MAXTRACK];
int			maxtrack,objects;
MFILE		fpw[MAXTRACK];
int			errors,warnings,erdisp;
MACRO		*macro;
ADT			*root;
char		*m_arg[MAXARG],*v_arg[MAXARG],*work;
ISTACK		xifdef;
char		incdir[MAXPATH];
int			option[26];
char		*s_macs,*s_dist,*s_args,*s_mrgs,*memofile;

#define		mem()	printf("	Available memory  :  %ldbytes.\n\n",coreleft());

void exits2(int erc)
{
	char *tmpdir,fname[256],buf[256],filename[256];
	int i;

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

	if( option[OPT_E]==FALSE )
	{
		for( i=0; i<MAXTRACK; i++)
		{
			sprintf(filename,"%s.$%02d",fname,i);
			unlink(filename);
		}
		unlink(memofile);
	}
	else
	{
		printf("Not deleted for sound effect.\n");
	}
	exit(erc);
}

void exits(int erc)
{
	mem();
	exits2(erc);
}

void errchk(void)
{
	printf("	Fatal Error Messages: %d\n",errors  );
	printf("	Warning     Messages: %d\n\n",warnings);
	if( errors )
	{
		exits(1);
	}
}

void erl(BFILE *fp,int type)
{
	if( erdisp==FALSE )
	{
		fprintf(stdout,"\n");
		erdisp = TRUE;
	}

	if( type & SYS )
	{
		fputs("System ",stdout);
	}
	if( type & ERR )
	{
		fputs("Error:",stdout);
		errors++;
	}
	if( type & WNG )
	{
		fputs("Warning:",stdout);
		warnings++;
	}
	if(!(type&SYS))	fprintf(stdout,"%s(L%05d) ",fp->filename,fp->line);
	else			fprintf(stdout," ");
	fprintf(stderr,"\x1b[0K");

	if( errors>20 )
	{
		printf("�G���[���������܂��B�R���p�C���𒆒f���܂����B\n");
		errchk();
	}
}

void init_status(void)
{
	errors   = 0;
	warnings = 0;
	objects  = 0;
	erdisp   = 0;
	macro    = NULL;
	root     = NULL;
	xifdef.err_flag=FALSE;
}

char *keepmem(int size)
{
	char *mem;
	mem = (char *)keep_highmemory(size);
	if( mem==NULL )
	{
		erl(NULL,ERR|SYS);
		printf("�R���p�C���̂��߂̃������[������܂���B\n");
		exits(1);
	}
	return mem;
}

int main(int argc,char **argv)
{
	BFILE *fpr;
	MFILE mbjfpw;
	FILE *fp;
	int c;

	char
		*dr,*di,*fi,*ex,*foption,
		*mmdfile,*mbjfile,*mbsfile,*linker,*linkopt,
		*filename,*tmp,*tmdr,*tmdi,*buf1,*buf,*fargv[64];
	int i,l,fargc=0;
	
	linker = "ml.exe";

	for( i=0; i<MAXARG; i++)
	{
		m_arg[i] = (char *)malloc(MAXARGSIZE+1);
		v_arg[i] = (char *)malloc(MAXARGSIZE+1);
	}
	work    = keepmem(4096);
	dr      = keepmem(MAXDRIVE);
	di      = keepmem(MAXDIR);
	fi      = keepmem(MAXFILE);
	ex      = keepmem(MAXEXT);
	mmdfile = keepmem(MAXPATH);
	mbsfile = keepmem(MAXPATH);
	mbjfile = keepmem(MAXPATH);
	memofile= keepmem(MAXPATH);
	linkopt = keepmem(1024);
	filename= keepmem(MAXPATH);
	buf1    = keepmem(256);
	buf     = keepmem(1024);
	s_args = (char *)malloc(4096);
	s_mrgs = (char *)malloc(4096);
	s_dist = (char *)malloc(4096);
	s_macs = (char *)malloc(512);
	if( !s_macs || !s_dist || !s_args || !s_mrgs )
	{
		erl(NULL,ERR|SYS);
		printf("�R���p�C���̂��߂̃������[������܂���B\n");
		exits(1);
	}

	strcpy( linkopt,"" );
	strcpy( incdir ,"" );
	for( i=OPT_A; i<=OPT_Z; i++)option[i] = FALSE;

	printf(
		"music driver MFXDDN XMML3.00 compiler mPlus(mfxc+) "
		"version %1d.%02d%c\n"
		"copyright (c) 1994,95 by ABA / T.Kobayashi and Interfair"
		" All Rights Reserved.\n",
		version_int,version_real,version_char
	);
	if( argc<=1 )
	{
		puts(
			"Syntax ;\n"
			"         mplus.exe [filename] <option 1>.....<option n>....\n"
			"Option ;\n"
			"         *.mbj       �ꏏ�Ƀ����J�ɓn���āALINK���܂�\n"
			"         -!(linker)  �����J���w�肵�܂�(DEF: -!ml.exe )\n"
			"         -l(cmd)     �����J�ɃI�v�V�����������n���܂�\n"
			"         -c          �R���p�C���݂̂��s���܂�\n"
			"         -i(dir)     include �f�B���N�g����ݒ肵�܂�\n"
			"         -d          system debug mode1\n"
			"         -x          system debug mode2\n"
		);
		exits(1);
	}
	if( (fp=fopen("mplus.cfg","r"))==NULL )
	{
		clearerr(fp);
	}
	else
	{
		while( fgets(buf,255,fp)!=NULL )
		{
			cut_space(buf);
			l = strlen(buf);
			if( !l )continue;
			foption=keepmem(l+1);
			strcpy(foption,buf);
			fargv[fargc++] = foption;
			if( fargc>=32 )
			{
				erl(NULL,SYS|WNG);
				printf("\'mplus.cfg\' �̃p�����[�^����32���z���܂����B\n");
				break;
			}
		}
		fclose(fp);
	}
	
	strcpy( filename,"" );
	for( i=1; i<argc ; i++)fargv[fargc++] = argv[i];
	for( i=0; i<fargc; i++)
	{
		if( *fargv[i]=='/' || *fargv[i]=='-' ){
			switch( *(fargv[i]+1) ){
					/* Make only usual object */
				case 'c':
				case 'C':
					printf("-- �R���p�C���̂ݍs���܂�. --\n");
					option[ OPT_C ] = TRUE;
					break;
					/* ���ʉ� */
				case 'e':
				case 'E':
					printf("-- �e���|�����t�@�C�����폜���܂��� --\n");
					option[ OPT_E ] = TRUE;
					break;
					/* ��񂩂ɂ킽�� */
				case 'L':
				case 'l':
					sprintf( buf," -%s",fargv[i]+2 );
					strcat( linkopt,buf );
					break;
				case 'I':
				case 'i':
					strcpy( incdir,fargv[i]+2 );
					add_dirmark(incdir);
					break;
				case 'D':
				case 'd':
					printf("-- �R���p�C���f�o�b�O���[�h. --\n");
					option[ OPT_D ] = TRUE;
					break;
				case 'M':
				case 'm':
					printf("-- �}�N���`�F�b�N���܁`����(��������) --\n");
					option[ OPT_M ] = TRUE;
					break;
				case 'X':
				case 'x':
					printf("-- �m�[�g�R���p�C���f�o�b�O���[�h. --\n");
					option[ OPT_X ] = TRUE;
					break;
				case '!':
					printf("-- �����J�w�� --\n");
					linker = fargv[i]+2;
					break;
				default:
					printf("Illigal Option : -%c\n",*(*(fargv+i)+1) );
					break;
			}
		}
		else {
			fnsplit( fargv[i],dr,di,fi,ex );
			if( stricmp(ex,".mbj")==NULL ){
				sprintf( buf," %s",*(fargv+i));
				strcat (linkopt,buf);
			}
			else
				strcpy(filename,strlwr(fargv[i]));
		}
	}

	if( !filename[0] )
	{
		printf("No target file.\n");
		exits(1);
	}
	fnsplit( filename,dr,di,fi,ex     );

	tmp = getenv("TMP");
	if( tmp==NULL || option[ OPT_C ]==TRUE )
	{
		tmdr = "";
		tmdi = "";
	}
	else
	{
		strcpy(buf1,tmp);
		cut_dirmark(buf1);
		tmdr = buf1;
		tmdi = "\\";
	}

	fnmerge( mmdfile ,dr  ,di  ,fi,".mmd" );
	fnmerge( mbsfile ,tmdr,tmdi,fi,".mbs" );
	fnmerge( mbjfile ,tmdr,tmdi,fi,".mbj" );
	fnmerge(memofile ,tmdr,tmdi,MEMOFILE,".$$$" );

	if( mopen(mbjfile,&mbjfpw)==EOF )
	{
		erl(NULL,ERR|SYS);
		printf("\'%s\' ���쐬�ł��܂���B\n",mbjfile);
		exits(1);
	}
	init_status();
	init_label();
	if( option[OPT_E]==FALSE )makembj_header(&mbjfpw);

	printf("%s:\n",mmdfile);
	compile( mmdfile,&mbjfpw );
	errchk();

	mputc(0,&mbjfpw);
	mclose(&mbjfpw);
	if( option[OPT_E]==FALSE )
	{
		write_label(mbjfile);
		makembs( mbsfile );
	}
	else
	{
		unlink(mbjfile);
		unlink(memofile);
	}

	if( option[OPT_C]!=TRUE && option[OPT_E]!=TRUE )
	{
		mem();
		if( searchpath(linker)==NULL ){
			erl(NULL,SYS|WNG);
			printf("Can\'t find \'%s\'\n",linker);
			return NULL;
		}
		spawnlp( P_WAIT,linker,linker,mbsfile,mbjfile,linkopt,NULL );
		unlink( mbsfile );
		unlink( mbjfile );
		unlink( memofile);
		exits2(NULL);
	}
	exits(NULL);
	return NULL;
}
