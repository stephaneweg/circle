#include once "vm_gc.bi"
type VM_STRING extends VM_GC field = 8
    STRINGLEN   as unsigned integer
    BUFFER      as unsigned byte ptr
    HASH        as unsigned longint
    ADDEDSTRING as unsigned integer
    PrevString  as VM_String ptr
    NextString  as VM_String ptr
    
    declare static function Create(ctx as any ptr,b as unsigned byte ptr) as VM_STRING ptr
    declare constructor(ctx as any ptr,b as unsigned byte ptr)
    declare constructor(ctx as any ptr,b as unsigned byte ptr,slen as unsigned integer,h as unsigned longint)
    declare destructor()
    declare function CompareTo(other as VM_STRING ptr) as integer
    declare function Equals(other as VM_String ptr) as integer
end type    
#define VM_STRING_MAGIC       &h9876
declare sub DestroyVMString(s as VM_String ptr)