#include once "vm_task.bi"
constructor VM_TASK(ctx as VM_Context ptr)
    MainStack.Init()
    CallStack.Init()
    RegBase         = 0
    IP              = 0
    CurrentContext  = ctx
    StartContext    = ctx
    
    NextTaskQueue = 0
    PrevTaskQueue = 0
    
    NextTaskContext = 0
    PrevTaskContext = 0
    Terminated      = false
    ctx->AddTask(@this)
end constructor

destructor VM_TASK()
    'KWriteLine @"destruct vm task"
    'VM_MANAGER_ShowRefs()
end destructor

function VM_TASK.Regs(n as integer) as VM_BoxedValue ptr
    return @(MainStack.Values(RegBase+n))
end function
    

sub VM_TASK.PushNull()
    MainStack.PushNull()
end sub

sub VM_TASK.PushBoxed(b as VM_BoxedValue ptr)
    MainStack.Push(b)
end sub

sub VM_TASK.PushBoolean(i as unsigned byte)
    MainStack.PushBoolean(i)
end sub

sub VM_TASK.PushInteger(i as longint)
    MainStack.PushInteger(i)
end sub

sub VM_TASK.PushReal(i as double)
    MainStack.PushReal(i)
end sub

sub VM_TASK.PushString( i as unsigned byte ptr)
    MainStack.PushString(this.StartContext,i)
end sub

sub VM_TASK.PushObj(c as any ptr)
    MainStack.PushObj(c)
end sub

sub VM_Task.Start(entry as unsigned longint,parameterCount as unsigned integer)
    IP              = entry
    RegBase         = MainStack.Position - parameterCount
    VM_AddTask(@this)
end sub



