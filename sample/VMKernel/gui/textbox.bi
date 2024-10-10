TYPE TextBox extends GUI_ELEMENT FIELD=1
    _text as unsigned byte ptr
    _TextBufferSize as unsigned integer
    _TextLen as integer
	MaxLen as unsigned integer
    MouseOver as integer
    MousePressed as integer
	
    declare constructor(_left as integer, _top as integer,_width as integer,_height as integer)
	declare destructor()
    
    
    declare sub DrawTextValue()
    declare Property Text() as unsigned byte ptr
    declare Property Text(value as unsigned byte ptr)
    declare sub CreateBuffer(newTextSize as integer)
	
end type

TYPE TextBlock extends GUI_ELEMENT FIELD=1
    _text as unsigned byte ptr
    _TextBufferSize as unsigned integer
    _fg as unsigned integer
    BorderColor as unsigned integer
    Padding as integer
    declare constructor(_left as integer, _top as integer,_width as integer,_height as integer)
	declare destructor()
    
    declare Property Text() as unsigned byte ptr
    declare Property Text(value as unsigned byte ptr)
    
    declare Property ForeColor() as unsigned integer
    declare property ForeColor(f as unsigned integer)
	
end type
declare sub TextBlock_OnDestroy(elem as TextBlock ptr)
declare sub TextBlock_Redraw(txt as TextBlock ptr)

declare sub TextBox_OnDestroy(elem as TextBox ptr)
declare sub TextBox_Redraw(txt as textbox ptr)
declare sub TextBox_Resized(txt as textbox ptr)
declare function TextBox_HandleMouse(txt as textbox ptr,_mx as integer,_my as integer,bleft as integer,bright as integer,bmiddle as integer,wheel as integer) as integer
declare sub TextBox_GotFocus(obj as TextBox ptr)
declare sub TextBox_LostFocus(obj as TextBox ptr)
declare sub TextBox_KeyPress(obj as textbox ptr,char as unsigned byte)

dim shared TextBoxTypeName as unsigned byte ptr=@"TextBox"
dim shared TextBlockTypeName as unsigned byte ptr=@"TextBlock"