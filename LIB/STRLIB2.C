/*
// •¶š—ñˆ—ƒ‰ƒCƒuƒ‰ƒŠ‚Q
*/
#include	<stdio.h>
#include	<string.h>

/* ‘½íŠî”•\Œ»‚Ì•¶š—ñ‚ğAint ”‚É•ÏŠ·
// ****h  : ‚P‚Ui”
// ****b  :   ‚Qi”
// ****   : ‚P‚Oi”
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