#ifndef _gui_h
#define _gui_h

#include <circle/types.h>
extern "C" void gui_init (void* lfb,u32 screenwidth,u32 screenheight);
extern "C" u32 gui_redraw();
extern "C" u32 gui_set_lfb(void* lfb);
#endif