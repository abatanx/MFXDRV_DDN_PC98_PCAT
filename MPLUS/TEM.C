/*---------------------------------------------------------------------------
       MFXDRV/DDN system XMML3.00 compiler MPLUS(mfxc+) release 1.00
  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
 *---------------------------------------------------------------------------*/
//
// # �R�}���h����
//
#include	<stdio.h>
#include	<stdlib.h>
#include	<io.h>
#include	<string.h>
#include	<dos.h>
#include	<dir.h>
#include	<alloc.h>
#include	<mylib.h>
#include	"mplus.h"

extern		char	incdir[];
extern		char	*s_macs,*s_dist,*s_args,*s_mrgs;
static		int		memlevel=0;

void encode_macro_argument(char *,char *,char *,char *,BFILE *,char *);

// �^�C�g���ݒ�
void title(BFILE *fpr)
{
	bgets(head.title,255,fpr);
}
// ��ȎҐݒ�
void composer(BFILE *fpr)
{
	bgets(head.composer,255,fpr);
}
// �ҋȎҐݒ�
void arranger(BFILE *fpr)
{
	bgets(head.arranger,255,fpr);
}
// �쎌�Ґݒ�
void lyric(BFILE *fpr)
{
	bgets(head.lyric,255,fpr);
}
// �A�[�e�B�X�g���ݒ�
void artist(BFILE *fpr)
{
	bgets(head.artist,255,fpr);
}
// �v���O���}���ݒ�
void programmer(BFILE *fpr)
{
	bgets(head.programmer,255,fpr);
}
// �R�s�[���C�g�ݒ�
void copyright(BFILE *fpr)
{
	bgets(head.copyright,255,fpr);
}

// �C���N���[�h����
void include(BFILE *fpr,MFILE *fp)
{
	char buf[64],file[128];
	bgets(buf,63,fpr);
	if( access(buf,0)==NULL )
	{
		strcpy(file,buf);
	}
	else
	{
		strcpy(file,incdir);
		strcat(file,buf);
	}
	preprocessor(file,fp);
}

// �D��I�u�W�F�N�g�w��
void precede(BFILE *fpr)
{
	char driver[64],object[64];
	bgetspace(driver,63,fpr);
	bskipspace(fpr);
	bgetspace(object,63,fpr);
	set_mplay(driver,object);
}

// ���b�Z�[�W�\��
void cmes(BFILE *fpr)
{
	char buf[256];
	bgets( buf,255,fpr );
//	erl(fpr,NULL);
	printf("\n%s\n",buf);
}

// IFDEF����
void set_ifdef(BFILE *fpr)
{
	char	buf[64];
	bgets(buf,63,fpr);
	
	if( xifdef.stack_pointer>0 )
	{
		if( xifdef.top()==FALSE )
		{
			xifdef.push(FALSE);
			return;
		}
	}
	if( get_define(buf)!=NULL )
	{
		xifdef.push(TRUE);
	}
	else
		xifdef.push(FALSE);
}
// IFNDEF����
void set_ifndef(BFILE *fpr)
{
	char	buf[64];
	bgets(buf,63,fpr);

	if( xifdef.stack_pointer>0 )
	{
		if( xifdef.top()==FALSE )
		{
			xifdef.push(FALSE);
			return;
		}
	}
	if( get_define(buf)==NULL )
	{
		xifdef.push(TRUE);
	}
	else
		xifdef.push(FALSE);
}
// ELSE����
void set_else(void)
{
	int x;
	x = xifdef.pop();
	if( xifdef.stack_pointer>0 )
	{
		if( xifdef.top()==FALSE )
		{
			xifdef.push(FALSE);
			return;
		}
	}
	if( x==TRUE )	xifdef.push(FALSE);
	else			xifdef.push(TRUE);
}
// ELSEIF ����
void set_elseif(BFILE *fpr)
{
	int x;
	char	buf[64];
	bgets(buf,63,fpr);
	x = xifdef.pop();
	
	if( xifdef.stack_pointer>0 )
	{
		if( xifdef.top()==FALSE )
		{
			xifdef.push(FALSE);
			return;
		}
	}
	if( x==FALSE )
	{
		if( get_define(buf)!=NULL )
		{
			xifdef.push(TRUE);
			return;
		}
	}
	xifdef.push(FALSE);
}
// ENDIF����
void set_endif()
{
	xifdef.pop();
}

// �^�C���x�[�X����
void chgtimebase(BFILE *fpr)
{
	timebase = bnumber(fpr);
	if( timebase<24 )
	{
		erl(fpr,WNG);
		printf("�^�C���x�[�X�l�� 24 ��������Ă��܂��B\n");
	}
}

// �g�����X�|�[�Y����
void chgtranspose(BFILE *fpr)
{
	char buf[64];
	bgetspace(buf,63,fpr);
	if( !strcmp(buf,"up") || !strcmp(buf,"+") )transpose++;
	else if( !strcmp(buf,"down") || !strcmp(buf,"-") )transpose--;
	else transpose=atoi(buf);
}

// �}�N������
// �}�N�������`�F�b�N
int check_define(char *name)
{
	MACRO	*trace;
	trace = macro;
	while( trace!=NULL )
	{
		if( !strcmp(trace->source,name) )return TRUE;
		trace = trace->next;
	}
	return FALSE;
}

// �}�N�����o��
char *get_define(char *name)
{
	MACRO	*trace;
	trace = macro;
	while( trace!=NULL )
	{
		if( !strcmp(trace->source,name) )return trace->distnation;
		trace = trace->next;
	}
	return NULL;
}

// �}�N�����o��
char *get_define2(char *name)
{
	MACRO	*trace;
	trace = macro;
	while( trace!=NULL )
	{
		if( !strcmp(trace->source,name) )return trace->argument;
		trace = trace->next;
	}
	return NULL;
}

// �}�N���f�R�[�_
void macro_decoder(char *buffer,char *wrtbuffer,BFILE *fpr)
{
	int angle,wrtp,macp;
	char *encbuf;
	char *macname;
	wrtbuffer[0] = NULL;
	wrtp = 0;
	macp = 0;
	angle = 0;
	while( *buffer!=NULL )
	{
		switch( *buffer )
		{
			case '\"':
				angle = 1-angle;
				break;
			case '(':
				wrtbuffer[wrtp] = NULL;
				encbuf = keepmem(4096);
				macro_decorder_main(buffer,encbuf);
				strcat(wrtbuffer,encbuf);
				free_memory(encbuf);
				wrtp = strlen(wrtbuffer);
				break;



// �}�N���o�b�t�@��`(���C��)
void define_main(BFILE *fpr,char *mac1,char *mac2)
{
	int x,s1=0,s2=0,s3=0,s4=0;
	char *arg,*sbuf,*dbuf;
	MACRO *trace;

	if( check_define(mac1)==TRUE )
	{
		erl(fpr,WNG);
		printf("\'%s\' �́A���łɃ}�N���o�^����Ă��܂��B\n",mac1);
		return;
	}
	if( (x=instr(mac1,'(' ))!=EOF )
	{
		mac1[x-1]=NULL;
		arg = (char *)malloc(s4=(strlen(mac1+x)+1));
		strcpy(arg,mac1+x);
		x=strlen(arg);
		if( arg[x-1]!=')' )
		{
			erl(fpr,ERR);

			printf("\'%s\' �ɕ����� \')\' ������܂���B\n",arg);
			return;
		}
		arg[x-1]  = NULL;
	}
	else
		*arg = NULL;

	sbuf  = (char *)malloc(s1=(strlen(mac1)+1));
	dbuf  = (char *)malloc(s2=(strlen(mac2)+1));
	trace = (MACRO *)malloc(s3=sizeof(MACRO));

	if( !sbuf || !dbuf || !trace )
	{
		erl(fpr,SYS|ERR);
		printf("�}�N����`�̂��߂̃������[���s�����Ă��܂��B\n");
		exits(1);
	}
	strcpy(sbuf,mac1);
	strcpy(dbuf,mac2);

	trace->source     = sbuf;
	trace->distnation = dbuf;
	trace->argument   = arg;
	trace->next       = macro;
	macro             = trace;

	if( option[OPT_D]==TRUE )
	{
		fprintf(stderr,"\x1b[4;31mMacro:\x1b[m%s(L%05d)\n",fpr->filename,fpr->line);
		fprintf(stderr,
			"   \x1b[4;31msbuf:\x1b[m%s\n"
			"   \x1b[4;31mdbuf:\x1b[m%s\n"
			"   \x1b[4;31marg :\x1b[m%s\n"
			"   \x1b[4;31mUsed memory:\x1b[m%dbytes\n",
			sbuf,dbuf,arg,s1+s2+s3+s4
		);
	}
//	printf("#def S:%s D:%s A:%s\n",sbuf,dbuf,arg);
}

// �}�N���o�b�t�@��`
void define(BFILE *fpr)
{
	char mac1[256],mac2[256];

	bgetspace( mac1,255,fpr );
	bskipspace(fpr);
	bgets( mac2,255,fpr );
	define_main(fpr,mac1,mac2);
}

// �}�N���o�b�t�@��`(����)
void def(BFILE *fpr)
{
	int size=0;
	char *mac1,*mac2,*mac3,buf[256];
	mac1 = keepmem(4096);
	mac2 = keepmem(4096);
	mac3 = keepmem(4096);
	if( !mac1 || !mac2 )
	{
		erl(fpr,ERR|SYS);
		printf("�}�N����`�̂��߂̃������[���s�����Ă��܂��B\n");
		exits(1);
	}

	size = 0;
	strcpy(mac1,"");
	for(;;)
	{
		buntilchar(fpr);
		if( btop(fpr)==EOF )
		{
			erl(fpr,ERR);
			printf("#def A #nextdef B #enddef ���ߒ��Ƀt�@�C�����I���܂����B\n");
			goto freemem;
		}
		
		bgets(buf,255,fpr);
		operate_line(mac3,buf,fpr);
		if( !strcmp(mac3,"#nextdef") )break;
		
		size += strlen(mac3);
		if( size>=4096 )
		{
			erl(fpr,ERR);
			printf("#def A #nextdef B #enddef �� A ��4096�������z���Ă��܂��B\n");
			goto freemem;
		}
		strcat(mac1,mac3);
	}

	size = 0;
	strcpy(mac2,"");
	for(;;)
	{
		buntilchar(fpr);
		if( btop(fpr)==EOF )
		{
			erl(fpr,ERR);
			printf("#def A #nextdef B #enddef ���ߒ��Ƀt�@�C�����I���܂����B\n");
			goto freemem;
		}
		
		bgets(buf,255,fpr);
		operate_line(mac3,buf,fpr);
		if( !strcmp(mac3,"#enddef") )break;
		
		size += strlen(mac3);
		if( size>=4096 )
		{
			erl(fpr,ERR);
			printf("#def A #nextdef B #enddef �� B ��4096�������z���Ă��܂��B\n");
			goto freemem;
		}
		strcat(mac2,mac3);
	}

	define_main(fpr,mac1,mac2);
freemem:
	free_memory((unsigned char *)mac3);
	free_memory((unsigned char *)mac2);
	free_memory((unsigned char *)mac1);
}

void sys(BFILE *fpr,MFILE *fp)
{
	char buf[256],pt=0;
	bstandard(buf,255,fpr);
	bskipspace(fpr);

	if( option[OPT_D]==TRUE )
	{
		fprintf(stderr,"\x1b[4;32mPreprocessingCmd:\x1b[m%s(L%05d) ",fpr->filename,fpr->line);
		puts(buf);
	}

			if( !stricmp(buf,"ifdef"      )){set_ifdef(fpr);	pt=1;}
	else	if( !stricmp(buf,"ifndef"     )){set_ifndef(fpr);	pt=1;}
	else	if( !stricmp(buf,"else"       )){set_else();		pt=1;}
	else	if( !stricmp(buf,"elseif"     )){set_elseif(fpr);	pt=1;}
	else	if( !stricmp(buf,"endif"      )){set_endif();		pt=1;}

	if( xifdef.err_flag!=FALSE )
	{
		erl(fpr,ERR);
		printf("#ifdef,#ifndef,#else,#elseif,#endif ���Ή����Ă��܂���B\n");
		exits(1);
	}
	if( xifdef.stack_pointer>0 ){
		if( xifdef.top()==FALSE )
		{
			buntilreturn(fpr);
			return;
		}
	}
	if( pt )return;
	
			if( !stricmp(buf,"define"     ))define      (fpr);
	else	if( !stricmp(buf,"def"        ))def         (fpr);
	else	if( !stricmp(buf,"precede"    ))precede     (fpr);
	else	if( !stricmp(buf,"include"    ))include     (fpr,fp);
	else	if( !stricmp(buf,"title"      ))title       (fpr);
	else	if( !stricmp(buf,"composer"   ))composer    (fpr);
	else	if( !stricmp(buf,"arranger"   ))arranger    (fpr);
	else	if( !stricmp(buf,"programmer" ))programmer  (fpr);
	else	if( !stricmp(buf,"lyric"      ))lyric       (fpr);
	else	if( !stricmp(buf,"artist"     ))artist      (fpr);
	else	if( !stricmp(buf,"copyright"  ))copyright   (fpr);
	else	if( !stricmp(buf,"timebase"   ))chgtimebase (fpr);
	else	if( !stricmp(buf,"transpose"  ))chgtranspose(fpr);
	else	if( !stricmp(buf,"enddef"     ))
	{
		erl(fpr);
		printf("#def A #nextdef B #enddef �̏��������Ԉ���Ă��܂��B\n");
	}
	else	if( !stricmp(buf,"nextdef"     ))
	{
		erl(fpr);
		printf("#def A #nextdef B #enddef �̏��������Ԉ���Ă��܂��B\n");
	}
	else	if( !stricmp(buf,"message"    ))cmes(fpr);
	else
	{
		erl(fpr,ERR);
		printf("#%s �Ƃ������߂͑��݂��܂���B\n",buf);
	}
}
