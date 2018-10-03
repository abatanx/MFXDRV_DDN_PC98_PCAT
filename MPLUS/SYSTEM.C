/*---------------------------------------------------------------------------
       MFXDRV/DDN system XMML3.00 compiler MPLUS(mfxc+) release 1.00
  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
 *---------------------------------------------------------------------------*/
//
// # コマンド処理
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

// メモ設定
void writememo(BFILE *fpr)
{
	MFILE memow;
	int c;
	if( mopen(memofile,&memow)==EOF )
	{
		erl(NULL,WNG|SYS);
		printf("メモ用テンポラリファイル \'%s\' が作成できません。\n",memofile);
		return;
	}
	for(;;)
	{
		if( (c=bgetc(fpr))==EOF )
		{
			erl(fpr,WNG);
			printf("#memo が終わっていません。\n",memofile);
			return;
		}
		if( (c>=0x80 && c<=0x9e)||(c>=0xe0 && c<=0xfc))
		{
			mputc( c,&memow );
			mputc( bgetc(fpr),&memow );
		}
		else if( c=='/' )
		{
			if( (c=bgetc(fpr))=='/' )break;
			mputc( '/',&memow );
			mputc( c  ,&memow );
		}
		else if( c=='\\' )
		{
			mputc( bgetc(fpr),&memow);
		}
		else mputc( c,&memow);
	}
	mclose(&memow);
}

// タイトル設定
void title(BFILE *fpr)
{
	bgets(head.title,255,fpr);
}
// 作曲者設定
void composer(BFILE *fpr)
{
	bgets(head.composer,255,fpr);
}
// 編曲者設定
void arranger(BFILE *fpr)
{
	bgets(head.arranger,255,fpr);
}
// 作詞者設定
void lyric(BFILE *fpr)
{
	bgets(head.lyric,255,fpr);
}
// アーティスト名設定
void artist(BFILE *fpr)
{
	bgets(head.artist,255,fpr);
}
// プログラマ名設定
void programmer(BFILE *fpr)
{
	bgets(head.programmer,255,fpr);
}
// コピーライト設定
void copyright(BFILE *fpr)
{
	bgets(head.copyright,255,fpr);
}

// インクルード処理
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

// 優先オブジェクト指定
void precede(BFILE *fpr)
{
	char driver[64],object[64];
	bgetspace(driver,63,fpr);
	bskipspace(fpr);
	bgetspace(object,63,fpr);
	set_mplay(driver,object);
}

// メッセージ表示
void cmes(BFILE *fpr)
{
	char buf[256];
	bgets( buf,255,fpr );
//	erl(fpr,NULL);
	printf("\n%s\n",buf);
}

// IFDEF処理
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
// IFNDEF処理
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
// ELSE処理
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
// ELSEIF 処理
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
// ENDIF処理
void set_endif()
{
	xifdef.pop();
}

// タイムベース処理
void chgtimebase(BFILE *fpr)
{
	timebase = bnumber(fpr);
	if( timebase<24 )
	{
		erl(fpr,WNG);
		printf("タイムベース値が 24 を下回っています。\n");
	}
}

// トランスポーズ処理
void chgtranspose(BFILE *fpr)
{
	char buf[64];
	bgetspace(buf,63,fpr);
	if( !strcmp(buf,"up") || !strcmp(buf,"+") )transpose++;
	else if( !strcmp(buf,"down") || !strcmp(buf,"-") )transpose--;
	else transpose=atoi(buf);
}

// マクロ処理
// マクロ辞書チェック
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

// マクロ取り出し
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

// マクロ取り出し
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

// マクロエンコーダー
void encode_macro(char *buffer,BFILE *fpr)
{
	int angle,angle2,mi,di,angleflag,x;
	char *macs,*dist,*mc,*mc1,*mc2,*buf,*args,*mrgs,argc;
	di   = 0;
	buf  = buffer;
	argc = 0;

	if( option[OPT_M]==TRUE )
		printf("=============================== [%s]\n",buffer);
	if( memlevel>0 )
	{
		macs = (char *)malloc(512);
		dist = (char *)malloc(4096);
		args = (char *)malloc(4096);
		mrgs = (char *)malloc(4096);
	}
	else
	{
		macs = s_macs;
		dist = s_dist;
		args = s_args;
		mrgs = s_mrgs;
	}
	memlevel++;
	angle2 = 0;
	args[0] = NULL;
	macs[0] = NULL;
	mrgs[0] = NULL;
	dist[0] = NULL;
	
	while( *buffer!=NULL )
	{
		if( *buffer=='(' && !angle2 )
		{
			buffer++;
			angle = 0;
			mi = 0;
			argc = 0;
			for(;;)
			{
				if( option[OPT_M]==TRUE )
					printf("\x1b[33m%c\x1b[m",*buffer);
				if( *buffer=='\0' )
				{
					erl(fpr,ERR);
					printf("\')\' が見つかりません。\n");
					goto errexit;
				}
				else if( *buffer=='(' ){
					angle++;
					if( angle>=2 )
					{
						args[argc] = *buffer;
						argc++;
						buffer++;
					}
					else
						buffer++;
				}
				else if( *buffer==')' ){
					if( angle>=2 )
					{
						args[argc] = *buffer;
						argc++;
						buffer++;
					}
					else
						buffer++;
					angle--;
					if( angle<0 ){
						macs[mi]   = NULL;
						args[argc] = NULL;
						break;
					}
				}
				else if( angle>0 )
				{
					args[argc] = *buffer;
					if( option[OPT_M]==TRUE )
						printf("\x1b[36m%c\x1b[m",args[argc]);
					argc++;
					buffer++;
					
					
					if( argc>4095 )
					{
						erl(fpr,ERR);
						printf("マクロ式が長すぎます。\n");
						goto errexit;
					}
				}
				else
				{
					macs[mi] = *buffer;
					mi++;
					buffer++;
					if( mi>=511 )
					{
						erl(fpr,ERR);
						printf("マクロ名が長すぎます。\n");
						goto errexit;
					}
				}
			}

			macs[mi]   = NULL;
			args[argc] = NULL;
			if( option[OPT_M]==TRUE )printf("macs=%s args=%s\n",macs,args);

			if( (mc=get_define(macs))==NULL )
			{
				erl(fpr,ERR);
				printf("\'%s\' というマクロは定義されていません。\n",macs);
				goto errexit;
			}
			
			if( args[0]!=NULL )
			{
				mc1 = get_define (macs);
				strcpy(mrgs,get_define2(macs));
				encode_macro_argument(mrgs,args,mc1,work,fpr,macs);
				mc = work;
				mi = 0;
				argc = 0;
			}
			while( *mc!=NULL && di<4095 )*(dist+di++) = *(mc++);
		}
		else if( *buffer==')' && !angle2 )
		{
			erl(fpr,ERR);
			printf("\'(\' が見つかりません。\n");
			goto errexit;
		}
		else if( *buffer=='!' && !angle2 )
		{
			if( (macs[0] = *(buffer+1))==NULL )
			{
				erl(fpr,ERR);
				printf("\'!\' コマンドが不正です。\n");
				goto errexit;
			}
			
			macs[1] = NULL;
			buffer+=2;
			if( (mc=get_define(macs))==NULL )
			{
				erl(fpr,ERR);
				printf("\'%s\' というマクロは定義されていません。\n",macs);
				goto errexit;
			}
			while( *mc!=NULL && di<4095 )*(dist+di++) = *(mc++);
		}
		else 
		{
			if( *buffer=='\"' )angle2 = 1-angle2;
			*(dist+di) = *buffer;
			x = *buffer;
			di++;
			buffer++;
			if( (x>=0x81 && x<=0x9f)||(x>=0xe0 && x<=0xfc))
			{
				if( (*(dist+di++)=*(buffer++))==NULL )break;
			}
			if( di>=4095 )
			{
				erl(fpr,ERR);
				printf("マクロ展開中に行が4096文字をオーバーしました。\n");
				*(dist+di)=NULL;
				goto errexit;
			}
		}
	}
	*(dist+di) = NULL;
	strcpy( buf,dist );
//	puts(buf);
	
	angleflag = FALSE;
	angle2    = 0;
	mi = 0;
	while( buf[mi]!=NULL )
	{
		if( buf[mi]=='\"' )angle2 = 1-angle2;
		else if( (buf[mi]>=0x81 && buf[mi]<=0x9f)||(buf[mi]>=0xe0 && buf[mi]<=0xfc))
		{
			mi++;
			if( buf[mi]==NULL )break;
		}
		else if( (buf[mi]=='(' || buf[mi]==')' || buf[mi]=='!') && !angle2 )
		{
			angleflag = TRUE;
			break;
		}
		mi++;
	}
	if( angleflag==TRUE )
	{
//		puts(buf);
		encode_macro(buf,fpr);
	}
errexit:
	memlevel--;
	if( memlevel>0 )
	{
		free(mrgs);
		free(args);
		free(dist);
		free(macs);
	}
}
// マクロアーギュメントエンコーダー
void encode_macro_argument(char *macroarg,char *valuearg,char *encode,char *buf,BFILE *fpr,char *macs)
{
	int p,p1,p2,p3,i,x,si,di,flag,argmin[MAXARG],argmax[MAXARG],a,wq,strempty;
	char *token,*tsearch,argflag[MAXARG];
	BFILE localfpr;

	for( i=0; i<MAXARG; i++) argflag[i] = FALSE;

if( option[OPT_M]==TRUE )
{
	printf("=========\n");
	printf("macroarg:%s\nvaluearg:%s\nencode:%s\n",macroarg,valuearg,encode);
//	printf("\nMACRO ARG:");
}

	x = 0;
	token   = macroarg;
	tsearch = macroarg;
	strempty = FALSE;
	while(1)
	{
		tsearch = token;
		wq = 0;
		if( strempty==FALSE )while(1)
		{
			switch( *tsearch )
			{
				case '\"':
					wq = 1-wq;
					break;
				case ',':
					if( wq==0 )
					{
						*tsearch=NULL;
						goto exit_s;
					}
					break;
				case NULL:
					strempty = TRUE;
					goto exit_s;
			}
			tsearch++;
		}
		else break;
exit_s:
		if( option[OPT_M]==TRUE )printf("%s ",token);
	
		if( (p=instr(token,'('))!=EOF )
		{
			strncpy(m_arg[x],token,MAXARGSIZE);
			*(m_arg[x]+p-1) = NULL;
			if( (p2=instr(token+p,'.'))==EOF )
			{
				erl(fpr);
				printf("\'%s\' マクロ数値範囲 prm(min..max)の .. がありません。\n",macs);
				buf[0]=NULL;
				return;
			}
			*(m_arg[x]+p+p2-1) = NULL;
			argmin[x] = atoi(m_arg[x]+p);
			p2 = instrback(token+p,'.');
			if( (p3=instr(token+p+p2,')'))==EOF )
			{
				erl(fpr);
				printf("\'%s\' マクロ数値範囲 prm(min..max)の ) がありません。\n",macs);
				buf[0]=NULL;
				return;
			}
			*(m_arg[x]+p+p2+p3-1) = NULL;
			argmax[x] = atoi(m_arg[x]+p+p2);
			argflag[x] = TRUE;
			if( argmin[x]>argmax[x] )
			{
				erl(fpr);
				printf("\'%s\' マクロ数値範囲 prm(min..max) で、min>max です。\n",macs);
				buf[0]=NULL;
				return;
			}
//			printf("%d..%d\n",argmin[x],argmax[x]);
			x++;
		}
		else 
		{
			strncpy(m_arg[x++],token,MAXARGSIZE);
		}
		if( x>=MAXARG )
		{
			erl(fpr);
			printf("マクロパラメータが128を越えました。\n");
			buf[0]=NULL;
			return;
		}
		if( strempty==FALSE )*tsearch=',';
		token = tsearch+1;
	}

//	printf("\nVALUE ARG:");
	token   = valuearg;
	tsearch = valuearg;
	strempty = FALSE;
	for( i=0; i<x; i++)
	{
		tsearch = token;
		wq = 0;
		if( strempty==FALSE )while(1)
		{
			switch( *tsearch )
			{
				case '\"':
					wq = 1-wq;
					break;
				case ',':
					if( wq==0 )
					{
						*tsearch=NULL;
						goto exit_s2;
					}
					break;
				case NULL:
					strempty = TRUE;
					goto exit_s2;
			}
			tsearch++;
		}
		else 
		{
			token = NULL;
		}
exit_s2:
		if( token==NULL )
		{
			erl(fpr);
			printf("マクロのパラメータ数が少なすぎます。\n");
			buf[0]=NULL;
			return;
		}
		if( option[OPT_M]==TRUE )printf("%s ",token);
		strncpy(v_arg[i],token,MAXARGSIZE);
		if( *v_arg[i]=='(' )encode_macro(v_arg[i],fpr);
		if( strempty==FALSE )*tsearch=',';
		token = tsearch+1;
	}
	if( strempty==FALSE )
	{
		erl(fpr);
		printf("マクロのパラメータ数が多すぎます。\n");
		buf[0]=NULL;
		return;
	}
	
	si = 0;
	while( *encode!=NULL )
	{
		flag = -1;
		for( i=0; i<x; i++)
		{
			if( !strncmp(encode,m_arg[i],strlen(m_arg[i])) )
			{
				if( argflag[i]==TRUE )
				{
					a = (int)math_op(&localfpr,v_arg[i]);
					if( a<argmin[i] || a>argmax[i] )
					{
						erl(fpr,WNG);
						printf("\'%s\' のパラメータ %sが、%d..%dの範囲内にありません。\n",
							macs,m_arg[i],argmin[i],argmax[i]
						);
					}
				}
				di = 0;
				while( *(v_arg[i]+di)!=NULL )
				{
					buf[si++] = *(v_arg[i]+di++);
				}
				flag = i;
				break;
			}
		}
		if( flag!=-1 )
		{
			encode+=strlen(m_arg[i]);
		}
		else
			buf[si++] = *(encode++);

		if( si>=4095 )
		{
			erl(fpr);
			printf("マクロ展開中に 4096文字をこえました。\n");
		}
	}
	buf[si] = NULL;
	if( option[OPT_M]==TRUE )printf("\n[\x1b[33m%s\x1b[m]\n",buf);
}

// マクロバッファ定義(メイン)
void define_main(BFILE *fpr,char *mac1,char *mac2)
{
	int x,s1=0,s2=0,s3=0,s4=0;
	char *arg,*sbuf,*dbuf;
	MACRO *trace;

	if( check_define(mac1)==TRUE )
	{
		erl(fpr,WNG);
		printf("\'%s\' は、すでにマクロ登録されています。\n",mac1);
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

			printf("\'%s\' に閉じ括弧 \')\' がありません。\n",arg);
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
		printf("マクロ定義のためのメモリーが不足しています。\n");
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

// マクロバッファ定義
void define(BFILE *fpr)
{
	char mac1[256],mac2[256];

	bgetspace( mac1,255,fpr );
	bskipspace(fpr);
	bgets( mac2,255,fpr );
	define_main(fpr,mac1,mac2);
}

// マクロバッファ定義(長文)
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
		printf("マクロ定義のためのメモリーが不足しています。\n");
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
			printf("#def A #nextdef B #enddef 解釈中にファイルが終わりました。\n");
			goto freemem;
		}
		
		bgets(buf,255,fpr);
		operate_line(mac3,buf,fpr);
		if( !strcmp(mac3,"#nextdef") )break;
		
		size += strlen(mac3);
		if( size>=4096 )
		{
			erl(fpr,ERR);
			printf("#def A #nextdef B #enddef の A が4096文字を越えています。\n");
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
			printf("#def A #nextdef B #enddef 解釈中にファイルが終わりました。\n");
			goto freemem;
		}
		
		bgets(buf,255,fpr);
		operate_line(mac3,buf,fpr);
		if( !strcmp(mac3,"#enddef") )break;
		
		size += strlen(mac3);
		if( size>=4096 )
		{
			erl(fpr,ERR);
			printf("#def A #nextdef B #enddef の B が4096文字を越えています。\n");
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
		printf("#ifdef,#ifndef,#else,#elseif,#endif が対応していません。\n");
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
	else	if( !stricmp(buf,"memo"       ))writememo   (fpr);
	else	if( !stricmp(buf,"enddef"     ))
	{
		erl(fpr);
		printf("#def A #nextdef B #enddef の書き方が間違っています。\n");
	}
	else	if( !stricmp(buf,"nextdef"     ))
	{
		erl(fpr);
		printf("#def A #nextdef B #enddef の書き方が間違っています。\n");
	}
	else	if( !stricmp(buf,"message"    ))cmes(fpr);
	else
	{
		erl(fpr,ERR);
		printf("#%s という命令は存在しません。\n",buf);
	}
}
