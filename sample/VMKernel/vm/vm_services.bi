
declare sub VM_SERVICES_INIT cdecl alias "vm_services_init"()
declare sub VM_ButtonClick(btn as GUI_BUTTON ptr)
declare sub VM_ELEMENT_ADD(ctx as VM_Context ptr, parent as GUI_ELEMENT ptr,child as GUI_ELEMENT ptr)

declare sub VM_KWRITELINE(ctx as VM_CONTEXT ptr,Inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_SYSTEM_EXECUTE(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)

declare sub VM_StringToFloat(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_FloatToString(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_COS(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_SIN(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
	

declare sub VM_SCREEN_GETWIDTH(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_SCREEN_GETHEIGHT(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)

declare sub VM_IMAGE_CREATE(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_IMAGE_FILLRECT(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_IMAGE_CLEAR(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_IMAGE_SET_TRANSPARENT(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_IMAGE_INVALIDATE(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)

declare sub VM_BUTTON_CREATE(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_TEXTBOX_CREATE(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_TEXTBLOC_CREATE(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_TEXTBOX_SETTEXT(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_TEXTBOX_GETTEXT(ctx as VM_Context ptr,inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_WINDOW_Create(ctx as VM_CONTEXT ptr,Inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)



declare sub VM_IO_FLUSH(ctx as VM_CONTEXT ptr,Inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_IO_OPEN(ctx as VM_CONTEXT ptr,Inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_IO_CLOSE(ctx as VM_CONTEXT ptr,Inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_IO_EOF(ctx as VM_CONTEXT ptr,Inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_IO_LOF(ctx as VM_CONTEXT ptr,Inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_IO_READLINE(ctx as VM_CONTEXT ptr,Inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)
declare sub VM_IO_WRITELINE(ctx as VM_CONTEXT ptr,Inregs as VM_BOXEDVALUE ptr,outreg as VM_BOXEDVALUE ptr)