//---------------------------------------------------------------------------
//  Stranderd MIDI file format transfer 'format 0 to 1' utility.
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
#include	<stdio.h>
#include	<stdlib.h>
#include	<alloc.h>
#include	<dos.h>
#include	<string.h>
#include	<dir.h>
#include	<mfile.h>
#include	<mylib.h>

#define		version_int		0
#define		version_real	1
#define		version_char	' '

void usage_out   (void);
void convert     (char *);
void convert_main(FILE *fpw);

long fgetcount;
int fgetcbuf=EOF , option[26];

void main(int argc,char **argv)
{
	printf(	"Standerd MIDI file format transfer '0 to 1' utility"
			" version %d.%02d%c\n"
			"copyright (c) 1994 by ABA / T.Kobayashi and Interfair  "
			"All Rights Reserved.\n",
			version_int,version_real,version_char
	);
	if( argc<=2 ){
		usage_out();
		exit(EOF);
	}
	convert( *(argv+1) );
}

//-----------------------------------------------------------------------------
void usage_out(void)
{
	puts(
		"Syntax ;\n"
		"         smf0to1.exe [source] [distination] {[option]...}\n"
		"Option ;\n"
	);
}

//-----------------------------------------------------------------------------
int fgetcb(FILE *fpr)
{
	int a;
	fgetcount++;
	if( fgetcbuf!=EOF ){
		a = fgetcbuf;
		fgetcbuf = EOF;
		return a;
	}
	a=fgetc(fpr);
	if( a==EOF ){
		printf("File stream error : overread (%dbytes)\n",fgetcount);
		mcv_exit(EOF);
	}
	return a;
}
int freadb(char *buf,int size,int block,FILE *fpr)
{
	int a,i,j;
	for( j=0; j<block; j++){
		for( i=0; i<size; i++)buf[i]=fgetcb(fpr);
	}
	return NULL;
}

// hh m1 m2 ll 順のlong数値読み出し
long smfgetl( FILE *fpr )
{
	long num;
	num  = ( (long)fgetcb(fpr)*0x01000000L );
	num |= ( (long)fgetcb(fpr)*0x00010000L );
	num |= ( (long)fgetcb(fpr)*0x00000100L );
	num |= ( (long)fgetcb(fpr)             );
	return num;
}
// hh ll 順のword数値読み出し
word smfgetw( FILE *fpr )
{
	word num;
	num  = ( (word) fgetcb(fpr)<<8  );
	num |= ( (word) fgetcb(fpr)     );
	return num;
}
// 7bit 可変長数値の読み出し(SMF専用)
long smfget7bit( FILE *fpr )
{
	long num;
	int b1,b2;
	
	num = 0;
	do {
		b1   = fgetcb(fpr);
		num  = num << 7L;
		b2   = b1 & 0x7f;
		num += (long)b2;
	}
	while( (b1&0x80)!=0 );
	return num;
}
//-----------------------------------------------------------------------------
// hh m1 m2 ll 順のlong数値書き込み
void smfputl( long l,MFILE *fpw )
{
	int i;
	for( i=0; i<4; i++){
		mputc( (int)(l & 0x00ff),fpw );
		l>>=8;
	}
}
// hh ll 順のword数値書き込み
void smfputw( word l,MFILE *fpw )
{
	int i;
	for( i=0; i<2; i++){
		mputc( (int)(l & 0x00ff),fpw );
		l>>=8;
	}
}
// 7bit数値書き込み
void smfput7bit( long l,MFILE *fpw )
{
	long buf;

	buf = l & 0x7f;
	while ((l >>= 7) > 0){
		buf <<= 8;
		buf |= 0x80;
		buf += (l & 0x7f);
	}
	for( ;; ){
		mputc( buf,fpw );
		if (buf & 0x80)	buf >>= 8;
		else			break;
	}
}

//-----------------------------------------------------------------------------
// 環境変数 TMP の取得
void get_temporary(char *tmpfile)
{
	char *env;
	env = getenv("TMP");
	if( env==NULL ){
		strcpy( tmpfile,"" );
	}
	else {
		strcpy(tmpfile,env);
		cut_dirmark(tmpfile);
	}
}

//------------------------------------------------ MIDIファイルコンバート -----
void convert( char *midifile )
{
	FILE  *fpr;
	MFILE fpw[17];

	long header;
	int i,format,track,timebase,delta,stackfp;

	char
		buf[256],
		dr[MAXDRIVE],di[MAXDIR],fi[MAXFILE],ex[MAXEXT],
		sfile[MAXPATH],dfile[MAXPATH],tmp[256],tmpfile[256];
	
	get_temporary(tmp);
	
	fnsplit( midifile,dr,di,fi,ex     );
	fnmerge( sfile,   dr,di,fi,".mid" );
	fnmerge( dfile,   dr,di,fi,".smf" );
	
	if( (fpr=fopen(sfile,"rb"))==NULL ){
		printf( "Can\'t open format 0 file \'%s\'\n",sfile );
		exit(EOF);
	}
	fread( buf,4,1,fpr );
	buf[4] = '\0';

	if( strcmp(buf,"MThd")!=NULL ){
		puts("Not Standerd MIDI file.");
		exit(EOF);
	}
	
	for( i=0; i<MAX_CH; i++)
	{
		sprintf( tmpfile,"%s\\$smtmp%d.$$$",tmp,i );
		if( mopen(tmpfile,&fpw[i])==EOF )
		{
			printf("Can\'t creat temporaryfile.\n");
			exit(EOF);
		}
	}
	
	mwrite( buf,4,&fpw[0] );
	header       = smfgetl(fpr);	smfputl( header  ,&fpw[0] );
	format       = smfgetw(fpr);	smfputw( 0       ,&fpw[0] );
	track        = smfgetw(fpr);	smfputw( track   ,&fpw[0] );
	timebase     = smfgetw(fpr);	smfputw( timebase,&fpw[0] );
	
	if( format!=0 ){
		printf("Not format0 file.\n");
		exit(EOF);
	}
	else {
		printf("	FORMAT%d TRACK%d TIMEBASE%d\n",format,track,timebase);
	}
	
	fread( buf,4,1,fpr );
	buf[4] = '\0';
	if( strcmp(buf,"MTrk")!=NULL ){
		puts("MTrk Header cunck is broken.");
		exit(EOF);
	}
	
	delta  = smfgetl(fpr);
	stackfp= ftell(fpr);
	
	printf("\x1b[2K\r	MTrk : (%6ld) - ",delta);
	
	fseek( fpr,stackfp,SEEK_SET );
	fseek( fpr,delta  ,SEEK_CUR );
	
	
	for( i=0; i<MAX_CH; i++) steptime[i] = 0L;
// convert-main!
	for( ;; )
	{
		step = smf7bit(fpr);
		for( i=0; i<MAX_CH; i++) steptime[i] += step;

		cmd = fgetcb(fpr);
		if( cmd<0x80 )
		{
			fgetcbuf = cmd;
			cmd = cmdtype;
		}
		else {
			cmdtype= cmd;
		}
		mputc( cmd,&fpw[0] );

		switch( cmd & 0xf0 )
		{
			case 0xf0:
				if( cmd==0xf0 )					// Exclusive Message
				{
					
					c = fgetcb(fpr);
					do
					{
						c = fgetcb(fpr);
						mputc( c,&fpw[0] );
					}
					while( c!=0xf7 );
					break;
				}
				else if( cmd==0xff )
				{
					val = fgetcb(fpr);
					mputc( val,&fpw[0] );
					switch( val )
					{
						case 0x00:
							for( i=0; i<3; i++)mputc( fgetc(fpr),&fpw[0] );
							break;
						case 0x01:
						case 0x02:
						case 0x03:
						case 0x04:
						case 0x05:
						case 0x06:
						case 0x07:
							val = (int)smf7bit(fpr);
							freadb( buf,val,1,fpr );
							smfput7bit( val,&fpw[0] );
							mwrite( buf,val,&fpw[0] );
							break;
						
			
	
	
	
	
	
	
	fclose( fpr );
	
	for( i=0; i<MAX_CH; i++) mclose(&fpw[i]);
	
	
}
