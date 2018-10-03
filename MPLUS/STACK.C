/*---------------------------------------------------------------------------
       MFXDRV/DDN system XMML3.00 compiler MPLUS(mfxc+) release 1.00
  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
 *---------------------------------------------------------------------------*/
//
// スタック制御
//

#include	<stdio.h>
#include	<alloc.h>
#include	"mplus.h"

void stkover(char *m)
{
	erl(NULL,ERR|SYS);
	printf(" stack.c %s:overflow!\n",m);
}
void stkunder(char *m)
{
	erl(NULL,ERR|SYS);
	printf(" stack.c %s:underflow!\n",m);
}

// スタックシステム
void pstack::push(void *data)
{
	if( stack_pointer==MAXSTACK )
	{
		err_flag = TRUE;
		stkover("pstack::push(void *data)");
		return;
	}
	stack[stack_pointer++] = data;
}

void *pstack::pop(void)
{
	if( stack_pointer<=0 )
	{
		err_flag = TRUE;
		stack_pointer=-1;
		stkunder("*pstack::pop(void)");
		return 0;
	}
	return stack[--stack_pointer];
}

void istack::push(int data)
{
	if( stack_pointer==MAXSTACK )
	{
		err_flag = TRUE;
		stkover("istack::push(int data)");
		return;
	}
	stack[stack_pointer++] = data;
}

int  istack::pop(void)
{
	if( stack_pointer<=0 )
	{
		err_flag = TRUE;
		stack_pointer=-1;
		stkunder("istack::pop(void)");
		return 0;
	}
	return stack[--stack_pointer];
}

int  istack::top(void)
{
	if( stack_pointer==0 )
	{
		err_flag = TRUE;
		stkunder("istack::top(void)");
		return 0;
	}
	return stack[stack_pointer-1];
}

void lstack::push(long data)
{
	if( stack_pointer==MAXSTACK )
	{
		err_flag = TRUE;
		stkover("lstack::push(long data)");
		return;
	}
	stack[stack_pointer++] = data;
}

long lstack::pop(void)
{
	if( stack_pointer<=0 )
	{
		err_flag = TRUE;
		stack_pointer=-1;
		stkunder("lstack::pop(void)");
		return 0;
	}
	return stack[--stack_pointer];
}

// ADTシステム ----------------------------------------------------------------
ADT *makeadt(ADT *p,int bank,int no)
{
	long a,b;
	if( p==NULL )
	{
		if( (p = (ADT *)malloc(sizeof(ADT)))==NULL ){
			erl(NULL,SYS|ERR);
			printf("makeadt():音色情報を定義するためのメモリーが足りません。\n");
			exits(1);
		}
		p->bank = bank;
		p->no   = no;
		p->left = NULL;
		p->right= NULL;
		
//		printf("登録:バンク:%04x 音色:%3d\n",bank,no);
	}
	else
	{
		a = bank*256L+(long)no;
		b = p->bank*256L+(long)p->no;
		if( a < b )
			p->left = makeadt(p->left ,bank,no);
		else if( a > b)
			p->right= makeadt(p->right,bank,no);
		else return p;
	}
	return p;
}

void printadt(ADT *p,MFILE *fp)
{
	if( p!=NULL )
	{
		printadt(p->left,fp);
		mputw( p->bank,fp );
		mputc( p->no  ,fp );
//		printf("書出:バンク:%04x 音色:%3d\n",p->bank,p->no);
		printadt(p->right,fp);
	}
}

