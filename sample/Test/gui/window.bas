
constructor GUI_WINDOW()
	this.constructor(0,0,0,0,0,0)
end constructor

constructor GUI_WINDOW(l as integer,t as integer,w as integer,h as integer,_title as unsigned byte ptr,addCloseBtn as integer)
	CatchMouseOutsideBounds = 1
	if (_title<>0) then
		Title = allocate(strlen(_title)+1)
		strcpy(Title,_title)
	else
		Title = 0
	end if
	Draging	= 0
	DragStartX = 0
	DragStartY = 0
	DrawMethod			= cptr(any ptr,@GUI_WINDOW_DRAW)
	HandleMouseMethod	= cptr(any ptr,@GUI_WINDOW_HANDLE_MOUSE)
	DestroyMethod		= cptr(any ptr,@GUI_WINDOW_DESTROY)
    CloseButton          = 0
    if (WindowSkin<>0) then
        PaddingLeft = WindowSkin->LeftWidth
        PaddingTop  = WindowSkin->TopHeight
    end if
    
    this.Left = l
    this.Top  = t
    this.SetSize(w,h)
    
    if (addCloseBtn=1) then
        CloseButton = new GUI_BUTTON(w-30,5,24,24)
        CloseButton->OnClick = @GUI_WINDOW_CLOSEBTN_CLICKED
        CloseButton->Skin = WindowCloseButtonSkin
        AddChild(CloseButton)
    end if
end constructor

destructor GUI_WINDOW()
	if Title<>0 then
		deallocate(Title)
		Title = 0
	end if
end destructor 

sub GUI_WINDOW_CLOSEBTN_CLICKED(btn as GUI_BUTTON ptr)
    if (btn->ParentNode<>0) then
        btn->ParentNode->ParentNode->RemoveChild(btn->ParentNode)
        if (btn->ParentNode->VMCTX<>0) then
            'VM_ENDAPP(btn->ParentNode->VMCTX)
        end if
    end if
end sub

sub GUI_WINDOW_DESTROY(win as GUI_WINDOW ptr)
	win->destructor()
end sub

sub GUI_WINDOW_DRAW(win as GUI_WINDOW ptr)
    dim x1 as integer = 0
	dim y1 as integer = 0
	dim x2 as integer = x1+win->Width-1
	dim y2 as integer = y1+win->Height-1
	if (WindowSkin<>0) then
		WindowSkin->DrawOn(win,0,0,0,win->Width,win->Height,0)
	else
		win->Clear(&hFFFFFF)
		win->DrawRectangle(x1,y1,x2,y2,&h000000)
		win->DrawRectangle(x1+5,y1+35,x2-5,y2-5,&h000000)
	end if
	if (win->Title<>0) then
		win->DrawText(win->Title,7,8+(24-FontManager.ML->FontHeight)/2,&hFFFFFFFF,FontManager.ML,1)
	end if
end sub

function GUI_WINDOW_HANDLE_MOUSE(win as GUI_WINDOW ptr,mx as integer,my as integer,bleft as integer,bright as integer,bmiddle as integer,wheel as integer) as integer
	dim x1 as integer = 0
	dim y1 as integer = 0
	dim x2 as integer = x1+win->Width-1
	dim y2 as integer = y1+35
	
	if (bleft) then
		if (win->Draging=0) then		
			if (mx>=x1 and my>=y1 and mx<x2 and my<y2) then
				win->DragStartX	= mx
				win->DragStartY	= my
				win->Draging = 1
				
				win->BringToFront()
					
			end if
		end if
		if (win->Draging) then 
			win->Left		+= mx-win->DragStartX
			win->Top		+= my-win->DragStartY
			win->Invalidate(false)
		end if
		
		
	else
		win->Draging=0
	end if
	return win->Draging
end function

