#include once "vm_method.bi"


constructor VM_METHOD(n as VM_STRING ptr,nativeptr as any ptr,vmctx as VM_CONTEXT ptr, vmptr as unsigned long)
    METHOD_NAME = n
    NATIVE_PTR  = nativeptr
    VM_PTR      =  vmptr
    VM_CTX      = vmctx
    PREV_METHOD = 0
    NEXT_METHOD = 0
end constructor