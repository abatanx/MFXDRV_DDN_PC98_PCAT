/*---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 MFXDRV/DDN êßå‰ÉâÉCÉuÉâÉä
//                            DDNLIB version 1.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------
*/

#include	<stdio.h>
#include	"mfxddn.h"

#if			CONFIG_FILELINK == TRUE
#include	"fl.h"
#endif

/*
// å¯â âπì«Ç›çûÇ›
*/
#if			CONFIG_FILELINK == TRUE
int mfxddn_se_load_filelink( int no,char *filename,char *drvid,int channel,int track )
#else
int mfxddn_se_load( int no,char *filename,char *drvid,int channel,int track )
#endif
{
	int drvno,size;
	FILE *fpr;
	
	if( no>=MAX_SEBUF || MFXDDN_Initialize==EOF ){
		mfxddn_errset(DDN_NOTINSTALLED);
		return EOF;
	}
	
	drvno = mfxddn_get_driver_table( drvid );
	if( drvno==EOF || se[no].buffer!=NULL ){
		mfxddn_errset(DDN_DRIVERNOTFOUND);
		return EOF;
	}

#if		CONFIG_FILELINK == TRUE
	if( (fpr=fl_open(filename,"rb"))==NULL ){
#else
	if( (fpr=fopen(filename,"rb"))==NULL ){
#endif
		mfxddn_errset(DDN_FILENOTFOUND);
		return EOF;
	}
	
#if		CONFIG_FILELINK == TRUE
	size = finf.size;
#else
	fseek( fpr,0L,SEEK_END );
	size = ftell(fpr);
	fseek( fpr,0L,SEEK_SET );
#endif

	if( (se[no].buffer=ddn_keep_highmemory((long)size))==NULL ){
		fclose(fpr);
		mfxddn_errset(DDN_NOTENOUGHMEMORY);
		return EOF;
	}
#if	__TURBOC__ && (__COMPACT__+__LARGE__+__HUGE__==1)
	fread( se[no].buffer,size,1,fpr );
#else
	{long bsize;
	for( bsize=0; bsize<size; bsize++)
		*(se[no].buffer+(unsigned)bsize) = fgetc(fpr);
	}
#endif
	fclose( fpr );
	
	se[no].channel = channel;
	se[no].driver  = drvno;
	se[no].track   = track;
	return NULL;
}

