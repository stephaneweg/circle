#include once "vm_gc.bi"

type VM_KEY_VALUE_PAIR field = 1
    KEY     as VM_BoxedValue
    VALUE   as VM_BoxedValue
end type

type VM_TABLE_NODE extends VM_KEY_VALUE_PAIR  field = 1
    MAGIC as unsigned short
    NextNode as VM_TABLE_NODE ptr
    PrevNode as VM_TABLE_NODE ptr
    
    declare constructor()
    declare destructor()
end type

type VM_TABLE extends VM_GC field = 1
    FirstNode as VM_TABLE_NODE ptr
    LastNode as VM_TABLE_NODE ptr
    
    declare constructor()
    declare destructor()
    
    declare sub RemoveNode(item as VM_TABLE_NODE ptr)
    declare sub AddNode(item as VM_TABLE_NODE ptr)
    
    declare function Exists(key as VM_BoxedValue ptr) as integer
    declare function SetValue(key as VM_BoxedValue ptr,value as VM_BoxedValue ptr) as integer
    declare function GetValue(key as VM_BoxedValue ptr) as VM_BoxedValue ptr
    declare sub VISIT()
end type

type VM_CLASS_INSTANCE extends VM_GC field = 1
    CLASS_CONTEXT   as VM_CONTEXT ptr
    FIELDS          as VM_KEY_VALUE_PAIR ptr
    FIELDSCOUNT     as unsigned long
    
    declare constructor(class as VM_CONTEXT ptr,owner as VM_CONTEXT ptr)
    declare sub SetValue(k as VM_BOXEDVALUE ptr,v as VM_BOXEDVALUE ptr)
    declare function GetValue(k as VM_BOXEDVALUE ptr) as VM_BOXEDVALUE ptr
    declare destructor()
end type

declare sub DestroyVMInstance(inst as VM_CLASS_INSTANCE ptr)
declare sub DestroyVMTable(tbl as VM_TABLE ptr)
declare sub VisitVMTable(tbl as VM_Table ptr)

#define VM_INSTANCE_MAGIC        &h3456
#define VM_TABLE_MAGIC        &h4567
#define VM_TABLE_NODE_MAGIC   &h7654

