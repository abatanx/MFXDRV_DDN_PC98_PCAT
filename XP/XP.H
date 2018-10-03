/*
 *  XMML3.00 visual music player xp.exe for MFXDRV/DDN
 *  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
 *  94/09/15 êßçÏäJén
 */

#define		version_int		0
#define		version_real	01
#define		version_char	' '

enum ViewStatusCodes{
	QUIT,VIEW_A,VIEW_B
};

extern		char *soundlist[],*keymonitor[],*keymonitor2[];

void	check_and_write(int *,int,int,int,int,char *);
int		view_a_mode(void);
int		view_b_mode(void);
