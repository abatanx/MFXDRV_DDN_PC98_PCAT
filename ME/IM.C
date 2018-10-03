/*
   MFXDRV/DDN mPlus source generater by interpreter editor
*/

#include	<stdio.h>
#include	<master.h>
#include	"im.h"

ELINE *eline;

ELINE *get_resource(void)
{
	ELINE *k;
	unsigned seg;

	seg = hmem_allocbyte(sizeof(ELINE));
	if( seg==0 )
	{
		printf("im: メモリが足りないので、編集が不可能です(ELINE)。\n");
		exit(1);
	}
	k = (ELINE *)seg2fp(seg);

	seg = hmem_allocbyte(ELINE_SIZE);
	if( seg==0 )
	{
		printf("im: メモリが足りないので、編集が不可能です(ELINE.buf)。\n");
		exit(1);
	}
	k->buf = (ELINE *)seg2fp(seg);
	return k;
}

void show_editor_line(void)
{
	




int main(void)
{
	text_init();
	text_systemline_hide();
	text_cursor_show();
	text_clear();

	eline = NULL;
	show_editor_line();

	text_systemline_show();
	text_clear();

	return 0;
}
