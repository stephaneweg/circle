#include once "gui/gui.bi"



type Application field = 1
	OnUpdate as sub(g as Application ptr,state as GameState ptr)
	OnRedraw as sub(g as Application ptr,root as GUI_Element ptr)
	OnExit	 as sub(g as Application ptr)
end type