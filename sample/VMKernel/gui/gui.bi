'declare function VFS_LOAD_FILE cdecl alias "vfs_load_file"(path as unsigned byte ptr,fsize as unsigned long ptr) as unsigned byte ptr
declare sub KWrite cdecl alias "kwrite"(s as unsigned byte ptr)
declare sub KWriteLine cdecl alias "kwriteline"(s as unsigned byte ptr)
declare sub gui_init cdecl alias "gui_init"(_lfb as unsigned integer,_width as unsigned integer,_height as unsigned integer)
declare sub gui_setl_fb cdecl alias "gui_setl_fb"(_lfb as unsigned integer)
declare function gui_mouse_update cdecl alias "gui_mouse_update"(mouse_x as integer,mouse_y as integer,mouse_left as integer,mouse_right as integer, mouse_middle as integer,mouse_wheel as integer) as integer
declare function gui_keypress cdecl alias "gui_keypress"(c as unsigned byte) as integer
declare function gui_redraw cdecl alias "gui_redraw"() as integer
declare sub GUI_LOCK cdecl alias "gui_lock"()
declare sub GUI_UNLOCK cdecl alias "gui_unlock"()

#include once "gui/font.bi"
#include once "gui/fontmanager.bi"
#include once "gui/gimage.bi"
#include once "gui/skin.bi"
#include once "gui/gelement.bi"
#include once "gui/graphic_console.bi"

#include once "gui/button.bi"
#include once "gui/window.bi"
#include once "gui/textbox.bi"