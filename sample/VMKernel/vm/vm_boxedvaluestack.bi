#include once "vm_boxedvalue.bi"
type VM_Stack field = 4
    Position    as integer
    declare function canPush() as boolean
    declare function canPop() as boolean
end type

type VM_BoxedValueStack extends VM_Stack field = 4
    Values(0 to 1023) as VM_BoxedValue
    Owner as any ptr
    declare sub init()
    declare destructor()
    
    declare function Last(n as integer) as VM_BoxedValue ptr
    declare sub Push(b as VM_BoxedValue ptr)
    declare sub PushNull()
    declare sub PushInteger(i as longint)
    declare sub PushBoolean(i as unsigned byte)
    declare sub PushReal(i as double)
    declare sub PushString(owner as any ptr,i as unsigned byte ptr)
    declare sub PushObj(o as any ptr)
    declare function Pop() as VM_BoxedValue ptr
end type

type VM_CallStackFrame field = 4
    IP      as unsigned long
    RegBase as unsigned long
    DestReg as VM_BoxedValue ptr
    CTX as any ptr
end type

type VM_CallStack extends VM_Stack field = 4
    Values(0 to 1023) as VM_CallStackFrame
    declare sub Init()
    declare function Last(n as integer) as VM_CallStackFrame ptr
    declare sub Push(ip as unsigned long, regbase as unsigned long,ctx as any ptr,dest as VM_BoxedValue ptr)
    declare function Pop() as VM_CallStackFrame ptr
end type



type VM_UintValueStack extends VM_Stack field = 4
    Values(0 to 1023) as Unsigned integer
    
    declare sub init()
    declare function Last(n as integer) as Unsigned integer
    declare sub Push(b as Unsigned integer)
    declare function Pop() as Unsigned integer
end type
