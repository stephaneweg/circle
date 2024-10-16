'declare function VFS_LOAD_FILE cdecl alias "vfs_load_file"(path as unsigned byte ptr,fsize as unsigned long ptr) as unsigned byte ptr
declare sub gui_init cdecl alias "gui_init"(lfb as unsigned integer ,screenwidth as unsigned long,screenheight as unsigned long,rotatescreen as unsigned long)
declare sub gui_setl_fb cdecl alias "gui_setl_fb"(_lfb as unsigned integer)
declare function gui_mouse_update cdecl alias "gui_mouse_update"(mouse_x as integer,mouse_y as integer,mouse_left as integer,mouse_right as integer, mouse_middle as integer,mouse_wheel as integer) as integer
declare function gui_keypress cdecl alias "gui_keypress"(c as unsigned byte) as integer
declare function gui_redraw cdecl alias "gui_redraw"() as unsigned long
declare sub GUI_LOCK cdecl alias "gui_lock"()
declare sub GUI_UNLOCK cdecl alias "gui_unlock"()

#include once "font.bi"
#include once "fontmanager.bi"
#include once "gimage.bi"
#include once "skin.bi"
#include once "gelement.bi"
#include once "graphic_console.bi"

#include once "button.bi"
#include once "window.bi"
#include once "textbox.bi"