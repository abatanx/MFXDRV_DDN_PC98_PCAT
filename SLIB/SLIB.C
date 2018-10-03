#include	<stdio.h>
#include	<stdlib.h>
#include	<dos.h>
#include	<dir.h>
#include	<ctype.h>
#include	<string.h>
#include	<mylib.h>
#include	<master.h>
#include	"slib.h"

#define		MAX_FILENAME	100

char *argfile[100];
int  argx;

char *addfilename[256],*delfilename[256],*extfilename[256],libfile[256];
char tmpfilename[256];
int  addx,delx,extx;

void slib_exit(int);
void mkheader_library(FILE *);
void del_library(FILE *);
void add_library(FILE *);
void lst_library(char *);

typedef struct
{
	char filename[13];
	long filesize;
	char drvid[16];
} LISHEAD;

byte *readbuffer;

int main(int argc,char **argv)
{
	int i,j,fdr,fdw;
	FILE *fpw;
	char cmd[16],buf[256],*tmp,*libf;
	char dr[MAXDRIVE],di[MAXDIR],fi[MAXFILE],ex[MAXEXT],pa[MAXPATH];
	
	printf(
		"music driver MFXDDN XMML3.00 sound library manager SLIB "
			"version %1d.%02d%c\n"
		"copyright (c) 1994 by ABA / T.Kobayashi and Interfair"
			" All Rights Reserved.\n",
		version_int,version_real,version_char
	);
	
	if( argc<=1 )
	{
		printf(
			"Syntax ;\n"
			"         slib.exe <option> [libfile] [[cmd]filename]...\n"
			"Option ;\n"
			"Cmd    ;\n"
			"         +         Add     sound object\n"
			"         -         Delete  sound object\n"
			"         *         Extract sound object\n"
			"         -+ or +-  Replace sound object\n"
			"         -* or *-  Extract and delete sound object\n"
		);
		return NULL;
	}

	for( i=1; i<argc ; i++ )
	{
		if( *argv[i]=='/' )
		{
//			printf( "Option : %s\n",argv[i] );
		}
		else break;
	}

	libf = argv[i++];
	fnsplit( libf   ,dr,di,fi,ex     );
	fnmerge( libfile,dr,di,fi,".lis" );
	
	argx = 0;

	for( ; i<argc ; i++ )
	{
//		printf("File : %s\n",argv[i] );
		argfile[argx++] = argv[i];
	}
	
	delx = 0;
	addx = 0;
	extx = 0;
	for( i=0; i<argx; i++)
	{
		for( j=0; j<2; j++)
		{
			cmd[j] = *(argfile[i]+j);
			if( cmd[j]!='+' && cmd[j]!='-' && cmd[j]!='*' )break;
		}
		cmd[j]='\0';
		argfile[i] += j;

		if( !strcmp(cmd,"-+") || !strcmp(cmd,"+-") )
		{
			addfilename[addx++] = argfile[i];
			delfilename[delx++] = argfile[i];
		}
		else if( !strcmp(cmd,"-*") || !strcmp(cmd,"*-") )
		{
			extfilename[extx++] = argfile[i];
			delfilename[delx++] = argfile[i];
		}
		else if( !strcmp(cmd,"+") )addfilename[addx++] = argfile[i];
		else if( !strcmp(cmd,"-") )delfilename[delx++] = argfile[i];
		else if( !strcmp(cmd,"*") )extfilename[extx++] = argfile[i];
		else {
			printf("Command prefix error: %s\n",argfile[i]);
		}
	}
	printf("%s:\n",libfile);
/*
	for( i=0; i<addx; i++)printf("Add object: %s\n",addfilename[i]);
	for( i=0; i<delx; i++)printf("Del object: %s\n",delfilename[i]);
	for( i=0; i<extx; i++)printf("Ext object: %s\n",extfilename[i]);
*/
	if( (tmp=getenv("TMP"))==NULL )
	{
		strcpy(tmpfilename,"\\$slbtmp$.$$$");
	}
	else
	{
		strcpy(buf,tmp);
		cut_dirmark(buf);
		sprintf(tmpfilename,"%s\\$slbtmp$.$$$",buf);
	}

	fnsplit( libf   ,dr,di,fi,ex     );
	fnmerge( libfile,dr,di,fi,".lis" );

	if( !delx && !addx && !extx )
	{
		lst_library(libfile);
		return NULL;
	}

	if( (fpw=fopen(tmpfilename,"wb"))==NULL )
	{
		printf("Can\'t creat temporary file \'%s\'\n",tmpfilename);
		return 1;
	}
	mkheader_library(fpw);
	del_library(fpw);
	add_library(fpw);
	fclose(fpw);
	if( (fdr=dos_ropen(tmpfilename))==NULL )
	{
		printf("Can\'t read temporary file \'%s\'\n",tmpfilename);
		slib_exit(1);
	}
	if( (fdw=dos_create(libfile,0x20))==NULL )
	{
		printf("Can\'t creat file \'%s\'\n",libfile);
		slib_exit(1);
	}
	dos_copy( fdr,fdw,COPY_ALL );
	dos_close(fdr);
	dos_close(fdw);
	unlink(tmpfilename);
	return NULL;
}

void slib_exit(int no)
{
	unlink(tmpfilename);
	exit(no);
}

void mkheader_library(FILE *fpw)
{
	struct date da;
	struct time ti;
	int i;

	fprintf( fpw,
		"Lissf%c%c%c%c\n"
		"XMML3.00 library manager slib version %1d.%02d%c\n"
		"copyright (c) 1994 by Interfair all rights reserved.\n%c",
		version_int,version_real,version_char,0x1a,
		version_int,version_real,version_char,NULL
	);
	
	getdate( &da );
	gettime( &ti );
	fputc( da.da_year,fpw );
	fputc( da.da_mon ,fpw );
	fputc( da.da_day ,fpw );
	fputc( ti.ti_hour,fpw );
	fputc( ti.ti_min ,fpw );
	fputc( ti.ti_sec ,fpw );
	for( i=0; i<16; i++)fputc( NULL,fpw );
}

void del_library(FILE *fpw)
{
	FILE *fpr,*fpw2;
	LISHEAD	lh;
	long p,fp;
	int i,c,delf,warf;
	char cmpfilename[256];
	char dr[MAXDRIVE],di[MAXDIR],fi[MAXFILE],ex[MAXEXT],pa[MAXPATH];
	byte buf[256];
	
	if( (fpr=fopen(libfile,"rb"))==NULL )
	{
		printf("New library file.\n");
		return;
	}
	
	fread( buf,9,1,fpr );
	if( strncmp(buf,"Lissf",5) )
	{
		printf("Not sound library(.lis) file \'%s\'\n",libfile);
		slib_exit(1);
	}
	if( buf[5]!=version_int )
	{
		printf("Sound library file version error(ver.%d.%02d%c).\n",
			buf[5],buf[6],buf[7]
		);
		slib_exit(1);
	}
	while( fgetc(fpr)!=NULL );
	fseek( fpr,6+16,SEEK_CUR );

	while( fgetc(fpr)!=NULL )
	{
		delf = FALSE;
		warf = FALSE;
		
		fread( &lh,sizeof(LISHEAD),1,fpr );
		for( i=0; i<extx; i++)
		{
			fnsplit( extfilename[i],dr,di,fi,ex     );
			fnmerge( cmpfilename   ,"","",fi,".sbj" );
			if( !stricmp( cmpfilename , lh.filename) )
			{
				fp = ftell(fpr);
				if( (fpw2=fopen(cmpfilename,"wb"))==NULL )
				{
					printf("Can\'t make file.\n");
					slib_exit(1);
				}
				printf("%s: Extracting(%ldbytes)...",cmpfilename,lh.filesize);
				for( p=0; p<lh.filesize; p++)fputc(fgetc(fpr),fpw2);
				fclose(fpw2);
				printf("done\n");
				fseek( fpr,fp,SEEK_SET );
				break;
			}
		}
		for( i=0; i<delx; i++)
		{
			fnsplit( delfilename[i],dr,di,fi,ex     );
			fnmerge( cmpfilename   ,"","",fi,".sbj" );
			if( !stricmp( cmpfilename , lh.filename) )
			{
				fseek( fpr,lh.filesize,SEEK_CUR );
				delf = TRUE;
				break;
			}
		}
		if( delf==FALSE )
		{
			for( i=0; i<addx; i++)
			{
				fnsplit( addfilename[i],dr,di,fi,ex     );
				fnmerge( cmpfilename   ,"","",fi,".sbj" );
				if( !stricmp( cmpfilename , lh.filename) )
				{
					printf("Warning: \'%s\' is already registerd.\n",cmpfilename);
					fseek( fpr,lh.filesize,SEEK_CUR );
					warf = TRUE;
					break;
				}
			}
			if( warf==FALSE )
			{
				fputc( 0x01,fpw );
				fwrite( &lh,sizeof(LISHEAD),1,fpw );
				for( p=0; p<lh.filesize; p++)fputc(fgetc(fpr),fpw);
			}
		}
	}
	fclose(fpr);
}

void add_library(FILE *fpw )
{
	FILE *fpr;
	LISHEAD	lh;
	int i,j;
	long p;
	char dr[MAXDRIVE],di[MAXDIR],fi[MAXFILE],ex[MAXEXT],pa[MAXPATH],buf[256],
		objectfname[256];
	for( i=0; i<addx; i++)
	{
		fnsplit( addfilename[i],dr,di,fi,ex     );
		fnmerge( objectfname   ,dr,di,fi,".sbj" );
		
		if( (fpr=fopen(objectfname,"rb"))==NULL )
		{
			printf("Warning: file not found \'%s\'.\n",addfilename[i]);
			clearerr(fpr);
			continue;
		}
		fnsplit( addfilename[i],dr,di,fi,ex     );
		fnmerge( lh.filename   ,"","",fi,".sbj" );
		fseek(fpr,0,SEEK_END);
		lh.filesize = ftell(fpr);
		fseek(fpr,0,SEEK_SET);

		fread( buf,21,1,fpr );
		if( strncmp( buf,"XMML3.00 sound object",21 )!=NULL )
		{
			printf("Warning: \'%s\' isn\'t sound object format\n",addfilename[i]);
			fclose(fpr);
			clearerr(fpr);
			continue;
		}

		while( fgetc(fpr)!=NULL );
		for( j=0; j<=15; j++)
		{
			if( (lh.drvid[j]=fgetc(fpr))==NULL )break;
		}
		lh.drvid[j]=NULL;
		fseek(fpr,0,SEEK_SET);
		
		fputc( 0x01,fpw );
		fwrite( &lh,sizeof(LISHEAD),1,fpw );
		for( p=0; p<lh.filesize; p++)fputc(fgetc(fpr),fpw);
		fclose(fpr);
	}
	fputc( 0x00,fpw );
}

void lst_library( char *fname )
{
	FILE *fpr;
	int no;
	LISHEAD	lh;
	byte buf[256];
	
	if( (fpr=fopen(fname,"rb"))==NULL )
	{
		printf("Can\'t read library file \'%s\'.\n",fname);
		return;
	}
	
	fread( buf,9,1,fpr );
	if( strncmp(buf,"Lissf",5) )
	{
		printf("Not sound library(.lis) file \'%s\'\n",libfile);
		slib_exit(1);
	}
	if( buf[5]!=version_int )
	{
		printf("Sound library file version error(ver.%d.%02d%c).\n",
			buf[5],buf[6],buf[7]
		);
		slib_exit(1);
	}
	while( fgetc(fpr)!=NULL );
	fseek( fpr,6+16,SEEK_CUR );

	no = 1;
	
	printf(" No_ Filename____ Driver-ID_______ Size(bytes)\n");
	
	while( fgetc(fpr)!=NULL )
	{
		fread( &lh,sizeof(LISHEAD),1,fpr );
		printf(" %3d %-12s %-16s %11ld\n",
			no++,
			lh.filename,
			lh.drvid,
			lh.filesize
		);
		fseek( fpr,lh.filesize,SEEK_CUR );
	}
	fclose(fpr);
}
