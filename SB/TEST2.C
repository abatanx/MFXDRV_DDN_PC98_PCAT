#include <stdio.h>
#include <mfxddn.h>

void main(void)
{
	if( mfxddn_bgm_init()==EOF )exit(1);
	while( !kbhit() )printf("\r%ld",mfxddn_get_counter());
}
