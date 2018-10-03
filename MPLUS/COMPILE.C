/*---------------------------------------------------------------------------
       MFXDRV/DDN system XMML3.00 compiler MPLUS(mfxc+) release 1.00
  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
 *---------------------------------------------------------------------------*/
//
// MMLコンパイル／プリプロセス
//

#include	<stdio.h>
#include	<string.h>
#include	<ctype.h>
#include	<mfile.h>
#include	<mylib.h>
#include	"mplus.h"

#define		MAXNOTEBUF	32
#define		ECMBUF		8192

#define		TIEON		1
#define		TIEOFF		2

void mml(BFILE *,int);

typedef struct
{
	char flag;
	byte no;
	long tick;
	long len;
} NOTE;

typedef struct
{
	NOTE note[MAXNOTEBUF];
} NOTEINFO;

static NOTEINFO noteinfo[MAXTRACK];
static int
	objflag,
	octave[MAXTRACK],volume[MAXTRACK],expression[MAXTRACK],
	modulation[MAXTRACK],csendlv[MAXTRACK],rsendlv[MAXTRACK],
	panpot[MAXTRACK],length[MAXTRACK],gatetime[MAXTRACK],velocity[MAXTRACK],
	instrument[MAXTRACK],bank[MAXTRACK],pitchbend[MAXTRACK],loop[MAXTRACK],
	cpress[MAXTRACK],chgflag[MAXTRACK],harmony[MAXTRACK],lnote[MAXTRACK],
	key[MAXTRACK][7],tieflag[MAXTRACK],tieflag2[MAXTRACK],tempo,
	transposeflag[MAXTRACK],transposetrack[MAXTRACK];
static long
	tienotelen[MAXTRACK];
static BFILE closefp;

int timebase,transpose,playflag;
static char *ecmbuf=NULL;

extern	int		bnum16flag,bnumflag;

//
#include	"compile2.c"

// パラメータイニシャライズ
void init_parameters(void)
{
	int i,j;

	for( i=0; i<MAXTRACK; i++)
	{
		octave[i]     = 4;
		volume[i]     = 100;
		expression[i] = 127;
		panpot[i]     = 64;
		rsendlv[i]    = 40;
		csendlv[i]    = 0;
		modulation[i] = 0;
		length[i]     = 48;
		gatetime[i]   = 100;
		velocity[i]   = 127;
		instrument[i] = 0;
		bank[i]       = 0;
		pitchbend[i]  = 0;
		loop[i]       = 0;
		cpress[i]     = 0;
		chgflag[i]    = TRUE;
		tieflag [i]   = TIEOFF;
		tieflag2[i]   = FALSE;
		transposeflag[i] =TRUE;
		transposetrack[i]=0;
		tienotelen[i] = 0;
		harmony[i]    = 0;
		lnote[i]      = 0;
		
		for( j=0; j<MAXNOTEBUF; j++) noteinfo[i].note[j].flag = FALSE;
		for( j=0; j<7         ; j++) key[i][j] = 0;
	}
	playflag=TRUE;
	tempo=120;
}

// コンパイラ
void compile(char *filename,MFILE *fp)
{
	timebase  = 48;
	transpose = 0;
	objflag   = FALSE;
	if( ecmbuf==NULL )ecmbuf = keepmem(ECMBUF);

	init_parameters();
	preprocessor(filename,fp);
	if( objflag==TRUE )
	{
		erl(&closefp);
		printf(".object の閉じかっこ \'}\' がありません。\n");
		exits(1);
	}
}

// プリプロセッサ
void preprocessor(char *filename,MFILE *fp)
{
	int i,c,mmltrack,dmc=0;
	BFILE *fpr,fprlocal;
	char trkname[64],objname[64],*linebuf,*linebuf2;

	linebuf  = keepmem(4096);
	linebuf2 = keepmem(4096);

	if( option[ OPT_D ]==TRUE )
	{
		printf("OPENFILE;%s\n",filename);
	}
	if( (fpr=bopen(filename))==NULL )
	{
		erl(NULL,SYS|ERR);
		printf("\'%s\' が読み込めません。\n",filename);
		return;
	}
	
	for(;;)
	{
		dmc++;
		if( !(dmc%16) )
		{
			if( option[OPT_D]==TRUE )
				fprintf(stderr,"------------------------------------------------------------------------------\n");
			fprintf(stderr," compiling:%s(L%05d,%3d\%)\x1b[0K\r",
				fpr->filename,fpr->line,(fpr->fp+fpr->binfp+1)*100/(fpr->size+1));
			if( option[OPT_D]==TRUE )
				fprintf(stderr,"\n------------------------------------------------------------------------------\n\n");
		}
		buntilchar(fpr);
		switch( btop(fpr) )
		{
			case EOF:						// ファイル終了
				fprintf(stderr," compiled :%s(L%05d,100\%)\x1b[0K\n",
					fpr->filename,fpr->line
				);
				closefp = *fpr;
				bclose(fpr);
				free_memory((unsigned char *)linebuf );
				free_memory((unsigned char *)linebuf2);
				return;
			case '#':						// システム制御命令
				bnext(fpr);
				sys(fpr,fp);
				break;
			case ';':case '*':				// コメント
				for(;;)
				{
					c = bgetc(fpr);
					if( c=='\n' || c==EOF )break;
				}
				break;
			case '.':						// オブジェクト開始
				if( xifdef.stack_pointer>0 )
				{
					if( xifdef.top()==FALSE )
					{
						buntilreturn(fpr);
						break;
					}
				}
				bnext(fpr);
				if( objflag==TRUE )
				{
					erl(fpr);
					printf(".object のネストはできません。\n");
					break;
				}
				if( obj(fpr,objname)==TRUE )
				{
					objflag = TRUE;
				}
				printf("	obj(%d):%-10s in %s\n",objects,objname,fpr->filename);
				init_parameters();
				break;
			case '}':						// オブジェクト終了
				if( xifdef.stack_pointer>0 )
				{
					if( xifdef.top()==FALSE )
					{
						buntilreturn(fpr);
						break;
					}
				}
				bnext(fpr);
				if( objflag==FALSE )
				{
					erl(fpr);
					printf(".object 文法が不正です。\n");
					break;
				}
				objflag = FALSE;

				for( i=0; i<maxtrack; i++)
				{
					mputc( 0xe2,&fpw[i] );
					mclose(&fpw[i]);
				}
				
				makembj(fp,objname);
				objects++;
				
				break;

			default:
				if( xifdef.stack_pointer>0 )
				{
					if( xifdef.top()==FALSE )
					{
						buntilreturn(fpr);
						break;
					}
				}
				if( objflag==FALSE )
				{
					erl(fpr);
					printf(".object ...{...} 外に MMLは記述できません。\n");
					for(;;)
					{
						c = bgetc(fpr);
						if( c=='\n' || c==EOF )break;
					}
					break;
				}
				bstandard( trkname,63,fpr );
				mmltrack = -1;
				for( i=0; i<maxtrack; i++)
				{
					if( !strcmp(trkname,trk[i].name) )
					{
						mmltrack = i;
						break;
					}
				}
				if( mmltrack==-1 )
				{
					erl(fpr);
					printf("\'%s\' というトラックは存在しません。\n",trkname);
					break;
				}

				breadchar(linebuf,4095,';',fpr);
				operate_line(linebuf2,linebuf,fpr);
				encode_macro(linebuf2,fpr);

				if( option[OPT_D]==TRUE )
				{
					fprintf(stderr,"\x1b[4;33mAnalyzing:\x1b[m%s(L%05d) ",fpr->filename,fpr->line);
					puts(linebuf2);
				}

				bopen2(&fprlocal,filename,linebuf2,fpr->line,strlen(linebuf2));
				mml(&fprlocal,mmltrack);
				break;
		}
	}
}

// MMLコンパイラ
void mml(BFILE *fpr,int track)
{
	int nc,nc2,i,j,si,emptyno,x,x1,x2,ll,mm,adr,ei,di,angle;
	int cmd,cmd2,note,notenumber,notevelocity,notegtime;
	long notelen,notelen2,notelen3,sortbuf[MAXNOTEBUF],sorttmp;
	long sum;
	unsigned drvid,drvtype;
	char element[256];
	int elementdata[256];
	BFILE localfp;
	
	if( option[OPT_D]==TRUE )
	{
		fprintf(stderr,"\x1b[32m(\x1b[m");
	}
	while( (cmd=bgetc2(fpr))!=EOF )
	{
		if( cmd=='@' || cmd=='_' )
		{
			cmd2 = btop(fpr);
			if( (cmd2>='a' && cmd2<='z') || cmd2=='{' || cmd2=='}' )
			{
				cmd |= cmd2<<8;
				bnext(fpr);
			}
		}
/*==== SPACE || TAB ====*/
		if( cmd==' ' || cmd=='\r' || cmd=='\n' || cmd==0x09) continue;
		if( option[OPT_D]==TRUE )fputc( cmd,stderr );
		switch(cmd)
		{
/*==== Note情報だった！ ====*/
			case 'c':case 'd':case 'e':case 'f':case 'g':case 'a':case 'b':
			case 'r':case 'l':case 'k':
			case '\'':
	/*.... ノートナンバーを計算 ....*/
				if( chgflag[track]==TRUE )
				{
					root = makeadt(root,bank[track],instrument[track]);
					chgflag[track] = FALSE;
				}
				if( cmd=='\'' )
				{
					harmony[track] = 1-harmony[track];
					if( harmony[track]==1 )break;
					else cmd = 'r';
				}
				else if( cmd=='k' )
				{
					notenumber=bnumber(fpr);
					if( btop(fpr)==',' )bnext(fpr);
				}
				else
				{
					nc2 = btop(fpr);
					if( nc2!='*' && nc2!='+' && nc2!='-' && nc2!='#' && 
						cmd>='a' && cmd<='g' )
					{
						x = cmd-'a';
						     if( key[track][x]==1  )nc2= 1;
						else if( key[track][x]==-1 )nc2=-1;
						else if( key[track][x]==0  )nc2=NULL;
						else 
						{
							erl(fpr,SYS|WNG);
							printf("mml():key[][]バッファが破壊されています。\n");
							exits(1);
						}
					}
					if( nc2=='+' || nc2=='#' || nc2==1 ){
						note = 1;
						if( nc2!=1 )bnext(fpr);
						
						if( cmd=='e' || cmd=='b' )
						{
							erl(fpr,WNG);
							printf("\'%c%c\' というノートはありません。\n",cmd,nc2);
						}
					}
					else if( nc2=='-' || nc2==-1 ){
						note =-1;
						if( nc2!=-1 )bnext(fpr);

						if( cmd=='c' || cmd=='f' )
						{
							erl(fpr,WNG);
							printf("\'%c%c\' というノートはありません。\n",cmd,nc2);
						}
					}
					else note = 0;
				}
				if( cmd!='k' )
				{
					switch(cmd)
					{
						case 'c':	notenumber=0;	break;
						case 'd':	notenumber=2;	break;
						case 'e':	notenumber=4;	break;
						case 'f':	notenumber=5;	break;
						case 'g':	notenumber=7;	break;
						case 'a':	notenumber=9;	break;
						case 'b':	notenumber=11;	break;
						default:	notenumber=0;	break;
					}
					notenumber += octave[track]*12+note;
					if(transposeflag[track]==TRUE)notenumber+=transpose;
					notenumber+=transposetrack[track];
				}

	/*.... 音長を計算 ....*/
				nc = btop(fpr);
				if( nc>='0' && nc<='9' ){
					notelen = bnumber(fpr);
					if( notelen==0 )
					{
						erl(fpr);
						printf("\'%c\' 0分音符は存在しません。\n",cmd);
						notelen=1;
					}
					else
						notelen=timebase*4/notelen;
					
					if( lnote[track]!=0 && harmony[track]==0 )
					{
						erl(fpr,WNG);
						printf("\'{len/div ..}\' の中での音長は無効です。\n");
					}
				}
				else {
					if( cmd=='l' )
					{
						erl(fpr);
						printf("\'l\' の音長が指定してありません。\n");
						break;
					}
					notelen = length[track];
				}

				notelen2 = notelen;

				while( (nc=btop(fpr))=='.' )
				{
					if( notelen2 & 1 )
					{
						erl(fpr,WNG);
						printf("\'%c\' テンポずれが起こっています。\n",cmd);
					}
					notelen2 /= 2;
					notelen  += notelen2;
					bnext(fpr);
				}
				if( cmd=='l' )
				{
					length[track] = notelen;
					break;
				}
	/*.... ゲートタイム && ヴェロイシティー 指定有り?? ....*/
				nc = btop(fpr);
				notegtime    = gatetime[track];
				notevelocity = velocity[track];
				
				if( nc=='/' )
				{
					bnext(fpr);
					if( btop(fpr)!='/' )
						notegtime = bnumber(fpr);
					if( btop(fpr)=='/' )
					{
						bnext(fpr);
						notevelocity = bnumber(fpr);
					}
				}
	/*.... タイチェック ....*/
				x = btop(fpr);
				if( x=='&' || x=='^' )
				{
					tieflag[track] = TIEON;
					bnext(fpr);
				}
				else tieflag[track] = TIEOFF;
	/*.... 連符時のデフォルト音長 ....*/
				if( lnote[track]!=0 )
				{
					notelen = lnote[track];
				}
	/*.... パラメーターチェック ....*/
				if( (notenumber<0 || notenumber>127) && cmd!='r' ){
					erl(fpr);printf("\'%c\' ノート番号が C0..B7 の範囲を越えています。\n",cmd);
					notenumber &= 127;
				}
				if( notelen<0 ){
					erl(fpr);
					printf("\'%c\' 音長が不正です。\n",cmd);
					notelen=1;
				}
				if( notegtime==0 ){
					erl(fpr,WNG);printf("\'%c\' ゲートタイム比が 0 です。\n",cmd);
					notegtime=1;
				}
				if( notevelocity<1 || notevelocity>127 )
				{
					erl(fpr,WNG);printf("\'%c\' ヴェロシティーが 1..127 の範囲を超えています。\n",cmd);
				}
	/*.... ノートを on にして、辞書に登録 ....*/
				if( cmd!='r' )
				{
					if( tieflag2[track]==FALSE )
					{
						mputc( notenumber  ,&fpw[track] );
						mputc( notevelocity,&fpw[track] );
					}
					
					if( tieflag2[track]==TRUE )
					{
						x = FALSE;
						for( i=0; i<MAXNOTEBUF; i++)
						{
							if( noteinfo[track].note[i].flag==FALSE )continue;
							if( noteinfo[track].note[i].no==notenumber )
							{
								noteinfo[track].note[i].tick = 
									((noteinfo[track].note[i].len+notelen)*notegtime)/100;
								noteinfo[track].note[i].len += notelen;
								x = TRUE;
							//	printf("Tie complete.\n");
								break;
							}
						}
						if( x==FALSE )
						{
							erl(fpr,WNG);
							printf("tieコマンド \'&\' の前後の音程が違います。\n");
						}
					}
					else 
					{
						emptyno = EOF;
						for( i=0; i<MAXNOTEBUF; i++)
						{
							if( noteinfo[track].note[i].flag==FALSE )
							{
								emptyno = i;
								break;
							}
						}
						if( emptyno==EOF )
						{
							erl(fpr,SYS|WNG);
							printf(
								"\'%c\' 1trackの同時発音数が %dを越え処理"
								"できないので無視します。\n",
								cmd,MAXNOTEBUF)	;
							break;
						}
						noteinfo[track].note[emptyno].flag = TRUE;
						noteinfo[track].note[emptyno].no   = (byte)notenumber;
						noteinfo[track].note[emptyno].tick = (notelen*notegtime)/100;
						noteinfo[track].note[emptyno].len  = notelen;
					}
				}
				if( tieflag[track]==TIEON )
				{
					tieflag2[track] = TRUE;
					tienotelen[track] += notelen;
					break;
				}
				else
				{
					if( tieflag2[track]==TRUE )
					{
						notelen += tienotelen[track];
						tienotelen[track] = 0;
					}
					tieflag2[track] = FALSE;
				}
	/*.... debug ...*/
				if( option[OPT_X]==TRUE )
				{
					printf("\x1b[4;36mNoteinfo(TR%02d):NUM  \x1b[m",track);
					for(i=0;i<MAXNOTEBUF;i++)
					{
						if( noteinfo[track].note[i].flag==FALSE )continue;
						printf("%5d",noteinfo[track].note[i].no);
					}
					printf("\n\x1b[4;35mNoteinfo(TR%02d):TICK \x1b[m",track);
					for(i=0;i<MAXNOTEBUF;i++)
					{
						if( noteinfo[track].note[i].flag==FALSE )continue;
						printf("%5ld",noteinfo[track].note[i].tick);
					}
					puts("");
				}

	/*.... ゲートタイムずらし処理(ミソ) 和音の時は無視するだけだね(笑)....*/
				if( harmony[track]==1 )break;
	
				si=0;
				for( i=0; i<MAXNOTEBUF; i++)
				{
					if( noteinfo[track].note[i].flag==FALSE )continue;
					if( (noteinfo[track].note[i].tick -= notelen) <=0 )
					{
						sortbuf[si++] = i+(-noteinfo[track].note[i].tick)*0x100L;
					}
				}
				if( si>1 )
				{
					/* ソーティング */
					for( i=0; i<si-1; i++)
					{
						for( j=i+1; j<si; j++)
						{
							if( sortbuf[i]<sortbuf[j] )
							{
								sorttmp    = sortbuf[j];
								sortbuf[j] = sortbuf[i];
								sortbuf[i] = sorttmp;
							}
						}
					}
				}
				for( i=0; i<si; i++)
					sortbuf[i] &= 0xffL;
				
				notelen2 = notelen + noteinfo[track].note[sortbuf[0]].tick;
				notelen3 = 0;
				for( i=0; i<si; i++)
				{
					notewait( notelen2,&fpw[track] );
					notelen3 += notelen2;

					mputc( 0x80,&fpw[track] );
					mputc( noteinfo[track].note[sortbuf[i]].no,&fpw[track] );
					noteinfo[track].note[sortbuf[i]].flag = FALSE;
					if( i==si-1 )break;
					notelen2  = noteinfo[track].note[sortbuf[i+1]].tick-noteinfo[track].note[sortbuf[i]].tick;
				}
				notelen3 = notelen-notelen3;
				notewait( notelen3,&fpw[track] );
				
				break;
/*==== 連符処理 ====*/
			case '{':
				if( lnote[track]!=0 )
				{
					erl(fpr,ERR);
					printf("\'{\' 連音符命令のネストはできません。\n");
					break;
				}
	/*.... 音長を計算 ....*/
				nc = btop(fpr);
				if( nc>='0' && nc<='9' ){
					notelen = bnumber(fpr);
					if( notelen==0 )
					{
						erl(fpr);
						printf("\'{\' 0分音符は存在しません。\n",cmd);
						notelen=1;
					}
					else
						notelen=timebase*4/notelen;
				}
				else 
					notelen = length[track];

				notelen2 = notelen;

				while( (nc=btop(fpr))=='.' )
				{
					if( notelen2 & 1 )
					{
						erl(fpr,WNG);
						printf("\'{\' テンポずれが起こっています。\n");
					}
					notelen2 /= 2;
					notelen  += notelen2;
					bnext(fpr);
				}
	/*.... 分割数 ....*/
				if( bgetc(fpr)!='/' )
				{
					erl(fpr,ERR);
					printf("\'{\' の音長分割数がありません。\n");
					break;
				}
				x = bnumber(fpr);
				lnote[track] = notelen/x;
				
				if( notelen%x )
				{
					erl(fpr,WNG);
					printf("\'{\' 連音符計算時にテンポずれが起こっています。\n");
				}
				break;
/*==== 連符終了処理 ====*/
			case '}':
				if( lnote[track]==0 )
				{
					erl(fpr,ERR);
					printf("\'}\' 連音符命令開始 \'{\' がありません。\n");
					break;
				}
				lnote[track] = 0;
				break;

/*==== Volume情報(1)だった！ ====*/
			case '@v':
				x = valcomp("@v",&volume[track],0,127,fpr);
				mputc( 0xa5,&fpw[track] );
				mputc( x   ,&fpw[track] );
				break;
/*==== Volume情報(2)だった！ ====*/
			case 'v':
				x  = valcomp("v",&volume[track],0,15,fpr);
				x *= 8;
				volume[track] = x;
				mputc( 0xa5,&fpw[track] );
				mputc( x   ,&fpw[track] );
				break;
/*==== @e 関連  @e,@exc,@ecm ====*/
			case '@e':
				switch( btop(fpr) )
				{
/*==== エクスクルーシブだった！ ====*/
					case 'x':
						bnext(fpr);
						if( (cmd=bgetc(fpr))!='c' )
						{
							erl(fpr,ERR);
							printf("\'@ex%c\' というコマンドは存在しません。\n",cmd);
							break;
						}
						if( (cmd=bgetc(fpr))!='[' )
						{
							erl(fpr,ERR);
							printf("\'@exc\' \'[\' が見つかりません。\n",cmd);
							break;
						}
						ei = 0;
						while( btop(fpr)!=']' )
						{
							breadchar2(element,255,',',']',fpr);
							if( btop(fpr)==',' )bnext(fpr);

							if( !stricmp(element,"sum") )
							{
								if( ei<4 )
								{
									erl(fpr,ERR);
									printf("\'@exc\' データがないので sum が作成できません。\n");
									break;
								}
								sum = 0L;
								for( i=4; i<ei; i++)
								{
									sum+=elementdata[i];
								}
								sum = 128L-sum%128L;
								elementdata[ei++]=sum;
							}
							else
							{
								elementdata[ei++]=math_op(fpr,element);
							}
							if( ei>=255 )
							{
								erl(fpr,ERR);
								printf("\'@exc\' データが多すぎます。\n");
								return;
							}
						}
						bnext(fpr);
						mputc( 0xbb,&fpw[track] );
						mputc( ei  ,&fpw[track] );
						for( i=0; i<ei; i++)
							mputc( elementdata[i],&fpw[track]);
						break;
/*==== ECM だった！ ====*/
					case 'c':
						bnext(fpr);
						if( (cmd=bgetc(fpr))!='m' )
						{
							erl(fpr,ERR);
							printf("\'@ec%c\' というコマンドは存在しません。\n",cmd);
							break;
						}
						if( (cmd=bgetc(fpr))!='[' )
						{
							erl(fpr,ERR);
							printf("\'@ecm\' \'[\' が見つかりません。\n");
							break;
						}
						breadchar(element,255,',',fpr);
						drvid   = math_op(fpr,element);
						breadchar(element,255,',',fpr);
						drvtype = math_op(fpr,element);

						ei = 0;
						while( btop(fpr)!=']' )
						{
							i  = 0;
							angle = 0;
							for(;;)
							{
								element[i] = btop(fpr);
								if( (element[i]>=0x81 && element[i]<=0x9f)||(element[i]>=0xe0 && element[i]<=0xfc))
								{
									element[i++]=bgetc(fpr);
									element[i  ]=btop (fpr);
								}
								else if( element[i]=='\"' )angle=1-angle;
								else if( (element[i]==',' || element[i]==']') && angle==0 )
								{
									if( element[i]==',' )bnext(fpr);
									break;
								}
								i++;
								if( i>=255 )
								{
									erl(fpr,ERR);
									printf("\'@ecm\' エレメントが長すぎます。\n");
									return;
								}
								bnext(fpr);
							}
							element[i]=NULL;
							
							if( element[0]=='\"' )
							{
								cut_space(element);
								di = 0;
								while( element[di]!=NULL )
								{
									ecmbuf[ei++] = element[di++];
									if( ei>=ECMBUF )
									{
										erl(fpr,ERR);
										printf("\'@ecm\' メッセージが長すぎます。\n");
										return;
									}
								}
							}
							else if( element[0]=='w' )
							{
								x = math_op(fpr,element+1);
								ecmbuf[ei++] = x &  0xff;
								ecmbuf[ei++] = x >> 8;
							}
							else 
							{
								x = math_op(fpr,element);
								ecmbuf[ei++] = x;
							}
							if( ei>=ECMBUF )
							{
								erl(fpr,ERR);
								printf("\'@ecm\' データが多すぎます。\n");
								break;
							}
						}
						bnext(fpr);
						mputc( 0xe1   ,&fpw[track] );
						mputw( drvid  ,&fpw[track] );
						mputc( drvtype,&fpw[track] );
						mputw( ei     ,&fpw[track] );
						for( i=0; i<ei; i++)
							mputc( ecmbuf[i],&fpw[track]);
						break;
/*==== エクスプレッション情報だった！ ====*/
					default:
						x = valcomp("@e",&expression[track],0,127,fpr);
						mputc( 0xa7,&fpw[track] );
						mputc( x   ,&fpw[track] );
						break;
				}
				break;
/*==== 音色変更 ====*/
			case '@':
				x = valcomp("@",&instrument[track],0,255,fpr);
				mputc( 0xb1,&fpw[track] );
				mputc( x   ,&fpw[track] );
				chgflag[track] = TRUE;
				break;
/*==== オクターブ変更(1) ====*/
			case 'o':
				x = valcomp("o",&octave[track],0,9,fpr);
				break;
/*==== オクターブ変更(2) ====*/
			case '>':
				if( ++octave[track]>10 )
				{
					erl(fpr);
					printf("\'>\' で octave が 10 より大きくなりました。\n");
					octave[track] = 9;
				}
				break;
			case '<':
				if( --octave[track]<0 )
				{
					erl(fpr);
					printf("\'<\' で octave が 0 より小さくなりました。\n");
					octave[track] = 0;
				}
				break;
/*==== パンポット情報 & poly！ ====*/
			case '@p':
				if( btop(fpr)!='l' )
				{
					x = valcomp("@p",&panpot[track],0,127,fpr);
					mputc( 0xa6,&fpw[track] );
					mputc( x   ,&fpw[track] );
					break;
				}
				else
				{
					bnext(fpr);
					mputc( 0xba,&fpw[track] );
				}
				break;
/*==== ビブラート情報！ ====*/
			case 'm':
				x = valcomp("m",&modulation[track],0,127,fpr);
				mputc( 0xa2,&fpw[track] );
				mputc( x   ,&fpw[track] );
				break;
/*==== リバーブセンドレベル情報！ ====*/
			case '@f':
				switch( cmd=bgetc(fpr) )
				{
					case 'r':
						x = valcomp("@fr",&rsendlv[track],0,127,fpr);
						mputc( 0xad,&fpw[track] );
						mputc( x   ,&fpw[track] );
						break;
					case 'c':
						x = valcomp("@fc",&csendlv[track],0,127,fpr);
						mputc( 0xae,&fpw[track] );
						mputc( x   ,&fpw[track] );
						break;
					default:
						erl(fpr,ERR);
						printf("\'@f%c\' というコマンドは存在しません。\n",cmd);
						break;
				}
				break;
/*==== バンク変更 ====*/
			case '@b':
				x = bnumber16(fpr);
				if( bnum16flag==FALSE )
				{
					erl(fpr,ERR);
					printf("\'@b\' パラメータの数値(10,16進数)がありません。\n");
					break;
				}
				if( x&0x8000 || x&0x0080 )
				{
					erl(fpr,ERR);
					printf("\'@b\' コマンドのバンクナンバー上位または下位が7fを越えています。\n");
					break;
				}
				bank[track] = x;
				mputc( 0xa1,&fpw[track] );
				mputw( x   ,&fpw[track] );
				chgflag[track] = TRUE;
				break;
/*==== デフォルトゲートタイム変更 ====*/
			case 'q':
				valcomp("q",&gatetime[track],1,32767,fpr);
				break;
/*==== デフォルトベロシティー変更 ====*/
			case 'x':
				valcomp("x",&velocity[track],1,127,fpr);
				break;
/*==== 繰り返し ====*/
			case '[':
				x = bnumber(fpr);
				if( bnumflag==FALSE )
				{
					erl(fpr,ERR);
					printf("\'[x\' 繰り返し数(10進数)がありません。\n");
					break;
				}
				if( x>255 )
				{
					erl(fpr,ERR);
					printf("\'[n\' 繰り返し回数は 1..255 or 0(無限loop) です。\n");
					break;
				}
				if( loop[track]++>=16 )
				{
					erl(fpr,WNG);
					printf("\'[n\' 繰り返し可能な nest 回数は 16階層までです。\n");
				}
				mputc( 0xd0,&fpw[track] );
				mputc( x   ,&fpw[track] );
				break;

			case ']':
				if( loop[track]<=0 )
				{
					erl(fpr,ERR);
					printf("\'[\' と \']\' が対応していません。\n");
					break;
				}
				loop[track]--;
				mputc( 0xd1,&fpw[track] );
				break;
			
			case ':':
				if( loop[track]<=0 )
				{
					erl(fpr,ERR);
					printf("\':\' が、\'[\' と \']\' の間にはさまれていません。\n");
					break;
				}
				mputc( 0xd2,&fpw[track] );
				break;

/*==== テンポ変更 ====*/
			case 't':
				x = valcomp("t",&tempo,32,32767,fpr);
				mputc( 0xc4,&fpw[track] );
				mputw( x   ,&fpw[track] );
				break;
/*==== ベンド変更 ====*/
			case 'p':
				x = valcomp2("p",&pitchbend[track],-8192,8191,fpr);
				pitchbend[track] = x;
				mputc( 0xb3,&fpw[track] );
				mputw( x   ,&fpw[track] );
				break;
/*==== @x関連 ====*/
			case '@x':
				switch(bgetc(fpr))
				{
/*---- @xan,@xas : all noteoff ----*/
					case 'a':
						cmd = bgetc(fpr);
						if( cmd=='n' )
						{
							mputc(0xb6,&fpw[track]);
						}
						else if( cmd=='s' )
						{
							mputc(0xb4,&fpw[track]);
						}
						else
						{
							erl(fpr,ERR);
							printf("\'@xa%c\' というコマンドは存在しません。\n");
						}
						break;
/*---- @xt ソステヌート ----*/
					case 't':
						cmd = bgetc(fpr);
						if( cmd=='+' )
						{
							mputc(0xaa,&fpw[track]);
							mputc(127, &fpw[track]);
						}
						else if( cmd=='-' )
						{
							mputc(0xaa,&fpw[track]);
							mputc(0   ,&fpw[track]);
						}
						else 
						{
							erl(fpr,ERR);
							printf("\'@xt\' のスイッチは + or - です。\n");
						}
						break;
/*---- @xs ソフト ----*/
					case 's':
						cmd = bgetc(fpr);
						if( cmd=='+' )
						{
							mputc(0xab,&fpw[track]);
							mputc(127, &fpw[track]);
						}
						else if( cmd=='-' )
						{
							mputc(0xab,&fpw[track]);
							mputc(0   ,&fpw[track]);
						}
						else 
						{
							erl(fpr,ERR);
							printf("\'@xs\' のスイッチは + or - です。\n");
						}
						break;
/*---- @xh ホールド ----*/
					case 'h':
						cmd = bgetc(fpr);
						if( cmd=='+' )
						{
							mputc(0xa8,&fpw[track]);
							mputc(127, &fpw[track]);
						}
						else if( cmd=='-' )
						{
							mputc(0xa8,&fpw[track]);
							mputc(0   ,&fpw[track]);
						}
						else 
						{
							erl(fpr,ERR);
							printf("\'@xh\' のスイッチは + or - です。\n");
						}
						break;
/*---- @xp? ポルタメント関係 ----*/
					case 'p':
						cmd = bgetc(fpr);
						if( cmd=='+' )
						{
							mputc(0xa9,&fpw[track]);
							mputc(127, &fpw[track]);
						}
						else if( cmd=='-' )
						{
							mputc(0xa9,&fpw[track]);
							mputc(0   ,&fpw[track]);
						}
						else if( cmd=='t' )
						{
							x = bnumber(fpr);
							if( bnumflag==FALSE )
							{
								erl(fpr,ERR);
								printf("\'@xpt\' パラメータの数値(10進数)がありません。\n");
								break;
							}
							if( x<0 || x>127 )
							{
								erl(fpr,ERR);
								printf("\'@xpt\' の値は 0..127 までです。\n");
								break;
							}
							mputc( 0xa3,&fpw[track] );
							mputc(    x,&fpw[track] );
						}
						else if( cmd=='c' )
						{
							x = bnumber(fpr);
							if( bnumflag==FALSE )
							{
								erl(fpr,ERR);
								printf("\'@xpc\' パラメータの数値(10進数)がありません。\n");
								break;
							}
							if( x<0 || x>127 )
							{
								erl(fpr,ERR);
								printf("\'@xpc\' の値は 0..127 までです。\n");
								break;
							}
							mputc( 0xac,&fpw[track] );
							mputc(    x,&fpw[track] );
						}
						else {
							erl(fpr,ERR);
							printf("\'@xp\' のスイッチは +,-,t and c です。\n");
						}
						break;
/*---- @xr reset all controller ----*/
					case 'r':
						mputc(0xb5,&fpw[track]);
						break;
/*---- channel presser 変更 ----*/
					case 'c':
						valcomp("@xc",&cpress[track],0,127,fpr);
						break;
				}
				break;
/*==== @om関連 ====*/
			case '@o':
				if( (cmd=bgetc(fpr))!='m' )
				{
					erl(fpr,ERR);
					printf("\'@o%c\' というコマンドは存在しません。\n",cmd);
					break;
				}
				cmd = bgetc(fpr);
				if( cmd=='+' )
					mputc(0xb8,&fpw[track]);
				else if( cmd=='-' )
					mputc(0xb7,&fpw[track]);
				else {
					erl(fpr,ERR);
					printf("\'@om\' のスイッチは + or - です。\n");
				}
				break;
/*==== @nr関連 ====*/
			case '@n':
				if( (cmd=bgetc(fpr))!='r' )
				{
					erl(fpr,ERR);
					printf("\'@n%c\' というコマンドは存在しません。\n",cmd);
					break;
				}
				adr=bnumber16(fpr);
				if( bnum16flag==FALSE )
				{
					erl(fpr,ERR);
					printf("\'@nr\' パラメータのアドレス(10,16進数)がありません。\n");
					break;
				}
				ll = adr &  0xff;
				mm = adr >> 8;
				if( mm>=0x80 )
				{
					erl(fpr,WNG);
					printf("NRPN のアドレス 上位8ビット(mm)が、0..127 を越えています。\n");
					mm &= 0x7f;
				}
				if( ll>=0x80 )
				{
					erl(fpr,WNG);
					printf("NRPN のアドレス 下位8ビット(ll)が、0..127 を越えています。\n");
					ll &= 0x7f;
				}
				mputc( 0xaf,&fpw[track] );
				mputc(    0,&fpw[track] );
				mputc(   mm,&fpw[track] );
				mputc( 0xaf,&fpw[track] );
				mputc(    1,&fpw[track] );
				mputc(   ll,&fpw[track] );
				break;
/*==== @rp関連 ====*/
			case '@r':
				if( (cmd=bgetc(fpr))!='p' )
				{
					erl(fpr,ERR);
					printf("\'@r%c\' というコマンドは存在しません。\n",cmd);
					break;
				}
				adr=bnumber16(fpr);
				if( bnum16flag==FALSE )
				{
					erl(fpr,ERR);
					printf("\'@rp\' パラメータのアドレス(10,16進数)がありません。\n");
					break;
				}
				ll = adr &  0xff;
				mm = adr >> 8;
				if( mm>=0x80 )
				{
					erl(fpr,WNG);
					printf("RPN のアドレス 上位8ビット(mm)が、0..127 を越えています。\n");
					mm &= 0x7f;
				}
				if( ll>=0x80 )
				{
					erl(fpr,WNG);
					printf("RPN のアドレス 下位8ビット(ll)が、0..127 を越えています。\n");
					ll &= 0x7f;
				}
				mputc( 0xb0,&fpw[track] );
				mputc(    0,&fpw[track] );
				mputc(   mm,&fpw[track] );
				mputc( 0xb0,&fpw[track] );
				mputc(    1,&fpw[track] );
				mputc(   ll,&fpw[track] );
				break;
/*==== @dm,@dl,@dt 関連 ====*/
			case '@d':
				switch( bgetc(fpr) )
				{
					case 'l':
						x = bnumber16(fpr);
						if( bnum16flag==FALSE )
						{
							erl(fpr,ERR);
							printf("\'@dl\' データ(10,16進数)がありません。\n");
							break;
						}
						if( x<0 || x>127 )
						{
							erl(fpr,WNG);
							printf("\'@dl\' DATAENTRY の下位8ビット(ll)が、0..127 を越えています。\n");
							x &= 0x7f;
						}
						mputc( 0xa4,&fpw[track] );
						mputc(    1,&fpw[track] );
						mputc(    x,&fpw[track] );
						break;
					case 'm':
						x = bnumber16(fpr);
						if( bnum16flag==FALSE )
						{
							erl(fpr,ERR);
							printf("\'@dm\' データ(10,16進数)がありません。\n");
							break;
						}
						if( x<0 || x>127 )
						{
							erl(fpr,WNG);
							printf("\'@dh\' DATAENTRY の上位8ビット(mm)が、0..127 を越えています。\n");
							x &= 0x7f;
						}
						mputc( 0xa4,&fpw[track] );
						mputc(    0,&fpw[track] );
						mputc(    x,&fpw[track] );
						break;
					case 't':
						x = bnumber16(fpr);
						if( bnum16flag==FALSE )
						{
							erl(fpr,ERR);
							printf("\'@dt\' データ(10,16進数)がありません。\n");
							break;
						}
		
						ll = x &  0xff;
						mm = x >> 8;
						if( mm>=0x80 )
						{
							erl(fpr,WNG);
							printf("\'@dm\' DATAENTRY の上位8ビット(mm)が、0..127 を越えています。\n");
							mm &= 0x7f;
						}
						if( ll>=0x80 )
						{
							erl(fpr,WNG);
							printf("\'@dm\' DATAENTRY の下位8ビット(ll)が、0..127 を越えています。\n");
							ll &= 0x7f;
						}
						mputc( 0xa4,&fpw[track] );
						mputc(    0,&fpw[track] );
						mputc(   mm,&fpw[track] );
						mputc( 0xa4,&fpw[track] );
						mputc(    1,&fpw[track] );
						mputc(   ll,&fpw[track] );
						break;
					defaut:
						erl(fpr,ERR);
						printf("\'@d%c\' というコマンドは存在しません。\n",cmd);
						break;
				}
				break;
/*==== @mn,@mv ====*/
			case '@m':
				switch( cmd=bgetc(fpr) )
				{
					case 'n':
						x = bnumber(fpr);
						if( bnumflag==FALSE )
						{
							erl(fpr,ERR);
							printf("\'@mn\' mono数(10進数)がありません。\n");
							break;
						}
						if( x<0 || x>127 )
						{
							erl(fpr,ERR);
							printf("\'@mn\' の値は 0..127 までです。\n");
							break;
						}
						mputc( 0xb9,&fpw[track] );
						mputc(    x,&fpw[track] );
						break;
					case 'v':
						x = bnumber(fpr);
						if( bnumflag==FALSE )
						{
							erl(fpr,ERR);
							printf("\'@mv\' マスターボリューム値(10進数)がありません。\n");
							break;
						}
						if( x<0 || x>127 )
						{
							erl(fpr,ERR);
							printf("\'@mv\' の値は 0..127 までです。\n");
							break;
						}
						mputc( 0xb9,&fpw[track] );
						mputc(    x,&fpw[track] );
						break;
					default:
						erl(fpr,ERR);
						printf("\'@m%c\' というコマンドは存在しません。\n",cmd);
						break;
				}
				break;
/*==== 調設定 ====*/
			case '%':
				for( i=0; i<7; i++)
				{
					key[track][i] = 0;
				}
				while( (cmd=bgetc(fpr))!='%' )
				{
					if( cmd<'a' || cmd>'g' )
					{
						erl(fpr,ERR);
						printf("\'\%\' \%..\%#,+/- の中身に note以外の文字(%c)があります。\n",cmd);
						break;
					}
					cmd-='a';
					key[track][cmd]=1;
				}
				cmd=bgetc(fpr);
				if( cmd=='+' || cmd=='#' ) x = 1;
				else if( cmd=='-' )        x = -1;
				else {
					erl(fpr,ERR);
					printf("\'\%\' \%..\%#,+/- の #,+/- の指定が不正です(%c)。\n",cmd);
					break;
				}
				for(i=0; i<7; i++)
				{
					if( key[track][i]==1 )key[track][i]=x;
				}
				break;
/*==== トランスポーズ状態変化 ====*/
			case '_{':
				if( transposeflag[track]==FALSE )
				{
					erl(fpr,WNG);
					printf("\'_{\' _{ ... _} のネストはできません。\n");
				}
				transposeflag[track]=FALSE;
				break;
			case '_}':
				if( transposeflag[track]==TRUE )
				{
					erl(fpr,WNG);
					printf("\'_}\' _{ ... _}のネストはできません。\n");
				}
				transposeflag[track]=TRUE;
				break;
			case '_':
				x = valcomp2("_",&transposetrack[track],-127,127,fpr);
				break;
/*==== プレイフラグ変更 ====*/
			case '|':
				playflag=(playflag==TRUE)?FALSE:TRUE;
				break;
/*==== バイナリ書き出し機能 ====*/
			case '\\':
				if( (cmd=bgetc(fpr))!='[' )
				{
					erl(fpr,ERR);
					printf("\'\\\' \'[\' が見つかりません。\n",cmd);
					break;
				}
				ei = 0;
				while( btop(fpr)!=']' )
				{
					breadchar2(element,255,',',']',fpr);
					if( btop(fpr)==',' )bnext(fpr);
					elementdata[ei++]=math_op(fpr,element);

					if( ei>=255 )
					{
						erl(fpr,ERR);
						printf("\'\\\' データが多すぎます。\n");
						return;
					}
				}
				bnext(fpr);
				for( i=0; i<ei; i++)
					mputc( elementdata[i],&fpw[track]);
				break;
/*==== 区切り ====*/
			case ',':
				break;
/*==== 行終了 ====*/
			case ';':
				if( option[OPT_D]==TRUE )
				{
					fprintf(stderr,"\x1b[4;32m;)\x1b[m\n\n");
				}
				return;
/*==== 意味不明 ====*/
			default:
			exits:
				erl(fpr);
				if(cmd>=0 && cmd<=255)
				{
					printf("\'%c\'",cmd);
				}
				else
				{
					printf("\'%c%c\'",cmd&0xff,cmd>>8);
				}
				printf("は解釈不可能なMMLコマンドです。\n");
				if( option[OPT_D]==TRUE )
				{
					fprintf(stderr,"\x1b[4;32m)\x1b[41mERROR\x1b[m\n\n");
				}
				return;
		}
	}
	if( option[OPT_D]==TRUE )
	{
		fprintf(stderr,"\x1b[4;32m EOL)\x1b[m\n\n");
	}
}
