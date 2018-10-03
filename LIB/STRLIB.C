/*
// 文字列処理ライブラリ
*/
#include	<stdio.h>
#include	<string.h>

/*
// スペースをカットする ( "..." は、そのまま )
*/
void ddn_cut_space( char *buf )
{
	char trans[256] , *tr, *bs;
	int  dubc = 0;
	
	tr = trans;
	bs = buf;
	
	while( *buf!='\0' ){
		if( ( *buf==' ' || *buf=='\x09' || *buf=='\n' ) && dubc==0 )buf ++;
		else if( *buf==';'  && dubc==0 )break;
		else if( *buf=='\"'            ){
			dubc = 1-dubc;
			buf ++;
		}
		else *(tr++) = *(buf++);
	}

	*tr = '\0';
	strcpy( bs, trans);
}

/*
// 文字列から、１文字検索する
*/
int ddn_instr(char *str , char keyword)
{
	int x=EOF ,i=1;
	while( *str!='\0' ){
		if( *str==keyword ){
			x = i;
			break;
		}
		i  ++;
		str++;
	}
	return x;
}

/*
// 文字列から、１文字検索する(後から検索)
*/
int ddn_instrback(char *str , char keyword)
{
	int x=EOF ,i;
	i    = strlen(str)-1;
	str += i;
	
	while( i>=0 ){
		if( *str==keyword ){
			x = i+1;
			break;
		}
		str--;
		i--;
	}
	return x;
}

/*
// 一番後ろに \ がついていたら、消す
*/
void ddn_cut_dirmark(char *str)
{
	int x;
	x = strlen(str);
	if( str[x-1]=='\\' )str[x-1]='\0';
}

/*
// 一番後ろに \ がついてないなら、つける
*/
void ddn_add_dirmark(char *str)
{
	int x;
	x = strlen(str);
	if( str[x-1]!='\\' ){
		str[ x ]='\\';
		str[x+1]='\0';
	}
}

/*
// string compare
*/
int ddn_strcmp(char *str1,char *str2)
{
	int ret=0;
	while(1)
	{
		if( *str1!=*str2 )return 1;
		if( !*str1 || !*str2 )break;
		str1++;
		str2++;
	}
	return 0;
}

/*
// string compare for n
*/
int ddn_strncmp(char *str1,char *str2,int n)
{
	int ret=0,i=0;
	while(i<n)
	{
		if( *str1!=*str2 )return 1;
		if( !*str1 || !*str2 )break;
		str1++;
		str2++;
		i++;
	}
	return 0;
}

/*
// string compare by force
*/
int ddn_stricmp(char *str1,char *str2)
{
	int ret=0;
	char c1,c2;
	while(1)
	{
		c1 = *str1;
		c2 = *str2;
		c1 = (c1>='A' && c1<='Z')?(c1-'A'+'a'):c1;
		c2 = (c2>='A' && c2<='Z')?(c2-'A'+'a'):c2;
		if( c1!=c2 )return 1;
		if( !c1 || !c2 )break;
		str1++;
		str2++;
	}
	return 0;
}

