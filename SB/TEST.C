#include <mfxddn.h>

void main(void)
{
	int k;
	if( mfxddn_bgm_init()==-1 )
	{
		printf("Not installed mfxddn.\n");
		return;
	}
	k = mfxddn_get_driver_table("OPL2");
	if( k==EOF )
	{
		printf("Not stay driver.\n");
		exit(1);
	}
	mfxddn_dcm_init(k);					puts("init done");
	mfxddn_dcm_progchange(k,0,0);		puts("pchg done");
	mfxddn_dcm_volume(k,0,127);			puts("vol  done");
	mfxddn_dcm_expression(k,0,127);		puts("exp  done");
	mfxddn_dcm_noteon(k,0,64,127);		puts("noteon done");
	getch();
	mfxddn_dcm_noteoff(k,0,64);			puts("noteoff done");
	mfxddn_dcm_end(k);					puts("dcmend done");
}
