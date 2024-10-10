#include once "vm_string.bi"
enum VM_ValueType
    vmNULL      = 0
    vmINT       = 1
    vmBOOL      = 2
    vmREAL      = 3
    vmSTRING    = 4
    vmTABLE     = 5
    vmOBJ       = 6
    vmFUNC      = 7
    vmGC        = 8
end enum
    
    
type VM_BoxedValue field = 4
    vValue  as unsigned longint
    vType   as unsigned byte
    declare sub PrintValue()
    
    declare sub SetBoxed(b as VM_BoxedValue ptr)
    declare sub SetNull()
    declare sub SetBoolean(i as unsigned byte)
    declare sub SetInteger(i as longint)
    declare sub SetReal(i as double)
    declare sub SetString(s as VM_String ptr)
    
    declare sub SetFunction(i as unsigned longint)
    declare sub SetPtr(t as VM_ValueType,p as any ptr)
    declare function GetPtr() as any ptr
    declare function GetBoolean() as unsigned byte
    declare function GetInteger() as longint
    declare function GetReal() as double
    declare function GetString() as unsigned byte ptr
    declare function IsNumeric() as boolean
    
    declare static sub DoAdd(owner as any ptr,vdest as VM_BoxedValue ptr,v1 as VM_BoxedValue ptr,v2 as VM_BoxedValue ptr)
    declare static sub DoSub(owner as any ptr,vdest as VM_BoxedValue ptr,v1 as VM_BoxedValue ptr,v2 as VM_BoxedValue ptr)
    declare static sub DoMul(owner as any ptr,vdest as VM_BoxedValue ptr,v1 as VM_BoxedValue ptr,v2 as VM_BoxedValue ptr)
    declare static sub DoDiv(owner as any ptr,vdest as VM_BoxedValue ptr,v1 as VM_BoxedValue ptr,v2 as VM_BoxedValue ptr)
    
    
    declare static sub DoInc(owner as any ptr,vdest as VM_BoxedValue ptr,v1 as VM_BoxedValue ptr)
    declare static sub DoDec(owner as any ptr,vdest as VM_BoxedValue ptr,v1 as VM_BoxedValue ptr)
    declare static function Equals(v1 as VM_BoxedValue ptr,other as VM_BoxedValue ptr) as boolean
    
    declare sub VISIT()
end type

