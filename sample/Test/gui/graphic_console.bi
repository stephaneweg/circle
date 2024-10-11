
TYPE GRAPHIC_CONSOLE extends GUI_ELEMENT field=1
	CursorX 		as integer
	CursorY 		as integer
	ConsoleWidth	as integer
	ConsoleHeight	as integer
	Foreground as unsigned long
	Background as unsigned long
	declare constructor()
	declare constructor(_left as integer, _top as integer,_width as integer,_height as integer)
	
	declare sub ClearConsole()
	declare sub PutChar(_b as unsigned byte)
	declare sub Write(_s as unsigned byte ptr)
	declare sub WriteLine(_s as unsigned byte ptr)
	declare sub NewLine()
	declare sub BackSpace()
	declare sub Scroll()
	declare sub PrintOK()
end type