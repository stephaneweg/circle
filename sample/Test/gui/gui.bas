#include once "../system.bi"
#include once "gui.bi"



dim shared ScreenRoot as GUI_ELEMENT ptr
dim shared MainConsole as GRAPHIC_CONSOLE ptr
dim shared ButtonSkin as Skin ptr
dim shared WindowSkin as Skin ptr
dim shared WindowCloseButtonSkin as Skin ptr


#include once "arch/stdlib.bas"
#include once "arch/arch.bas"
#include once "font.bas"
#include once "fontmanager.bas"
#include once "gimage.bas"
#include once "skin.bas"
#include once "gelement.bas"
#include once "button.bas"
#include once "window.bas"
#include once "graphic_console.bas"




dim shared lfbptr as unsigned long ptr
dim shared lfbBackBuffer as unsigned long ptr
dim shared lfbwidth as unsigned integer
dim shared lfbheight as unsigned integer
dim shared lfbSize as unsigned integer

dim shared _guiLock         as integer

dim shared RotateScreen as integer
sub GUI_LOCK cdecl alias "gui_lock"()
    ARCH_SPINLOCK(@_guiLock)
end sub

sub GUI_UNLOCK cdecl alias "gui_unlock"()
    ARCH_UNLOCK(@_guiLock)
end sub

sub gui_init cdecl alias "gui_init"(lfb as unsigned integer ,screenwidth as unsigned long,screenheight as unsigned long)
	KWRITELine(@"Hello from GUI System")
	FontManager.Init()
    _guiLock    = 0
	RotateScreen = 1
	
	ButtonSkin = Skin.Create(@"SD:/skins/button.bmp",3,5,5,5,5)
    WindowSkin = Skin.Create(@"SD:/skins/wings.bmp",1,7,7,32,7)
    WindowCloseButtonSkin = Skin.Create(@"SD:/skins/closebgs.bmp",3,5,5,5,5)
    WindowSkin->ApplyColor(&h303d45,0)
    WindowCloseButtonSkin->ApplyColor(&h303d45,1)
	
	lfbptr			= cptr(unsigned long ptr,lfb)
	lfbSize			= ((screenwidth * screenheight)*sizeof(unsigned long))
	lfbBackBuffer	= cptr(unsigned long ptr,lfb + lfbSize)
	lfbwidth 		= screenwidth
	lfbheight 		= screenheight
	
	
	kwriteFormatLine(@"LFB is at 0x%x",lfbptr)
	kwriteFormatLine(@"LFB size :  %d",lfbSize)
	kwriteFormatLine(@"Screen width : %d",lfbwidth)
	kwriteFormatLine(@"Screen height : %d",lfbheight)
	
	if (RotateScreen=1) then
		ScreenRoot = new GUI_ELEMENT(0,0,lfbheight,lfbwidth)
	else
		ScreenRoot = new GUI_ELEMENT(0,0,0,0)
		ScreenRoot->Buffer	= lfbptr
		ScreenRoot->Width	= lfbwidth
		ScreenRoot->Height	= lfbheight
		ScreenRoot->Left	= 0
		ScreenRoot->Top		= 0
	end if
	
	var twin1 = new GUI_WINDOW(300,50,600,400,@"Debug Console window",0)
	MainConsole = new GRAPHIC_CONSOLE(7,32,twin1->Width-14,twin1->Height-39)
	twin1->AddChild(MainConsole)
    ScreenRoot->AddChild(twin1)
	
	MainConsole->WriteLine(@"GUI System ready")
end sub

function gui_redraw cdecl alias "gui_redraw"() as unsigned long
	dim retval as integer = 0

    if (ScreenRoot->IsValid=0) then
		ScreenRoot->Clear(&h224488)
		ScreenRoot->DrawText(@"Onyx RPI V0.1.1",10,10,&hFFFFFFFF,FontManager.SIMPAGAR,1)
		
		GUI_LOCK()
		ScreenRoot->Draw()
        GUI_UNLOCK()
		if (RotateScreen=1) then
			dim o as integer,cx as integer,cy as integer
			o = 0
			for cx=0 to ScreenRoot->Width-1
				for cy=ScreenRoot->Height-1 to 0 step -1
					lfbptr[o] = ScreenRoot->Buffer[cy*ScreenRoot->Width+cx]
					o+=1
				next cy
			next cx
		end if
		retval = 1
	end if
	return retval
end function

sub gui_set_lfb cdecl alias "gui_set_lfb"(lfb as unsigned integer)
	lfbptr = cptr(unsigned long ptr,lfb)
	lfbBackBuffer 		= cptr(unsigned long ptr,lfb + lfbSize)	
	if (RotateScreen=0) then
		ScreenRoot->Buffer	= lfbptr
	end if
end sub