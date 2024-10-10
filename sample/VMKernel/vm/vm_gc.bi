TYPE VM_GC field =8
    MAGIC   as unsigned short
    MAGIC2   as unsigned short
    VISITED as unsigned byte
    ADDED   as unsigned byte
    NextGC  as VM_GC ptr
    PrevGC  as VM_GC ptr
    VisitMethod as sub(gc as VM_GC ptr)
    DestroyMethod as sub(gc as VM_GC ptr)
    declare constructor()
    declare destructor()
    declare sub Destruct()
    declare sub Visit()
end type

#define GC_MAGIC &h6543