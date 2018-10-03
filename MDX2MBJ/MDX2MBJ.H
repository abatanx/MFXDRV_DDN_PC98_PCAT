//---------------------------------------------------------------------------
//  MFXDDN the XMML ver.3.00 SMF converter XMML object maker.
//                         MCV(tm) version 2.00
//   copyright (c) 1993 by T.Kobayashi and Interfair , all rights reserved.
//---------------------------------------------------------------------------

typedef struct {
	char module[16];
	char channel;
} MODULE;

typedef struct {
	MODULE chain[4];
	long   fp;
	long   size;
	unsigned compless;
	unsigned ext;
} TRACK;
