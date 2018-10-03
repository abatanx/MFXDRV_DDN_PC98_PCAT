// MLD オプション解析
#include	<stdio.h>
#include	<string.h>
#include	<dos.h>
#include	<mylib.h>

extern char *x_argv[32];
extern int  x_argc;

long get_option_parameter( char *option,int type )
{
	int i,l1,l2,x;
	char xa1[256],xa2[256];
	
	for( i=0; i<x_argc; i++){
		strcpy( xa1,option      );
		strcpy( xa2,x_argv[i]+1 );
	
		if( *x_argv[i]=='/' || *x_argv[i]=='-' ){
			x = instr(xa2,'=');
			if( x!=EOF )l2 = x-1;
			else {
				x = instr(xa2,':');
				if( x!=EOF )l2 = x-1;
				else {
					l2 = strlen( xa2 );
				}
			}
			
			l1 = strlen( xa1 );
		
			if( l1==l2 && strnicmp(xa1,xa2,l1)==NULL ){
				switch( type ){
					case 0:			// オプションなしの場合
						if( x!=EOF )return -1;
						return 0;
					case 1:			// 数値
						if( x==EOF )return -1;
						return((long)valtonum(xa2+x));
					case 2:			// 文字
						if( x==EOF )return -1;
						return((long)(x_argv[i]+x+1));
					case 3:			// +-スイッチ
						if( x==EOF )return -1;
						if( xa2[x]=='+' )return 0;
						else if(xa2[x]=='-' )return 1;
						else return -1;
					case 4:			// on,offスイッチ
						if( x==EOF )return -1;
						if( stricmp(xa2+x,"on")==NULL )return 0;
						else if( stricmp(xa2+x,"off")==NULL )return 1;
						else return -1;
					case 5:			// true,falseスイッチ
						if( x==EOF )return -1;
						if( stricmp(xa2+x,"true")==NULL )return 0;
						else if( stricmp(xa2+x,"false")==NULL )return 1;
						else return -1;
					default:
						return -1;
				}
			}
		}
	}
	return (unsigned long)0xffff0000L;
}

