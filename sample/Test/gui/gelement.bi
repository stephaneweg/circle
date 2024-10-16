type GUI_ELEMENT extends GIMAGE field=1
	Left        as double
	Top         as double
    Transparent as integer
	ParentNode	as GUI_ELEMENT ptr
	FirstNode	as GUI_ELEMENT ptr
	LastNode	as GUI_ELEMENT ptr
	PrevNode	as GUI_ELEMENT ptr
	NextNode	as GUI_ELEMENT ptr
	PrevHandled as GUI_ELEMENT ptr
    PaddingLeft as integer
    PaddingTop  as integer
	IsValid		as integer
    ShouldRedraw as integer
	CatchMouseOutsideBounds	as integer
    CanTakeAutoFocus as integer
    HasFocus as integer
	VMCTX			as any ptr
    
    OnGotFocusMethod as sub(elem as GUI_ELEMENT ptr)
	OnLostFocusMethod as sub(elem as GUI_ELEMENT ptr)
    
	DrawMethod as sub(elem as GUI_ELEMENT ptr)
	HandleMouseMethod as function(elem as GUI_ELEMENT ptr,mx as integer,my as integer,bleft as integer,bright as integer,bmiddle as integer,wheel as integer) as integer
	HandleKeyboardMethod as function(elem as GUI_ELEMENT ptr,c as unsigned byte) as integer
	declare sub BringToFront()
	declare sub AddChild(child as GUI_ELEMENT ptr)
	declare sub RemoveChild(child as GUI_ELEMENT ptr)
	declare sub Invalidate(_shouldRedraw as boolean)
	declare sub Draw()
	declare function HandleMouse(mx as integer,my as integer,bleft as integer,bright as integer,bmiddle as integer,wheel as integer) as integer
	declare function HandleKeyboard(c as unsigned byte) as integer
    
	declare constructor()
	declare constructor(l as integer,t as integer,w as integer,h as integer)
    declare destructor()
    
    declare sub TakeFocus()
	declare sub TakeFocusInternal()
	declare sub LostFocusInternal()
	declare sub FocusNext()
end type

declare sub GUI_ELEMENT_VISIT(g as GUI_ELEMENT ptr)
declare sub GUI_ELEMENT_DESTROY(g as GUI_ELEMENT ptr)