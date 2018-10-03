/* fl.h */
#ifndef		__FL
#define		__FL

typedef struct {
	char atr;
	unsigned time;
	unsigned date;
	long size;
	char fname[14];
} FILEDEF;

typedef struct {
	FILEDEF finf;
	long fp;
} FILEINFO;

extern FILEDEF  finf;
extern FILEINFO file_info[];
extern int FILELINK_use_switch;

#ifdef	__cplusplus
extern "C" {
#endif

FILE *fl_open(char *,char *);
int  fl_file(char *);
void fl_switch(int);

#ifdef	__cplusplus
}
#endif

#endif
