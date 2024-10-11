constructor GUI_BUTTON()
	this.constructor(0,0,0,0)
end constructor

constructor GUI_BUTTON(_left as integer, _top as integer,_width as integer,_height as integer)
	this.Left = _left
    this.Top  = _top
    this.SetSize(_width,_height)
    this.Transparent = 1
    MouseOver		= 0
	MousePressed	= 0
	OnClick			= 0
	Tag				= 0
	'VMClick			= 0
	'VMCTX			= 0
    this._Text      = 0
    this._TextBufferSize = 0
    'VMTAG.vType     = 0
    'VMTAG.vValue    = 0
    Skin            = ButtonSKin
    DestroyMethod       = cptr(any ptr,@GUI_BUTTON_DESTROY)
	DrawMethod			= cptr(any ptr,@GUI_BUTTON_DRAW)
	HandleMouseMethod	= cptr(any ptr,@GUI_BUTTON_HANDLE_MOUSE)
end constructor

destructor GUI_BUTTON()
kwriteline(@"Delete button")
    if (this._Text<>0) then
        deallocate this._Text
    end if
end destructor


property GUI_BUTTON.Text(value as unsigned byte ptr)
    dim newLen as unsigned integer = strlen(value)+1
    dim buffSize as unsigned integer = newLen shr 5
    if (buffSize shl 5) < newLen then buffSize+=1
    buffSize = buffSize shl 5
    dim newBuffer as unsigned byte ptr = this._text
    
    if (buffSize>_TextBufferSize) then
        if (this._text<>0) then deallocate this._text
        this._text = allocate(buffSize)
        _TextBufferSize = buffSize
    end if
    strcpy(this._text,value)
    _TextLen = strlen(this._Text)
    this.Invalidate(true)
end Property

property GUI_BUTTON.Text() as unsigned byte ptr
    return this._Text
end property

sub GUI_BUTTON_DESTROY(btn as GUI_BUTTON ptr)
    btn->destructor()
end sub

sub GUI_BUTTON_DRAW(btn as GUI_BUTTON ptr)
    
    
    if (btn->Skin<>0) then
        var idx = 0
        if (btn->MouseOver=1) then
            idx=1
            if (btn->MousePressed=1) then
                idx=2
            end if
        end if
        btn->Clear(&hFF00FF)
        btn->Skin->DrawOn(btn,idx,0,0,btn->Width,btn->Height,0)
    else
        
        dim c1 as unsigned long = &haaaaaa
        dim c2 as unsigned long = &heeeeee
        dim c3 as unsigned long = &h666666
        
        if (btn->MouseOver=1) then 
            if btn->MousePressed=1 then
                dim cx as unsigned long = c2
                c2 = c3
                c3 = cx
            else
                c1 = &hbbbbbb
            end if
        end if
        
        btn->Clear(c1)
        btn->DrawRectangle(0,0,btn->Width-1,btn->Height-1,&h000000)
        
        btn->DrawLine(1,1,btn->Width-2,1,c2)
        btn->DrawLIne(1,1,1,btn->Height-2,c2)
        btn->DrawLine(1,btn->Height-2,btn->Width-2,btn->Height-2,c3)
        btn->DrawLine(btn->Width-2,1,btn->Width-2,btn->Height-2,c3)
        end if
    
    dim tx as integer = (btn->Width - (btn->_TextLen*8))/2
    dim ty as integer = (btn->Height-16)/2
    
    if (btn->_Text<>0) then
        btn->DrawText(btn->_Text    ,tx   ,ty   ,&hFF000000,FontManager.SIMPAGAR,1)
    end if
end sub

function GUI_BUTTON_HANDLE_MOUSE(btn as GUI_BUTTON ptr,mx as integer,my as integer,bleft as integer,bright as integer,bmiddle as integer,wheel as integer) as integer
	dim oldOver 	as integer = btn->MouseOver	
	dim oldPressed as integer = btn->MousePressed
    if (bleft=1) and (btn->HasFocus=0) then btn->TakeFocus()
	if (mx>=0 and my>=0 and mx<btn->Width and my<btn->Height) then
		btn->MouseOver		= 1
		btn->MousePressed	= bleft
	else
		btn->MouseOver 		= 0
		btn->MousePressed	= 0
	end if
	
	if (oldOver<>btn->MouseOver or oldPressed<>btn->MousePressed) then
		btn->Invalidate(true)
		
		if (oldOver=1 and oldPressed=1 and btn->MouseOver=1 and btn->MousePressed=0) then
			if (btn->OnClick<>0) then btn->OnClick(btn)
		end if
	end if
	return btn->MouseOver
end function