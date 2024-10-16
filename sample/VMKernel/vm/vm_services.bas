#include once "vm_services.bi"
sub VM_SERVICES_INIT cdecl alias "vm_services_init"()
	VM_MANAGER_REGISTER_METHOD(@"StringToReal",@VM_StringToFloat)
	VM_MANAGER_REGISTER_METHOD(@"RealToString",@VM_FloatToString)
	VM_MANAGER_REGISTER_METHOD(@"math.cos",@VM_COS)
	VM_MANAGER_REGISTER_METHOD(@"math.sin",@VM_SIN)
    
    
	VM_MANAGER_REGISTER_METHOD(@"kwriteline",@VM_KWRITELINE)
	VM_MANAGER_REGISTER_METHOD(@"window.create",@VM_WINDOW_Create)
	VM_MANAGER_REGISTER_METHOD(@"button.create",@VM_BUTTON_CREATE)
	VM_MANAGER_REGISTER_METHOD(@"textbox.create",@VM_TEXTBOX_CREATE)
	VM_MANAGER_REGISTER_METHOD(@"textbloc.create",@VM_TEXTBLOC_CREATE)
	VM_MANAGER_REGISTER_METHOD(@"textbox.settext",@VM_TEXTBOX_SETTEXT)
	VM_MANAGER_REGISTER_METHOD(@"textbox.gettext",@VM_TEXTBOX_GETTEXT)
    VM_MANAGER_REGISTER_METHOD(@"image.create",@VM_IMAGE_CREATE)
    VM_MANAGER_REGISTER_METHOD(@"image.fillrectangle",@VM_IMAGE_FILLRECT)
    VM_MANAGER_REGISTER_METHOD(@"image.clear",@VM_IMAGE_CLEAR)
    VM_MANAGER_REGISTER_METHOD(@"image.flush",@VM_IMAGE_INVALIDATE)
    VM_MANAGER_REGISTER_METHOD(@"image.transparent",@VM_IMAGE_SET_TRANSPARENT)
    
    
    
    
	VM_MANAGER_REGISTER_METHOD(@"io.openfile",@VM_IO_OPEN)
	VM_MANAGER_REGISTER_METHOD(@"io.closefile",@VM_IO_CLOSE)
	VM_MANAGER_REGISTER_METHOD(@"io.flushfile",@VM_IO_FLUSH)
	VM_MANAGER_REGISTER_METHOD(@"io.eof",@VM_IO_EOF)
	VM_MANAGER_REGISTER_METHOD(@"io.lof",@VM_IO_LOF)
	VM_MANAGER_REGISTER_METHOD(@"io.readline",@VM_IO_READLINE)
	VM_MANAGER_REGISTER_METHOD(@"io.writeline",@VM_IO_WRITELINE)
    
	VM_MANAGER_REGISTER_METHOD(@"screen.getwidth",@VM_SCREEN_GETWIDTH)
	VM_MANAGER_REGISTER_METHOD(@"screen.getheight",@VM_SCREEN_GETHEIGHT)
    
    
	VM_MANAGER_REGISTER_METHOD(@"system.execute",@VM_SYSTEM_EXECUTE)
	
	
	
    VM_MANAGER_APP_START(@"SD:/apps/demo.bin")
end sub


sub VM_SYSTEM_EXECUTE(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    if (inregs[0].vType = VM_ValueType.vmSTRING) then
        var vs = cptr(VM_STRING ptr,cuint(inregs[0].vValue))
        VM_MANAGER_APP_START(strcat(@"SD:/", vs->Buffer))
    end if
end sub

sub VM_SCREEN_GETWIDTH(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    outreg->SetInteger(ScreenRoot->Width)
end sub

sub VM_SCREEN_GETHEIGHT(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    outreg->SetInteger(ScreenRoot->Height)
end sub

sub VM_IO_OPEN(ctx as VM_CONTEXT ptr,Inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    if (inregs[0].vType = VM_ValueType.vmSTRING) then
        var vs = cptr(VM_STRING ptr,cuint(inregs[0].vValue))
        var fhandle = FILE_HANDLE.OpenFile(vs->Buffer)
        
        if (fhandle<>0) then
            outreg->SetPtr(VM_ValueType.vmGC,fhandle)
            ctx->Add_GC(fhandle)
        else
            outreg->SetNull()
        end if
    end if
end sub

sub VM_IO_FLUSH(ctx as VM_CONTEXT ptr,Inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    dim handle as FILE_HANDLE PTR = inregs[0].getPtr()
    if (handle<>0) then handle->Flush()
end sub

sub VM_IO_CLOSE(ctx as VM_CONTEXT ptr,Inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    dim handle as FILE_HANDLE PTR = inregs[0].getPtr()
    if (handle<>0) then 
        handle->Save()
    end if
end sub

sub VM_IO_EOF(ctx as VM_CONTEXT ptr,Inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    dim handle as FILE_HANDLE PTR = inregs[0].getPtr()
    
    if (handle<>0) then
        dim result as integer = iif(handle->Position>=handle->FileSize,1,0)
        outreg->SetInteger(result)
    end if
end sub

sub VM_IO_LOF(ctx as VM_CONTEXT ptr,Inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    dim handle as FILE_HANDLE PTR = inregs[0].getPtr()
    if (handle<>0) then
        outreg->SetInteger(handle->FileSize)
    end if
end sub

sub VM_IO_READLINE(ctx as VM_CONTEXT ptr,Inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    dim handle as FILE_HANDLE PTR = inregs[0].getPtr()
    var l = handle->ReadLine()
    var vs = VM_STRING.Create(ctx, l)
    deallocate l
    outreg->SetString(vs)
end sub

sub VM_IO_WRITELINE(ctx as VM_CONTEXT ptr,Inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    dim handle as FILE_HANDLE PTR = inregs[0].getPtr()
    if (inregs[1].vType = VM_ValueType.vmSTRING) then
        var s = inregs[1].getString()
        
        handle->WriteLine(s)
    end if
    
end sub


sub VM_ButtonClick(btn as GUI_BUTTON ptr)
	if (btn->VMCtx<>0) then
		if (btn->VMClick<>0) then
			dim btnctx as VM_Context ptr = btn->VMCtx
			var task = new VM_TASK(btnctx)
			task->PushBoxed(@btn->VMTAG)
			task->Start(btn->VMClick,1)
		end if
	end if
end sub

sub VM_ELEMENT_ADD(ctx as VM_Context ptr, parent as GUI_ELEMENT ptr,child as GUI_ELEMENT ptr)
    GUI_LOCK()
    if (parent<>0 and parent<>ScreenRoot) then
    
        child->Left   += parent->PaddingLeft
        child->Top    += parent->PaddingTop
        parent->AddChild(child)
            
    else
        ScreenRoot->AddChild(child)

    end if
    ctx->Add_GC(child)
    GUI_UNLOCK()
end sub
        




sub VM_KWRITELINE(ctx as VM_CONTEXT ptr,Inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    if (inregs[0].vType = VM_ValueType.vmSTRING) then
        var vs = cptr(VM_STRING ptr,cuint(inregs[0].vValue))
        KWriteLine(vs->BUFFER)
        
        outreg->SetInteger(65)
    end if
    
end sub


sub VM_COS(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
   outreg->SetReal(cos(inregs[0].GetReal()))
end sub

sub VM_SIN(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    outreg->SetReal(sin(inregs[0].GetReal()))
end sub

sub VM_StringToFloat(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    var s = inregs[0].getString()
    outreg->SetReal(atof(s))
end sub

sub VM_FloatToString(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
	var d = inregs[0].GetReal()
    var vs = VM_STRING.Create(ctx,DoubleToStr(d))
    outreg->SetString(vs)
end sub

sub VM_IMAGE_INVALIDATE(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    dim img as GUI_ELEMENT PTR = inregs[0].GetPtr()
    img->Invalidate(1)
end sub

sub VM_IMAGE_CREATE(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    dim parent as GUI_ELEMENT PTR = inregs[0].GetPtr()
    
	dim x as integer = inregs[1].getInteger()
	dim y as integer = inregs[2].getInteger()
	dim w as integer = inregs[3].getInteger()
	dim h as integer = inregs[4].getInteger()
    
    var img = new GUI_ELEMENT(x,y,w,h)
    VM_ELEMENT_ADD(ctx,parent,img)
    outreg->SetPtr(VM_ValueType.vmGC,img)
end sub

sub VM_IMAGE_FILLRECT(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    dim img as GUI_ELEMENT PTR = inregs[0].GetPtr()
    dim x as integer = inregs[1].getInteger()
	dim y as integer = inregs[2].getInteger()
	dim w as integer = inregs[3].getInteger()
	dim h as integer = inregs[4].getInteger()
	dim c as unsigned long = cast(unsigned long , inregs[5].getInteger())
    
    img->FILLRectangle(x,y,x+w-1,y+h-1,c)
end sub

sub VM_IMAGE_CLEAR(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    dim img as GUI_ELEMENT PTR = inregs[0].GetPtr()
    dim c as unsigned long =cast(unsigned long, inregs[1].getInteger)
    
    img->Clear(c)
end sub
    
sub VM_IMAGE_SET_TRANSPARENT(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    dim img as GUI_ELEMENT PTR = inregs[0].GetPtr()
    img->Transparent = inregs[1].getInteger()
end sub

sub VM_BUTTON_CREATE(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
	dim parent as GUI_ELEMENT PTR = inregs[0].GetPtr()
    
	dim x as integer    = inregs[1].getInteger()
	dim y as integer    = inregs[2].getInteger()
	dim w as integer    = inregs[3].getInteger()
	dim h as integer    = inregs[4].getInteger()
	dim vmTarget as integer = inregs[7].getInteger()
	var btn = new GUI_BUTTON(x,y,w,h)
	btn->VMClick = vmTarget
	btn->VMCtx = ctx
	btn->OnClick = cptr(any ptr,@VM_ButtonClick)
    btn->VMTAG.SetBoxed(@inregs[6])
    if (inregs[5].vType = VM_ValueType.vmSTRING) then
        dim t as unsigned byte ptr = inregs[5].getString()
        btn->Text = t
    end if
    
    VM_ELEMENT_ADD(ctx,parent,btn)
    outreg->SetPtr(VM_ValueType.vmGC,btn)
end sub
	
sub VM_TEXTBOX_CREATE(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
	dim parent as GUI_ELEMENT PTR = inregs[0].GetPtr()
    
    dim x as integer = inregs[1].getInteger()
	dim y as integer = inregs[2].getInteger()
    
	dim w as integer = inregs[3].getInteger()
	dim h as integer = inregs[4].getInteger()
	dim tag as integer = inregs[6].getInteger()
	dim vmTarget as integer = inregs[7].getInteger()
    var txtb = new TextBox(x,y,w,h)
    
    if (inregs[5].vType = VM_ValueType.vmSTRING) then
        dim t as unsigned byte ptr = inregs[5].getString()
        txtb->Text = t
    end if
    
    VM_ELEMENT_ADD(ctx,parent,txtb)
    
    outreg->SetPtr(VM_ValueType.vmGC,txtb)
end sub
	
sub VM_TEXTBLOC_CREATE(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
	dim parent as GUI_ELEMENT PTR = inregs[0].GetPtr()
    
    dim x as integer = inregs[1].getInteger()
	dim y as integer = inregs[2].getInteger()
    
	dim w as integer = inregs[3].getInteger()
	dim h as integer = inregs[4].getInteger()
	dim tag as integer = inregs[6].getInteger()
	dim vmTarget as integer = inregs[7].getInteger()
	var txtb = new TextBlock(x,y,w,h)
	
    if (inregs[5].vType = VM_ValueType.vmSTRING) then
        dim t as unsigned byte ptr = inregs[5].getString()
        txtb->Text = t
    end if
    VM_ELEMENT_ADD(ctx,parent,txtb)
    outreg->SetPtr(VM_ValueType.vmGC,txtb)
end sub


sub VM_TEXTBOX_SETTEXT(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    dim tb as TextBox PTR = inregs[0].GetPtr()
    
    
    if (inregs[1].vType = VM_ValueType.vmSTRING) then
        dim txt as unsigned byte ptr = inregs[1].getString()
        tb->Text = txt
    end if
    
end sub

sub VM_TEXTBOX_GETTEXT(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
    dim tb as TextBox PTR = inregs[0].GetPtr()
	var vs = VM_STRING.Create(ctx,tb->Text)
    outreg->SetString(vs)
end sub

sub VM_WINDOW_Create(ctx as VM_CONTEXT ptr,Inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
	dim w as integer = inregs[0].getInteger() + WindowSkin->leftWidth+WindowSkin->rightWidth
	dim h as integer = inregs[1].getInteger() + WindowSkin->topHeight+WindowSkin->BottomHeight
	dim t as unsigned byte ptr = inregs[2].getString()
	
	var x = get_random(0,ScreenRoot->Width-w)
	var y = get_random(0,ScreenRoot->Height-h)
    
    
	var win = new GUI_WINDOW(x,y,w,h,t,inregs[3].getInteger())
	win->VMCTX = ctx
    
    VM_ELEMENT_ADD(ctx,ScreenRoot,win)
    if (win->CloseButton<>0) then
        ctx->Add_GC(win->CloseButton)
    end if
    
    outreg->SetPtr(VM_ValueType.vmGC,win)
end sub