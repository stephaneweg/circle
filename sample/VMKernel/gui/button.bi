type GUI_BUTTON extends GUI_ELEMENT field=1
	MouseOver		as integer
	MousePressed	as integer
	Tag				as integer
	VMClick			as integer
    VMTAG           as VM_BOXEDVALUE
    _text           as unsigned byte ptr
    _TextBufferSize as unsigned integer
    _TextLen        as integer
	OnClick			as sub(btn as GUI_BUTTON ptr)
    Skin            as Skin ptr
	declare constructor()
	declare constructor(_left as integer, _top as integer,_width as integer,_height as integer)
    declare destructor()
    
    declare Property Text() as unsigned byte ptr
    declare Property Text(value as unsigned byte ptr)
end type
declare sub GUI_BUTTON_DESTROY(btn as GUI_BUTTON ptr)
declare sub GUI_BUTTON_DRAW(btn as GUI_BUTTON ptr)
declare function GUI_BUTTON_HANDLE_MOUSE(win as GUI_BUTTON ptr,mx as integer,my as integer,bleft as integer,bright as integer,bmiddle as integer,wheel as integer) as integer
