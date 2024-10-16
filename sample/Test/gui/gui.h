#ifndef _gui_h
#define _gui_h

#include <circle/types.h>
extern "C" void load_game(const TCHAR* path);
extern "C" void gui_update(double elapsed);
extern "C" void gui_init (void* lfb,u32 screenwidth,u32 screenheight,u32 rotateScreen);
extern "C" u32 gui_redraw();
extern "C" u32 gui_set_lfb(void* lfb);
extern "C" void gui_writeline(const TCHAR*  txt);
extern "C" void gui_write(const TCHAR*  txt);
#endif