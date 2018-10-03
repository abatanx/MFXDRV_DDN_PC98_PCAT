#include	<stdio.h>
#include	<stdlib.h>
#include	<dos.h>
#include	<dir.h>
#include	<mylib.h>
#include	<mfxddn.h>
#include	"sabst.h"

byte *mmlbuffer;
byte addbin[256]={
	/* 0x00 */	2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,			// NOTEON,OFF
	/* 0x10 */	2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
	/* 0x20 */	2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
	/* 0x30 */	2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
	/* 0x40 */	2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
	/* 0x50 */	2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
	/* 0x60 */	2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
	/* 0x70 */	2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
	/* 0x80 */	2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,			// CTRL
	/* 0x90 */	2,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	/* 0xa0 */	3,3,2,2,3,2,2,2,2,2,2,2,2,2,2,3,
	/* 0xb0 */	3,2,2,3,1,1,1,1,1,2,1,1,0,0,0,0,
	/* 0xc0 */	0,2,0,0,3,0,0,0,0,0,0,0,0,0,0,0,
	/* 0xd0 */	2,1,1,0,0,0,0,0,0,0,1,1,0,0,0,0,
	/* 0xe0 */	2,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,
	/* 0xf0 */	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};

void asciiz(char *buf,FILE *fpr)
{
	int i=0;
	while( (buf[i]=fgetc(fpr))!=NULL )i++;
}

/* --- sbjÉwÉbÉ_çÏê¨ --- */
void makeheader(FILE *fpw,char *drvid,unsigned drvidnum)
{
	int i;
	long l;

	fprintf( fpw,
		"XMML3.00 sound object - Sound ECM abstracting utility version %1d.%02d%c\r\n"
		"copyright (c) 1995 by Interfair all rights reserved.\r\n\x1a%c",
		version_int,version_real,version_char,0
	);
	fwrite( drvid,strlen(drvid)+1,1,fpw );
	
	putw( drvidnum,fpw );		/* DRVID-Number */
	putc( 0x00,fpw );			/* DriverType   */
}

void analyze(FILE *fpw,int track,byte *buffer,unsigned size,unsigned drvidnum)
{
	unsigned p=0,drvidnum_k,drvtype,length,ctrl,sbank,snum;
	long step=0,ll;
	byte k=0;
	int pf=FALSE,cnt;
	
	while( p<size )
	{
		switch(*(buffer+p))
		{
			case 0x90:
				step += (long)*(buffer+p+1);
				p+=2;
				break;
			case 0x91:
				step += ((long)*(buffer+p+1)+256L*(long)*(buffer+p+2));
				p+=3;
				break;
			case 0xe2:
				return;
			case 0xbb:
				length  = (unsigned)*(buffer+p+1);
				p+=(length+1);
				break;
			case 0xe1:		/* ECM */
				drvidnum_k=((unsigned)*(buffer+p+1)+256U*(unsigned)*(buffer+p+2));
				drvtype =(unsigned)*(buffer+p+3);
				length  =((unsigned)*(buffer+p+4)+256U*(unsigned)*(buffer+p+5));
				ll      =(long)length;
				ctrl    =(unsigned)*(buffer+p+6);
				sbank   =((unsigned)*(buffer+p+7)+256U*(unsigned)*(buffer+p+8));
				snum    =(unsigned)*(buffer+p+9);
				if( drvidnum==drvidnum_k && ctrl==0 )
				{
					ll -= 4;
					putw(sbank,fpw);
					putc( snum,fpw);
					fwrite(&ll,sizeof(long),1,fpw);
					fwrite(buffer+p+10,ll,1,fpw);
					if( pf==FALSE )
					{
						printf("\n   * Track%02d : ",track);
						pf = TRUE;
						cnt= 0;
					}
					if( cnt>=7 )
					{
						cnt = 0;
						printf("\n             : ");
					}
					printf("%04x-%03d ",sbank,snum);
					cnt++;
				}
				p+=(6+length);
				break;
			default:
				if( addbin[*(buffer+p)]==0 )
				{
					printf("%u[%02x][Before:%02x] mbj-format error.\n",p,*(buffer+p),k);
					exit(1);
				}
				k  = *(buffer+p);
				p += addbin[*(buffer+p)];
				break;
		}
	}
}

void abst(char *filename,char *sbjfile,unsigned drvidnum,char *drvid)
{
	FILE *fpr,*fpw;
	char buf[256];
	int tmp,i,j,trsw[32];
	long trfp[32],trsize[32],nowfp,skipbin;
	unsigned trcmp[32],trext[32];
	
	printf("Abstracting for %04x(%s)\n",drvidnum,drvid);
	printf("%s:\n",filename);
	if( (fpr=fopen(filename,"rb"))==NULL )
	{
		printf("Can\'t open mbj-file \'%s\'\n",filename);
		exit(1);
	}
	fread(buf,15,1,fpr);
	buf[15]=NULL;
	if( strcmp(buf,"XMML3.00 object")!=NULL )
	{
		printf("Not mbj-format.\n");
		fcloseall();
		exit(1);
	}
	while( fgetc(fpr)!=NULL );

	if( (fpw=fopen(sbjfile,"wb"))==NULL )
	{
		printf("Can\'t create sbj-file \'%s\'\n",sbjfile);
		exit(1);
	}
	makeheader(fpw,drvid,drvidnum);
	while( fgetc(fpr)!=0x00 )
	{
		asciiz(buf,fpr);
		tmp = getw(fpr);
		printf("  [%s] \n",buf);
		skipbin = 0;
		for(i=0;i<32;i++)
		{
			switch(fgetc(fpr))
			{
				case 0x01:		/* äOïîobj */
					asciiz(buf,fpr);
					tmp=getc(fpr);
					trsw[i] = FALSE;
					break;
				case 0x00:		/* ì‡ïîobj */
					for(j=0;j<4;j++)
					{
						asciiz(buf,fpr);
						tmp=getc(fpr);
					}
					trsw[i] = TRUE;
					fread( &trfp[i],sizeof(long),1,fpr );
					fread( &trsize[i],sizeof(long),1,fpr );
					fread( &trcmp[i],sizeof(word),1,fpr );
					fread( &trext[i],sizeof(word),1,fpr );
					skipbin += trsize[i];
					if( trsize[i]==0 )trsw[i]=FALSE;
					break;
				default:
					printf("mbj-format error.");
					exit(1);
			}
		}
		nowfp = ftell(fpr);
		
		for( i=0; i<32 && trsw[i]==TRUE ; i++)
		{
			fseek( fpr,trfp[i],SEEK_SET );
			if( trcmp[i]=='NC' )
			{
				fread( mmlbuffer,(long)trsize[i],1,fpr );
				analyze(fpw,i,mmlbuffer,trsize[i],drvidnum);
			}
			else
			{
				ddn_flz_load_fp(mmlbuffer,fpr,(long)trsize[i]);
				analyze(fpw,i,mmlbuffer,trext[i],drvidnum);
			}
		}
		fseek( fpr,nowfp+skipbin,SEEK_SET );
		
		while( getw(fpr)!=EOF )fgetc(fpr);
	}
	putw( -1,fpw );
	fclose(fpw);
}

int main(int argc,char **argv)
{
	char dr[MAXDRIVE],di[MAXDIR],fi[MAXFILE],ex[MAXEXT],
		fname[MAXPATH],sname[MAXPATH];
	unsigned drvidnum;
	int i;

	printf(
		"music driver MFXDDN XMML3.00 sound ECM abstracting utility SABST "
			"version %1d.%02d%c\n"
		"copyright (c) 1995 by ABA / T.Kobayashi and Interfair"
			" All Rights Reserved.\n",
		version_int,version_real,version_char
	);
	
	if( argc<=3 )
	{
		printf(
			"Syntax ;\n"
			"         sabst.exe <filename[.mbj]> <DRVIDNUM> <DRVID>\n"
			"Examination ;\n"
			"         sabst sample.mbj 015c SAMPLE\n"
		);
		return NULL;
	}

	if( (mmlbuffer=keep_highmemory(65500))==NULL )
	{
		printf("Can\'t allocate memory.\n");
		exit(1);
	}

	fnsplit( argv[1],dr,di,fi,ex     );
	fnmerge( fname  ,dr,di,fi,".mbj" );
	fnmerge( sname  ,"","",fi,".sbj" );

	drvidnum = 0;
	i = 0;
	while( argv[2][i]!=NULL )
	{
		if( argv[2][i]>='0' && argv[2][i]<='9' )
			drvidnum = drvidnum*16+argv[2][i]-'0';
		else if( argv[2][i]>='a' && argv[2][i]<='f' )
			drvidnum = drvidnum*16+argv[2][i]-'a'+10;
		else if( argv[2][i]>='A' && argv[2][i]<='F' )
			drvidnum = drvidnum*16+argv[2][i]-'A'+10;
		else
		{
			printf("type mismatch : DRVIDNUM \"%s\"\n",argv[2]);
			exit(1);
		}
		i++;
	}

	abst(fname,sname,drvidnum,argv[3]);
	return NULL;

}
