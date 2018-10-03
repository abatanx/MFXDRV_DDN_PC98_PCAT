//---------------------------------------------------------------------------
//   BGMLIB形式のファイルを MMDファイルに変換するプログラム
//   copyright (c) 1994 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
#include	<stdio.h>
#include	<dos.h>
#include	<dir.h>
#include	<mylib.h>

#define		version_int		1
#define		version_real	20
#define		version_char	' '

char *module[3]={"SSG(0)","SSG(1)","SSG(2)"};

int main(int argc,char **argv)
{
	FILE *fpr,*fpw;
	char dr[MAXDRIVE],di[MAXDIR],fi[MAXFILE],ex[MAXEXT],base[MAXFILE];
	char mmd[MAXPATH],bgm[MAXPATH],buf[256],buf2[256];
	int cnt=1,ch,tr,line=0;

	printf(
		"bgmlib -> xmml3.00 format converter bgm2mmd version %1d.%02d%c\n"
		"copyright (c) 1994 ABA / T.Kobayashi and Interfair All Rights Reserved,\n"
		,version_int,version_real,version_char
	);
	if( argc<=1 )
	{
		puts("usage ; bgm2mmd [filename].bgm");
		exit(EOF);
	}
	fnsplit( argv[0],dr,di,fi,ex );
	fnmerge( buf,dr,di,"bgm2mmd",".cfg" );
	
	if( (fpr=fopen(buf,"r"))==NULL )
	{
		printf("\'%s\' がありません。SSGとしてコンバートします。\n",
			buf );
		clearerr(fpr);
	}
	else
	{
		while( fgets(buf,255,fpr)!=NULL )
		{
			cut_space(buf);
			if( buf[0]<'1' || buf[0]>'3' )continue;
			if( buf[1]!=':' )
			{
				printf("bgm2mmd.cfg の書式が違います。\n"
					"1～3:DRVID1(チャンネル), ... ,DRVID4(チャンネル)\n"
					"です。\n");
				continue;
			}
			module[ buf[0]-'1' ] = keep_highmemory(strlen(buf));
			strcpy( module[buf[0]-'1'],buf+2 );
		}
		fclose(fpr);
	}
	
	fnsplit( argv[1],dr,di,fi,ex );
	fnmerge( bgm,dr,di,fi,".bgm" );
	if( strlen(fi)<6 )
	{
		strcpy(base,fi);
		strcat(fi,"01");
	}
	else
	{
		fi[6]=NULL;
		strcpy(base,fi);
		strcat(fi,"01");
	}
	fnmerge( mmd,dr,di,fi,".mmd" );

	if( (fpr=fopen(bgm,"r"))==NULL )
	{
		printf("Can\'t open file \'%s\'\n",bgm);
		exit(EOF);
	}
	if( (fpw=fopen(mmd,"w"))==NULL )
	{
		printf("Can\'t creat file \'%s\'\n",mmd);
		exit(EOF);
	}
	printf("%s:\n",bgm);
	
	printf("Converting %s...\r",mmd);
	fprintf( fpw,
		".object _main\n"
		"BGMLib_Ch1 = %s;\n"
		"BGMLib_Ch2 = %s;\n"
		"BGMLib_Ch3 = %s;\n"
		"{\n"
		"\tBGMLib_Ch1\t@0@v100@e127m10;\n"
		"\tBGMLib_Ch2\t@0@v100@e127m10;\n"
		"\tBGMLib_Ch3\t@0@v100@e127m10;\n"
		,module[0],module[1],module[2]
	);
	while( fgets(buf,255,fpr)!=NULL )
	{
		line++;
		if( buf[0]=='\"' )
		{
			fputc( ';',fpw );
			fputs( buf,fpw );
			continue;
		}
		strcpy(buf2,buf);
		cut_space(buf);
		if( buf[0]==NULL )
		{
			fputs( buf2,fpw );
			continue;
		}
		if( buf[0]=='*' )
		{
			fprintf( fpw,"}\n\n" );
			fclose(fpw);
			printf("Converted  %s!  \n",mmd);
			cnt++;
			sprintf( fi,"%s%02d",base,cnt );
			fnmerge( mmd,dr,di,fi,".mmd" );
			if( (fpw=fopen(mmd,"w"))==NULL )
			{
				printf("Can\'t creat file \'%s\'\n",mmd);
				exit(EOF);
			}
			printf("Converting %s...\r",mmd);
			fprintf( fpw,
				".object _main\n"
				"BGMLib_Ch1 = %s;\n"
				"BGMLib_Ch2 = %s;\n"
				"BGMLib_Ch3 = %s;\n"
				"{\n"
				"\tBGMLib_Ch1\t@0@v100@e100m10;\n"
				"\tBGMLib_Ch2\t@0@v100@e100m10;\n"
				"\tBGMLib_Ch3\t@0@v100@e100m10;\n"
				,module[0],module[1],module[2]
			);
			continue;
		}
		tr = 0;
		ch = 1;
		
		fprintf( fpw,"\tBGMLib_Ch%1d\t",ch++ );
		while( buf[tr]!=NULL )
		{
			if( buf[tr]>='A' && buf[tr]<='Z' )
			{
				buf[tr] = buf[tr]-'A'+'a';
			}
			if( buf[tr]=='n' )
			{
				if( buf[tr+1]=='0' )fprintf( fpw,"q80" );
				else if( buf[tr+1]=='1' )fprintf( fpw,"q100" );
				else 
				{
					printf("%s(L%05d):",bgm,line);
					printf("n のパラメータが 0,1 ではありません。\n");
				}
				tr+=2;
				continue;
			}
			if( buf[tr]==',' )
			{
				fprintf( fpw,";\n\tBGMLib_Ch%1d\t",ch++ );
				if( ch>4 )
				{
					printf("%s(L%05d):",bgm,line);
					printf("チャンネル数が 3チャンネルを越えています。\n");
					ch=3;
				}
				tr++;
				continue;
			}
			fputc( buf[tr++],fpw );
		}
		fprintf( fpw,";\n\n" );
	}
	fprintf( fpw,"}\n\n");
	fclose(fpr);
	fclose(fpw);
	printf("Converted  %s! Thank you.\n",mmd);
	
	return NULL;
}
