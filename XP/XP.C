/*
 *  XMML3.00 visual music player xp.exe for MFXDRV/DDN
 *  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
 *  94/09/15 制作開始
 */
#include	<stdio.h>
#include	<string.h>
#include	<conio.h>
#include	<master.h>
#include	<mfxddn.h>
#include	"xp.h"

unsigned char palettes[48]=
	{
	15,15,15,	0,0,15,		15,0,0,		15,0,15,
	0,15,0,		0,15,15,	15,15,0,	12,12,12,

	14,14,14,	0,0,4,		6,3,0,		6,0,4,
	0,5,0,		0,3,9,		7,5,0,		0,0,0
	};

char *keymonitor[32],*keymonitor2[32];

int main(int argc,char **argv)
{
	int i,j,erc,flag = NULL;
	unsigned seg;
	char exepath[128],fname[128],*p;
	int viewmode;
	
	strcpy(exepath,argv[0]);
	p = file_basename(exepath);
	*p = NULL;

	printf(
		"XMML3.00 music driver visual monitor XP version %1d.%02d%c\n"
		"copyright (c) 1994 by ABA / T.Kobayashi and Interfair All Rights "
		"Reserved.\n",
		version_int,version_real,version_char
	);
	if( mfxddn_bgm_init()!=NULL )
	{
		printf("mfxdrv/ddn が常駐していません。\n");
		return 1;
	}

//	graph_backup(G_ALLPAGE);
	graph_start();
	graph_analog();

	key_start();
	key_beep_off();

	text_backup(0);
	text_start();
	text_clear();
	text_cursor_hide();
	text_systemline_hide();

	for(i=0;i<32;i++)
	{
		seg = hmem_lallocate(256L);
		if( !seg )
		{
			printf("T_T メモリーが足りません。\n");
			flag=EOF;
			break;
		}
		keymonitor [i]=MK_FP(seg,0  );
		keymonitor2[i]=MK_FP(seg,128);
		for( j=0;j<256;j++ )*(keymonitor[i]+j)=0;
	}
	strcpy(fname,exepath);
	strcat(fname,"xp.p16");
	erc = super_entry_bfnt(fname);
	if( erc<1 || erc>511 )
	{
		printf("%s:",fname);
		switch(erc)
		{
			case GeneralFailure:
				puts("登録できるキャラクター数を越えています。");
				break;
			case FileNotFound:
				puts("ファイルがオープンできません。");
				break;
			case InvalidData:
				puts("ファイルの形式が BFNT+ ではありません。");
				break;
			case InsufficientMemory:
				puts("メモリーが足りません。");
				break;
		}
		flag = EOF;
	}
	else
	{
		for(i=0;i<8;i++)super_entry_char(3+i);
	}

	strcpy(fname,exepath);
	strcat(fname,"xp.ank");
	erc = wfont_entry_bfnt(fname);
	if( erc!=NoError )
	{
		printf("%s:",fname);
		switch(erc)
		{
			case FileNotFound:
				puts("ファイルが見つかりません。");
				break;
			case InvalidData:
				puts("フォントの内容が違います。");
				break;
			case InsufficientMemory:
				puts("メモリーが足りません。");
				break;
		}
		flag = EOF;
	}

	palette_init();
	strcpy(fname,exepath);
	strcat(fname,"xp.rgb");
	erc = palette_entry_rgb(fname);
	if( erc!=NoError )
	{
		printf("%s:ファイルが見つかりません。\n",fname);
		flag = EOF;
	}
	else
	{
		palette_show();
	}

/*---- メイン ----*/
	if( flag==NULL )
	{
		for(i=0;i<32;i++)mfxddn_set_note_buffer(i,keymonitor[i]);
		viewmode = VIEW_B;
		for(;;)
		{
			if( viewmode==QUIT )break;
			switch(viewmode)
			{
				case VIEW_A:
					viewmode=view_a_mode();
					break;
				case VIEW_B:
					viewmode=view_b_mode();
					break;
				default:
					viewmode=QUIT;
					break;
			}
		}
		for(i=0;i<32;i++)mfxddn_rel_note_buffer(i);
	}
/*---- メイン終了^^; ----*/

	text_cursor_show();
	text_systemline_show();

	if( respal_exist() )
	{
		respal_get_palettes();
		palette_show();
	}
	else
	{
		palette_init();
		palette_show();
	}

	text_restore();
	graph_clear();
//	graph_restore();
	key_beep_on();
	key_end();

	return NULL;
}
