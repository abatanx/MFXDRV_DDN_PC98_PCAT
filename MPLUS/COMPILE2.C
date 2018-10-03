/*---------------------------------------------------------------------------
       MFXDRV/DDN system XMML3.00 compiler MPLUS(mfxc+) release 1.00
  copyright (c) 1994 by ABA / T.Kobayashi and Interfair all rights reserved.
 *---------------------------------------------------------------------------*/
//
// MML�R���p�C���⏕�֐��Q
//

// �E�F�C�g�������o��
void notewait(long notelen,MFILE *fpw )
{
	if( playflag!=TRUE )return;
	if( notelen>=256L ){
		while( notelen>0L ){
			mputc( 0x91,fpw );
			if( notelen>65535L ){
				mputw( 65535,fpw );
				notelen -= 65535L;
			}
			else {
				mputw( notelen,fpw );
				notelen  =   0L;
				break;
			}
		}
	}
	else if( notelen>0 ){
		mputc( 0x90,fpw );
		mputc( (int)notelen,fpw );
	}
}

// ���l�ǂݏo��(1)
int valcomp(char *param,int *data,int min,int max,BFILE *fpr)
{
	int cmd,dx,x;
	
	x   = *data;
	cmd = btop(fpr);
	if( cmd=='+' )
	{
		bnext(fpr);
		dx = bnumber(fpr);
		if( bnumflag==FALSE )
		{
			erl(fpr,ERR);
			printf("\'%s\' �p�����[�^�̐��l +x (10�i��)������܂���B\n");
			return 0;
		}
	}
	else if( cmd=='-' )
	{
		bnext(fpr);
		dx = -bnumber(fpr);
		if( bnumflag==FALSE )
		{
			erl(fpr,ERR);
			printf("\'%s\' �p�����[�^�̐��l -x (10�i��)������܂���B\n");
			return 0;
		}
	}
	else if( cmd>='0' && cmd<='9' )
	{
		x  = bnumber(fpr);
		dx = 0;
		if( bnumflag==FALSE )
		{
			erl(fpr,ERR);
			printf("\'%s\' �p�����[�^�̐��l x (10�i��)������܂���B\n");
			return 0;
		}
	}
	else
	{
		erl(fpr);
		printf("\'%s\' �̐��l�w�肪�Ԉ���Ă��܂��B\n",param);
		return *data;
	}

	x += dx;
	if( x<min || x>max )
	{
		erl(fpr);
		printf("\'%s\' �̒l�� %d..%d �͈̔͂��z���܂���(%d)�B\n",param,min,max,x);
		*data = min;
		return min;
	}
	*data = x;
	return x;
}

// ���l�ǂݏo��(2)
int valcomp2(char *param,int *data,int min,int max,BFILE *fpr)
{
	int cmd;
	long x;
	
	x   = (long)*data;
	cmd = btop(fpr);
	if( cmd>='0' && cmd<='9' )
	{
		x  = (long)bnumber(fpr);
		if( bnumflag==FALSE )
		{
			erl(fpr,ERR);
			printf("\'%s\' �p�����[�^�̐��l x (10�i��)������܂���B\n");
			return 0;
		}
	}
	else if( cmd=='-' )
	{
		bnext(fpr);
		x = -(long)bnumber(fpr);
		if( bnumflag==FALSE )
		{
			erl(fpr,ERR);
			printf("\'%s\' �p�����[�^�̐��l -x (10�i��)������܂���B\n");
			return 0;
		}
	}
	else
	{
		erl(fpr);
		printf("\'%s\' �̐��l�w�肪�Ԉ���Ă��܂��B\n",param);
		return *data;
	}

	if( x<(long)min || x>(long)max )
	{
		erl(fpr);
		printf("\'%s\' �̒l�� %d..%d �͈̔͂��z���܂���(%ld)�B\n",param,min,max,x);
		*data = min;
		return min;
	}
	*data = (int)x;
	return (int)x;
}

// �X�y�[�X���J�b�g����
void operate_line( char *buf2,char *buf,BFILE *fp )
{
	int i,j,angle;
	i = 0;
	j = 0;
	angle = 0;

	while( buf[i]!=NULL ){
		if( (buf[i]>=0x81 && buf[i]<=0x9f)||(buf[i]>=0xe0 && buf[i]<=0xfc))
		{
			buf2[j++] = buf[i++];
			if( (buf2[j++] = buf[i++])==NULL )break;
			continue;
		}
		if( buf[i]=='\"' )angle = 1-angle;
		if( (buf[i]!=' ' && buf[i]!=0x09 && buf[i]!='\n' && buf[i]!='\r') || angle==1 )
			buf2[j++] = buf[i];
		i++;
		if( j>=4095 || i>=4095 )
		{
			erl(fp,ERR);
			printf("��s���A4095�����Ɏ��܂�悤�L�q���ĉ������B\n");
			break;
		}
	}
	buf2[j] = '\0';
}
