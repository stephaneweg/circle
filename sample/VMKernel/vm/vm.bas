
#include once "vm.bi"

#include once "vm_boxedvalue.bas"
#include once "vm_boxedvaluestack.bas"
#include once "vm_gc.bas"
#include once "vm_string.bas"
#include once "vm_table.bas"
#include once "vm_context.bas"
#include once "vm_context_gc.bas"
#include once "vm_task.bas"
#include once "vm_task_scheduler.bas"
#include once "vm_method.bas"
#include once "vm_manager.bas"


sub vm_init cdecl alias "vm_init"()
	VM_MANAGER_INIT()
    
	VM_TaskScheduler.Init()
end sub