type VM_METHOD field = 1
    METHOD_NAME as VM_STRING PTR
    NATIVE_PTR  as sub(ctx as VM_CONTEXT PTR,REGS as VM_BOXEDVALUE ptr, destReg as VM_BOXEDVALUE ptr)
    
    VM_PTR      as unsigned long
    VM_CTX      as VM_CONTEXT ptr
    NEXT_METHOD as VM_METHOD ptr
    PREV_METHOD as VM_METHOD ptr
    
    declare constructor(n as VM_STRING ptr,nativeptr as any ptr,vmctx as VM_CONTEXT ptr, vmptr as unsigned long)
end type


