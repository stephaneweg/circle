#include once "textbox.bi"
Constructor TextBox(_left as integer, _top as integer,_width as integer,_height as integer)
	this.Left = _left
    this.Top  = _top
    this.SetSize(_width,_height)
    
	
    CanTakeAutoFocus = 1
    this._text=0
    this._TextBufferSize = 0
    this._TextLen       = 0
    this.MaxLen         = 255
    DestroyMethod           = cptr(any ptr,@TextBox_OnDestroy)
    DrawMethod              = cptr(any ptr,@TextBox_Redraw)
    HandleMouseMethod       = cptr(any ptr,@TextBox_HandleMouse)
    HandleKeyboardMethod   = cptr(any ptr,@TextBox_KeyPress)
    OnGotFocusMethod        = cptr(any ptr,@TextBox_GotFocus)
    OnLostFocusMethod       = cptr(any ptr,@TextBox_LostFocus)
    this.Text = @""

end Constructor

destructor TextBox()
    if (this._Text<>0) then
        deallocate this._text
    end if
end destructor

Constructor TextBlock(_left as integer, _top as integer,_width as integer,_height as integer)
    this.Left = _left
    this.Top  = _top
    this.SetSize(_width,_height)
    
    DestroyMethod   =cptr(any ptr,@TextBlock_OnDestroy)
    DrawMethod      =cptr(any ptr,@TextBlock_Redraw)
    
    this._Text= 0
    this._TextBufferSize = 0
    this._fg=&hFF000000
end Constructor

destructor TextBlock()
    if (this._Text<>0) then
        deallocate this._text
    end if
end destructor 


sub TextBox_OnDestroy(elem as TextBox ptr)
    elem->destructor()
end sub

sub TextBlock_OnDestroy(elem as TextBlock ptr)
    elem->destructor()
end sub

sub TextBlock_Redraw(txt as TextBlock ptr)
	txt->Clear(&hFFFFFFFF)
	txt->DrawText(txt->_text,3,(txt->Height-16)/2,txt->_fg,FontManager.SIMPAGAR,1)

end sub

sub TextBox_Redraw(txt as TextBox ptr)
	txt->FillRectangle(0,0,txt->Width-1,txt->Height-1,&hFFffffff)
	
	txt->DrawTextValue()
	
	if (txt->HasFocus<>0) then
		txt->DrawRectangle(0,0,txt->Width-1,txt->Height-1,&hFF33B5E5)
		txt->DrawRectangle(1,1,txt->Width-2,txt->Height-2,&hFF33B5E5)
	else
		txt->DrawRectangle(0,0,txt->Width-1,txt->Height-1,&hFFaaaaaa)
	end if
end sub

sub TextBox.DrawTextValue()
    dim ml as integer =(this.Width-8)/9
    dim toDraw as unsigned byte ptr = this._text
	
	if (this.HasFocus<>0) then
		toDraw = strCat(toDraw,@"_")
	end if
	
    dim x as integer=5
    var l=strlen(toDraw)
    if l>ml then 
        toDraw=substring(toDraw,l-ml,-1)
        l=maxlen
    end if
	
    
    dim ty as integer=(this.Height-16)/2
    DrawText(toDraw    ,x   ,ty   ,&hFF000000,FontManager.SIMPAGAR,1)
    
end sub


sub TextBox.CreateBuffer(newTextSize as integer)
    dim newLen as unsigned integer = newTextSize+1
    dim buffSize as unsigned integer = newLen shr 5
    if (buffSize shl 5) < newLen then buffSize+=1
    buffSize = buffSize shl 5
    
    
    if (buffSize>_TextBufferSize) then
        var newBuffer = allocate(buffSize)
        if (this._text<>0) then 
            strcpy(newBuffer,this._text)
            deallocate this._text
        end if
        this._text      = newBuffer
        _TextBufferSize = buffSize
    end if
end sub

property TextBox.Text(value as unsigned byte ptr)
    this._TextLen = strlen(value)
    this.CreateBuffer(this._TextLen)
    strcpy(this._text,value)
    this.Invalidate(true)
end Property

property TextBox.Text() as unsigned byte ptr
    return this._Text
end property

property TextBlock.Text(value as unsigned byte ptr)
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
    this.Invalidate(true)
end Property

property TextBlock.Text() as unsigned byte ptr
    return this._text
end property

property TextBlock.ForeColor() as unsigned integer
    return this._fg
end property

property TextBlock.ForeColor(f as unsigned integer)
    this._fg=f
    this.Invalidate(true)
end property

sub TextBox_GotFocus(obj as TextBox ptr)
    obj->Invalidate(true)
end sub

sub TextBox_LostFocus(obj as TextBox ptr)
    obj->Invalidate(true)
end sub


function TextBox_HandleMouse(txt as textbox ptr,_mx as integer,_my as integer,bleft as integer,bright as integer,bmiddle as integer,wheel as integer) as integer
    dim oldMouseOver as integer     = txt->MouseOver
    dim oldMousePressed as integer  = txt->MousePressed
      
    
    txt->MouseOver= (_mx>=0) and (_mx<txt->Width) and (_my>=0) and (_my<txt->Height)
    txt->MousePressed=txt->MouseOver and (bleft = 1)
    
    if (not txt->MousePressed) and (oldMousePressed) then
        if (txt->MouseOver) then
            if (not txt->HasFocus<>0) then
                txt->TakeFocus()
                'TextBox_GotFocus(elem)
            end if
        else
            txt->LostFocusInternal()
        end if
    end if
    return 0
end function

sub TextBox_KeyPress(txt as textbox ptr,char as unsigned byte)
    if (char=8) then
        if (txt->_TextLen>0) then
            txt->_TextLen-=1
            txt->_Text[txt->_TextLen]=0
        end if
    elseif (char=13) or (char=27) then
        txt->LostFocusInternal()
    elseif (char=9) then
        txt->LostFocusInternal()
        txt->FocusNext()
    else
        if (txt->_TextLen<txt->MaxLen) then
            txt->CreateBuffer(txt->_TextLen+1)
            txt->_Text[txt->_TextLen] = char
            txt->_TextLen = txt->_TextLen+1
            txt->_Text[txt->_TextLen] = 0
        end if
    end if
    txt->Invalidate(true)
end sub