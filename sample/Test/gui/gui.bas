
#include once "../arch/stdlib.bi"
#include once "../system.bi"
#include once "gui.bi"
#include once "../game/game.bi"
#include once "../app.bi"


dim shared ScreenRoot as GUI_ELEMENT ptr
dim shared MainConsole as GRAPHIC_CONSOLE ptr
dim shared ButtonSkin as Skin ptr
dim shared WindowSkin as Skin ptr
dim shared WindowCloseButtonSkin as Skin ptr


#include once "font.bas"
#include once "fontmanager.bas"
#include once "gimage.bas"
#include once "skin.bas"
#include once "gelement.bas"
#include once "button.bas"
#include once "window.bas"
#include once "graphic_console.bas"



#define APP_LOADADDR &h900000

dim shared lfbptr as unsigned long ptr
dim shared lfbBackBuffer as unsigned long ptr
dim shared lfbwidth as unsigned integer
dim shared lfbheight as unsigned integer
dim shared lfbSize as unsigned integer


dim shared current_application as Application ptr
dim shared m_rotateScreen as integer


dim shared m_GameState as GameState



sub load_application(path as unsigned byte ptr)
	dim app_main as function (root as GUI_Element ptr) as Application ptr
	
	dim result as Application ptr = 0
	
	dim buffer as unsigned byte ptr
    dim fsize as unsigned long=0
    buffer=vfs_load_file(path,@fsize)
	if (fsize>0 and buffer>0) then
		memcpyarch(cptr(any ptr,APP_LOADADDR),buffer,fsize)
		deallocate(buffer)
		
		app_main = cptr(any ptr,APP_LOADADDR)
		result = app_main(ScreenRoot)
	end if
	
	current_application = result
end sub

sub gui_init cdecl alias "gui_init"(lfb as unsigned integer ,screenwidth as unsigned long,screenheight as unsigned long,rotatescreen as unsigned long)
	KWRITELine(@"Hello from GUI System")
	GetFontManager()->Init()
	MainConsole = 0
	current_application = 0
	
	m_rotateScreen = rotatescreen
	
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
	
	if (m_rotateScreen<>0) then
		ScreenRoot = new GUI_ELEMENT(0,0,lfbheight,lfbwidth)
	else
		ScreenRoot = new GUI_ELEMENT(0,0,0,0)
		ScreenRoot->Buffer	= lfbptr
		ScreenRoot->Width	= lfbwidth
		ScreenRoot->Height	= lfbheight
		ScreenRoot->Left	= 0
		ScreenRoot->Top		= 0
	end if
	
	var twin1 = new GUI_WINDOW((ScreenRoot->Width-600)/2,50,600,400,@"Debug Console window",0)
	MainConsole = new GRAPHIC_CONSOLE(7,32,twin1->Width-14,twin1->Height-39)
	twin1->AddChild(MainConsole)
    'ScreenRoot->AddChild(twin1)
	
	
	'MainConsole->WriteLine(@"GUI System ready")
	
	m_GameState.controller(0).joypad_num = 0
	m_GameState.controller(0).vertical_axis = 0
	m_GameState.controller(0).vertical_sign = 1
	m_GameState.controller(0).horizontal_axis = 1
	m_GameState.controller(0).horizontal_sign = -1
	

	m_GameState.controller(1).joypad_num = 1
	m_GameState.controller(1).vertical_axis = 0
	m_GameState.controller(1).vertical_sign = -1
	m_GameState.controller(1).horizontal_axis = 1
	m_GameState.controller(1).horizontal_sign = 1
	
	load_application(@"SD:/pong.img")
end sub

sub update_controller()
	dim i as integer
	for i=lbound(m_GameState.controller) to ubound(m_GameState.controller)
		
		m_GameState.controller(i).horizontal_movement	= get_joypad_axis(m_GameState.controller(i).joypad_num,m_GameState.controller(i).horizontal_axis)*m_GameState.controller(i).horizontal_sign
		m_GameState.controller(i).vertical_movement		= get_joypad_axis(m_GameState.controller(i).joypad_num,m_GameState.controller(i).vertical_axis)*m_GameState.controller(i).vertical_sign
		
		dim buttons as unsigned integer
		buttons = get_joypad_buttons(m_GameState.controller(i).joypad_num)
		
		m_GameState.controller(i).button0 =(( buttons shr 0) and 1)
		m_GameState.controller(i).button1 =(( buttons shr 1) and 1)
		m_GameState.controller(i).button2 =(( buttons shr 2) and 1)
		m_GameState.controller(i).button3 =(( buttons shr 3) and 1)
		m_GameState.controller(i).button4 =(( buttons shr 4) and 1)
		m_GameState.controller(i).button5 =(( buttons shr 5) and 1)
		m_GameState.controller(i).button6 =(( buttons shr 6) and 1)
		m_GameState.controller(i).button7 =(( buttons shr 7) and 1)
		
		m_GameState.controller(i).button8 =(( buttons shr 8) and 1)
		m_GameState.controller(i).button9 =(( buttons shr 9) and 1)
		m_GameState.controller(i).button10 =(( buttons shr 10) and 1)
		m_GameState.controller(i).button11 =(( buttons shr 11) and 1)
		m_GameState.controller(i).button12 =(( buttons shr 12) and 1)
		m_GameState.controller(i).button13 =(( buttons shr 13) and 1)
		m_GameState.controller(i).button14 =(( buttons shr 14) and 1)
		m_GameState.controller(i).button15 =(( buttons shr 15) and 1)
	
	next i
end sub


sub gui_update cdecl alias "gui_update"(elapsed as double)

	m_GameState.elapsed = elapsed
	update_controller()
	
	'sys_lock_gui()
	if (current_application<>0) then
		if (current_application->OnUpdate<>0) then	current_application->OnUpdate(current_application,@m_GameState)
	end if
	ScreenRoot->Invalidate(false)
	'sys_unlock_gui()
	
end sub


function gui_redraw cdecl alias "gui_redraw"() as unsigned long
	dim retval as integer = 0


	
    'if (ScreenRoot->IsValid=0) then
		ScreenRoot->Clear(&h000000)
		'ScreenRoot->DrawText(@"Onyx RPI V0.1.1",10,10,&hFFFFFFFF,FontManager.SIMPAGAR,1)
		
		sys_lock_gui()
		ScreenRoot->Draw()
		if (current_application<>0) then 
			if (current_application->OnRedraw <>0) then current_application->OnRedraw(current_application,ScreenRoot)
		end if
        sys_unlock_gui()
		
		
		if (m_rotateScreen<>0) then
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
	'end if
	return retval
end function

sub gui_set_lfb cdecl alias "gui_set_lfb"(lfb as unsigned integer)
	lfbptr = cptr(unsigned long ptr,lfb)
	lfbBackBuffer 		= cptr(unsigned long ptr,lfb + lfbSize)	
	if (m_rotateScreen=0) then
		ScreenRoot->Buffer	= lfbptr
	end if
end sub

sub gui_writeline cdecl alias "gui_writeline"(txt as unsigned byte ptr)
	if (MainConsole<>0) then
		sys_lock_gui()
		MainConsole->WriteLine(txt)
		MainConsole->Invalidate(false)
		sys_unlock_gui()
	end if
end sub

sub gui_write cdecl alias "gui_write"(txt as unsigned byte ptr)
	if (MainConsole<>0) then
		sys_lock_gui()
		MainConsole->Write(txt)
		MainConsole->Invalidate(false)
		sys_unlock_gui()
	end if
end sub
