/*
 *  XMML3.00 visual music player xp.exe for MFXDRV/DDN
 *  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
 *  94/09/15 êßçÏäJén
 */

#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>
#include	<conio.h>
#include	<masterc.h>
#include	<mfxddn.h>
#include	"xp.h"
#define		MAXTRACK	32

static char buf[100];
static int  vol[MAXTRACK],exp[MAXTRACK],rev[MAXTRACK],cho[MAXTRACK],
			mod[MAXTRACK],pan[MAXTRACK],bank[MAXTRACK],ntotal[MAXTRACK],
			program[MAXTRACK],useflag[MAXTRACK],drvch[MAXTRACK],
			pitch[MAXTRACK],notecnt[MAXTRACK],level[MAXTRACK],timebase,
			m_measure,m_counter,tempo,force;

void setup_screen_amode(void)
{
	int i,j,type;
	char *p;
	
//	palette_black();

	graph_clear();

	grcg_setcolor(GC_RMW,7);
	for( i=0; i<2; i++)
	{
		grcg_vline(  0+i,0+i,399-i);
		grcg_vline(639+i,0+i,399-i);
		grcg_hline(  0+i,639-i,0+i);
		grcg_hline(0+i,639-i,399+i);
	}
	grcg_off();

	sprintf( buf,
		"MFXDRV/DDN visual monitor *XP* Version%1d.%02d%c",
		version_int,version_real,version_char
	);
	graph_wfont_plane(GC_RMW|GC_BRG,GC_RMW|GC_BRG);
	graph_wfont_puts(10,2,16,buf);
	graph_wfont_plane(GC_RMW|GC_BRGI,GC_RMW|GC_BRGI);
	graph_wfont_puts(8,2,16,buf);

	graph_wfont_puts(512,2,16,"(Status Monitor)");

	grcg_setcolor(GC_RMW|GC_BRGI,8);
	grcg_hline(4,347,12);
	grcg_off();


	p =	"TR DRVID    Ch Instrument       "
		"Bnk VOL EXP REV CHO MOD PAN PITCH VC SP";
	graph_wfont_plane(GC_RMW|GC_B,GC_RMW|GC_B);
	graph_wfont_puts(8,24,16,p);

	graph_wfont_plane(GC_RMW|GC_R,GC_RMW|GC_R);
	for( i=0; i<32; i++)
	{
		sprintf(buf,"%2d",i+1);
		graph_wfont_puts(8,i*8+32,16,buf);
	}
	graph_wank_puts(8,296,8,"\x82=    TIMEBASE=    MEAS=   :   ");

	graph_wfont_plane(GC_RMW|GC_R,GC_RMW|GC_R);
	graph_wfont_puts(8,320,16,"COMPOSER");
	graph_wfont_puts(8,328,16,"ARRANGER");
	graph_wfont_puts(8,336,16,"LYRICS");
	graph_wfont_puts(8,344,16,"ARTISTS");
	graph_wfont_puts(8,352,16,"COPYRIGHT");

// ï‚èïê¸çÏê¨
	grcg_setcolor(GC_RMW|GC_G,15);

	for( i=0; i<6; i++)
		grcg_hline(4,635,i*40+71);
	grcg_hline(4,635,292);

	grcg_vline(124,20,287);
	grcg_vline(260,20,287);
	grcg_vline(292,20,287);
	grcg_vline(356,20,287);
	grcg_vline(420,20,287);
	grcg_vline(484,20,287);
	grcg_vline(532,20,287);

// ãÊêÿÇËê¸çÏê¨
	grcg_setcolor(GC_RMW,15);
	grcg_hline(0,639,292);
	grcg_vline(292,300,395);
	grcg_setcolor(GC_RMW,7 );
	grcg_hline(0,639,291);
	grcg_vline(291,300,395);
	grcg_off();

// DRIVERÇï\é¶
	graph_wfont_plane(GC_RMW|GC_B,GC_RMW|GC_B);
	graph_wfont_puts(312,296,16,"Registerd Drivers");

	for( i=0;i<=7;i++ )
	{
		graph_wfont_plane(GC_RMW|GC_R,GC_RMW|GC_R);
		sprintf(buf,"%2d",i);
		graph_wfont_puts(296,i*10+312,16,buf);
		sprintf(buf,"%2d",i+8);
		graph_wfont_puts(464,i*10+312,16,buf);


		for( j=0; j<=1; j++)
		{
			graph_wfont_plane(GC_RMW|GC_BRGI,GC_RMW|GC_BRGI);
			p = mfxddn_get_driver_name(j*8+i);
			if( p )
			{
				strcpy(buf,p);
				graph_wfont_puts(312+j*168,i*10+312,16,buf);
			}
			else
				graph_wfont_puts(312+j*168,i*10+312,16,"*** none ***");
			
			graph_wfont_plane(GC_RMW|GC_BRGI,GC_G|GC_G);
			type = mfxddn_get_driver_type(p);
			switch(type&0xff00)
			{
				case 0x0000:
					sprintf(buf,"Snd");					break;
				case 0x1000:
					sprintf(buf,"Tim");					break;
				case 0x2000:
					sprintf(buf,"Etc");					break;
				default:
					sprintf(buf,"---");
			}
			graph_wfont_puts(432+j*168,i*10+312,16,buf);
		}
	}
}

void check_and_write(int *param,int newvalue,int x1,int y1,int x2,char *format)
{
	if( *param!=newvalue || force )
	{
		grcg_setcolor(GC_RMW|GC_RI,0);
		grcg_byteboxfill_x(x1,y1*8,x2,y1*8+7);
		grcg_off();
		sprintf(buf,format,newvalue);
		if( (force&2)==2 )
		{
			graph_wfont_plane(GC_RMW|GC_RI,GC_RMW|GC_RI);
		}
		else
		{
			graph_wfont_plane(GC_RMW|GC_I,GC_RMW|GC_I);
		}
		graph_wfont_puts(x1*8,y1*8,16,buf);
		*param = newvalue;
	}
}

int view_a_mode(void)
{
	int x,trk,i,xh,xl,pikapika;
	char *p;
	unsigned scan;
	int v;
	unsigned x1,x2,y1;

	vsync_start();
	vsync_Count1 = 0;

	force = 1;
	pikapika = 0;

	setup_screen_amode();

	for( i=0; i<MAXTRACK; i++)
	{
		vol[i]     = 100;
		exp[i]     = 127;
		rev[i]     = 40;
		cho[i]     = 0;
		mod[i]     = 0;
		pan[i]     = 64;
		bank[i]    = 0x00;
		ntotal[i]  = 0;
		program[i] = 0;
		useflag[i] = 1;
		drvch[i]   = 0;
		pitch[i]   = 0;
		notecnt[i] = 0;
		level[i]   = 0;
	}
	tempo=120;
	timebase=48;
	m_measure=0;
	m_counter=0;

	graph_wfont_plane( GC_RMW|GC_I,GC_RMW|GC_I );
	for( trk=0; trk<MAXTRACK; trk++)
	{
		x = mfxddn_get_work_byte(trk,1);
		p = mfxddn_get_driver_name(x);
		if(p)
		{
			strcpy(buf,p);
			buf[8]=NULL;
			graph_wfont_puts(32,32+trk*8,16,buf);
		}
	}

	for(;;)
	{
		scan = key_scan();
		if( scan==K_ESC || scan=='Q' || scan=='q' )
		{
			v = QUIT;
			break;
		}
		else if( scan==K_F2 )
		{
			v = VIEW_B;
			break;
		}
	
		for( trk=0; trk<MAXTRACK; trk++)
		{
			x = mfxddn_get_work_byte(trk,0);
			if( x==0 )
			{
				if( useflag[trk]==1 )force|=2;
				else continue;
			}
			else
			{
				if( useflag[trk]==0 )force|=4;
			}
			useflag[trk] = x;
		
			x = mfxddn_get_work_byte(trk,2);
			check_and_write(&drvch[trk],x,13,4+trk,14,"%2d");
	
			x = mfxddn_get_work(trk,16)>>8;
			check_and_write(&bank[trk],x,33,4+trk,35,"%02x");
	
			x = mfxddn_get_work_byte(trk,12);
			check_and_write(&vol[trk] ,x,37,4+trk,39,"%3d");

			x = mfxddn_get_work_byte(trk,13);
			check_and_write(&exp[trk] ,x,41,4+trk,43,"%3d");
	
			x = mfxddn_get_work_byte(trk,24);
			check_and_write(&rev[trk] ,x,45,4+trk,47,"%3d");
		
			x = mfxddn_get_work_byte(trk,26);
			check_and_write(&cho[trk] ,x,49,4+trk,51,"%3d");
		
			x = mfxddn_get_work_byte(trk,14);
			check_and_write(&mod[trk] ,x,53,4+trk,55,"%3d");
			
			x = mfxddn_get_work_byte(trk,15);
			check_and_write(&pan[trk] ,x,57,4+trk,59,"%3d");

			x = mfxddn_get_work(trk,28);
			check_and_write(&pitch[trk] ,x,61,4+trk,65,"%5d");

			x = mfxddn_get_work_byte(trk,32);
			check_and_write(&ntotal[trk],x,67,4+trk,68,"%2d");

			x = mfxddn_get_work_byte(trk,11);
			if( x!=program[trk] || force )
			{
				grcg_setcolor(GC_RMW|GC_RI,0);
				grcg_byteboxfill_x(16,32+trk*8,31,39+trk*8);
				grcg_off();
				sprintf(buf,"%3d %s",x,soundlist[x]);
				if( (force&2)==2 )
				{
					graph_wfont_plane(GC_RMW|GC_RI,GC_RMW|GC_RI);
				}
				else
				{
					graph_wfont_plane(GC_RMW|GC_I,GC_RMW|GC_I);
				}
				graph_wfont_puts(128,32+trk*8,16,buf);
				program[trk] = x;
			}

			force &= 1;
			x = mfxddn_get_timebase();
			check_and_write(&timebase,x,16,37,18,"%3d");
			x = mfxddn_get_mean();
			check_and_write(&m_measure,x,25,37,27,"%3d");
			x = mfxddn_get_mean_counter();
			check_and_write(&m_counter,x,29,37,32,"%4d");
			x = mfxddn_get_tempo();
			check_and_write(&tempo,x,3,37,5,"%3d");

			x = mfxddn_get_work(trk,30);
			if( notecnt[trk]!=x )
			{
				notecnt[trk]=x;
				level[trk]=mfxddn_get_work_byte(trk,10)>>3;
			}
		}
		if( force&1 )palette_show100();
		force = 0;
		
		if( vsync_Count1>2 )
		{
			for( trk=0; trk<MAXTRACK; trk++)
			{
				if( level[trk]==0 && ntotal[trk]==0 )
				{
					grcg_setcolor(GC_RMW|GC_BRGI,3);
					grcg_boxfill(560,32+trk*8,575,38+trk*8);
					grcg_off();
				}
				else
				{
					grcg_setcolor(GC_RMW|GC_BRGI,5);
					grcg_boxfill(560,32+trk*8,575,38+trk*8);
					grcg_setcolor(GC_RMW|GC_BRGI,1);
					grcg_boxfill(560,32+trk*8,560+level[trk],38+trk*8);
					grcg_off();
					if( level[trk]>0 )level[trk]--;
				}
			}
			vsync_Count1 = 0;
			super_in(624,16,pikapika++);
			if( pikapika>=8 )pikapika=0;
		}
	}
	vsync_end();
	return v;
}
