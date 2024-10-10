#include once "vm_gc.bi"

    
constructor VM_GC()
    VISITED         = 0
    ADDED           = 0
    NextGC          = 0
    PrevGC          = 0
    DestroyMethod   = 0
    VisitMethod     = 0
    MAGIC  = GC_MAGIC
    MAGIC2 = 0
end constructor

destructor VM_GC()
end destructor

sub VM_GC.Visit()
    if (this.Visited = 0) then
        this.Visited = 1
        if (VisitMethod<>0) then VisitMethod(@this)
    end if
end sub

sub VM_GC.Destruct()
    if (DestroyMethod<>0) then DestroyMethod(@this)
end sub

