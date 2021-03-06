/*
// 文字列処理ライブラリ２
*/
#include	<stdio.h>
#include	<string.h>

/* 多種基数表現の文字列を、int 数に変換
// ****h  : １６進数
// ****b  :   ２進数
// ****   : １０進数
*/
unsigned ddn_valtonum(char *str)
{
	char buf[256];
	int x;
	unsigned base,n;
	strcpy( buf,str );
	ddn_cut_space(buf);
	
	x = strlen(buf);
	strcpy( buf,strupr(buf) );
	
	switch( buf[x-1] ){
		case 'H':
					n    = 0;
					base = 1;
					x   -= 2;
					while( x>=0 ){
						if( buf[x]>='0' && buf[x]<='9' )buf[x]-= '0';
						else
						if( buf[x]>='A' && buf[x]<='Z' )buf[x]-= ('A'-10);
						else
														buf[x] = '0';
						n    |=( base * buf[x]);
						base *= 16;
						x--;
					}
					break;
		case 'B':
					n    = 0;
					base = 1;
					x   -= 2;
					while( x>=0 ){
						if( buf[x]!='1' && buf[x]!='0' )buf[x] = '0';
						n    |=( base * (buf[x]-'0') );
						base<<= 1;
						x--;
						
					}
					break;
		default:
					if( buf[x-1]<'0' || buf[x-1]>'9' )
						n = 0;
					else
						n = (unsigned)atoi(buf);
					break;
	}
	return n;
}
