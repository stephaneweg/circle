#include once "graphic_console.bi"


constructor GRAPHIC_CONSOLE()
	this.constructor(0,0,0,0)
	

end constructor

constructor GRAPHIC_CONSOLE(_left as integer, _top as integer,_width as integer,_height as integer)
	this.Left = _left
    this.Top  = _top
    this.SetSize(_width,_height)
    
	DrawMethod			= 0
	HandleMouseMethod	= 0
	this.CursorX 		= 0
	this.CursorY		= 0
	this.Foreground		= &hFFFFFFFF
	this.Background		= &hFF000000
	this.ConsoleWidth	= floor(_width/8)
	this.ConsoleHeight	= floor(_height/16)
	this.ClearConsole()
	if (_width>0 and _height>0) then this.WriteLine(@"Console Ready")
end constructor


sub GRAPHIC_CONSOLE.ClearConsole()
	this.Clear(this.Background)
	this.CursorX	= 0
	this.CursorY	= 0
	this.Invalidate(true)
end sub

sub GRAPHIC_CONSOLE.PrintOK()
	this.DrawChar(asc("["),(this.ConsoleWidth-7)*8,this.CursorY*16,&h0000FF,FontManager.SIMPAGAR,1)
	this.DrawChar(asc("O"),(this.ConsoleWidth-5)*8,this.CursorY*16,&h00FF00,FontManager.SIMPAGAR,1)
	this.DrawChar(asc("K"),(this.ConsoleWidth-4)*8,this.CursorY*16,&h00FF00,FontManager.SIMPAGAR,1)
	this.DrawChar(asc("]"),(this.ConsoleWidth-2)*8,this.CursorY*16,&h0000FF,FontManager.SIMPAGAR,1)
end sub

sub GRAPHIC_CONSOLE.PutChar(_b as unsigned byte)
	if (_b)=13 then exit sub
	if (_b=10) then
		this.NewLine()
		exit sub
	end if
	if (_b=8) then
		this.BackSpace()
	end if
	if (_b=9) then
		CursorX += 5-(CursorX mod 5)
		if (CursorX>=ConsoleWidth) then NewLine()
	else
		this.DrawChar(_b,CursorX*8,CursorY*16,Foreground,FontManager.SIMPAGAR,1)
		CursorX+=1
	end if
	
	if (CursorX>=ConsoleWidth) then
		NewLine()
	end if
end sub

sub GRAPHIC_CONSOLE.Write(_s as unsigned byte ptr)
	dim cpt as unsigned integer
	while _s[cpt]<>0
		PutChar(_s[cpt])
		cpt+=1
	wend
end sub

sub GRAPHIC_CONSOLE.WriteLine(_s as unsigned byte ptr)
	Write(_s)
	NewLine()
end sub

sub GRAPHIC_CONSOLE.NewLine()
    CursorX=0
    CursorY+=1
    if (CursorY>=ConsoleHeight) then Scroll()
end sub

sub GRAPHIC_CONSOLE.Scroll()
   
	dim dst_start as unsigned integer		= cuint(this.BUFFER)
	dim row_size as unsigned integer		= this.WIDTH*FontManager.SIMPAGAR->FontHeight*4
	dim count_to_copy as unsigned integer	= (this.ConsoleHeight-1)*row_size 
	dim dst_end as unsigned integer			= dst_start+count_to_copy
    
    'print count_to_copy
    'print this.BufferSize
    
    'sleep
	
    if (this.Buffer<>0) then
        if (count_to_copy>0) then
            MemCpyARCH(this.BUFFER,cptr(unsigned byte ptr,dst_start+row_size),count_to_copy )
            MemSet32(cptr(unsigned long ptr,dst_end),this.Background,row_size shr 2)
        end if
    end if
    CursorY-=1
end sub

sub GRAPHIC_CONSOLE.BackSpace()
end sub



