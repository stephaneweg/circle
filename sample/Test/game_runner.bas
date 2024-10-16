#include once "system.bi"
#include once "gui/gui.bi"
#include once "game/game.bi"
#include once "game/pong/pong.bi"
#include once "arch/stdlib.bi"

dim shared ScreenRoot as GUI_ELEMENT ptr
dim shared MainConsole as GRAPHIC_CONSOLE ptr
dim shared ButtonSkin as Skin ptr
dim shared WindowSkin as Skin ptr
dim shared WindowCloseButtonSkin as Skin ptr

#define appLocation &h8000
dim shared lfbptr as unsigned long ptr
dim shared lfbBackBuffer as unsigned long ptr
dim shared lfbwidth as unsigned integer
dim shared lfbheight as unsigned integer
dim shared lfbSize as unsigned integer


dim shared currentGame as Game ptr
dim shared m_rotateScreen as integer


dim shared m_GameState as GameState



sub kwriteline cdecl alias "kwriteLine"(txt as unsigned byte ptr)
end sub

sub sys_lock_gui cdecl alias "sys_lock_gui"()
end sub

sub sys_unlock_gui cdecl alias "sys_unlock_gui"()
end sub

function VFS_LOAD_FILE cdecl alias "vfs_load_file"(path as unsigned byte ptr,fsize as unsigned long ptr) as unsigned byte ptr
    *fsize = 0
    dim result as any ptr
    result = 0
    return result
end function

#include once "arch/stdlib.bas"
#include once "gui/font.bas"
#include once "gui/fontmanager.bas"
#include once "gui/gimage.bas"
#include once "gui/skin.bas"
#include once "gui/gelement.bas"
#include once "gui/button.bas"
#include once "gui/window.bas"
#include once "gui/graphic_console.bas"
#include once "game/pong/pong.bas"

screenres(640,480,32)
gui_init(cast(unsigned integer,Screenptr()),640,480,0)

sub gui_init cdecl alias "gui_init"(_lfb as unsigned integer,_width as unsigned long,_height as unsigned long,rotatescreen as unsigned long)
        
   
	m_rotateScreen = rotatescreen
	
	
	
	lfbptr			= cptr(unsigned long ptr,_lfb)
	lfbSize			= ((_width * _height)*sizeof(unsigned long))
	lfbBackBuffer	= cptr(unsigned long ptr,_lfb + lfbSize)
	lfbwidth 		= _width
	lfbheight 		= _height
	
	
	if (m_rotateScreen<>0) then
		ScreenRoot = new GUI_ELEMENT(0,0,_height,_width)
	else
		ScreenRoot = new GUI_ELEMENT(0,0,0,0)
		ScreenRoot->Buffer	= lfbptr
		ScreenRoot->Width	= lfbwidth
		ScreenRoot->Height	= lfbheight
		ScreenRoot->Left	= 0
		ScreenRoot->Top		= 0
	end if
	
	
	
	
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
	
    currentGame = game_init(screenRoot)
end sub


sub update_controller()
	dim i as integer
    
    dim k as long = GetKey
    
    
    if (k=18687) then 
        m_GameState.controller(1).vertical_movement = 1
    elseif (k=20735) then 
        m_GameState.controller(1).vertical_movement = -1
    else 
        m_GameState.controller(1).vertical_movement = 0
    end if
    
    
    if (k=19967) then 
        m_GameState.controller(1).horizontal_movement = -1
    elseif (k=19455) then 
        m_GameState.controller(1).horizontal_movement = 1
    else 
        m_GameState.controller(1).horizontal_movement = 0
    end if
    
    if (k=asc("z")) then 
        m_GameState.controller(0).vertical_movement = -1
    elseif (k=asc("s")) then 
        m_GameState.controller(0).vertical_movement = 1
    else 
        m_GameState.controller(0).vertical_movement = 0
    end if
    
    if (k=asc("q")) then
        m_GameState.controller(0).horizontal_movement = -1
    elseif (k=asc("d")) then 
        m_GameState.controller(0).horizontal_movement = 1
    else 
        m_GameState.controller(0).horizontal_movement = 0
    end if
    
    if (k=asc(" ")) then
        m_GameState.controller(0).button0 = 1
        m_GameState.controller(1).button0 = 1
    else
        m_GameState.controller(0).button0 = 0
        m_GameState.controller(1).button0 = 0
    end if
    
end sub


sub gui_update cdecl alias "gui_update"(elapsed as double)

	m_GameState.elapsed = elapsed
	
	'sys_lock_gui()
	if (currentGame<>0) then currentGame->OnUpdate(currentGame,@m_GameState)
	ScreenRoot->Invalidate(false)
	'sys_unlock_gui()
	
end sub


function gui_redraw cdecl alias "gui_redraw"() as unsigned long
	dim retval as integer = 0


	
    if (ScreenRoot->IsValid=0) then
		ScreenRoot->Clear(&h224488)
		'ScreenRoot->DrawText(@"Onyx RPI V0.1.1",10,10,&hFFFFFFFF,FontManager.SIMPAGAR,1)
		
		'sys_lock_gui()
		ScreenRoot->Draw()
		if (currentGame<>0) then currentGame->OnRedraw(currentGame,ScreenRoot)
        'sys_unlock_gui()
		
		
		
		retval = 1
	end if
	return retval
end function



declare sub loop_update(ByVal userdata As Any Ptr)
declare sub loop_updateController(ByVal userdata As Any Ptr)

ThreadCreate(@loop_update)
ThreadCreate(@loop_updateController)

do
'    Screenlock
    cls
    gui_redraw()
'    screenUnlock
loop 


sub loop_update(ByVal userdata As Any Ptr)
    
    dim secs as double = timer()
    dim newsecs as double = secs
    do
        newsecs = timer()
        dim elapsed as double = newsecs - secs
        gui_update(elapsed)
        secs = newsecs
    loop
end sub

sub loop_updateController(byval userdata as any ptr)
    do            
        update_controller()
    loop
end sub

