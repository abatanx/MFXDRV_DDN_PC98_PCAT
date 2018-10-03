/*---------------------------------------------------------------------------
       MFXDRV/DDN system XMML3.00 compiler MPLUS(mfxc+) release 1.00
  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
 *---------------------------------------------------------------------------*/
//
// Header file
//
#include	<mfile.h>
#include	<mylib.h>

#define		version_int		1
#define		version_real	19
#define		version_char	' '
#define		MAXSTACK	32				// スタック
#define		MAXARG		128				// マクロアーギュメント
#define		MAXARGSIZE	128				// マクロアーギュメント

#define		TMPFILE		"$xmpctrk"
#define		MEMOFILE	"$xmpcmmo"

#define		ERR			1
#define		WNG			2
#define		SYS			4

enum {
	OPT_A,OPT_B,OPT_C,OPT_D,OPT_E,OPT_F,OPT_G,OPT_H,OPT_I,OPT_J,OPT_K,OPT_L,
	OPT_M,OPT_N,OPT_O,OPT_P,OPT_Q,OPT_R,OPT_S,OPT_T,OPT_U,OPT_V,OPT_W,OPT_X,
	OPT_Y,OPT_Z
};

// トラック情報
#define		MAXTRACK	32

typedef struct 
{
	char linkflag;
	char linktrack;
	char name[32];
	struct {
		char module[32];
		int  channel;
	} chain[4];
} TRACKINFO;
extern	TRACKINFO	trk[MAXTRACK];
extern	int			maxtrack,timebase,transpose,objects;

#define		LINK_INTERNAL	1
#define		LINK_EXTERNAL	2

// CLASS定義
typedef class pstack
{
	void *stack[MAXSTACK];
public:
	int  stack_pointer;
	int  err_flag;
	pstack(){stack_pointer=0;}
	void push(void *data);
	void *pop(void);
} PSTACK;

typedef class istack
{
	int  stack[MAXSTACK];
public:
	int  stack_pointer;
	int  err_flag;
	istack(){stack_pointer=0;}
	void push(int data);
	int  pop(void);
	int  top(void);
} ISTACK;

typedef class lstack
{
	long stack[MAXSTACK];
public:
	int  stack_pointer;
	int  err_flag;
	lstack(){stack_pointer=0;}
	void push(long data);
	long pop(void);
} LSTACK;

// 音色辞書
typedef struct instrument_adt {
	int no,bank;
	struct instrument_adt *left,*right;
} ADT;
extern	ADT		*root;

// 曲データヘッダ
typedef struct {
	byte
		title[256],composer[256],arranger[256],lyric[256],artist[256],
		copyright[256],programmer[256];
} MUDHEADMSG;
extern	MUDHEADMSG	head;

// マクロ制御
typedef struct MacroDefinition {
	char *source;
	char *distnation;
	char *argument;
	struct MacroDefinition *next;
} MACRO;
extern	MACRO		*macro;
extern	char		*m_arg[],*v_arg[],*work,*memofile;

// ファイル制御
#define		BFILE_BUFSIZE	6144
#define		BFILE_FILE		1
#define		BFILE_MEMORY	2

typedef struct {
	char dmy[128];
	unsigned char *buf;
	char filename[80];
	long size;
	long fp;
	unsigned binfp;
	int chr;
	int line;
	int fd;
	int type;
} BFILE;

BFILE		*bopen(char *);
int			bopen2(BFILE *,char *,char *,int,int);
void		bclose(BFILE *);
int			bgetc(BFILE *);
int			bgetc2(BFILE *);
unsigned	bgetw(BFILE *);
int			bread(void *,unsigned,BFILE *);
int			btop(BFILE *fp);
void		bnext(BFILE *fp);
int			breadchar(void *buf,unsigned size,unsigned char c,BFILE *fp);
int			breadchar2(void *buf,unsigned size,unsigned char c1,unsigned char c2,BFILE *fp);
int			bstandard(void *buf,unsigned size,BFILE *fp);
int			bstandard2(void *buf,unsigned size,BFILE *fp);
int			bstandard3(void *buf,unsigned size,BFILE *fp);
int			bskipspace(BFILE *fp);
int			bgets(void *buf,unsigned size,BFILE *fp);
int			bgetspace(void *buf,unsigned size,BFILE *fp);
int			buntilchar(BFILE *fp);
int			buntilreturn(BFILE *fp);
int			bnumber(BFILE *fp);
int			bnumber16(BFILE *fp);

extern		MFILE	fpw[MAXTRACK];

// Plottype
void exits(int);
void exits2(int);

void compile(char *,MFILE *);
void preprocessor(char *,MFILE *);
void sys(BFILE *,MFILE *);
void erl(BFILE *,int type=ERR);
int  obj(BFILE *,char *objname);
void operate_line(char *,char *,BFILE *);


void init_label(void);
void set_label(MFILE *,int,int);
void set_label_value(int,long);
void write_label(char *);

void makembj_header(MFILE *);
void makembj       (MFILE *,char *);
void makembs       (char *);

void encode_macro(char *,BFILE *);
char *keepmem(int);

ADT  *makeadt(ADT *,int,int);
void printadt(ADT *,MFILE *);

char *get_define(char *);
char *get_define2(char *);

void set_mplay(char *,char *);

long math_op(BFILE *,char *);
//
void _deb(char *);
void _deb(byte *);
void _deb(int);
void _deb(long);

// ifdef関係
extern	ISTACK	xifdef;
extern	int	option[];
