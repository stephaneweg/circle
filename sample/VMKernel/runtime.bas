#include once "shared/stdlib.bi"
#include once "shared/arch.bi"
#include once "vm/vm.bi"
#include once "gui/gui.bi"
#include once "shared/file_handle.bi"


function KbdToKbd(c as unsigned byte) as unsigned byte
	dim cc as unsigned byte  = c
	if cc = 10 then cc = 13
	return c
end function

#include once "shared/stdlib.bas"
#include once "shared/arch.bas"
#include once "shared/file_handle.bas"
#include once "gui/gui.bas"
#include once "vm/vm.bas"
#include once "vm/vm_services.bas"