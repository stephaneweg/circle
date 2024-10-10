#include once "vm_manager.bi"
dim shared VM_FIRST_METHOD as VM_METHOD PTR
dim shared VM_LAST_METHOD as VM_METHOD ptr

dim shared VM_FIRST_CLASS as VM_CONTEXT ptr
dim shared VM_LAST_CLASS as VM_CONTEXT ptr

sub VM_MANAGER_INIT()
     VM_FIRST_METHOD    = 0
     VM_LAST_METHOD     = 0
     VM_FIRST_CLASS     = 0
     VM_LAST_CLASS      = 0
end sub



sub VM_MANAGER_APP_START(path as unsigned byte ptr)
    var  actx = VM_Context.LoadFile(path)
    if (actx<>0) then
        var atask = new VM_Task(actx)
        atask->PushBoolean(1)
        atask->Start(actx->Entry,1)
    else
        KWrite(@"Unable to start ")
        KWriteLine(path)
    end if
end sub






function VM_MANAGER_FIND_METHOD_BY_HASH(hash as unsigned longint) as VM_METHOD ptr
    var method = VM_FIRST_METHOD
    while method<>0
        if (method->METHOD_NAME->HASH = hash) then return method
        method=method->NEXT_METHOD
    wend
    return 0
end function

function VM_MANAGER_FIND_METHOD_BY_NAME(methodName as unsigned byte ptr) as VM_METHOD ptr
    dim l as integer = strlen(methodName)
    dim mn as unsigned byte ptr = strtoupper(methodName)
    var hash = StringHash(mn,l)
    return VM_MANAGER_FIND_METHOD_BY_HASH(hash)
end function

sub VM_MANAGER_ADD_CLASS(ctx as VM_CONTEXT ptr)
    ctx->PrevContext = VM_LAST_CLASS
    ctx->NextContext = 0
    if (VM_LAST_CLASS<>0) then
        VM_LAST_CLASS->NextContext = ctx
    else 
        VM_FIRST_CLASS=ctx
    end if
    VM_FIRST_CLASS = ctx
    KWrite(@"CLASS : "):KWrite(ctx->ClassName->Buffer):KWriteLine(@" added")
end sub


sub VM_MANAGER_ADD_METHOD(method as VM_METHOD ptr)
    method->PREV_METHOD = VM_LAST_METHOD
    method->NEXT_METHOD = 0
    if (VM_LAST_METHOD<>0) then
        VM_LAST_METHOD->NEXT_METHOD = method
    else 
        VM_FIRST_METHOD=method
    end if
    VM_LAST_METHOD = method
    KWrite(@"METHOD : "):KWrite(Method->METHOD_NAME->BUFFER):KWriteLine(@" added")
end sub

sub VM_MANAGER_REGISTER_METHOD(methodName as unsigned byte ptr,target as any ptr)
    dim l as unsigned integer = strlen(methodName)
    dim mn as unsigned byte ptr = strtoupper(methodName)
    var hash = StringHash(mn,l)
    
    if (VM_MANAGER_FIND_METHOD_BY_HASH(hash)=0) then
        var mname = VM_STRING.Create(0,mn)
        var method = new VM_METHOD(mname,target,0,0)
        VM_MANAGER_ADD_METHOD(method)
    end if
    
end sub
