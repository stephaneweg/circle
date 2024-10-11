declare sub gui_init cdecl alias "gui_init"(lfb as unsigned integer,screenwidth as unsigned long,screenheight as unsigned long)
declare function gui_need_update cdecl alias "gui_need_update"() as unsigned long
declare function gui_redraw cdecl alias "gui_redraw"() as unsigned long
declare sub gui_set_lfb cdecl alias "gui_set_lfb"(lfb as unsigned integer)

#include once "arch/stdlib.bi"
#include once "arch/arch.bi"
#include once "font.bi"
#include once "fontmanager.bi"
#include once "gimage.bi"
#include once "skin.bi"
#include once "gelement.bi"
#include once "button.bi"
#include once "window.bi"
#include once "graphic_console.bi"