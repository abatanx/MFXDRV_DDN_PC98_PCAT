//
// Yah! Event Scenario Compiler YCC.EXE release 1.00
// copyright (c) 1994 by ABA / Interfair all rights reserved.
//
// 数式解析部
//

#include	<stdio.h>
#include	<stdlib.h>
#include	<dir.h>
#include	<dos.h>
#include	<string.h>
#include	<mylib.h>
#include	<ctype.h>
#include	"mplus.h"

static int ch,rfp;
static long p1,p2;
static char *buffer,buf[256];
static LSTACK math;
static BFILE *fpr;

void bit_xor(void);

void readch(void)
{
	ch = *(buffer+rfp++);
	if( ch==NULL )return;
}

void factor( void )
{
	int s,i;

	if( ch=='{' ){
		readch();
		bit_xor();
		if( ch=='}' )readch();
		else {
			erl(fpr,ERR);
			printf("数式中に \'}\' が見つかりません。\n");
			return;
		}
	}
	else if( isgraph(ch) ){
		s = 0;
		while( 
			( ch>='0' && ch<='9' ) || ( ch>='A' && ch<='Z' ) ||
			( ch>='a' && ch<='z' ) ||   ch=='_'  ){
			buf[s++] = ch;
			readch();
			if( s>=31 )break;
		}
		buf[s] = '\0';
		rfp --;

		if( buf[0]=='0' && buf[1]=='x' )
		{
			for( i=2; i<s; i++)
			{
				if( (buf[i]<'0' || buf[i]>'9') && (buf[i]<'a' || buf[i]>'f') )
				{
					erl(fpr);
					printf("数式中で、16進数表記が間違っています。\n");
					return;
				}
			}
			sscanf(buf+2,"%x",&p1);
		}
		else
		{
			for( i=2; i<s; i++)
			{
				if( buf[i]<'0' || buf[i]>'9' )
				{
					erl(fpr);
					printf("数式中で、10進数表記が間違っています。\n");
					return;
				}
			}
			p1 = atol(buf);
		}
		math.push(p1);

		readch();
	}
	else {
		erl(fpr);
		printf("数式が解釈できません。\n");
		return;
	}
}

void term(void)
{
	factor();
	for ( ;; ){
		if( ch=='*' ){
			readch();
			factor();
			
			p1 = math.pop();
			p2 = math.pop();
			math.push(p2*p1);
		}
		else if( ch=='/' ){
			readch();
			factor();
			
			p1 = math.pop();
			p2 = math.pop();
			math.push(p2/p1);
		}
		else if( ch=='%' ){
			readch();
			factor();
			
			p1 = math.pop();
			p2 = math.pop();
			math.push(p2%p1);
		}
		else break;
	}
}

void expression(void)
{
	term();
	for( ;; ){
		if( ch=='+' ){
			readch();
			term();
			
			p1 = math.pop();
			p2 = math.pop();
			math.push(p2+p1);
		}
		else if( ch=='-' ){
			readch();
			term();
			
			p1 = math.pop();
			p2 = math.pop();
			math.push(p2-p1);
		}
		else break;
	}
}

void shift(void)
{
	expression();
	for( ;; ){
		if( ch=='>' ){
			readch();
			if( ch!='>' )
			{
				erl(fpr);
				printf("数式中に、不明な演算子が存在します(>%c)。\n",ch);
				return;
			}
			readch();
			expression();
			
			p1 = math.pop();
			p2 = math.pop();
			math.push(p2>>p1);
		}
		else if( ch=='<' ){
			readch();
			if( ch!='<' )
			{
				erl(fpr);
				printf("数式中に、不明な演算子が存在します(<%c)。\n",ch);
				return;
			}
			readch();
			expression();
			
			p1 = math.pop();
			p2 = math.pop();
			math.push(p2<<p1);
			
		}
		else break;
	}
}

void bit_and(void)
{
	shift();
	for( ;; ){
		if( ch=='&' ){
			readch();
			shift();
			
			p1 = math.pop();
			p2 = math.pop();
			math.push(p2&p1);
		}
		else break;
	}
}
void bit_or(void)
{
	bit_and();
	for( ;; ){
		if( ch=='|' ){
			readch();
			bit_and();
			
			p1 = math.pop();
			p2 = math.pop();
			math.push(p2|p1);
		}
		else break;
	}
}
void bit_xor(void)
{
	bit_or();
	for( ;; ){
		if( ch=='^' ){
			readch();
			bit_or();
			
			p1 = math.pop();
			p2 = math.pop();
			math.push(p2^p1);
		}
		else break;
	}
}
// 数式解析／書き込み
long math_op(BFILE *mx,char *mbuf)
{
	rfp    = 0;
	buffer = mbuf;
	fpr    = mx;
	
	math.stack_pointer = 0;				// スタック初期化
	math.err_flag      = FALSE;			// エラーフラグ初期化
	readch();
	bit_xor();
	p1 = math.pop();
	if( math.stack_pointer!=0 || math.err_flag!=FALSE )
	{
		erl(fpr);
		printf("数式が異常です(%s)。\n",buffer);
		return 0;
	}
	return p1;
}
