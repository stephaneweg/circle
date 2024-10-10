#include once "vm_boxedvaluestack.bi"


function VM_Stack.CanPush() as boolean
    return this.Position<1024
end function

function VM_Stack.CanPop() as boolean
    return this.Position>0
end function

sub VM_BoxedValueStack.Init()
    this.Position       = 0
    this.Owner          = 0
    for i as integer = 0 to 1023
        this.Values(i).vType = VM_ValueType.vmNULL
        this.Values(i).vValue = 0
    next i
end sub

destructor VM_BoxedValueStack()
    for i as integer = 0 to 1023
        this.Values(i).SetNull()
    next i
end destructor


sub VM_BoxedValueStack.PushObj(o as any ptr)
    if (this.CanPush()) then
        this.Values(this.Position).SetPtr(VM_ValueType.VmObj,o)
        this.Position+=1
    end if
end sub

sub VM_BoxedValueStack.Push(b as VM_BoxedValue ptr)
    if (b<>0) then
        if (this.CanPush()) then
            this.Values(this.Position).SetBoxed(b)
            this.Position+=1
        end if
    end if
end sub

sub VM_BoxedValueStack.PushInteger(i as longint)
        if (this.CanPush()) then
            this.Values(this.Position).SetInteger(i)
            this.Position+=1
        end if
end sub

sub VM_BoxedValueStack.PushBoolean(i as unsigned byte)
        if (this.CanPush()) then
            this.Values(this.Position).SetBoolean(i)
            this.Position+=1
        end if
end sub

sub VM_BoxedValueStack.PushReal(i as double)
    if (this.CanPush()) then
        this.Values(this.Position).SetReal(i)
        this.Position+=1
    end if
end sub

sub VM_BoxedValueStack.PushString(owner as any ptr,s as unsigned byte ptr)
    if (this.CanPush()) then
        var vs = VM_STRING.Create(owner,s)
        this.Values(this.Position).SetString(vs)
        this.Position+=1
    end if
end sub

sub VM_BoxedValueStack.PushNull()
    if (this.CanPush()) then
        this.Values(this.Position).SetNull()
        this.Position+=1
    end if
end sub

function VM_BoxedValueStack.Pop() as VM_BoxedValue ptr
    if (this.CanPop()) then
        this.Values(this.Position).SetNull()
        this.Position-=1
        return @this.Values(this.Position)
    end if
    return 0
end function

function VM_BoxedValueStack.Last(n as integer) as VM_BoxedValue ptr
    if (this.Position>n) then
        return @this.Values(this.Position-(1+n))
    end if
    return 0
end function


sub VM_CallStack.Init()
    this.Position = 0
    for i as integer = 0 to 1023
        this.Values(i).IP = 0
        this.Values(i).Ctx = 0
        this.Values(i).RegBase = 0
    next
end sub

function VM_CallStack.Last(n as integer) as VM_CallStackFrame ptr
    if (this.Position>n) then
        return @this.Values(this.Position-(1+n))
    end if
    return 0
end function

sub VM_CallStack.Push(ip as unsigned long, regbase as unsigned long,ctx as any ptr,dest as VM_BoxedValue ptr)
    if (this.CanPush()) then
        this.Values(this.Position).IP       = ip
        this.Values(this.Position).CTX      = ctx
        this.Values(this.Position).RegBase  = regbase
        this.Values(this.Position).DestReg  = dest
        this.Position+=1
    end if
end sub

function VM_CallStack.Pop() as VM_CallStackFrame ptr
    if (this.CanPop()) then
        this.Position-=1
        return @this.Values(this.Position)
    end if
    return 0    
end function

sub VM_UintValueStack.Init()
    this.Position       = 0
    for i as integer = 0 to 1023
        this.Values(i) = 0
    next i
end sub

sub VM_UintValueStack.Push(b  as unsigned integer)
    if (this.CanPush()) then
        this.Values(this.Position) = b
        this.Position+=1
    end if
end sub

function VM_UintValueStack.Pop() as unsigned integer
    if (this.CanPop()) then
        this.Position-=1
        return this.Values(this.Position)
    end if
    return 0
end function

function VM_UintValueStack.Last(n as integer) as unsigned integer
    if (this.Position>n) then
        return this.Values(this.Position-(1+n))
    end if
    return 0
end function
