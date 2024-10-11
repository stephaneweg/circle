type GUI_WINDOW extends GUI_ELEMENT field=1
	Title as unsigned byte ptr
	Draging as integer
	DragStartX as integer
	DragStartY as integer
    CloseButton as GUI_BUTTON ptr
	declare constructor()
	declare constructor(l as integer,t as integer,w as integer,h as integer,_title as unsigned byte ptr,addCloseBtn as integer)
	declare destructor()
end type

declare sub GUI_WINDOW_CLOSEBTN_CLICKED(btn as GUI_BUTTON ptr)
declare sub GUI_WINDOW_DESTROY(win as GUI_WINDOW ptr)
declare sub GUI_WINDOW_DRAW(win as GUI_WINDOW ptr)
declare function GUI_WINDOW_HANDLE_MOUSE(win as GUI_WINDOW ptr,mx as integer,my as integer,bleft as integer,bright as integer,bmiddle as integer,wheel as integer) as integer
