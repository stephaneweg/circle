#include once "vm_boxedvalue.bi"
type VM_TASK field = 4
    MainStack           as VM_BoxedValueStack
    CallStack           as VM_CallStack
    IP                  as unsigned longint
    RegBase             as unsigned integer
    CurrentContext      as VM_Context ptr
    StartContext        as VM_Context ptr
    Terminated          as boolean
    
    NextTaskQueue    as VM_Task ptr
    PrevTaskQueue    as VM_Task ptr
    
    NextTaskContext    as VM_Task ptr
    PrevTaskContext    as VM_Task ptr
    
    declare constructor(ctx as VM_Context ptr)
    
    declare sub PushNull()
    declare sub PushBoxed(b as VM_BoxedValue ptr)
    declare sub PushBoolean(i as unsigned byte)
    declare sub PushInteger(i as longint)
    declare sub PushReal(i as double)
    declare sub PushString(i as unsigned byte ptr)
    declare sub PushObj(c as any ptr)

    declare sub Start(entry as unsigned longint,parameterCount as unsigned integer)
    declare function Regs(n as integer) as VM_BoxedValue ptr
    
    declare destructor()
end type