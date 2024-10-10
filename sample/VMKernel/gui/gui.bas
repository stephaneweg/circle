
#include once "vm/vm.bi"
#include once "gui/gui.bi"

dim shared ScreenRoot as GUI_ELEMENT ptr
dim shared MainConsole as GRAPHIC_CONSOLE ptr
dim shared ButtonSkin as Skin ptr
dim shared WindowSkin as Skin ptr
dim shared WindowCloseButtonSkin as Skin ptr


#include once "gui/font.bas"
#include once "gui/fontmanager.bas"
#include once "gui/gimage.bas"
#include once "gui/skin.bas"
#include once "gui/gelement.bas"
#include once "gui/graphic_console.bas"
#include once "gui/window.bas"
#include once "gui/button.bas"
#include once "gui/textbox.bas"

dim shared lfbptr as unsigned long ptr
dim shared lfbBackBuffer as unsigned long ptr
dim shared lfbwidth as unsigned integer
dim shared lfbheight as unsigned integer
dim shared lfbSize as unsigned integer

dim shared oldMouseX		as integer
dim shared oldMouseY 		as integer
dim shared oldMouseLeft		as integer
dim shared oldMouseRight	as integer
dim shared oldMouseMiddle	as integer
dim shared _guiLock         as integer

dim shared cx as integer
dim shared cy as integer
dim shared dx as integer
dim shared dy as integer


sub GUI_LOCK cdecl alias "gui_lock"()
    ARCH_SPINLOCK(@_guiLock)
end sub

sub GUI_UNLOCK cdecl alias "gui_unlock"()
    ARCH_UNLOCK(@_guiLock)
end sub

sub KWrite cdecl alias "kwrite"(s as unsigned byte ptr)  
    if (MainConsole<>0) then
        MainConsole->Write(s)
        MainConsole->Invalidate(false)
    end if	
end sub

sub KWriteLine cdecl alias "kwriteline"(s as unsigned byte ptr)   
    if (MainConsole<>0) then
        MainConsole->WriteLine(s)
        MainConsole->Invalidate(false)
    end if	
end sub


sub gui_init cdecl alias "gui_init"(_lfb as unsigned integer,_width as unsigned integer,_height as unsigned integer)
	FontManager.Init()
    _guiLock    = 0
    
    ButtonSkin = Skin.Create(@"SD:/skins/button.bmp",3,5,5,5,5)
    WindowSkin = Skin.Create(@"SD:/skins/wings.bmp",1,7,7,32,7)
    WindowCloseButtonSkin = Skin.Create(@"SD:/skins/closebgs.bmp",3,5,5,5,5)
    WindowSkin->ApplyColor(&h303d45,0)
    WindowCloseButtonSkin->ApplyColor(&h303d45,1)
	GUI_FocusedElement = 0
	lfbptr			= cptr(unsigned long ptr,_lfb)
	lfbSize			= ((_width * _height)*sizeof(unsigned long))
	lfbBackBuffer	= cptr(unsigned long ptr,_lfb + lfbSize)
	lfbwidth 		= _width
	lfbheight 		= _height
	ScreenRoot = new GUI_ELEMENT(0,0,0,0)
	ScreenRoot->Buffer	= lfbptr
	ScreenRoot->Width	= lfbwidth
	ScreenRoot->Height	= lfbheight
	ScreenRoot->Left		= 0
	ScreenRoot->Top		= 0
	
	
	
	cx=0
	cy=0
	dx=1
	dy=1
    var twin1 = new GUI_WINDOW(300,50,600,400,@"Debug Console window",0)
	MainConsole = new GRAPHIC_CONSOLE(7,32,twin1->Width-14,twin1->Height-39)
	twin1->AddChild(MainConsole)
    ScreenRoot->AddChild(twin1)
	
	
end sub


sub gui_setl_fb cdecl alias "gui_setl_fb"(_lfb as unsigned integer)
	lfbptr = cptr(unsigned long ptr,_lfb)
	lfbBackBuffer 		= cptr(unsigned long ptr,_lfb + lfbSize)	
	ScreenRoot->Buffer	= lfbptr
end sub

function gui_mouse_update cdecl alias "gui_mouse_update"(mouse_x as integer,mouse_y as integer,mouse_left as integer,mouse_right as integer, mouse_middle as integer,mouse_wheel as integer) as integer
	dim result as integer = 0
    if (mouse_x<0 or mouse_y<0) then return 0
	if	(mouse_x <> oldMouseX) or _'
		(mouse_y <> oldMouseY) or _
		(mouse_left <> oldMouseLeft) or _
		(mouse_right <> oldMouseRight) or _
		(mouse_middle <> oldMouseMiddle) or _
		(mouse_wheel<>0) then
	
		'ScreenRoot.Clear(&h0)
		
		GUI_LOCK()
		result = ScreenRoot->HandleMouse(mouse_x,mouse_y,mouse_left,mouse_right,mouse_middle,mouse_wheel)
		GUI_UNLOCK()
		oldMouseX		= mouse_x
		oldMouseY		= mouse_y
		oldMouseLeft	= mouse_left
		oldMouseRight	= mouse_right
		oldMouseMiddle	= mouse_middle
		
		
	end if
	return iif(ScreenRoot->IsValid=0,1,0)
end function

function gui_keypress cdecl alias "gui_keypress"(c as unsigned byte) as integer
    if (c<>0) then
        return ScreenRoot->HandleKeyboard(c)
    end if
    return 0
end function

function gui_redraw cdecl alias "gui_redraw"() as integer
	dim retval as integer = 0

    if (ScreenRoot->IsValid=0) then
		ScreenRoot->Clear(&h224488)
		ScreenRoot->DrawText(@"Onyx RPI V0.1.1",10,10,&hFFFFFFFF,FontManager.SIMPAGAR,1)
		
		GUI_LOCK()
		ScreenRoot->Draw()
        GUI_UNLOCK()
		retval = 1
	end if
	return retval
end function