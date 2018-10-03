#include	<stdio.h>
#include	<dos.h>
#include	<mylib.h>
#include	<mfxddn.h>

void main(int argc,char **argv)
{
	char *p;
	int i,ver,ch,type;
	char buf[256],m1[17],m2[17];
	
	puts(
		"MFXDRV/DDN registered driver status viewer version 1.00\n"
		"copyright (c) 1993 by ABA / T.Kobayashi and Interfair all rights reserved.\n"
	);

	if( mfxddn_bgm_init()==EOF ){
		puts("MFXDRV/DDN が常駐していません.");
		exit(EOF);
	}

	if( argc>1 )
	{
		if( *argv[1]=='-' || *argv[1]=='/' )
		{
			switch( *(argv[1]+1) )
			{
				case 'd':case 'D':
					printf("--- DRVID強制変更 ---\n");
					strncpy( buf,argv[2],15 );
					mfxddn_add_space(m1,buf);
					strncpy( buf,argv[3],15 );
					mfxddn_add_space(m2,buf);
					for( i=0; i<16; i++){
						p   = mfxddn_get_driver_name( i );
						if( !strcmp(p,m1) )
						{
							printf("\'%s\' を \'%s\' に変更します。\n",
								p,m2
							);
							strcpy( p,m2 );
							break;
						}
					}
					break;
				case 'h':case 'H':
					printf(
						"Syntax ;\n"
						"         mfxdrs.exe <option...>\n"
						"Option ;\n"
						"         -d [DRVID1] [DRVID2]   DRVIDを強制的に変更する\n"
					);
					break;
			}
		}
	}
	printf("## Device Name_____ Seg_ Type___ Ver_ CH_\n");
	for( i=0; i<16; i++){
		printf("%2d ",i);
		p   = mfxddn_get_driver_name( i );
		if( p==NULL ){
			puts("not registered");
			continue;
		}
		
		printf("%-16s %4x ",
			p, FP_SEG(p) );
		ver = mfxddn_get_driver_version(p);
		ch  = mfxddn_get_driver_canusech(p);
		type= mfxddn_get_driver_type(p);
		switch( type ){
			case 0x0000:
				printf("NORMAL  ");break;
			case 0x1000:
				printf("TIMER   ");break;
			case 0x2000:
				printf("ETC     ");break;
			default:
				printf("??????? ");break;
		}
		sprintf( buf,"%1d.%02d", ver/100,ver%100 );
		printf( "%-4s %3d\n",buf,ch );
	}
}
