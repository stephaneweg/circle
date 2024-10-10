#include once "vm_boxedvalue.bi"
#include once "vm_gc.bi"
TYPE VM_Context    
    GlobalVars          as VM_BoxedValue ptr
    ConstTable          as unsigned longint ptr 
    Entry               as unsigned long
    Memory              as unsigned byte ptr
    MemorySize          as unsigned long
    GlobalVarCount      as unsigned integer
    
    FieldsCount         as unsigned integer
    ClassName           as VM_STRING ptr
    Fields              as VM_STRING ptr
    
    PrevContext         as VM_Context ptr
    NextContext         as VM_Context ptr
    
    
    
    VM_First_GC         as VM_GC ptr
    VM_Last_GC          as VM_GC ptr

    VM_FIRST_STRING     as VM_STRING ptr
    VM_Last_STRING      as VM_STRING ptr
    VM_GC_COUNT         as integer
    VM_STRING_COUNT     as integer

    
    FirstTask as any ptr
    LastTask as any ptr
    declare sub AddTask(t as any ptr)
    declare sub RemoveTask(t as any ptr)
    
    declare static function LoadFile(path  as unsigned byte ptr) as VM_Context ptr
    
    declare constructor()
    declare destructor()
    
    
    declare sub         ShowRefs()
    declare function    GET_FIRST_STRING() as VM_STRING ptr
    declare function    FIND_STRING(item as VM_STRING ptr) as VM_STRING PTR
    declare function    ADD_STRING(item as VM_String ptr) as integer
    declare function    REMOVE_String(item as VM_String ptr) as integer
    declare function    Add_GC(item as VM_GC ptr) as integer
    declare function    Remove_GC(item as VM_GC ptr) as integer
    declare sub         Collect_GC(gc as VM_GC ptr)
    declare sub         Collect()
    declare sub         VISIT(v as VM_BoxedValue ptr)
end Type