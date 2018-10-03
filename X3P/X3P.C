//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN 簡易プレイヤー
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------

#include	<stdio.h>
#include	<dos.h>
#include	<crtbios.h>
#include	<conio.h>
#include	<mylib.h>
#include	<game.h>
#include	<mfxddn.h>

void main(int argc,char **argv)
{
	int i,ch,x,a1,a2,rtc,st,key;
	unsigned char p1,p2,p3,p7,p8,p9,pa,pb,pc,pd;
	unsigned p4,p5,p6,pe,pf;
	key = FALSE;

	key_beep(BEEPOFF);

	if( mfxddn_bgm_init3(200000L)==EOF ){
		puts("MFXDRV/DDN(XMML3.00) が常駐していません。");
		exit(EOF);
	}
	if( argc<=1 ){
		puts("usage ; x3p [filename].mud");
		exit(EOF);
	}
	
	if( mfxddn_se_load( 0,"effect0.eud","MIDI",15,16 )!=EOF ){
		puts("[RETURN]で効果音もだせまーす。");
	}
	x=mfxddn_bgm_play(*(argv+1));
	init_joystick(JOY_NORMAL);
	
	if( x==0 ){
		text_init();
		locate(0,0);
		textcolor(T_YELLOW);	cputs("TITLE : ");
		textcolor(T_WHITE);		cputs(mud.title);
		locate(0,1);
		cputs("TR UF DV-CH MML-PTR.  STIME NT-VL PG VL EX MD PN BANK BUFSIZE/ONADRES");
		while( !(strig(0) & _TRIG1) ){
			if( get_key(0x09) & 0x40 && key==FALSE ){
				mfxddn_se_play( 0 );
				key=TRUE;
			}
			else {
				key=FALSE;
			}
			for( i=0; i<22; i++){
				locate(0,i+2);
				p1 = (unsigned char)mfxddn_get_work(i,0);
				p2 = (unsigned char)mfxddn_get_work(i,1);
				p3 = (unsigned char)mfxddn_get_work(i,2);
				p4 = (unsigned     )mfxddn_get_work(i,3);
				p5 = (unsigned     )mfxddn_get_work(i,5);
				p6 = (unsigned     )mfxddn_get_work(i,7);
				p7 = (unsigned char)mfxddn_get_work(i,9);
				p8 = (unsigned char)mfxddn_get_work(i,10);
				p9 = (unsigned char)mfxddn_get_work(i,11);
				pa = (unsigned char)mfxddn_get_work(i,12);
				pb = (unsigned char)mfxddn_get_work(i,13);
				pc = (unsigned char)mfxddn_get_work(i,14);
				pd = (unsigned char)mfxddn_get_work(i,15);
				pe = (unsigned     )mfxddn_get_work(i,16);
				
				if( p1 )textcolor(T_WHITE);
				else	textcolor(T_BLUE);

				cprintf("%2d %2x %2x %2x %04x:%04x %5u %2x %2x%3d %2x %2x "
						"%2x %2x %4x %7ld/%7ld",
					i,p1,p2,p3,p5,p4,p6,p7,p8,p9,pa,pb,pc,pd,pe,
						mud_track_work[i].buffer_size,(long)p4
					);
			}
		}
		puts("Fadeout中...");
		mfxddn_bgm_fadeout(3);
		while( strig(0)!=NULL );
		while( strig(0)==NULL );
		mfxddn_bgm_stop();
		text_end();
	}
	else {
		printf("LIBRARY ERROR : %s\n\n",mfxddn_errmsg());
	}
	key_beep(BEEPON);
}
