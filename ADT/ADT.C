//
// ADT-LIBRARY
//
#include	<stdio.h>
#include	<mylib.h>
#include	"adt.h"

void init_adt(ADT *buf)
{
	buf->next = NULL;
}

void make_adt(ADT *buf,word bank,byte no)
{
	ADT *tp;
	tp = buf;
	while( tp->next!=NULL ){
		tp = tp->next;
		if( tp->bank==bank && tp->no==no )return;
	}
	if( (tp=(ADT *)malloc(sizeof(ADT)))==NULL )return;
	tp->bank = bank;
	tp->no   = no;
	tp->next = NULL;
}

void main(void)
{
	unsigned a,b;
	ADT buf,*tp;
	init_adt(&buf);
	for(;;)
	{
		printf("--- 255:end ---\n");
		scanf("%u",&a);
		if( a==255 )break;
		scanf("%u",&b);
		make_adt( &buf,a,b );
	}
	tp = buf.next;
	while( tp!=NULL )
	{
		printf("%u %u\n",tp->bank, tp->no);
		tp=tp->next;
	}
}
