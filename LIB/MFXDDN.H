/*---------------------------------------------------------------------------
   MFXDDN the XMML ver.3.00 MFXDRV/DDN ドライバー制御ライブラリ
                             MFXDDN.H version 1.00
  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
-----------------------------------------------------------------------------*/
#ifndef		__mfxddn_h_ver100
#define		__mfxddn_h_ver100

#ifdef		__DDN_BUILT__
#include	"ddnbuilt.h"
#endif

#define		C_DDN_VERSION				"1.10"
#define		C_DDN_INNERRELEASE			"R1.3"

#include	<stdio.h>
extern	int MFXDDN_Initialize;				/* 初期化フラグ */
#define		CONFIG_FILELINK			FALSE	/* 常時FALSEにしてください     */
#define		CONFIG_MTLIB			FALSE	/* 常時FALSEにしてください     */

#define		DDN_NOTINSTALLED			0	/* DDNLIB がINSTALLされてない	*/
#define		DDN_NOTENOUGHMEMORY			1	/* メモリが足りない				*/
#define		DDN_FILENOTFOUND			2	/* ファイルが見つからない		*/
#define		DDN_NOTMUDFILE				3	/* MUD ファイルではない			*/
#define		DDN_VERSIONERROR			4	/* XMML3.00 ではない			*/
#define		DDN_DRIVERNOTFOUND			5	/* DRIVERが見つからない			*/
#define		DDN_MUDSIZEOVER				6	/* サイズが大きすぎる			*/
#define		DDN_COMPLETE				7	/* 演奏成功						*/
#define		DDN_COMPLETEEXEC			8	/* 実行成功						*/
#define		DDN_FAULTEXEC				9	/* 実行失敗						*/

#define		XDVTITLE_ON					0
#define		XDVTITLE_OFF				1

#define		MAX_SEBUF		16

#ifndef		TRUE
#define		TRUE		1
#define		FALSE		0
typedef		unsigned char	byte;
typedef		unsigned		word;
#endif

/*** MFXDDN structure ***/
typedef struct {
	int ver_int;
	int ver_float;
	int ver_char;
	char title[256];
	char composer[256];
	char arranger[256];
	char lyric[256];
	char artist[256];
	char copyright[256];
	char memo[256];
	int  da_year,da_month,da_day;
	int  ti_hour,ti_min,  ti_sec;
} MUD_HEADER;

/*** MFXDDN structure ***/
typedef struct {
	int ver_int;
	int ver_float;
	int ver_char;
	char *memory;
	char *linker;
	char *title;
	char *composer;
	char *arranger;
	char *lyric;
	char *artist;
	char *copyright;
	char *memo;
	int  da_year,da_month,da_day;
	int  ti_hour,ti_min,  ti_sec;
} MUD_MUSICINFO;

#define		MUSICINFO_LINKER	255
#define		MUSICINFO_TITLE		255
#define		MUSICINFO_COMPOSER	255
#define		MUSICINFO_ARRANGER	255
#define		MUSICINFO_LYRIC		255
#define		MUSICINFO_ARTIST	255
#define		MUSICINFO_COPYRIGHT	255
#define		MUSICINFO_MEMO		1024
#define		MUSICINFO_TOTALSIZE	(MUSICINFO_LINKER+MUSICINFO_TITLE+\
			MUSICINFO_COMPOSER+MUSICINFO_ARRANGER+MUSICINFO_LYRIC+\
			MUSICINFO_ARTIST+MUSICINFO_COPYRIGHT+MUSICINFO_MEMO)

/*** MFXDDN track buffer structure ***/
typedef struct {
	int flag;
	char far *buffer;
	long buffer_size;
} MUD_TRACKWORK;

typedef struct {
	char module[16];
	unsigned char channel;
} MUD_MODULE;

typedef struct {
	MUD_MODULE chain[4];
	long bin_fp;
	long bin_size;
	unsigned bin_comp;
	unsigned ext;
} MUD_TRACK;

typedef struct {
	char track_number;
	int  timebase;
	char far *track_address[32];
} MUD_TRACKINFO;

typedef struct {
	char far *buffer;
	int driver;
	int channel;
	int track;
} SE_INFO;

extern	long			MFXDDN_MAXMUDSIZE;
extern	MUD_TRACKWORK	mud_track_work[32];
extern	MUD_TRACKINFO	track_info;
extern	MUD_HEADER		mud;
extern	SE_INFO			se[MAX_SEBUF];
extern	int				mfxddn_err;
extern	int				MFXDDN_Initialize;
extern	char far		*mfxddn_musicbuffer;

#define		mfxddn_errset(a)	mfxddn_err=(a)

/* Plottype */
#ifdef __cplusplus
extern "C" {
#endif

int		  mfxddn_install_kernel(void);
int		  mfxddn_remove_kernel(void);
int		  mfxddn_load_driver(char *,char *,int);
int		  mfxddn_load_driver_filelink(char *,char *,int);

unsigned  ddn_valtonum(char *str);
int		  ddn_flz_load_fp(char far *buf,FILE *fpr,long fsize);
int		  ddn_flz_load_fp_mtlib(char far *buf,long fsize);
int		  ddn_flz_load(char far *,char *);
void	  ddn_cut_space( char *buf );
int		  ddn_instr( char *,char );
int		  ddn_instrback( char *,char );
int		  ddn_strcmp(char *,char *);
int		  ddn_strncmp(char *,char *,int);
int		  ddn_stricmp(char *,char *);
void	  ddn_cut_dirmark(char *);
void	  ddn_add_dirmark(char *);
char	 *ddn_far2near( char far * );
int		  mfxddn_se_play( int no );
int		  mfxddn_se_load( int no,char *filename,char *drvid,int channel,int track );
int		  mfxddn_se_load_filelink( int no,char *filename,char *drvid,int channel,int track );
int		  mfxddn_get_driver_version(char *drvid);
int		  mfxddn_get_driver_type(char *drvid);
int		  mfxddn_get_driver_table( char *drvid );
int		  mfxddn_get_driver_canusech(char *drvid);
int		  mfxddn_errortype(void);
void	  mfxddn_add_space(char *buf,char *drvid);
char	 *mfxddn_errmsg(void);
void	  mfxddn_change_musicbuffer(char far *buffer);
int		  mfxddn_bgm_play(char *filename);
int		  mfxddn_bgm_replay(void);
int		  mfxddn_bgm_play_filelink(char *filename);
int		  mfxddn_bgm_play_mtlib(char *filename);
int		  mfxddn_bgm_init2(char far *buffer);
int		  mfxddn_bgm_init(void);

int		  mfxddn_se_play_local(char far *,int,int,int);
int		  ddn_free_memory(char far *);
char far *ddn_keep_highmemory(long);
int		  ddn_stay_memory(char far *);
int		  mfxddn_get_driver_version_local(char far *);
int		  mfxddn_get_work(int,int);
#define		mfxddn_get_work_byte(a,b)	(int)(mfxddn_get_work((a),(b))&0xff)
int		  mfxddn_get_driver_type_local(char far *);
int		  mfxddn_get_driver_table_local(char far *);
char far *mfxddn_get_driver_name(int);
int		  mfxddn_get_canuse_channel_local(char far *);
char far *mfxddn_get_chain_address(void);
int		  mfxddn_get_playstatus(void);
int		  mfxddn_get_timebase(void);
int		  mfxddn_get_tempo(void);
int		  mfxddn_get_mastervolume(void);
long	  mfxddn_get_counter(void);
int		  mfxddn_get_mean(void);
int		  mfxddn_get_mean_counter(void);
int		  mfxddn_del_chain_address(char far *);
int		  mfxddn_set_note_buffer(int,char far *);
int		  mfxddn_rel_note_buffer(int);
int		  mfxddn_install_check(void);
int		  mfxddn_dcm_volume(int,int,int);
int		  mfxddn_dcm_expression(int,int,int);
int		  mfxddn_dcm_init(int);
int		  mfxddn_dcm_end(int);
int		  mfxddn_dcm_progchange(int,int,int);
int		  mfxddn_dcm_noteon(int,int,int,int);
int		  mfxddn_dcm_noteoff(int,int,int);
int		  mfxddn_dcm_ecm(int,void far *);
int		  mfxddn_bgm_stop(void);
int		  mfxddn_bgm_start(void far *);
int		  mfxddn_bgm_pause(void);
int		  mfxddn_bgm_fadeout(int);
int		  mfxddn_bgm_continue(void);
int		  mfxddn_add_chain_address(char far *);

int		  mfxddn_get_musicinfo(char *,MUD_MUSICINFO *);
int		  mfxddn_get_musicinfo_filelink(char *,MUD_MUSICINFO *);
int		  mfxddn_alloc_musicinfo(MUD_MUSICINFO *);

FILE	 *fl_open(char *,char *);
void	  fl_switch(int);
int		  fl_file(char *);

#ifdef __cplusplus
}
#endif
#endif
