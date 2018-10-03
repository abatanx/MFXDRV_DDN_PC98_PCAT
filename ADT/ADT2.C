/*---------------------------------------------------------------------------
                             ADTƒ‰ƒCƒuƒ‰ƒŠ
-----------------------------------------------------------------------------*/
#include	<stdio.h>
#include	<alloc.h>


typedef struct instrument_adt {
	int no,bank;
	struct instrument_adt *left,*right;
} ADT;

ADT *maketree(ADT *p,int bank,int no)
{
	long a,b;
	if( p==NULL )
	{
		if( (p = malloc(sizeof(ADT)))==NULL )return NULL;
		p->bank = bank;
		p->no   = no;
		p->left = NULL;
		p->right= NULL;
	}
	else
	{
		a = bank*256L+(long)no;
		b = p->bank*256L+(long)p->no;
		if( a < b )
			p->left = maketree(p->left ,bank,no);
		else if( a > b)
			p->right= maketree(p->right,bank,no);
		else return p;
	}
	return p;
}

void printtree(ADT *p)
{
	if( p!=NULL )
	{
		printtree(p->left);
		printf("%04x %3d\n",p->bank,p->no);
		printtree(p->right);
	}
}

main(void)
{
	int a,b;
	ADT *p;
	
	p = NULL;
	
	for(;;)
	{
		printf("bank(-1=END):");scanf("%d",&a);
		if( a==-1 )break;
		printf("no          :");scanf("%d",&b);
		p = maketree(p,a,b);
	}
	printtree(p);
	return NULL;
}
