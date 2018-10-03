#include	<stdio.h>
#include	<dos.h>
#include	<dir.h>
#include	<mylib.h>
#include	"opns.h"
void conv( char *,char *,FILE *,int );

#define		version		"1.00"

#define		MDRV2FORMAT		1
#define		XMML200FORMAT	2

void main(int argc,char **argv)
{
	FILE *fpr,*fpw;
	char buf[256],*fname;
	char dr[MAXDRIVE],di[MAXDIR],fi[MAXFILE],ex[MAXEXT],dfile[MAXPATH];
	int x,n = 0;

	printf(
		"OPN.xdv sound data linking utility << OPNS >> version %s\n"
		"copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.\n"
		,version
	);

	if( argc<=1 ){
		puts("usage ; opns.exe [sound-filelist]");
		exit(EOF);
	}
	
	fnsplit( *(argv+1),dr,di,fi,ex     );
	fnmerge( dfile    ,dr,di,fi,".xsd" );
	
	if( (fpr=fopen(*(argv+1),"r"))==NULL ){
		printf("Can\'t open sound list \'%s\'.\n",*(argv+1));
		exit(EOF);
	}
	if( (fpw=fopen( dfile,"wb"))==NULL ){
		printf("Can\'t creat \'%s\'.",dfile);
		exit(EOF);
	}

	fprintf( fpw,"OPNX1A" );
	putw( sizeof(OPNPARAM),fpw );

	while( fgets(buf,255,fpr)!=NULL ){
		cut_space(buf);
		if( *buf==NULL )continue;
		if( (x = instr(buf,'='))==EOF ){
			puts("Type miss match.");
			continue;
		}
		buf[x-1] = '\0';
		fname    = buf+x;
		printf("#%03d %-16s %-16s ",n++,buf,fname );
		if( *fname!='\0' ){
			fnsplit( fname,dr,di,fi,ex );
			if( stricmp(ex,".fm")==NULL ){
				printf("mdrv2 format > ");
				conv( buf,fname,fpw,MDRV2FORMAT );
			}
			else if( stricmp(ex,".mmd")==NULL ){
				printf("XMML2.00 format > ");
				conv( buf,fname,fpw,XMML200FORMAT );
			}
			else {
				printf("??? > ");
				conv( buf,fname,fpw,MDRV2FORMAT );
			}
			puts("done.");
		}
		else {
			conv( buf,"dummy.fm",fpw,MDRV2FORMAT );
			puts("Can\'t find opn-tone file.");
		}
	}
	
	fclose(fpw);
	fclose(fpr);
}

void conv( char *sname,char *sfile,FILE *fpw,int type )
{
	FILE *fpr;
	OPNPARAM	opn;
	
	char buf[256],num[256],*trace,sndbuf[256];
	int param[5][10],l,i,j,x,opnum[5]={ 0,1,3,2,4 };

	strcpy( opn.name,sname );
	
	if( (fpr=fopen( sfile,"r"))==NULL ){
		printf("Can\'t open \'%s\'.",sfile);
		exit(EOF);
	}
	l = 0;
	while( fgets(buf,255,fpr)!=NULL && l<5 ){
		cut_space(buf);
		if( *buf==NULL )continue;
		trace = buf;
		for( i=0; i<10; i++){
			while( *trace<'0' || *trace>'9' )trace++;
			x = 0;
			while( *trace>='0' && *trace<='9' ){
				num[x] = *(trace++);
				x++;
			}
			num[ x ]='\0';
			param[l][i] = valtonum(num);
			if( *trace=='\0' && i<9 ){
				puts("Not enough to OPN parameter.");
				break;
			}
		}
		l++;
	}
	fclose(fpr);
/*	
	for( i=0; i<5; i++){
		for( j=0; j<10; j++){
			printf("%03d ",param[i][j]);
		}
		printf("\n");
	}
*/	
	if( type==XMML200FORMAT ){
		for( i=1; i<=4; i++){
			param[i][0] = 31 -param[i][0];
			param[i][1] = 31 -param[i][1];
			param[i][2] = 31 -param[i][2];
			param[i][3] = 15 -param[i][3];
			param[i][4] = 15 -param[i][4];
			param[i][5] = 127-param[i][5];
		}
	}
	
	// DT && ML
	for( i=1; i<=4; i++)opn.DTML[i-1]=(param[opnum[i]][8]<<4)|param[opnum[i]][7];
	// TL
	for( i=1; i<=4; i++)opn.TL[i-1]  =param[opnum[i]][5];
	// KS && AR
	for( i=1; i<=4; i++)opn.KSAR[i-1]=(param[opnum[i]][6]<<6)|param[opnum[i]][0];
	// DR
	for( i=1; i<=4; i++)opn.DR[i-1]  =param[opnum[i]][1];
	// SR
	for( i=1; i<=4; i++)opn.SR[i-1]  =param[opnum[i]][2];
	// SL && RR
	for( i=1; i<=4; i++)opn.SLRR[i-1]=(param[opnum[i]][4]<<4)|param[opnum[i]][3];
	// AFG & FB
	opn.FBALG = param[0][0];
	
	fwrite( &opn,sizeof(OPNPARAM),1,fpw );
	
}
