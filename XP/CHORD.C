#include	<stdio.h>
#include	<string.h>

#define		MajorTriad		1
#define		MinorTriad		2
#define		DiminishedTriad	3
#define		AugmentedTriad	4
#define		SuspendedTriad	5

int tension(int root,int tsc)
{
	int a;
	a = (root+tsc)%12;
	return a;
}

void chord(int note[])
{
	int flag,i,triad,_6th,x;
	char base[32],ext[32];
	char *rootnote[]=
		{"C","C#","D","D#","E","F","F#","G","G#","A","A#","B"};

	for(i=0;i<12;i++)
	{
		if(note[i]==0)continue;
		strcpy(base,rootnote[i]);
// Pass1
		_6th=0;
		if(note[tension(i,4)]&&note[tension(i,7)])
			triad=MajorTriad;
		else if(note[tension(i,3)]&&note[tension(i,7)])
		{
			strcat(base,"m");
			triad=MinorTriad;
		}
		else if(note[tension(i,3)]&&note[tension(i,6)])
		{
			strcat(base,"dim");
			triad=DiminishedTriad;
		}
		else if(note[tension(i,4)]&&note[tension(i,6)])
		{
			strcat(base,"aug");
			triad=AugmentedTriad;
		}
		else if(note[tension(i,5)]&&note[tension(i,7)])
		{
			triad=SuspendedTriad;
		}
		else
		{
			continue;
		}
// Pass2
		if(note[tension(i,11)])strcat(base,"Maj7");
		else if(note[tension(i,10)])strcat(base,"7");
		else if(note[tension(i,9)])
		{
			strcat(base,"6");
			_6th=1;
		}
		if( triad==SuspendedTriad )strcat(base,"sus4");
// Pass3
		strcpy(ext,"");
		if(note[tension(i,2)])strcat(ext,"9 ");
		if(note[tension(i,3)]
			&& (triad!=MinorTriad && triad!=DiminishedTriad) )strcat(ext,"+9 ");
		if(note[tension(i,1)])strcat(ext,"-9 ");
		if(note[tension(i,5)] && triad!=SuspendedTriad )strcat(ext,"11 ");
		if(note[tension(i,6)]
			&& (triad!=DiminishedTriad && triad!=AugmentedTriad) )strcat(ext,"+11 ");
		if(note[tension(i,9)] && _6th==0)strcat(ext,"13 ");
		if(note[tension(i,8)])strcat(ext,"-13 ");
///
		printf("%s",base);
		if( ext[0]!=NULL )
		{
			x=strlen(ext);
			ext[x-1]=NULL;
			printf("(%s)",ext);
		}
		printf(" ");
	}
	printf("\n");
}

int main(void)
{
	char buf[256];
	int note[12],i,key;
	printf("--- コード解析のテスト ---\n");
	for(;;)
	{
		for(i=0;i<12;i++)note[i]=0;
		printf("ノートを入力して下さい(Ex.ceg/q:END) >> ");
		scanf("%s",buf);
		if(buf[0]=='q')break;
		i=0;
		while(buf[i]!=NULL)
		{
			switch(buf[i])
			{
				case 'c':key= 0;break;
				case 'd':key= 2;break;
				case 'e':key= 4;break;
				case 'f':key= 5;break;
				case 'g':key= 7;break;
				case 'a':key= 9;break;
				case 'b':key=11;break;
				default:printf("\'%c\' ってなんですか?\n",buf[0]);break;
			}
			if(buf[i+1]=='+'||buf[i+1]=='#')
			{
				key++;
				i+=2;
			}
			else if(buf[i+1]=='-')
			{
				key--;
				i+=2;
			}
			else i++;
			if( key<0 )key+=12;
			else if( key>11 )key%=12;
			note[key]=1;
		}
		chord(note);
	}
	return NULL;
}
