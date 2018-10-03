/*
 *  XMML3.00 visual music player xp.exe for MFXDRV/DDN
 *  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
 *  94/09/22 êßçÏäJén
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

static struct {
	int x1,y1,x2,y2,n_on,n_off;
	}
	keypoint[12]=
{
	{1,4,2,6,6,0},{3,0,4,3,6,8},{5,4,6,6,6,0},{7,0,8,3,6,8},{9,4,10,6,6,0},
	{13,4,14,6,6,0},{15,0,16,3,6,8},{17,4,18,6,6,0},{19,0,20,3,6,8},
	{21,4,22,6,6,0},{23,0,24,3,6,8},{25,4,26,6,6,0}
};

void setup_screen_bmode(void)
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

	graph_wfont_puts(512,2,16,"(Keybrd Monitor)");

	grcg_setcolor(GC_RMW|GC_BRGI,8);
	grcg_hline(4,347,12);
	grcg_off();


	p =	"TR DRVID    Ch Instrument       "
		"KEYBOARD MONITOR";
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

// ãÊêÿÇËê¸çÏê¨
	grcg_setcolor(GC_RMW,15);
	grcg_hline(0,639,292);
	grcg_vline(292,300,395);
	grcg_setcolor(GC_RMW,7 );
	grcg_hline(0,639,291);
	grcg_vline(291,300,395);
	grcg_off();

// åÆî’ï\é¶
	for( i=0; i<32; i++)
	{
		for( j=0; j<10; j++)
		{
			super_put(j*28+272,i*8+32,0);
			super_put(j*28+288,i*8+32,1);
		}
	}
}

int view_b_mode(void)
{
	int x,trk,i,xh,xl,note,octv;
	char *p;
	unsigned scan;
	int v;

	force = 1;
	setup_screen_bmode();
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
		else if( scan==K_F1 )
		{
			v = VIEW_A;
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
			for(i=0; i<120; i++)
			{
				if( *(keymonitor[trk]+i)!=*(keymonitor2[trk]+i) )
				{
					octv=i/12;
					note=i%12;
					if( *(keymonitor[trk]+i)!=0 )
					{
						grcg_setcolor(GC_RMW|GC_BRGI,keypoint[note].n_on);
					}
					else
					{
						grcg_setcolor(GC_RMW|GC_BRGI,keypoint[note].n_off);
					}
					grcg_boxfill(
						272+octv*28+keypoint[note].x1,32+trk*8+keypoint[note].y1,
						272+octv*28+keypoint[note].x2,32+trk*8+keypoint[note].y2
					);
				}
				*(keymonitor2[trk]+i)=*(keymonitor[trk]+i);
			}
			grcg_off();
		}
		x = mfxddn_get_timebase();
		check_and_write(&timebase,x,16,37,18,"%3d");
		x = mfxddn_get_mean();
		check_and_write(&m_measure,x,25,37,27,"%3d");
		x = mfxddn_get_mean_counter();
		check_and_write(&m_counter,x,29,37,32,"%4d");
		x = mfxddn_get_tempo();
		check_and_write(&tempo,x,3,37,5,"%3d");

		if( force&1 )palette_show100();
		force = 0;
		
	}
	return v;
}
